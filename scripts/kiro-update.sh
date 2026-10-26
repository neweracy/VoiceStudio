#!/usr/bin/env bash
# kiro-update.sh — safe upstream sync for the neweracy/VoiceStudio fork.
#
# Default: READ-ONLY. Fetches upstream/main and reports how far behind you are.
# It never merges or builds unless you explicitly ask.
#
#   ./scripts/kiro-update.sh            # fetch + report only (safe)
#   ./scripts/kiro-update.sh --merge    # also merge upstream/main into current branch
#   ./scripts/kiro-update.sh --build    # also run deps install + typecheck
#   ./scripts/kiro-update.sh --merge --build
#
# Merge is skipped (not silently reset) if the working tree is dirty.
set -euo pipefail

cd "$(dirname "$0")/.."

UPSTREAM_REMOTE="upstream"
UPSTREAM_BRANCH="main"
DO_MERGE=0
DO_BUILD=0
for arg in "$@"; do
  case "$arg" in
    --merge) DO_MERGE=1 ;;
    --build) DO_BUILD=1 ;;
    *) echo "unknown flag: $arg" >&2; exit 2 ;;
  esac
done

if ! git remote get-url "$UPSTREAM_REMOTE" >/dev/null 2>&1; then
  echo "No '$UPSTREAM_REMOTE' remote. Run: git remote add upstream https://github.com/debpalash/VoiceStudio.git" >&2
  exit 1
fi

echo "Fetching $UPSTREAM_REMOTE/$UPSTREAM_BRANCH..."
git fetch "$UPSTREAM_REMOTE" "$UPSTREAM_BRANCH" --quiet

BEHIND=$(git rev-list --count "HEAD..$UPSTREAM_REMOTE/$UPSTREAM_BRANCH")
AHEAD=$(git rev-list --count "$UPSTREAM_REMOTE/$UPSTREAM_BRANCH..HEAD")
echo "You are $BEHIND commit(s) behind and $AHEAD ahead of $UPSTREAM_REMOTE/$UPSTREAM_BRANCH."

if [ "$BEHIND" -gt 0 ]; then
  echo "New upstream commits:"
  git --no-pager log --oneline --no-decorate "HEAD..$UPSTREAM_REMOTE/$UPSTREAM_BRANCH" | head -20
fi

if [ "$DO_MERGE" -eq 1 ]; then
  if [ -n "$(git status --porcelain)" ]; then
    echo "Working tree is dirty — refusing to merge. Commit or stash first." >&2
    exit 1
  fi
  if [ "$BEHIND" -eq 0 ]; then
    echo "Nothing to merge."
  else
    echo "Merging $UPSTREAM_REMOTE/$UPSTREAM_BRANCH..."
    git merge --no-edit "$UPSTREAM_REMOTE/$UPSTREAM_BRANCH"
  fi
fi

if [ "$DO_BUILD" -eq 1 ]; then
  echo "Installing deps + typecheck..."
  bun install
  bun run --cwd electron typecheck
fi

echo "Done."
