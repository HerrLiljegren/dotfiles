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
  FAKE_GH_REQUIRE_EXACT_PARALLEL="${FAKE_GH_REQUIRE_EXACT_PARALLEL:-}" \
  FAKE_GH_REQUIRE_PARALLEL="${FAKE_GH_REQUIRE_PARALLEL:-}" \
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
  '    printf "%s\n" "$*" >>"$GH_LOG.install"' \
  '    printf "verbose gh install output\n"' \
  '    if [[ ${FAKE_GH_FAIL_INSTALL:-} == 1 ]]; then printf "fake install failed\n" >&2; exit 42; fi' \
  '    selector=${4:-}' \
  '    source_repo=${3:-}' \
  '    if [[ ${FAKE_GH_REQUIRE_EXACT_PARALLEL:-} == 1 && $selector == */SKILL.md ]]; then' \
  '      marker="$GH_LOG.exact-parallel.$BASHPID"' \
  '      : >"$marker"' \
  '      ready=0' \
  '      for ((attempt=0; attempt < 200; attempt++)); do' \
  '        count=0' \
  '        for candidate in "$GH_LOG".exact-parallel.*; do' \
  '          [[ ! -e $candidate ]] || count=$((count + 1))' \
  '        done' \
  '        if ((count >= 2)); then ready=1; break; fi' \
  '        sleep 0.01' \
  '      done' \
  '      ((ready)) || { printf "same-source exact checks did not overlap\n" >&2; exit 9; }' \
  '    fi' \
  '    install_skill() {' \
  '      local name=$1' \
  '      local gh_path="skills/$name"' \
  '      [[ $source_repo != example/hidden ]] || gh_path=".agents/skills/$name"' \
  '      mkdir -p -- "$catalog/$name"' \
  '      printf "%s\n" --- "name: $name" "description: >" "  Added from GitHub" "  with folded text." "metadata:" "    github-path: $gh_path" "    github-tree-sha: new-tree-sha" --- >"$catalog/$name/SKILL.md"' \
  '    }' \
  '    if [[ -n $selector && $selector != --* ]]; then' \
  '      if [[ $selector == */SKILL.md ]]; then parent=${selector%/SKILL.md}; name=${parent##*/}; else name=${selector##*/}; fi' \
  '      install_skill "$name"' \
  '    elif [[ $source_repo == example/hidden ]]; then' \
  '      printf "[hidden-dir] hidden-one\tFirst hidden skill\n[hidden-dir] hidden-two\tSecond hidden skill\n"' \
  '    else' \
  '      printf "group/bundle-one\tFirst bundled skill\ngroup/bundle-two\tSecond bundled skill\n"' \
  '    fi' \
  '    ;;' \
  '  "skill update")' \
  '    printf "%s\n" "$*" >>"$GH_LOG"' \
  '    if [[ ${FAKE_GH_REQUIRE_PARALLEL:-} == 1 ]]; then' \
  '      marker="$GH_LOG.parallel.$BASHPID"' \
  '      : >"$marker"' \
  '      ready=0' \
  '      for ((attempt=0; attempt < 200; attempt++)); do' \
  '        count=0' \
  '        for candidate in "$GH_LOG".parallel.*; do' \
  '          [[ ! -e $candidate ]] || count=$((count + 1))' \
  '        done' \
  '        if ((count >= 2)); then ready=1; break; fi' \
  '        sleep 0.01' \
  '      done' \
  '      ((ready)) || { printf "parallel update check did not overlap\n" >&2; exit 9; }' \
  '    fi' \
  '    ;;' \
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

help_output="$(run_skillset --help)"
[[ "$help_output" == *'Choose which catalog skills are enabled'* ]] ||
  fail 'help did not explain the interactive picker'
[[ "$help_output" == *'Example: skillset sync'* ]] ||
  fail 'help did not include a sync example'
[[ "$help_output" == *'Example: skillset updates'* ]] ||
  fail 'help did not include an updates example'
[[ "$help_output" == *'Example: skillset update'* ]] ||
  fail 'help did not include an update example'
[[ "$help_output" == *'Example: skillset add mattpocock/skills'* ]] ||
  fail 'help did not include a repository add example'
[[ "$help_output" == *'Example: skillset add richlander/dotnet-inspect dotnet-inspect'* ]] ||
  fail 'help did not include a selector add example'
[[ "$help_output" == *'--allow-hidden-dirs'* ]] ||
  fail 'help did not document --allow-hidden-dirs'

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
printf '\n' | FAKE_FZF_SELECTED='alpha,beta' run_skillset >/dev/null
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

printf '\033' | FAKE_FZF_SELECTED='alpha' run_skillset >/dev/null
jq -e '[.skills[] | select(.enabled) | .name] == ["alpha", "beta"]' \
  "$MANIFEST" >/dev/null || fail 'Esc did not cancel the picker review'

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

printf '\n' | FAKE_FZF_SELECTED='bundle-one' run_skillset add example/bundle >/dev/null
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

parallel_manifest="$TEST_ROOT/parallel.json"
parallel_catalog="$TEST_ROOT/parallel-catalog"
mkdir -p -- "$parallel_catalog/exact-one" "$parallel_catalog/exact-two"
printf '%s\n' \
  '{"version":1,"skills":[' \
  '  {"name":"exact-one","source":"example/parallel","selector":"one/exact-one/SKILL.md","enabled":false},' \
  '  {"name":"exact-two","source":"example/parallel","selector":"two/exact-two/SKILL.md","enabled":false}' \
  ']}' >"$parallel_manifest"
for name in exact-one exact-two; do
  printf '%s\n' --- "name: $name" metadata: '    github-tree-sha: old-tree-sha' --- \
    >"$parallel_catalog/$name/SKILL.md"
done
FAKE_GH_REQUIRE_EXACT_PARALLEL=1 \
SKILLSET_MANIFEST="$parallel_manifest" \
SKILLSET_CATALOG="$parallel_catalog" \
  run_skillset updates >/dev/null 2>"$TEST_ROOT/parallel.progress"
if grep -Fq 'failed' "$TEST_ROOT/parallel.progress"; then
  fail 'same-source exact-path checks did not run concurrently'
fi

FAKE_GH_REQUIRE_PARALLEL=1 run_skillset updates \
  >"$TEST_ROOT/updates.out" 2>"$TEST_ROOT/updates.progress"
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
printf '\n' | run_skillset update >/dev/null
grep -Fq 'skill update ' "$GH_LOG" || fail 'update commands were not delegated to gh skill'
grep -Fq -- '--dry-run' "$GH_LOG" || fail 'updates did not use dry-run'
grep -Fq 'github-tree-sha: new-tree-sha' "$CATALOG/exact/SKILL.md" ||
  fail 'update did not refresh the exact-path skill'
if grep -Fq ' exact ' "$GH_LOG"; then
  fail 'exact-path skill was delegated to gh skill update discovery'
fi

: >"$GH_LOG.install"
run_skillset add example/skills epsilon >/dev/null
if grep -Fq -- '--allow-hidden-dirs' "$GH_LOG.install"; then
  fail 'add passed --allow-hidden-dirs without the flag'
fi
[[ -f "$CATALOG/epsilon/SKILL.md" ]] || fail 'default add did not install the skill'

: >"$GH_LOG.install"
run_skillset add example/skills zeta --allow-hidden-dirs >/dev/null
grep -Fq -- '--allow-hidden-dirs' "$GH_LOG.install" ||
  fail 'add did not pass --allow-hidden-dirs to gh skill install'

: >"$GH_LOG.install"
printf '\n' | FAKE_FZF_SELECTED='bundle-two' run_skillset add example/bundle --allow-hidden-dirs >/dev/null
grep -Fq -- '--allow-hidden-dirs' "$GH_LOG.install" ||
  fail 'repository add did not pass --allow-hidden-dirs during discovery'
[[ -f "$CATALOG/bundle-two/SKILL.md" ]] ||
  fail 'repository add did not install the hidden-dir selection'

: >"$GH_LOG.install"
printf '\n' | FAKE_FZF_SELECTED='hidden-one' run_skillset add example/hidden --allow-hidden-dirs >/dev/null
jq -e '
  .skills[] | select(.name == "hidden-one") |
  (.selector == "hidden-one" and .source == "example/hidden" and .hidden == true and .enabled == true)
' "$MANIFEST" >/dev/null ||
  fail 'hidden-dir add did not record the stripped selector and hidden flag'
[[ -f "$CATALOG/hidden-one/SKILL.md" ]] ||
  fail 'hidden-dir add did not install the selection'

rm -rf -- "$CATALOG/hidden-one"
: >"$GH_LOG.install"
run_skillset sync >/dev/null
grep -Fq -- '--allow-hidden-dirs' "$GH_LOG.install" ||
  fail 'sync did not pass --allow-hidden-dirs to reinstall the hidden skill'
[[ -f "$CATALOG/hidden-one/SKILL.md" ]] ||
  fail 'sync did not restore the missing hidden skill'

: >"$GH_LOG"
: >"$GH_LOG.install"
run_skillset updates >/dev/null 2>&1
if grep -Fq 'hidden-one' "$GH_LOG"; then
  fail 'hidden skill was delegated to gh skill update discovery'
fi
grep -Fq -- '--allow-hidden-dirs' "$GH_LOG.install" ||
  fail 'updates did not check the hidden skill with --allow-hidden-dirs'

printf 'skillset behavior tests passed\n'
