#!/bin/bash
# Publish the pack: refresh packwiz's file list, safety-check it, then commit + push.
# Usage (from the pack folder):  bash publish.sh "what changed"
set -e
cd "$(dirname "$0")"

packwiz.exe migrate loader latest
packwiz.exe refresh

# Safety check: every file packwiz lists must actually get uploaded by git.
bad=$(tr -d '\r' < index.toml | grep '^file = ' | sed 's/^file = "//; s/"$//' | git check-ignore --stdin || true)
if [ -n "$bad" ]; then
  echo "STOPPED: these are in the pack but git won't upload them (friends would get a 404):"
  echo "$bad"
  echo "Add them to .packwizignore, then run this again."
  exit 1
fi

git add -A
if git diff --cached --quiet; then
  echo "Nothing changed, nothing to publish."
  exit 0
fi
git status --short
git commit -q -m "${1:-Update pack}"
git push -q
echo "Published. Friends get it on their next launch (give GitHub ~5 minutes)."
