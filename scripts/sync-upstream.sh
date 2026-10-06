#!/usr/bin/env bash
# Merge micromatch/braces (upstream) into this fork without losing fork metadata.
# Never reset or force-push: the nesting-depth fix and @zklogic metadata must survive.
set -euo pipefail

UPSTREAM_URL="https://github.com/micromatch/braces.git"
BRANCH="${1:-master}"

if [ "$(git branch --show-current)" != "development" ]; then
  echo "Run this on the development branch (all fork work lives there)." >&2
  exit 1
fi

git remote get-url upstream >/dev/null 2>&1 || git remote add upstream "$UPSTREAM_URL"
git fetch upstream

FORK_VERSION="$(node -p "require('./package.json').version")"

if git merge "upstream/$BRANCH" --no-edit; then
  echo "Merged cleanly."
else
  CONFLICTS="$(git diff --name-only --diff-filter=U)"
  if [ "$CONFLICTS" != "package.json" ]; then
    echo "Conflicts besides package.json need a manual resolve:"
    echo "$CONFLICTS"
    exit 1
  fi
  # package.json: take upstream's (dependencies, scripts), then re-apply fork metadata.
  git checkout --theirs package.json
fi

node scripts/apply-fork-metadata.js --version "$FORK_VERSION"
git add package.json
git diff --cached --quiet || git commit -q -m "chore: re-apply @zklogic fork metadata after upstream sync"
echo "Done. Review 'git log' and run: npm install && npm test"
