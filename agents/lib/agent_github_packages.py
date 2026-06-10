#!/usr/bin/env python3
import argparse
import hashlib
import os
import re
import shlex
import shutil
import subprocess
import sys
import tempfile
import tomllib
from pathlib import Path


GITHUB_RE = re.compile(r"^https://github\.com/([A-Za-z0-9_.-]+)/([A-Za-z0-9_.-]+?)(?:\.git)?/?$")
COLORS = {
    "bold": "\033[1m",
    "dim": "\033[2m",
    "green": "\033[32m",
    "red": "\033[31m",
    "yellow": "\033[33m",
    "cyan": "\033[36m",
    "reset": "\033[0m",
}
PRETTY_OUTPUT = sys.stdout.isatty()


class CommandError(Exception):
    pass


def pretty_enabled():
    return PRETTY_OUTPUT and os.environ.get("NO_COLOR") is None and os.environ.get("TERM") != "dumb"


def style(text, *styles):
    if not pretty_enabled():
        return text
    prefix = "".join(COLORS[name] for name in styles)
    return f"{prefix}{text}{COLORS['reset']}"


def hyperlink(url, text=None):
    text = text or url
    if not pretty_enabled():
        return text
    return f"\033]8;;{url}\033\\{text}\033]8;;\033\\"


def label(text):
    return style(text.ljust(16), "dim")


def commit_value(source_url, commit):
    if not pretty_enabled():
        return commit
    return hyperlink(f"{source_url}/commit/{commit}", commit[:12])


def short_commit_value(source_url, commit):
    short = commit[:12]
    if not pretty_enabled():
        return short
    return hyperlink(f"{source_url}/commit/{commit}", short)


def run(args, cwd=None):
    try:
        return subprocess.run(
            args,
            cwd=cwd,
            check=True,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        ).stdout.strip()
    except subprocess.CalledProcessError as exc:
        detail = exc.stderr.strip() or exc.stdout.strip() or str(exc)
        raise CommandError(detail) from exc


def pager_command():
    configured = os.environ.get("AGENTCTL_PAGER") or os.environ.get("PAGER")
    if configured:
        return shlex.split(configured)
    return ["less", "-FRX"]


def page_text(text):
    if not text:
        return
    if not sys.stdout.isatty() or os.environ.get("AGENTCTL_NO_PAGER"):
        print(text, end="")
        return
    command = pager_command()
    if Path(command[0]).name == "less" and not any(arg.startswith("-") and "R" in arg for arg in command[1:]):
        command.append("-R")
    try:
        subprocess.run(command, input=text, text=True, check=False)
    except FileNotFoundError:
        print(text, end="")


def maybe_page_changelog(text):
    if not text:
        return
    if sys.stdout.isatty() and not os.environ.get("AGENTCTL_NO_PAGER"):
        page_text(text)
    else:
        print(text, end="")


def agents_home():
    return Path(os.environ.get("AGENTS_DOTFILES_HOME", Path.home() / "dotfiles" / "agents"))


def cache_home():
    return Path(os.environ.get("AGENTCTL_CACHE_HOME", Path.home() / ".cache" / "agentctl" / "github"))


def parse_github_url(url):
    match = GITHUB_RE.match(url)
    if not match:
        raise CommandError("expected a GitHub HTTPS repo URL like https://github.com/owner/repo")
    owner, repo = match.groups()
    return owner, repo.removesuffix(".git"), f"https://github.com/{owner}/{repo.removesuffix('.git')}.git"


def package_name(owner, repo):
    return f"{owner.lower()}-{repo.removesuffix('.git').lower()}"


def package_dir(name):
    return agents_home() / "packages" / name


def read_toml(path):
    with path.open("rb") as f:
        return tomllib.load(f)


def quote_toml(value):
    return '"' + value.replace("\\", "\\\\").replace('"', '\\"') + '"'


def write_package_toml(path, name, url, branch, skills_path, commit):
    path.write_text(
        "\n".join(
            [
                "[package]",
                f"name = {quote_toml(name)}",
                'type = "github"',
                "",
                "[github]",
                f"url = {quote_toml(url.removesuffix('.git'))}",
                f"branch = {quote_toml(branch)}",
                f"skills_path = {quote_toml(skills_path)}",
                f"last_imported_commit = {quote_toml(commit)}",
                "",
            ]
        ),
        encoding="utf-8",
    )


def write_lock_toml(path, hashes, skill_metadata=None):
    lines = ["[files]"]
    for rel_path in sorted(hashes):
        lines.append(f"{quote_toml(rel_path)} = {quote_toml(hashes[rel_path])}")
    if skill_metadata:
        lines.append("")
        for skill in sorted(skill_metadata):
            meta = skill_metadata[skill]
            lines.append(f"[skills.{quote_toml(skill)}]")
            lines.append(f"source_path = {quote_toml(meta['source_path'])}")
            lines.append(f"group = {quote_toml(meta['group'])}")
            lines.append(f"deprecated = {str(meta['deprecated']).lower()}")
    lines.append("")
    path.write_text("\n".join(lines), encoding="utf-8")


def ensure_cache(name, url):
    cache = cache_home() / name
    cache.parent.mkdir(parents=True, exist_ok=True)
    if cache.exists():
        run(["git", "fetch", "--prune", "origin"], cwd=cache)
    else:
        run(["git", "clone", url, str(cache)])
    return cache


def default_branch(repo):
    ref = run(["git", "symbolic-ref", "refs/remotes/origin/HEAD"], cwd=repo)
    return ref.rsplit("/", 1)[-1]


def checkout_worktree(repo, branch):
    tmp = Path(tempfile.mkdtemp(prefix="agentctl-github-"))
    try:
        run(["git", "worktree", "add", "--detach", str(tmp), f"origin/{branch}"], cwd=repo)
        commit = run(["git", "rev-parse", "HEAD"], cwd=tmp)
        return tmp, commit
    except Exception:
        shutil.rmtree(tmp, ignore_errors=True)
        raise


def cleanup_worktree(repo, worktree):
    try:
        run(["git", "worktree", "remove", "--force", str(worktree)], cwd=repo)
    except CommandError:
        shutil.rmtree(worktree, ignore_errors=True)


def parse_frontmatter(skill_md):
    text = skill_md.read_text(encoding="utf-8")
    if not text.startswith("---\n"):
        raise CommandError(f"missing YAML frontmatter: {skill_md}")
    end = text.find("\n---", 4)
    if end == -1:
        raise CommandError(f"unterminated YAML frontmatter: {skill_md}")
    values = {}
    for line in text[4:end].splitlines():
        if ":" not in line:
            continue
        key, value = line.split(":", 1)
        values[key.strip()] = value.strip().strip('"').strip("'")
    return values


def discover_skills(repo_root):
    skill_mds = sorted(p for p in repo_root.rglob("SKILL.md") if ".git" not in p.parts)
    if not skill_mds:
        raise CommandError("no SKILL.md files found")

    skill_dirs = [p.parent for p in skill_mds]
    root = Path(os.path.commonpath([str(p) for p in skill_dirs]))
    if not all(root in p.parents or root == p for p in skill_dirs):
        rels = ", ".join(str(p.relative_to(repo_root)) for p in skill_dirs[:8])
        raise CommandError(f"ambiguous skill roots; found skills under multiple parents: {rels}")
    skills_path = "." if root == repo_root else str(root.relative_to(repo_root))
    return skills_path, validate_skills(root)


def validate_skills(skills_root):
    skills = {}
    skill_dirs = sorted(p.parent for p in skills_root.rglob("SKILL.md") if ".git" not in p.parts)
    for skill_dir in skill_dirs:
        metadata = parse_frontmatter(skill_dir / "SKILL.md")
        name = metadata.get("name")
        description = metadata.get("description")
        if not name or not description:
            raise CommandError(f"missing name or description in {skill_dir / 'SKILL.md'}")
        if name != skill_dir.name:
            raise CommandError(f"skill directory/name mismatch: {skill_dir.name} has frontmatter name {name}")
        if name in skills:
            raise CommandError(f"duplicate skill name: {name}")
        skills[name] = skill_dir
    if not skills:
        raise CommandError(f"no immediate skill directories found under {skills_root}")
    return skills


def file_hash(path):
    digest = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            digest.update(chunk)
    return "sha256:" + digest.hexdigest()


def collect_hashes(root):
    hashes = {}
    for path in sorted(p for p in root.rglob("*") if p.is_file() and ".git" not in p.parts):
        hashes[str(path.relative_to(root))] = file_hash(path)
    return hashes


def collect_skill_hashes_from_source(skills_root, skills):
    hashes = {}
    for name, src in skills.items():
        for path in sorted(p for p in src.rglob("*") if p.is_file() and ".git" not in p.parts):
            rel = Path("skills") / name / path.relative_to(src)
            hashes[str(rel)] = file_hash(path)
    return hashes


def read_lock(pkg):
    lock = pkg / "package-lock.toml"
    if not lock.exists():
        raise CommandError(f"missing package-lock.toml: {lock}")
    data = read_toml(lock)
    return data.get("files", {})


def local_modified(pkg):
    expected = read_lock(pkg)
    current_root = pkg
    current = {}
    for rel in expected:
        path = current_root / rel
        if not path.exists() or not path.is_file():
            return True
        current[rel] = file_hash(path)
    extra = [
        str(p.relative_to(pkg))
        for p in (pkg / "skills").rglob("*")
        if p.is_file() and ".git" not in p.parts and str(p.relative_to(pkg)) not in expected
    ]
    return current != expected or bool(extra)


def diff_skills(old_hashes, new_hashes):
    old_skills = {Path(p).parts[1] for p in old_hashes if p.startswith("skills/") and len(Path(p).parts) > 2}
    new_skills = {Path(p).parts[1] for p in new_hashes if p.startswith("skills/") and len(Path(p).parts) > 2}
    added = sorted(new_skills - old_skills)
    removed = sorted(old_skills - new_skills)
    changed = []
    for skill in sorted(old_skills & new_skills):
        old = {p: h for p, h in old_hashes.items() if p.startswith(f"skills/{skill}/")}
        new = {p: h for p, h in new_hashes.items() if p.startswith(f"skills/{skill}/")}
        if old != new:
            changed.append(skill)
    return added, removed, changed


def enabled_affected(pkg_name, skills):
    enabled_dir = Path(os.environ.get("AGENTS_SKILLS_HOME", Path.home() / ".agents" / "skills"))
    affected = []
    for skill in skills:
        link = enabled_dir / skill
        if link.is_symlink() and str(link.resolve()).startswith(str((package_dir(pkg_name) / "skills").resolve())):
            affected.append(skill)
    return sorted(affected)


def print_skill_list(title, skills):
    if not skills:
        return
    print()
    print(style(f"{title} ({len(skills)})", "bold"))
    for skill in skills:
        print(f"  {style('-', 'dim')} {skill}")


def print_changelog(name, source, old_commit, new_commit, changelog):
    if old_commit is None or changelog is None:
        return

    print()
    print(style("Changelog", "bold"))
    compare = f"{source}/compare/{old_commit}...{new_commit}"
    print(f"  {label('Compare')}{hyperlink(compare)}")

    if old_commit == new_commit:
        print("  no upstream commits")
        return
    if not changelog:
        print("  no upstream commits")
        return

    lines = [
        f"Package: {name}",
        f"Compare: {compare}",
        "",
    ]
    for commit, date, message in changelog:
        message_lines = message.rstrip().splitlines() or ["<empty commit message>"]
        lines.append(f"  {short_commit_value(source, commit)}  {style(date, 'dim')}  {message_lines[0]}")
        for line in message_lines[1:]:
            if line:
                lines.append(f"                            {line}")
            else:
                lines.append("")
    maybe_page_changelog("\n".join(lines) + "\n")


def git_changelog(repo, old_commit, new_commit):
    if old_commit == new_commit:
        return []
    output = run(
        [
            "git",
            "log",
            "--date=short",
            "--pretty=format:%H%x1f%ad%x1f%B%x1e",
            f"{old_commit}..{new_commit}",
        ],
        cwd=repo,
    )
    entries = []
    for record in output.split("\x1e"):
        record = record.strip()
        if not record:
            continue
        commit, date, message = record.split("\x1f", 2)
        entries.append((commit, date, message))
    return entries


def print_preview(kind, name, url, branch, old_commit, new_commit, added, removed, changed, affected, skills_path=None, changelog=None):
    action = "Import preview" if kind == "import-github" else "Update preview"
    print(style(action, "bold", "cyan"))
    print()
    source = url.removesuffix(".git")
    print(f"  {label('Package')}{name}")
    print(f"  {label('Source')}{hyperlink(source)}")
    print(f"  {label('Branch')}{branch}")
    if skills_path:
        print(f"  {label('Skills path')}{skills_path}")
    if old_commit:
        print(f"  {label('Current commit')}{commit_value(source, old_commit)}")
    print(f"  {label('Fetched commit')}{commit_value(source, new_commit)}")

    print_changelog(name, source, old_commit, new_commit, changelog)

    print_skill_list(style("Added skills", "green"), added)
    print_skill_list(style("Removed skills", "red"), removed)
    print_skill_list(style("Changed skills", "yellow"), changed)
    print_skill_list(style("Enabled skills affected", "yellow"), affected)

    if not added and not removed and not changed:
        print()
        print(f"{style('Skill content changes', 'bold')}: none")


def sync_package(pkg, skills, name, url, branch, skills_path, commit, skills_root):
    if pkg.exists():
        shutil.rmtree(pkg / "skills", ignore_errors=True)
    (pkg / "skills").mkdir(parents=True, exist_ok=True)
    for skill_name, src in skills.items():
        shutil.copytree(src, pkg / "skills" / skill_name, copy_function=shutil.copy2)
    write_package_toml(pkg / "package.toml", name, url, branch, skills_path, commit)
    write_lock_toml(
        pkg / "package-lock.toml",
        imported_hashes_from_installed_package(pkg),
        skill_metadata_from_source(skills_root, skills),
    )


def load_package(name):
    pkg = package_dir(name)
    manifest = pkg / "package.toml"
    if not pkg.exists():
        raise CommandError(f"unknown package: {name}")
    if not manifest.exists():
        raise CommandError(f"package has no package.toml and is not update-owned: {pkg}")
    data = read_toml(manifest)
    if data.get("package", {}).get("type") != "github":
        raise CommandError(f"package is not GitHub-backed: {name}")
    gh = data.get("github", {})
    return pkg, data["package"]["name"], gh["url"], gh["branch"], gh["skills_path"], gh["last_imported_commit"]


def imported_hashes_from_source(skills):
    hashes = {}
    for name, src in skills.items():
        for path in sorted(p for p in src.rglob("*") if p.is_file() and ".git" not in p.parts):
            hashes[str(Path("skills") / name / path.relative_to(src))] = file_hash(path)
    return hashes


def skill_metadata_from_source(skills_root, skills):
    metadata = {}
    for name, src in skills.items():
        relative = src.relative_to(skills_root)
        parent = relative.parent
        metadata[name] = {
            "source_path": str(relative),
            "group": "." if str(parent) == "." else str(parent),
            "deprecated": "deprecated" in relative.parts,
        }
    return metadata


def skill_labels(names, metadata):
    labels = []
    for name in names:
        source_path = metadata.get(name, {}).get("source_path")
        labels.append(source_path or name)
    return sorted(labels)


def imported_hashes_from_installed_package(pkg):
    skills_root = pkg / "skills"
    hashes = {}
    if not skills_root.exists():
        return hashes
    for path in sorted(p for p in skills_root.rglob("*") if p.is_file() and ".git" not in p.parts):
        hashes[str(Path("skills") / path.relative_to(skills_root))] = file_hash(path)
    return hashes


def import_github(args):
    owner, repo_name, clone_url = parse_github_url(args.url)
    name = package_name(owner, repo_name)
    pkg = package_dir(name)
    if pkg.exists():
        raise CommandError(f"package already exists: {pkg}\nmove or remove it, then rerun import-github")

    cache = ensure_cache(name, clone_url)
    branch = default_branch(cache)
    worktree, commit = checkout_worktree(cache, branch)
    try:
        skills_path, skills = discover_skills(worktree)
        skills_root = worktree if skills_path == "." else worktree / skills_path
        metadata = skill_metadata_from_source(skills_root, skills)
        added = sorted(skills)
        print_preview("import-github", name, clone_url, branch, None, commit, skill_labels(added, metadata), [], [], [], skills_path)
        if not args.apply:
            print()
            print(f"{style('Next', 'bold')}: rerun with {style('--apply', 'cyan')} to write files.")
            return
        sync_package(pkg, skills, name, clone_url, branch, skills_path, commit, skills_root)
        print(f"imported: {pkg}")
    finally:
        cleanup_worktree(cache, worktree)


def update_one(name, apply):
    pkg, manifest_name, url, branch, skills_path, old_commit = load_package(name)
    if apply and local_modified(pkg):
        raise CommandError(f"local modifications detected in update-owned package: {pkg}")

    owner, repo_name, clone_url = parse_github_url(url)
    cache = ensure_cache(package_name(owner, repo_name), clone_url)
    worktree, commit = checkout_worktree(cache, branch)
    try:
        skills_root = worktree if skills_path == "." else worktree / skills_path
        skills = validate_skills(skills_root)
        metadata = skill_metadata_from_source(skills_root, skills)
        old_hashes = read_lock(pkg)
        new_hashes = imported_hashes_from_source(skills)
        added, removed, changed = diff_skills(old_hashes, new_hashes)
        affected = enabled_affected(manifest_name, set(added + removed + changed))
        changelog = git_changelog(worktree, old_commit, commit)
        print_preview(
            "update",
            manifest_name,
            clone_url,
            branch,
            old_commit,
            commit,
            skill_labels(added, metadata),
            removed,
            skill_labels(changed, metadata),
            affected,
            skills_path,
            changelog,
        )
        if not apply:
            print()
            print(f"{style('Next', 'bold')}: rerun with {style('--apply', 'cyan')} to write files.")
            return "preview"
        sync_package(pkg, skills, manifest_name, clone_url, branch, skills_path, commit, skills_root)
        print(f"updated: {pkg}")
        return "applied"
    finally:
        cleanup_worktree(cache, worktree)


def update_all(args):
    failures = []
    packages_root = agents_home() / "packages"
    names = []
    for manifest in sorted(packages_root.glob("*/package.toml")):
        try:
            data = read_toml(manifest)
        except Exception:
            continue
        if data.get("package", {}).get("type") == "github":
            names.append(manifest.parent.name)
    if not names:
        print("no GitHub-backed packages found")
        return
    for name in names:
        try:
            update_one(name, args.apply)
        except CommandError as exc:
            failures.append((name, str(exc)))
            print(f"blocked: {name}: {exc}")
    if failures:
        raise CommandError(f"{len(failures)} package(s) blocked or failed")


def main(argv):
    parser = argparse.ArgumentParser(prog="agentctl")
    sub = parser.add_subparsers(dest="command", required=True)
    import_parser = sub.add_parser("import-github")
    import_parser.add_argument("url")
    import_parser.add_argument("--apply", action="store_true")
    update_parser = sub.add_parser("update")
    update_parser.add_argument("package", nargs="?")
    update_parser.add_argument("--all", action="store_true")
    update_parser.add_argument("--apply", action="store_true")
    args = parser.parse_args(argv)

    try:
        if args.command == "import-github":
            import_github(args)
        elif args.command == "update":
            if args.all:
                if args.package:
                    raise CommandError("use either update <package> or update --all, not both")
                update_all(args)
            else:
                if not args.package:
                    raise CommandError("missing package; use update <package> or update --all")
                update_one(args.package, args.apply)
    except CommandError as exc:
        print(str(exc), file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
