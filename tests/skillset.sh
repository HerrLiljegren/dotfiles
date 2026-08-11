#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/bin/skillset"
TEST_ROOT="$(mktemp -d)"
MANIFEST="$TEST_ROOT/skills.json"
CATALOG="$TEST_ROOT/catalog"
AGENTS_DIR="$TEST_ROOT/agents"
CLAUDE_DIR="$TEST_ROOT/claude"
FAKE_BIN="$TEST_ROOT/bin"
GH_LOG="$TEST_ROOT/gh.log"
FZF_LOG="$TEST_ROOT/fzf.log"

cleanup() {
  rm -rf -- "$TEST_ROOT"
}
trap cleanup EXIT

fail() {
  printf 'test failure: %s\n' "$*" >&2
  exit 1
}

run_skillset() {
  SKILLSET_MANIFEST="${SKILLSET_MANIFEST:-$MANIFEST}" \
  SKILLSET_CATALOG="${SKILLSET_CATALOG:-$CATALOG}" \
  SKILLSET_AGENTS_DIR="${SKILLSET_AGENTS_DIR:-$AGENTS_DIR}" \
  SKILLSET_CLAUDE_DIR="${SKILLSET_CLAUDE_DIR:-$CLAUDE_DIR}" \
  GH_LOG="$GH_LOG" \
  FZF_LOG="$FZF_LOG" \
  SKILLSET_COLUMNS=120 \
  FAKE_GH_FAIL_INSTALL="${FAKE_GH_FAIL_INSTALL:-}" \
  PATH="$FAKE_BIN:$PATH" \
    "$SCRIPT" "$@"
}

write_manifest() {
  printf '%s\n' \
    '{' \
    '  "version": 1,' \
    '  "skills": [' \
    '    {"name":"alpha","source":"example/skills","selector":"alpha","description":"Alpha skill","enabled":true},' \
    '    {"name":"exact","source":"example/exact","selector":"src/Resources/exact/SKILL.md","description":"Exact-path skill","enabled":false},' \
    '    {"name":"gamma","source":"zeta/more","selector":"gamma","description":"Gamma skill","enabled":true},' \
    '    {"name":"beta","source":"example/skills","selector":"beta","description":"Beta skill","enabled":false}' \
    '  ]' \
    '}' >"$MANIFEST"
}

install_fixture_skill() {
  local name=$1 description=${2:-Fixture skill}
  mkdir -p -- "$CATALOG/$name"
  printf '%s\n' \
    '---' \
    "name: $name" \
    "description: $description" \
    '---' >"$CATALOG/$name/SKILL.md"
}

mkdir -p -- "$FAKE_BIN"
printf '%s\n' \
  '#!/usr/bin/env bash' \
  'set -euo pipefail' \
  'wanted=",${FAKE_FZF_SELECTED:-},"' \
  'while IFS= read -r row; do' \
  '  printf "%s\n" "$row" >>"$FZF_LOG"' \
  '  first=${row%%$'"'"'\t'"'"'*}' \
  '  remainder=${row#*$'"'"'\t'"'"'}' \
  '  name=${remainder%%$'"'"'\t'"'"'*}' \
  '  [[ -n "$name" ]] || name=$first' \
  '  if [[ "$wanted" == *",$name,"* ]]; then printf "%s\n" "$row"; fi' \
  'done' >"$FAKE_BIN/fzf"
chmod +x "$FAKE_BIN/fzf"

printf '%s\n' \
  '#!/usr/bin/env bash' \
  'set -euo pipefail' \
  'catalog='"'"''"'" \
  'for ((index=1; index <= $#; index++)); do' \
  '  if [[ ${!index} == --dir ]]; then next=$((index + 1)); catalog=${!next}; fi' \
  'done' \
  'case "${1:-} ${2:-}" in' \
  '  "skill list")' \
  '    printf "["' \
  '    separator='"'"''"'" \
  '    if [[ -d "$catalog" ]]; then' \
  '      for path in "$catalog"/*; do' \
  '        [[ -f "$path/SKILL.md" ]] || continue' \
  '        name=${path##*/}' \
  '        printf "%s" "$separator"' \
  '        jq -cn --arg name "productivity/$name" --arg path "$path" '\''{skillName:$name,path:$path,sourceURL:"https://github.com/example/skills",version:"main",pinned:false}'\''' \
  '        separator=,' \
  '      done' \
  '    fi' \
  '    printf "]\n"' \
  '    ;;' \
  '  "skill install")' \
  '    printf "verbose gh install output\n"' \
  '    if [[ ${FAKE_GH_FAIL_INSTALL:-} == 1 ]]; then printf "fake install failed\n" >&2; exit 42; fi' \
  '    install_skill() {' \
  '      local name=$1' \
  '      mkdir -p -- "$catalog/$name"' \
  '      printf "%s\n" --- "name: $name" "description: >" "  Added from GitHub" "  with folded text." "metadata:" "    github-tree-sha: new-tree-sha" --- >"$catalog/$name/SKILL.md"' \
  '    }' \
  '    selector=${4:-}' \
  '    [[ -n $selector && $selector != --* ]] || { printf "group/bundle-one\tFirst bundled skill\ngroup/bundle-two\tSecond bundled skill\n"; exit; }' \
  '    if [[ $selector == */SKILL.md ]]; then parent=${selector%/SKILL.md}; name=${parent##*/}; else name=${selector##*/}; fi' \
  '    install_skill "$name"' \
  '    ;;' \
  '  "skill update") printf "%s\n" "$*" >>"$GH_LOG" ;;' \
  '  *) exit 2 ;;' \
  'esac' >"$FAKE_BIN/gh"
chmod +x "$FAKE_BIN/gh"

write_manifest
install_fixture_skill alpha
install_fixture_skill beta
mkdir -p -- "$CATALOG/exact"
printf '%s\n' \
  '---' \
  'name: exact' \
  'description: Exact-path skill' \
  'metadata:' \
  '    github-tree-sha: old-tree-sha' \
  '---' >"$CATALOG/exact/SKILL.md"
install_fixture_skill gamma

run_skillset sync >/dev/null
for root in "$AGENTS_DIR" "$CLAUDE_DIR"; do
  [[ "$(readlink -- "$root/alpha")" == "$CATALOG/alpha" ]] || fail "alpha was not enabled in $root"
  [[ ! -e "$root/beta" ]] || fail "beta was unexpectedly enabled in $root"
  [[ "$(readlink -- "$root/gamma")" == "$CATALOG/gamma" ]] || fail "gamma was not enabled in $root"
done

for root in "$AGENTS_DIR" "$CLAUDE_DIR"; do
  mkdir -p -- "$root/tengella-style"
  printf 'foreign skill\n' >"$root/tengella-style/SKILL.md"
done
run_skillset sync >/dev/null
for root in "$AGENTS_DIR" "$CLAUDE_DIR"; do
  [[ -f "$root/tengella-style/SKILL.md" ]] ||
    fail "sync changed a foreign skill in $root"
done

rm -rf -- "$CLAUDE_DIR"
ln -s -- "$AGENTS_DIR" "$CLAUDE_DIR"
run_skillset sync >/dev/null
[[ -d "$CLAUDE_DIR" && ! -L "$CLAUDE_DIR" ]] ||
  fail 'sync did not migrate the shared Claude skill-directory symlink'
[[ "$(readlink -- "$CLAUDE_DIR/alpha")" == "$CATALOG/alpha" ]] ||
  fail 'sync did not populate the migrated Claude skill directory'

before="$(find "$AGENTS_DIR" "$CLAUDE_DIR" -mindepth 1 -maxdepth 1 -printf '%p -> %l\n' | sort)"
run_skillset sync >/dev/null
after="$(find "$AGENTS_DIR" "$CLAUDE_DIR" -mindepth 1 -maxdepth 1 -printf '%p -> %l\n' | sort)"
[[ "$before" == "$after" ]] || fail 'sync was not idempotent'

rm -rf -- "$CATALOG/beta"
printf 'y\n' | FAKE_FZF_SELECTED='alpha,beta' run_skillset >/dev/null
mapfile -t picker_input <"$FZF_LOG"
[[ "${picker_input[0]}" == CREATOR*SKILL*DESCRIPTION*STATUS*SOURCE* ]] ||
  fail 'picker did not render column headings'
[[ "${picker_input[1]}" == example*exact*'Exact-path skill'*installed*exact* ]] ||
  fail 'picker did not render the exact-path skill row'
[[ "${picker_input[2]}" == example*alpha*'Alpha skill'*installed*skills* ]] ||
  fail 'picker did not render the installed skill row'
[[ "${picker_input[3]}" == example*beta*'Beta skill'*'not installed'*skills* ]] ||
  fail 'picker did not group skills or render the missing skill row'
[[ "${picker_input[4]}" == zeta*gamma*'Gamma skill'*installed*more* ]] ||
  fail 'picker did not sort creator groups'
jq -e '[.skills[] | select(.enabled) | .name] == ["alpha", "beta"]' \
  "$MANIFEST" >/dev/null || fail 'picker did not update the manifest'
for root in "$AGENTS_DIR" "$CLAUDE_DIR"; do
  [[ -L "$root/alpha" && -L "$root/beta" ]] || fail "picker did not enable selected skills in $root"
  [[ ! -e "$root/gamma" ]] || fail "picker did not disable gamma in $root"
done

conflict_root="$TEST_ROOT/conflict"
mkdir -p -- "$conflict_root"
mkdir -p -- "$conflict_root/alpha"
printf 'foreign alpha\n' >"$conflict_root/alpha/SKILL.md"
if SKILLSET_AGENTS_DIR="$conflict_root" run_skillset sync >"$TEST_ROOT/conflict.out" 2>&1; then
  fail 'sync accepted a foreign entry with a managed name'
fi
grep -Fq 'foreign entry conflicts with managed skill' "$TEST_ROOT/conflict.out" ||
  fail 'sync did not explain the same-name conflict'
[[ -f "$conflict_root/alpha/SKILL.md" ]] ||
  fail 'failed preflight changed the foreign same-name skill'

missing_manifest="$TEST_ROOT/missing.json"
jq '(.skills[] | select(.name == "gamma") | .enabled) = true' "$MANIFEST" >"$missing_manifest"
rm -rf -- "$CATALOG/gamma"
missing_agents="$TEST_ROOT/missing-agents"
missing_claude="$TEST_ROOT/missing-claude"
if SKILLSET_MANIFEST="$missing_manifest" \
  SKILLSET_AGENTS_DIR="$missing_agents" \
  SKILLSET_CLAUDE_DIR="$missing_claude" \
  FAKE_GH_FAIL_INSTALL=1 \
  run_skillset sync >"$TEST_ROOT/missing.out" 2>&1
then
  fail 'sync accepted a missing enabled skill'
fi
[[ ! -e "$missing_agents" && ! -e "$missing_claude" ]] ||
  fail 'failed preflight partially changed destinations'
grep -Fq 'fake install failed' "$TEST_ROOT/missing.out" ||
  fail 'failed install did not preserve gh diagnostics'

sync_output="$(SKILLSET_MANIFEST="$missing_manifest" \
SKILLSET_AGENTS_DIR="$missing_agents" \
SKILLSET_CLAUDE_DIR="$missing_claude" \
  run_skillset sync)"
[[ "$sync_output" != *'verbose gh install output'* ]] ||
  fail 'successful install leaked verbose gh output'
[[ -f "$CATALOG/gamma/SKILL.md" ]] || fail 'sync did not install a missing catalog skill'
[[ -L "$missing_agents/gamma" && -L "$missing_claude/gamma" ]] ||
  fail 'sync did not enable the newly installed skill'

run_skillset add example/skills delta >/dev/null
jq -e '
  .skills[] |
  select(.name == "delta") |
  (.enabled == false and .description == "Added from GitHub with folded text.")
' "$MANIFEST" >/dev/null || fail 'add did not record the installed skill'

FAKE_FZF_SELECTED='bundle-one' run_skillset add example/bundle >/dev/null
grep -Fq 'bundle-one' "$FZF_LOG" || fail 'repository add picker omitted the first discovery'
grep -Fq 'bundle-two' "$FZF_LOG" || fail 'repository add picker omitted the second discovery'
jq -e '
  [.skills[] | select(.source == "example/bundle") | {name, enabled}] == [
    {name: "bundle-one", enabled: true}
  ]
' "$MANIFEST" >/dev/null || fail 'repository add did not register the selected skill as enabled'
[[ -f "$CATALOG/bundle-one/SKILL.md" && ! -e "$CATALOG/bundle-two" ]] ||
  fail 'repository add did not install only the selected skill'
for root in "$AGENTS_DIR" "$CLAUDE_DIR"; do
  [[ -L "$root/bundle-one" ]] || fail "repository add did not enable the selected skill in $root"
done

run_skillset updates >"$TEST_ROOT/updates.out" 2>"$TEST_ROOT/updates.progress"
updates_output="$(<"$TEST_ROOT/updates.out")"
grep -Fq 'example/exact' "$TEST_ROOT/updates.progress" ||
  fail 'updates did not report exact-path repository progress'
grep -Fq 'example/skills' "$TEST_ROOT/updates.progress" ||
  fail 'updates did not report discoverable repository progress'
grep -Fq 'skills checked across' "$TEST_ROOT/updates.progress" ||
  fail 'updates did not report the final progress summary'
[[ "$updates_output" == *'↑ exact'* ]] ||
  fail 'updates did not report the exact-path update'
[[ "$updates_output" != *'All skills are up to date.'* ]] ||
  fail 'updates leaked current skill output'
printf 'y\n' | run_skillset update >/dev/null
grep -Fq 'skill update ' "$GH_LOG" || fail 'update commands were not delegated to gh skill'
grep -Fq -- '--dry-run' "$GH_LOG" || fail 'updates did not use dry-run'
grep -Fq 'github-tree-sha: new-tree-sha' "$CATALOG/exact/SKILL.md" ||
  fail 'update did not refresh the exact-path skill'
if grep -Fq ' exact ' "$GH_LOG"; then
  fail 'exact-path skill was delegated to gh skill update discovery'
fi

printf 'skillset behavior tests passed\n'
