#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
REPO_URL="${1:?Usage: bash TERMUX_PUSH_COMMANDS.sh https://github.com/USERNAME/REPOSITORY.git}"
BRANCH="${2:-main}"
command -v git >/dev/null 2>&1 || { pkg update -y; pkg install git -y; }
if [[ ! -d .git ]]; then git init; fi
git branch -M "$BRANCH"
git add .
if ! git diff --cached --quiet; then
  git commit -m "ASTRIDE Passenger Driver v3.17.0 build source"
fi
if git remote get-url origin >/dev/null 2>&1; then git remote set-url origin "$REPO_URL"; else git remote add origin "$REPO_URL"; fi
git push -u origin "$BRANCH"
