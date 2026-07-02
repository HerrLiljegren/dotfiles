---
name: seqcli
description: "Use this skill when Codex needs to operate Seq through Datalust seqcli: configure connections and profiles, query/search/tail events, ingest CLEF/JSON or plain-text logs, send test events, inspect health, create API keys for automation, export/import Seq templates, or manage Seq resources from the command line. Use it for requests mentioning Seq CLI, seqcli, Seq logs, CLEF ingestion, Seq queries, Seq signals, Seq dashboards/templates, or command-line Seq administration."
---

# Seq CLI

Use `seqcli` for command-line work against a Seq server. Prefer exact command help or the bundled Datalust reference before guessing flags.

## First Checks

1. Check availability with `seqcli version` or `seqcli help`.
2. Identify the target Seq server and authentication method before running commands that connect.
3. Prefer `--profile <name>` when the environment has named Seq connections.
4. Prefer command-scoped `--server` and `--apikey` for one-off or sensitive runs.
5. Avoid storing API keys in config on Linux/macOS unless the user explicitly wants it; Datalust documents that `SeqCli.json` stores keys in plain text there.

## Configuration

Set defaults only when persistent local configuration is intended:

```bash
seqcli config set -k connection.serverUrl -v https://your-seq-server
seqcli config set -k connection.apiKey -v your-api-key
```

Use environment overrides for automation:

```bash
SEQCLI_CONNECTION_SERVERURL=https://your-seq-server
```

Use profiles when switching between servers:

```bash
seqcli profile create -n local -s http://localhost:5341 -a "$SEQ_API_KEY"
seqcli profile list
seqcli search --profile local -f "@Level = 'Error'" -c 20
```

For exact profile/config flags, read `references/command-line-client.md` around `### config set` and `### profile create`.

## Query And Inspect Logs

Use `search` for event retrieval, `query` for SQL-style aggregation, and `tail` for live streams.

```bash
seqcli search -f "@Exception like '%TimeoutException%'" -c 30 --start="2026-07-02T00:00:00Z" --json
seqcli query -q "select count(*) from stream group by @Level" --start="2026-07-02T00:00:00Z" --json
seqcli tail -f "@Level = 'Error'" --json
```

Rules:

- Always bound broad searches with `--start`, `--end`, `--count`, or a selective filter.
- Use `--json` when another tool will parse output.
- Use `--signal <signal-expression-or-ids>` when the user refers to a Seq signal.
- Use `--trace` only for query/search diagnostics.

For exact flags, read the bundled reference around `### query`, `### search`, and `### tail`.

## Ingest Logs

Use `ingest` for files or `STDIN`; use `log` for a single structured test event.

```bash
seqcli ingest -i "log-*.clef" --json -p Environment=Test
seqcli ingest -i app.log -x "{@t:timestamp} [{@l:level}] {@m:*}{:n}{@x:*}" --invalid-data=ignore
seqcli log -m "Smoke test from {Source}" -p Source=seqcli -l Information
```

Rules:

- Use `--json` for CLEF/JSON input.
- Use `-x`/`--extract` only for plain-text logs.
- Add stable enrichment with repeated `-p Name=Value`.
- Set `--invalid-data=ignore` only when dropping malformed lines is acceptable.
- Set `--send-failure=retry` for transient network conditions when ingesting important batches.

For extraction-pattern syntax and matchers, read `references/command-line-client.md` from `## Extraction patterns`.

## Health And Automation

Use unauthenticated node health checks when only liveness is needed:

```bash
seqcli node health -s http://localhost:5341
seqcli cluster health -s http://localhost:5341
```

For first-run automation, create an API key by piping the password to `apikey create` with `--connect-password-stdin`; do not place passwords directly in command arguments.

```bash
printf '%s\n' "$SEQ_ADMIN_PASSWORD" |
  seqcli apikey create \
    -t CLI \
    --permissions="read,write,project,organization,system" \
    --connect-username "$SEQ_ADMIN_USER" \
    --connect-password-stdin
```

When managing dashboards, signals, retention policies, workspaces, users, API keys, apps, or settings, prefer list-before-update/remove flows and use `--json` where supported so ids and titles are unambiguous.

## Templates

Use templates to move shared Seq entities between environments:

```bash
mkdir -p ./Templates
seqcli template export -o ./Templates --profile source
seqcli template import -i ./Templates --profile target --merge
```

Read `references/command-line-client.md` around `### template export` and `### template import` for state-file, argument, and include behavior.

## Reference

The full ingested Datalust command-line client documentation is in `references/command-line-client.md`.

Useful lookup anchors:

- `## Getting started`
- `### Environment variable overrides`
- `### Connecting without an API key`
- `### config set`
- `### profile create`
- `### query`
- `### search`
- `### tail`
- `### ingest`
- `### log`
- `### node health`
- `### cluster health`
- `### template export`
- `### template import`
- `## Extraction patterns`
