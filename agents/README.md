# Agent guidance

`AGENTS.md` is the public, harness-neutral source for global agent defaults.
The installer links that one file into each supported harness's documented
global instruction path:

```text
~/.agents/AGENTS.md
~/.codex/AGENTS.md
~/.claude/CLAUDE.md
~/.pi/agent/AGENTS.md
~/.config/opencode/AGENTS.md
~/.copilot/copilot-instructions.md
```

Repository `AGENTS.md` files remain closer, project-specific guidance.
`~/.agents/local.md` is an optional unmanaged escape hatch for private host and
workspace routing. Do not put credentials, authentication state, private
hosts, employer details, or session history in this public source.

## Personal skills

`skills.json` is the portable catalog and enabled set. Skill contents live
outside Git under `~/.local/share/skillset/catalog`; the `skillset` command
uses `gh skill` for installation and updates, and reconciles enabled skills
into `~/.agents/skills` and `~/.claude/skills`.

The optional command requires `gh` with `gh skill`, `jq`, and `fzf`; this
repository does not install them.

Run `skillset` for the interactive selector, `skillset sync` after cloning
onto another machine, and `skillset updates` before applying upstream changes
with `skillset update`.
