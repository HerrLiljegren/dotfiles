#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
TEST_ROOT="$(mktemp -d)"
trap 'rm -rf -- "$TEST_ROOT"' EXIT

BIN="$ROOT/bin/git-refresh"

fail() {
  printf 'test failure: %s\n' "$*" >&2
  exit 1
}

git_config() {
  git -C "$1" config user.name Tester
  git -C "$1" config user.email tester@example.com
}

refresh() {
  local dir=$1
  shift
  (cd -- "$dir" && "$BIN" "$@")
}

git init -q --bare "$TEST_ROOT/origin.git"
git init -q -b main "$TEST_ROOT/seed"
git_config "$TEST_ROOT/seed"
printf 'base\n' >"$TEST_ROOT/seed/file.txt"
printf 'conflict base\n' >"$TEST_ROOT/seed/conflict.txt"
git -C "$TEST_ROOT/seed" add .
git -C "$TEST_ROOT/seed" commit -qm base
git -C "$TEST_ROOT/seed" branch master
git -C "$TEST_ROOT/seed" branch develop
git -C "$TEST_ROOT/seed" remote add origin "$TEST_ROOT/origin.git"
git -C "$TEST_ROOT/seed" push -q origin main master develop

git clone -q "$TEST_ROOT/origin.git" "$TEST_ROOT/clone"
git_config "$TEST_ROOT/clone"
git -C "$TEST_ROOT/clone" branch -q master origin/master
git -C "$TEST_ROOT/clone" branch -q develop origin/develop
git -C "$TEST_ROOT/clone" worktree add -q "$TEST_ROOT/clone-master" master

# Up to date, including when invoked from a subdirectory.
mkdir -p "$TEST_ROOT/clone/sub/dir"
if ! output=$(refresh "$TEST_ROOT/clone/sub/dir"); then
  fail "up-to-date refresh failed: $output"
fi
grep -Fq 'clone is up to date' <<<"$output" || fail "missing up-to-date summary: $output"

# Dry run must not move refs, then a real run updates checked-out and
# non-checked-out branches and restores dirty worktree changes.
(
  cd "$TEST_ROOT/seed"
  git checkout -q main
  printf 'main v2\n' >>file.txt
  git commit -qam 'main v2'
  git push -q origin main
  git checkout -q develop
  printf 'dev v2\n' >dev.txt
  git add dev.txt
  git commit -qm 'develop v2'
  git push -q origin develop
  git checkout -q master
  printf 'master v2\n' >master.txt
  git add master.txt
  git commit -qm 'master v2'
  git push -q origin master
)
printf 'dirty worktree change\n' >>"$TEST_ROOT/clone-master/file.txt"

main_before=$(git -C "$TEST_ROOT/clone" rev-parse main)
master_before=$(git -C "$TEST_ROOT/clone-master" rev-parse master)
develop_before=$(git -C "$TEST_ROOT/clone" rev-parse develop)
if ! output=$(refresh "$TEST_ROOT/clone" --dry-run); then
  fail "dry run failed: $output"
fi
grep -Fq '3 branches would be updated' <<<"$output" || fail "missing dry-run summary: $output"
[[ "$(git -C "$TEST_ROOT/clone" rev-parse main)" == "$main_before" ]] ||
  fail 'dry run moved main'
[[ "$(git -C "$TEST_ROOT/clone-master" rev-parse master)" == "$master_before" ]] ||
  fail 'dry run moved master'
[[ "$(git -C "$TEST_ROOT/clone" rev-parse develop)" == "$develop_before" ]] ||
  fail 'dry run moved develop'

if ! output=$(refresh "$TEST_ROOT/clone"); then
  fail "real refresh failed: $output"
fi
grep -Fq 'refreshed: 3 updated' <<<"$output" || fail "missing refresh summary: $output"
grep -Fq 'dirty worktree change' "$TEST_ROOT/clone-master/file.txt" ||
  fail 'autostash did not restore dirty worktree changes'
[[ "$(git -C "$TEST_ROOT/clone-master" rev-parse master)" == "$(git -C "$TEST_ROOT/clone" rev-parse origin/master)" ]] ||
  fail 'worktree branch was not fast-forwarded'

# Diverged branches are reported and left untouched.
(
  cd "$TEST_ROOT/clone"
  printf 'local\n' >local.txt
  git add local.txt
  git commit -qm 'local main'
)
(
  cd "$TEST_ROOT/seed"
  git checkout -q main
  printf 'remote\n' >remote.txt
  git add remote.txt
  git commit -qm 'remote main'
  git push -q origin main
)
diverged_before=$(git -C "$TEST_ROOT/clone" rev-parse main)
set +e
output=$(refresh "$TEST_ROOT/clone" 2>&1)
status=$?
set -e
[[ $status == 1 ]] || fail "diverged refresh exited $status, expected 1"
grep -Fq 'diverged (1 local, 1 remote); not changed' <<<"$output" || fail "missing divergence reason: $output"
[[ "$(git -C "$TEST_ROOT/clone" rev-parse main)" == "$diverged_before" ]] ||
  fail 'diverged branch was changed'
git -C "$TEST_ROOT/clone" fetch -q origin
git -C "$TEST_ROOT/clone" reset -q --hard origin/main
git -C "$TEST_ROOT/clone" branch -q -u origin/main main

# A conflicting autostash is a failure even though the branch fast-forwards.
git -C "$TEST_ROOT/clone-master" reset -q --hard
printf 'dirty conflict\n' >>"$TEST_ROOT/clone-master/conflict.txt"
(
  cd "$TEST_ROOT/seed"
  git checkout -q master
  printf 'remote conflict\n' >>conflict.txt
  git commit -qam 'remote conflict'
  git push -q origin master
)
set +e
output=$(refresh "$TEST_ROOT/clone" 2>&1)
status=$?
set -e
[[ $status == 1 ]] || fail "autostash conflict exited $status, expected 1"
grep -Fq 'stashed changes conflict' <<<"$output" || fail "missing autostash reason: $output"
grep -Fq '<<<<<<<' "$TEST_ROOT/clone-master/conflict.txt" || fail 'autostash conflict was not left visible'
git -C "$TEST_ROOT/clone-master" stash list | grep -Fq autostash || fail 'autostash was not retained'
[[ "$(git -C "$TEST_ROOT/clone-master" rev-parse master)" == "$(git -C "$TEST_ROOT/clone" rev-parse origin/master)" ]] ||
  fail 'branch did not fast-forward before the autostash conflict'

# Outside a repository is a usage error.
set +e
output=$(refresh "$TEST_ROOT" 2>&1)
status=$?
set -e
[[ $status == 2 ]] || fail "outside-repository refresh exited $status, expected 2"
grep -Fq 'not inside a Git working tree' <<<"$output" || fail 'missing outside-repository error'

# A repository without the named branches or upstreams is a no-op, not a failure.
git init -q -b topic "$TEST_ROOT/topic-only"
git_config "$TEST_ROOT/topic-only"
printf 'x\n' >"$TEST_ROOT/topic-only/x"
git -C "$TEST_ROOT/topic-only" add x
git -C "$TEST_ROOT/topic-only" commit -qm x
if ! output=$(refresh "$TEST_ROOT/topic-only"); then
  fail "topic-only refresh failed: $output"
fi
grep -Fq 'no main, master or develop branch' <<<"$output" || fail "missing no-branches message: $output"

git init -q -b main "$TEST_ROOT/local-only"
git_config "$TEST_ROOT/local-only"
printf 'x\n' >"$TEST_ROOT/local-only/x"
git -C "$TEST_ROOT/local-only" add x
git -C "$TEST_ROOT/local-only" commit -qm x
if ! output=$(refresh "$TEST_ROOT/local-only"); then
  fail "local-only refresh failed: $output"
fi
grep -Fq 'no upstream' <<<"$output" || fail "missing no-upstream message: $output"

printf 'git-refresh tests passed\n'
