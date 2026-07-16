# Rebuild Goal 001 Runbook

This runbook is guarded execution guidance. It grants no authority. Run it only
after Barry explicitly authorizes every mutation in the sequence. Commands are
for macOS `zsh`; execute one numbered section at a time and inspect its output.

## Stop Rules

- Stop on any failed check or command. Preserve the exact current state and
  report it.
- Do not force, reset, clean, stash, rewrite history, improvise rollback,
  delete a repository, or create a replacement for a failed replacement.
- Do not regenerate or restore Goal 004 bundles or scratch-agent traces.
- Do not retain command transcripts or validation products in either repo.

## 1. Authorization And Preflight

First record Barry's explicit execution authorization in the live task. The
following checks are read-only apart from temporary comparison files under
`/tmp`, which are removed at the end of the block.

```zsh
set -euo pipefail

ACTIVE=/Users/bwbrook/git/herbivoreTTR
LEGACY=/Users/bwbrook/git/herbivoreTTR-legacy
BOOTSTRAP=/Users/bwbrook/git/herbivoreTTR-rebuild-bootstrap
BASE_SHA=abf68b691b4e30020625d1871dcabe56a5926bc1
OLD_MAIN_SHA=872fb20fe5ff4ffd00cf2d29369e61fad764867a
TAG=legacy-final-2026-07-16

test -d "$ACTIVE/.git"
test ! -e "$LEGACY"
test ! -e "$BOOTSTRAP"
test "$(git -C "$ACTIVE" branch --show-current)" = codex/herbivore-ttr-goal-002
test "$(git -C "$ACTIVE" rev-parse HEAD)" = "$BASE_SHA"
test "$(git -C "$ACTIVE" remote get-url origin)" = \
  git@github.com:BWBrook/herbivoreTTR.git
test ! -e "$ACTIVE/artefacts/goal004_energy_decomposition"
test ! -e "$ACTIVE/.superpowers/sdd/goal004-agents"

EXPECTED_STATUS=$(mktemp /tmp/rebuild001-expected-status.XXXXXX)
ACTUAL_STATUS=$(mktemp /tmp/rebuild001-actual-status.XXXXXX)
printf '%s\n' \
  '?? docs/goals/004-herbivore-energy-budget-forensic-decomposition/Goal.md' \
  '?? docs/goals/004-herbivore-energy-budget-forensic-decomposition/Log.md' \
  '?? docs/goals/004-herbivore-energy-budget-forensic-decomposition/Plan.md' \
  '?? docs/goals/004-herbivore-energy-budget-forensic-decomposition/Runbook.md' \
  '?? docs/goals/rebuild-001-legacy-freeze-clean-repository-foundation/Goal.md' \
  '?? docs/goals/rebuild-001-legacy-freeze-clean-repository-foundation/Log.md' \
  '?? docs/goals/rebuild-001-legacy-freeze-clean-repository-foundation/Plan.md' \
  '?? docs/goals/rebuild-001-legacy-freeze-clean-repository-foundation/Runbook.md' \
  '?? docs/log/20260714_goal004_energy_budget_decomposition.md' \
  '?? inst/extdata/scenarios/goal004_energy_decomposition_v1.yaml' \
  '?? scripts/goal004_energy_ledger_helpers.R' \
  '?? scripts/run_goal004_energy_decomposition.R' \
  '?? tests/testthat/test_goal004_energy_decomposition.R' \
  > "$EXPECTED_STATUS"
git -C "$ACTIVE" status --porcelain=v1 --untracked-files=all > "$ACTUAL_STATUS"
diff -u "$EXPECTED_STATUS" "$ACTUAL_STATUS"

case "$EXPECTED_STATUS:$ACTUAL_STATUS" in
  /tmp/rebuild001-expected-status.*:/tmp/rebuild001-actual-status.*)
    rm -f -- "$EXPECTED_STATUS" "$ACTUAL_STATUS"
    ;;
  *) printf '%s\n' 'Unsafe temporary path; stop.' >&2; exit 1 ;;
esac

AVAILABLE_KIB=$(df -Pk /Users/bwbrook/git | awk 'NR == 2 {print $4}')
test "$AVAILABLE_KIB" -ge 5242880

gh auth status --hostname github.com
test "$(gh api user --jq .login)" = BWBrook
gh api repos/BWBrook/herbivoreTTR \
  --jq 'select(.private == true and .archived == false and .default_branch == "main") | .full_name' \
  | grep -Fx BWBrook/herbivoreTTR

set +e
COLLISION_OUTPUT=$(gh api repos/BWBrook/herbivoreTTR-legacy 2>&1)
COLLISION_RC=$?
set -e
test "$COLLISION_RC" -ne 0
printf '%s\n' "$COLLISION_OUTPUT" | grep -q 'HTTP 404'

git -C "$ACTIVE" fetch --prune origin
test "$(git -C "$ACTIVE" rev-parse origin/main)" = "$OLD_MAIN_SHA"
git -C "$ACTIVE" merge-base --is-ancestor origin/main HEAD
test -z "$(git -C "$ACTIVE" tag --list "$TAG")"
test -z "$(git -C "$ACTIVE" ls-remote --tags origin "refs/tags/$TAG")"
```

Any difference is a stop, not an invitation to reconcile the checkout.

## 2. Construct And Validate The Bootstrap

Initialize an unrelated repository. Do not copy from legacy.

```zsh
set -euo pipefail
BOOTSTRAP=/Users/bwbrook/git/herbivoreTTR-rebuild-bootstrap
test ! -e "$BOOTSTRAP"
git init -b main "$BOOTSTRAP"
test -z "$(git -C "$BOOTSTRAP" remote)"
```

Using exact patch edits, create only the bootstrap tree declared in `Plan.md`.
The documents must implement the approved contract in `Goal.md`; they must not
copy legacy prose or code. Then generate only standard `renv` support and lock
state:

```zsh
set -euo pipefail
export BOOTSTRAP=/Users/bwbrook/git/herbivoreTTR-rebuild-bootstrap
test -d "$BOOTSTRAP/.git"
Rscript --vanilla -e \
  'renv::init(project = Sys.getenv("BOOTSTRAP"), bare = TRUE, restart = FALSE); renv::snapshot(project = Sys.getenv("BOOTSTRAP"), prompt = FALSE)'
Rscript --vanilla -e \
  's <- renv::status(project = Sys.getenv("BOOTSTRAP")); if (!isTRUE(s$synchronized)) quit(status = 1)'
test ! -e "$BOOTSTRAP/outputs"
```

Verify the exact source tree before validation:

```zsh
set -euo pipefail
BOOTSTRAP=/Users/bwbrook/git/herbivoreTTR-rebuild-bootstrap
EXPECTED_TREE=$(mktemp /tmp/rebuild001-expected-tree.XXXXXX)
ACTUAL_TREE=$(mktemp /tmp/rebuild001-actual-tree.XXXXXX)
printf '%s\n' \
  .Rbuildignore .Rprofile .gitignore AGENTS.md DESCRIPTION LICENSE LICENSE.md \
  NAMESPACE R/herbivoreTTR-package.R README.md \
  docs/decisions/0001-clean-rebuild.md docs/model-charter.md \
  docs/model-specification.md docs/roadmap.md docs/variable-dictionary.md \
  experiments/README.md man/herbivoreTTR-package.Rd references/README.md \
  renv.lock renv/.gitignore renv/activate.R renv/settings.json \
  tests/testthat.R tests/testthat/test-scaffold.R \
  | LC_ALL=C sort > "$EXPECTED_TREE"
find "$BOOTSTRAP" -path "$BOOTSTRAP/.git" -prune -o -type f -print \
  | sed "s#^$BOOTSTRAP/##" | LC_ALL=C sort > "$ACTUAL_TREE"
diff -u "$EXPECTED_TREE" "$ACTUAL_TREE"

case "$EXPECTED_TREE:$ACTUAL_TREE" in
  /tmp/rebuild001-expected-tree.*:/tmp/rebuild001-actual-tree.*)
    rm -f -- "$EXPECTED_TREE" "$ACTUAL_TREE"
    ;;
  *) printf '%s\n' 'Unsafe temporary path; stop.' >&2; exit 1 ;;
esac
```

Run validation from an external temporary directory and inspect the check log
before guarded removal:

```zsh
set -euo pipefail
BOOTSTRAP=/Users/bwbrook/git/herbivoreTTR-rebuild-bootstrap
VALIDATION_DIR=$(mktemp -d /tmp/herbivoreTTR-rebuild-check.XXXXXX)

Rscript --vanilla -e \
  'testthat::test_dir(file.path("/Users/bwbrook/git/herbivoreTTR-rebuild-bootstrap", "tests/testthat"), reporter = "summary", stop_on_failure = TRUE)'
(
  cd "$VALIDATION_DIR"
  R CMD build "$BOOTSTRAP"
  R CMD check --no-manual herbivoreTTR_0.0.0.9000.tar.gz
  grep -Fx 'Status: OK' herbivoreTTR.Rcheck/00check.log
)
test -z "$(git -C "$BOOTSTRAP" status --porcelain --ignored=no | grep -E '(^|/)outputs/|\.Rcheck/|\.tar\.gz$' || true)"

case "$VALIDATION_DIR" in
  /tmp/herbivoreTTR-rebuild-check.*)
    rm -rf -- "$VALIDATION_DIR"
    ;;
  *) printf '%s\n' 'Unsafe validation path; stop.' >&2; exit 1 ;;
esac
```

Stage the exact source tree and create the sole replacement commit:

```zsh
set -euo pipefail
BOOTSTRAP=/Users/bwbrook/git/herbivoreTTR-rebuild-bootstrap
git -C "$BOOTSTRAP" add -- \
  .Rbuildignore .Rprofile .gitignore AGENTS.md DESCRIPTION LICENSE LICENSE.md \
  NAMESPACE R/herbivoreTTR-package.R README.md \
  docs/decisions/0001-clean-rebuild.md docs/model-charter.md \
  docs/model-specification.md docs/roadmap.md docs/variable-dictionary.md \
  experiments/README.md man/herbivoreTTR-package.Rd references/README.md \
  renv.lock renv/.gitignore renv/activate.R renv/settings.json \
  tests/testthat.R tests/testthat/test-scaffold.R
git -C "$BOOTSTRAP" diff --cached --check
git -C "$BOOTSTRAP" diff --cached --stat
git -C "$BOOTSTRAP" commit -m 'Establish clean herbivoreTTR foundation'
test "$(git -C "$BOOTSTRAP" rev-list --count HEAD)" -eq 1
test "$(git -C "$BOOTSTRAP" rev-list --max-parents=0 --count HEAD)" -eq 1
test -z "$(git -C "$BOOTSTRAP" status --porcelain)"
test -z "$(git -C "$BOOTSTRAP" remote)"
NEW_SHA=$(git -C "$BOOTSTRAP" rev-parse HEAD)
printf 'new foundation SHA = %s\n' "$NEW_SHA"
```

If the commit fails, stop. Do not bypass a hook or amend.

## 3. Commit And Publish The Final Legacy Snapshot

Return to the active legacy checkout. Create `ARCHIVED.md` using exact patch
edits. It must state the read-only purpose, replacement repository, final tag,
and exclusion of deleted generated material. Append a concise validation
summary to `Log.md`; do not add raw transcripts.

Stage only the authorized paths:

```zsh
set -euo pipefail
ACTIVE=/Users/bwbrook/git/herbivoreTTR
TAG=legacy-final-2026-07-16

git -C "$ACTIVE" add -- \
  ARCHIVED.md \
  docs/goals/004-herbivore-energy-budget-forensic-decomposition/Goal.md \
  docs/goals/004-herbivore-energy-budget-forensic-decomposition/Log.md \
  docs/goals/004-herbivore-energy-budget-forensic-decomposition/Plan.md \
  docs/goals/004-herbivore-energy-budget-forensic-decomposition/Runbook.md \
  docs/log/20260714_goal004_energy_budget_decomposition.md \
  inst/extdata/scenarios/goal004_energy_decomposition_v1.yaml \
  scripts/goal004_energy_ledger_helpers.R \
  scripts/run_goal004_energy_decomposition.R \
  tests/testthat/test_goal004_energy_decomposition.R \
  docs/goals/rebuild-001-legacy-freeze-clean-repository-foundation/Goal.md \
  docs/goals/rebuild-001-legacy-freeze-clean-repository-foundation/Log.md \
  docs/goals/rebuild-001-legacy-freeze-clean-repository-foundation/Plan.md \
  docs/goals/rebuild-001-legacy-freeze-clean-repository-foundation/Runbook.md

EXPECTED_STAGED=$(mktemp /tmp/rebuild001-expected-staged.XXXXXX)
ACTUAL_STAGED=$(mktemp /tmp/rebuild001-actual-staged.XXXXXX)
printf '%s\n' \
  ARCHIVED.md \
  docs/goals/004-herbivore-energy-budget-forensic-decomposition/Goal.md \
  docs/goals/004-herbivore-energy-budget-forensic-decomposition/Log.md \
  docs/goals/004-herbivore-energy-budget-forensic-decomposition/Plan.md \
  docs/goals/004-herbivore-energy-budget-forensic-decomposition/Runbook.md \
  docs/goals/rebuild-001-legacy-freeze-clean-repository-foundation/Goal.md \
  docs/goals/rebuild-001-legacy-freeze-clean-repository-foundation/Log.md \
  docs/goals/rebuild-001-legacy-freeze-clean-repository-foundation/Plan.md \
  docs/goals/rebuild-001-legacy-freeze-clean-repository-foundation/Runbook.md \
  docs/log/20260714_goal004_energy_budget_decomposition.md \
  inst/extdata/scenarios/goal004_energy_decomposition_v1.yaml \
  scripts/goal004_energy_ledger_helpers.R \
  scripts/run_goal004_energy_decomposition.R \
  tests/testthat/test_goal004_energy_decomposition.R \
  | LC_ALL=C sort > "$EXPECTED_STAGED"
git -C "$ACTIVE" diff --cached --name-only | LC_ALL=C sort > "$ACTUAL_STAGED"
diff -u "$EXPECTED_STAGED" "$ACTUAL_STAGED"
git -C "$ACTIVE" diff --cached --check
git -C "$ACTIVE" diff --cached --stat

case "$EXPECTED_STAGED:$ACTUAL_STAGED" in
  /tmp/rebuild001-expected-staged.*:/tmp/rebuild001-actual-staged.*)
    rm -f -- "$EXPECTED_STAGED" "$ACTUAL_STAGED"
    ;;
  *) printf '%s\n' 'Unsafe temporary path; stop.' >&2; exit 1 ;;
esac

git -C "$ACTIVE" commit -m 'Archive final legacy herbivoreTTR state'
LEGACY_SHA=$(git -C "$ACTIVE" rev-parse HEAD)
test -z "$(git -C "$ACTIVE" status --porcelain)"

git -C "$ACTIVE" switch main
git -C "$ACTIVE" merge --ff-only "$LEGACY_SHA"
test "$(git -C "$ACTIVE" rev-parse HEAD)" = "$LEGACY_SHA"
git -C "$ACTIVE" push origin main:main
test "$(git -C "$ACTIVE" ls-remote origin refs/heads/main | awk '{print $1}')" = "$LEGACY_SHA"

git -C "$ACTIVE" tag -a "$TAG" "$LEGACY_SHA" \
  -m 'Final legacy herbivoreTTR snapshot, 2026-07-16'
test "$(git -C "$ACTIVE" rev-parse "$TAG^{}")" = "$LEGACY_SHA"
git -C "$ACTIVE" push origin "refs/tags/$TAG"
test "$(git -C "$ACTIVE" ls-remote origin "refs/tags/$TAG^{}" | awk '{print $1}')" = "$LEGACY_SHA"
printf 'legacy final SHA = %s\n' "$LEGACY_SHA"
```

If the commit, fast-forward, push, or tag operation fails, stop and report the
exact local and remote refs. Do not retry with broader authority.

## 4. Rename The Old Remote And Move Both Checkouts

Rename the old GitHub repository first, then perform exact sibling moves from
the parent directory:

```zsh
set -euo pipefail
gh api --method PATCH repos/BWBrook/herbivoreTTR \
  -f name=herbivoreTTR-legacy --jq .full_name \
  | grep -Fx BWBrook/herbivoreTTR-legacy
gh api repos/BWBrook/herbivoreTTR-legacy \
  --jq 'select(.private == true and .archived == false) | .full_name' \
  | grep -Fx BWBrook/herbivoreTTR-legacy

cd /Users/bwbrook/git
test "$PWD" = /Users/bwbrook/git
test -d herbivoreTTR/.git
test -d herbivoreTTR-rebuild-bootstrap/.git
test ! -e herbivoreTTR-legacy

mv -- herbivoreTTR herbivoreTTR-legacy
git -C /Users/bwbrook/git/herbivoreTTR-legacy remote set-url origin \
  git@github.com:BWBrook/herbivoreTTR-legacy.git
test "$(git -C /Users/bwbrook/git/herbivoreTTR-legacy remote get-url origin)" = \
  git@github.com:BWBrook/herbivoreTTR-legacy.git

test ! -e /Users/bwbrook/git/herbivoreTTR
mv -- herbivoreTTR-rebuild-bootstrap herbivoreTTR
test -d /Users/bwbrook/git/herbivoreTTR/.git
```

Each successful command changes the split state. On any failure, stop where it
stands and report all three local paths plus both GitHub names. Do not reverse a
move or rename.

## 5. Create And Push The Fresh Repository

Require the legacy rename to exist and the active name to be free, then create
the replacement:

```zsh
set -euo pipefail
NEW=/Users/bwbrook/git/herbivoreTTR
NEW_SHA=$(git -C "$NEW" rev-parse HEAD)

test -d "$NEW/.git"
test "$(git -C "$NEW" branch --show-current)" = main
test "$(git -C "$NEW" rev-list --count HEAD)" -eq 1
test -z "$(git -C "$NEW" status --porcelain)"
test -z "$(git -C "$NEW" remote)"
gh api repos/BWBrook/herbivoreTTR-legacy --jq .full_name \
  | grep -Fx BWBrook/herbivoreTTR-legacy

CURRENT_NAME_COUNT=$(gh api --paginate --slurp \
  'user/repos?affiliation=owner&visibility=all&per_page=100&sort=full_name' \
  --jq '[.[][] | select(.owner.login == "BWBrook" and .name == "herbivoreTTR")] | length')
test "$CURRENT_NAME_COUNT" -eq 0

gh api --method POST user/repos \
  -f name=herbivoreTTR \
  -f description='Transparent functional R models of herbivore energetics' \
  -F private=true --jq .full_name \
  | grep -Fx BWBrook/herbivoreTTR
git -C "$NEW" remote add origin git@github.com:BWBrook/herbivoreTTR.git
git -C "$NEW" push -u origin main
gh api --method PATCH repos/BWBrook/herbivoreTTR \
  -f default_branch=main --jq .default_branch | grep -Fx main

test "$(git -C "$NEW" ls-remote origin refs/heads/main | awk '{print $1}')" = "$NEW_SHA"
gh api repos/BWBrook/herbivoreTTR \
  --jq 'select(.private == true and .archived == false and .default_branch == "main") | .full_name' \
  | grep -Fx BWBrook/herbivoreTTR
```

If creation succeeds but the push or verification fails, stop with the new
remote present. Do not delete it or create another.

## 6. Archive Legacy And Final Verification

Archive legacy only after Section 5 passes:

```zsh
set -euo pipefail
NEW=/Users/bwbrook/git/herbivoreTTR
LEGACY=/Users/bwbrook/git/herbivoreTTR-legacy
TAG=legacy-final-2026-07-16
NEW_SHA=$(git -C "$NEW" rev-parse HEAD)
LEGACY_SHA=$(git -C "$LEGACY" rev-parse HEAD)

test "$(git -C "$NEW" ls-remote origin refs/heads/main | awk '{print $1}')" = "$NEW_SHA"
gh api --method PATCH repos/BWBrook/herbivoreTTR-legacy \
  -F archived=true --jq .archived | grep -Fx true

test "$(git -C "$LEGACY" branch --show-current)" = main
test -z "$(git -C "$LEGACY" status --porcelain)"
test "$(git -C "$LEGACY" remote get-url origin)" = \
  git@github.com:BWBrook/herbivoreTTR-legacy.git
test "$(git -C "$LEGACY" rev-parse "$TAG^{}")" = "$LEGACY_SHA"
test "$(git -C "$LEGACY" ls-remote origin "refs/tags/$TAG^{}" | awk '{print $1}')" = "$LEGACY_SHA"

test "$(git -C "$NEW" branch --show-current)" = main
test -z "$(git -C "$NEW" status --porcelain)"
test "$(git -C "$NEW" remote get-url origin)" = \
  git@github.com:BWBrook/herbivoreTTR.git
test "$(git -C "$NEW" rev-list --count HEAD)" -eq 1
test "$(git -C "$NEW" rev-list --max-parents=0 --count HEAD)" -eq 1
test ! -e "$NEW/outputs"

gh api repos/BWBrook/herbivoreTTR \
  --jq '{nameWithOwner: .full_name, private, archived, default_branch}'
gh api repos/BWBrook/herbivoreTTR-legacy \
  --jq '{nameWithOwner: .full_name, private, archived, default_branch}'
printf 'new SHA = %s\nlegacy SHA = %s\nlegacy tag = %s\n' \
  "$NEW_SHA" "$LEGACY_SHA" "$TAG"
find "$NEW" -path "$NEW/.git" -prune -o -type f -print \
  | sed "s#^$NEW/##" | LC_ALL=C sort
```

The final response must summarize the validation results and present the two
clean states, URLs/settings, exact SHAs/tag, replacement tree, and residual
risks. No post-archive file edit or commit is authorized. Stop without
implementing physiology.
