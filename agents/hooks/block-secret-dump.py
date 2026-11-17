#!/usr/bin/env python3
"""PreToolUse guard shared by Claude Code and Codex: refuse shell commands that print secret values.

Reads the hook payload on stdin and exits 2 with a message on stderr when the command would dump
secrets, which both harnesses treat as a denial. Anything it can't parse is allowed: this is a
guard against an agent's habit of listing secrets to check one key, not a sandbox.

Blocked unless every value is filtered away (a later pipe stage of `grep -q`, `grep -c`, `wc`, or
`cut ... -f1`, or stdout sent to /dev/null):
  - dotnet user-secrets list
  - aspire secret list | get
  - env / printenv / export -p / declare -p|-x / set, with no names
  - printenv NAME, when NAME looks like a secret
  - reading a user-secrets store (~/.microsoft/usersecrets, %APPDATA%\\Microsoft\\UserSecrets)
"""
import json
import re
import shlex
import sys

SECRETISH = re.compile(r"(KEY|TOKEN|SECRET|PASSWORD|PASSWD|PWD|CONNECTION|CONNSTR|CREDENTIAL|AUTH)", re.I)
READERS = {"cat", "less", "more", "head", "tail", "jq", "bat", "type", "Get-Content", "gc", "strings", "xxd"}
SHELLS = {"sh", "bash", "zsh", "dash", "pwsh", "powershell"}
SEPARATORS = {";", "&&", "||", "\n", "&", "(", ")"}

MESSAGE = """Blocked: this command would print secret values into the transcript.
Check one key and report only set or unset, for example:
  dotnet user-secrets list --project <proj> | grep -c '^<Key> ='
  dotnet user-secrets list --project <proj> | cut -d= -f1      (key names only)
  aspire secret get <Key> --apphost <apphost> >/dev/null && echo set || echo unset
  printenv <NAME> >/dev/null && echo set || echo unset
Never print a value. If you really need one, ask the user."""


def tokens(command: str):
    lexer = shlex.shlex(command, posix=True, punctuation_chars=";&|()<>")
    lexer.whitespace_split = True
    lexer.commenters = ""
    return list(lexer)


def pipelines(toks):
    """Split into pipelines, each a list of stages (token lists)."""
    current, stage, out = [], [], []
    for tok in toks:
        if tok in SEPARATORS or tok in (";;", "&&&"):
            current.append(stage)
            out.append(current)
            current, stage = [], []
        elif tok in ("|", "|&"):
            current.append(stage)
            stage = []
        else:
            stage.append(tok)
    current.append(stage)
    out.append(current)
    return [[s for s in p if s] for p in out if any(p)]


def command_words(stage):
    """Drop leading VAR=value assignments and wrappers such as sudo/command/exec."""
    words = list(stage)
    while words and (re.match(r"^[A-Za-z_][A-Za-z0-9_]*=", words[0]) or words[0] in ("sudo", "command", "exec", "time", "nohup")):
        words.pop(0)
    return words


def silenced(stage):
    for i, tok in enumerate(stage):
        if tok in (">", "&>", "1>") and i + 1 < len(stage) and stage[i + 1] == "/dev/null":
            return True
        if tok in (">/dev/null", "&>/dev/null", "1>/dev/null"):
            return True
    return False


def quiet_filter(stage):
    words = command_words(stage)
    if not words:
        return False
    name = words[0].rsplit("/", 1)[-1]
    flags = "".join(w[1:] for w in words[1:] if re.match(r"^-[A-Za-z]+$", w))
    if name in ("grep", "egrep", "fgrep", "rg"):
        return bool(set(flags) & set("qcl")) or "--count" in words or "--quiet" in words
    if name == "wc":
        return True
    if name == "cut":
        return any(w in ("-f1", "-f", "--fields=1") for w in words) and not any(w.startswith("-f") and w not in ("-f", "-f1") for w in words)
    if name in ("test", "true", "false"):
        return True
    return False


def dumps(stage):
    words = command_words(stage)
    if not words:
        return False
    name = words[0].rsplit("/", 1)[-1]
    args = [w for w in words[1:] if not w.startswith(">") and w not in ("2", "2>&1")]
    lowered = [w.lower() for w in words]
    if "user-secrets" in lowered and "list" in lowered:
        return True
    if name == "aspire" and "secret" in lowered and ("list" in lowered or "get" in lowered):
        return True
    if name in ("env", "printenv"):
        names = [a for a in args if not a.startswith("-")]
        if name == "env":
            # `env FOO=bar cmd` runs a command; only a bare `env` (or env -0) dumps.
            return not names
        return not names or any(SECRETISH.search(n) for n in names)
    if name == "export" and (not args or args == ["-p"]):
        return True
    if name in ("declare", "typeset") and args and all(a.startswith("-") for a in args) and any(set(a) & set("px") for a in args):
        return True
    if name == "set" and not args:
        return True
    if name in READERS and any(re.search(r"usersecrets", w, re.I) for w in words[1:]):
        return True
    return False


HEREDOC = re.compile(r"<<(-?)\s*(['\"]?)([A-Za-z_][A-Za-z0-9_]*)\2")


def shell_lines(command: str):
    """Yield the lines to parse as shell, skipping heredoc bodies.

    A heredoc body is data (Python, C#, JSON), and lines such as `{ get; set; }` or
    `x = set(a)` would otherwise read as a bare `set`. A body fed to a shell
    (`bash <<EOF`) is still shell, so it is kept.
    """
    lines = command.splitlines()
    i = 0
    while i < len(lines):
        line = lines[i]
        yield line
        i += 1
        for strip_tabs, _, delim in HEREDOC.findall(line):
            try:
                first = command_words(pipelines(tokens(line.split("<<", 1)[0]))[-1][-1])
            except (ValueError, IndexError):
                first = []
            feeds_shell = bool(first) and first[0].rsplit("/", 1)[-1] in SHELLS
            while i < len(lines):
                body = lines[i].lstrip("\t") if strip_tabs else lines[i]
                i += 1
                if body == delim:
                    break
                if feeds_shell:
                    yield lines[i - 1]


def blocked(command: str) -> bool:
    all_pipelines = []
    for line in shell_lines(command):
        try:
            all_pipelines += pipelines(tokens(line))
        except ValueError:
            continue
    for pipeline in all_pipelines:
        for i, stage in enumerate(pipeline):
            words = command_words(stage)
            if words and words[0].rsplit("/", 1)[-1] in SHELLS:
                inline = [w for j, w in enumerate(words) if j > 0 and words[j - 1] in ("-c", "-lc", "-Command", "-command")]
                if any(blocked(script) for script in inline):
                    return True
            if not dumps(stage) or silenced(stage):
                continue
            if any(quiet_filter(later) for later in pipeline[i + 1 :]):
                continue
            return True
    return False


def command_from(payload) -> str:
    # Patch text is source data, not a shell command. Preserve shell checks for
    # every other tool, including unnamed/legacy payloads.
    tool_name = str(payload.get("tool_name", "")).rsplit(".", 1)[-1]
    if tool_name == "apply_patch":
        return ""
    tool_input = payload.get("tool_input") or {}
    cmd = tool_input.get("command", "")
    if isinstance(cmd, list):
        # Codex sometimes passes argv, e.g. ["bash", "-lc", "<script>"].
        cmd = cmd[-1] if len(cmd) >= 3 and cmd[1] in ("-c", "-lc") else " ".join(cmd)
    return cmd if isinstance(cmd, str) else ""


def main():
    if len(sys.argv) > 1 and sys.argv[1] == "--check":
        # Test mode: classify the command given as the second argument.
        print("block" if blocked(sys.argv[2]) else "allow")
        return 0
    try:
        payload = json.load(sys.stdin)
    except Exception:
        return 0
    if blocked(command_from(payload)):
        print(MESSAGE, file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
