#!/usr/bin/env bash
# Merges upstream into the current branch and re-applies the debranding.
#   fork/sync-upstream.sh            merge + debrand + commit (no push)
#   fork/sync-upstream.sh --push     also push, tag new upstream releases and start their builds
#
# Conflicts are resolved in upstream's favour, then fork/debrand.sh re-applies the
# fork's changes on top, so the result is always "upstream minus the branding".
set -euo pipefail
cd "$(dirname "$0")/.."
source fork/config.sh

git remote get-url upstream >/dev/null 2>&1 \
  || git remote add upstream "https://github.com/$UPSTREAM_REPO.git"
git fetch --no-tags upstream "$UPSTREAM_BRANCH"

if ! git merge --no-commit --no-ff -X theirs "upstream/$UPSTREAM_BRANCH" >/dev/null 2>&1; then
  # Left over: files one side deleted (e.g. windows/, which the fork removes).
  # Take upstream's version where it has one; debrand.sh deletes it again if needed.
  git diff --name-only --diff-filter=U -z | while IFS= read -r -d '' path; do
    if git cat-file -e "MERGE_HEAD:$path" 2>/dev/null; then
      git checkout --theirs -- "$path" && git add -- "$path"
    else
      git rm -q -- "$path"
    fi
  done
fi

fork/debrand.sh
git add -A

if git rev-parse -q --verify MERGE_HEAD >/dev/null; then
  git commit -q --no-edit
  echo "sync: merged $(git rev-parse --short "upstream/$UPSTREAM_BRANCH")"
elif ! git diff --cached --quiet; then
  git commit -q -m "Re-apply debranding"
  echo "sync: re-applied debranding"
else
  echo "sync: already up to date"
fi

[ "${1:-}" = --push ] || exit 0

git push origin HEAD

# Mirror upstream's newest version tag, so the fork releases (and Sparkle updates)
# when upstream does. The tag goes on the fork's merge commit.
latest=$(git ls-remote --tags --refs upstream 'v*' | sed 's#.*refs/tags/##' | sort -V | tail -1)
if [ -n "$latest" ] && ! git ls-remote --exit-code --tags origin "refs/tags/$latest" >/dev/null; then
  git tag "$latest"
  git push origin "refs/tags/$latest"
  echo "sync: tagged $latest"
  gh workflow run fork-build.yml --repo "$FORK_REPO" --ref "$latest"
else
  gh workflow run fork-build.yml --repo "$FORK_REPO" --ref "$(git branch --show-current)"
fi
