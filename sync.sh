#!/usr/bin/env bash
# One-click, main-only synchronization for AshbyWiki.
set -Eeuo pipefail
DRY_RUN=0
usage() { echo "Usage: ./sync.sh [--dry-run]"; }
while (($#)); do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done
if ! git rev-parse --show-toplevel >/dev/null 2>&1; then echo "Not inside a Git checkout." >&2; exit 1; fi
ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"
BRANCH="$(git symbolic-ref --quiet --short HEAD 2>/dev/null || true)"
if [[ "$BRANCH" != main ]]; then echo "Refusing to sync branch '$BRANCH'; checkout main first." >&2; exit 1; fi
if [[ -d "$(git rev-parse --git-path rebase-merge)" || -d "$(git rev-parse --git-path rebase-apply)" ]]; then
  echo "A rebase is already in progress. Resolve it or run: git rebase --abort" >&2
  exit 1
fi
if [[ -n "$(git diff --name-only --diff-filter=U)" ]]; then
  echo "Unresolved merge conflicts are present. Resolve them before syncing." >&2
  exit 1
fi
if (( DRY_RUN )); then
  echo "Dry run: would stage all non-ignored files, commit if changed, rebase origin/main, and push origin main."
  git status --short
  exit 0
fi
git remote get-url origin >/dev/null 2>&1 || { echo "Remote 'origin' is not configured." >&2; exit 1; }
git add --all
if git diff --cached --quiet; then echo "No changes to sync."; exit 0; fi
git commit -m "Auto-sync: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
if ! git fetch origin main; then echo "Fetch failed; nothing was pushed. Check authentication/network." >&2; exit 1; fi
if ! git rebase origin/main; then
  echo "Rebase conflict; nothing was pushed. Resolve conflicts, then run 'git rebase --continue', or abort with 'git rebase --abort'." >&2
  exit 1
fi
if ! git push origin main; then echo "Push failed. Check authentication/network; local commits remain intact." >&2; exit 1; fi
echo "Sync complete."
