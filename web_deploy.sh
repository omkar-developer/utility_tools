#!/bin/bash
set -e

# Ensure you’re on main branch and changes are committed
git checkout main
git pull origin main

# Build Flutter web release
flutter build web --release

# Commit web build into gh-pages branch without switching
git worktree add /tmp/gh-pages gh-pages

# Copy build output
rsync -av --delete build/web/ /tmp/gh-pages/

# Commit and push
cd /tmp/gh-pages
git add --all
git commit -m "Update GitHub Pages build" || true
git push origin gh-pages

# Cleanup
cd -
git worktree remove /tmp/gh-pages
