#!/usr/bin/env python3
"""Regression cases for block-secret-dump.py. Run: python3 -I ~/.agents/hooks/test_block_secret_dump.py"""
import importlib.util
import json
import pathlib
import sys

spec = importlib.util.spec_from_file_location("hook", pathlib.Path(__file__).with_name("block-secret-dump.py"))
hook = importlib.util.module_from_spec(spec)
spec.loader.exec_module(hook)

BLOCK = [
    "dotnet user-secrets list --project X",
    "env",
    "printenv",
    "printenv API_TOKEN",
    "set",
    "export -p",
    "aspire secret list",
    "cd x && env | sort",
    "bash -c 'printenv'",
    "bash <<'EOF'\nenv\nEOF",  # heredoc fed to a shell is still shell
    "cat <<EOF\nhi\nEOF\nenv",  # commands after the heredoc are still checked
]
ALLOW = [
    "dotnet user-secrets list --project X | grep -c '^Key ='",
    "printenv HOME",
    "env FOO=1 make",
    "printenv NAME >/dev/null && echo set || echo unset",
    # Heredoc bodies are data, not shell (false positives seen 2026-11-07..10).
    "python3 - <<'EOF'\nx = set(a) | set(b)\nEOF",
    "cat > A.cs <<EOF\npublic int X { get; set; }\nEOF",
    "cat > A.cs <<-EOF\n\tpublic int X { get; set; }\n\tEOF",
    "python3 <<PY\nfor k in sorted(set(a)): print(k)\nPY\necho done",
]
PAYLOAD_ALLOW = [
    {"tool_name": "apply_patch", "tool_input": {"command": "*** Begin Patch\n+public int X { get; set; }\n"}},
    {"tool_name": "functions.apply_patch", "tool_input": {"command": "+set\n"}},
]

fails = [c for c in BLOCK if not hook.blocked(c)] + [c for c in ALLOW if hook.blocked(c)]
fails += [json.dumps(p) for p in PAYLOAD_ALLOW if hook.blocked(hook.command_from(p))]
for c in fails:
    print("FAIL:", repr(c))
print(f"{len(BLOCK) + len(ALLOW) + len(PAYLOAD_ALLOW) - len(fails)} passed, {len(fails)} failed")
sys.exit(1 if fails else 0)
