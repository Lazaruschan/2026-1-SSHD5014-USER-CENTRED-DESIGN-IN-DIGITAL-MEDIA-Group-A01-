#!/usr/bin/env bash
# Publish SSHD5014 course site to GitHub Pages.
# Repo: https://github.com/Lazaruschan/2026-1-SSHD5014-USER-CENTRED-DESIGN-IN-DIGITAL-MEDIA-Group-A01-
#
# Usage:
#   cd Github/SSHD5014
#   ./publish.sh
#   # or: npm run publish
#
# Use a GitHub Personal Access Token when asked for "Password" (not your account password).
# After push: Settings → Pages → Deploy from branch → main / (root)
#
# Note: This folder lives under OneDrive. Files On-Demand can turn .git files into
# "dataless" placeholders and git then fails with "Operation timed out".
# Prefer: Finder → this folder → Always Keep on This Device
# Or clone/copy the repo outside OneDrive (e.g. ~/Developer).

set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

REPO_URL="https://github.com/Lazaruschan/2026-1-SSHD5014-USER-CENTRED-DESIGN-IN-DIGITAL-MEDIA-Group-A01-.git"
BRANCH="main"
REMOTE="origin"

# Clear OneDrive dataless placeholders that block git writes/reads under .git
onedrive_git_preflight() {
  [[ -d .git ]] || return 0

  rm -f .git/COMMIT_EDITMSG .git/index.lock .git/MERGE_MSG .git/MERGE_HEAD \
    .git/CHERRY_PICK_HEAD .git/REBASE_HEAD 2>/dev/null || true

  # macOS UF_DATALESS — skip quietly on systems without this find flag
  local f
  while IFS= read -r f; do
    [[ -n "$f" ]] || continue
    case "$f" in
      .git/objects/*/*)
        if ! cat "$f" >/dev/null 2>&1; then
          echo "Warning: removing unreadable OneDrive placeholder: $f"
          rm -f "$f" 2>/dev/null || true
        fi
        ;;
      *)
        if ! cat "$f" >/dev/null 2>&1; then
          echo "Warning: removing unreadable OneDrive placeholder: $f"
          rm -f "$f" 2>/dev/null || true
        fi
        ;;
    esac
  done < <(find .git -flags +dataless 2>/dev/null || true)
}

echo "==> Publishing from: $ROOT"
echo "==> Target: $REPO_URL"

if ! command -v git >/dev/null 2>&1; then
  echo "Error: git is not installed. Install Xcode CLT or Git first."
  exit 1
fi

if [[ ! -d .git ]]; then
  echo "==> git init"
  git init
fi

onedrive_git_preflight

# Keep ignore list current
cat > .gitignore <<'EOF'
node_modules/
.DS_Store
*.log
*.rtf
start.rtf
.env
.env.*
*token*
*secret*
EOF

# Remove secret-prone files from disk if present
rm -f start.rtf *.rtf 2>/dev/null || true

# Refresh tutorial worksheet PDFs from Notes (if source tree is present)
if [[ -x "$ROOT/sync-tutorial-notes.sh" ]] || [[ -f "$ROOT/sync-tutorial-notes.sh" ]]; then
  echo "==> Syncing tutorial notes PDFs"
  bash "$ROOT/sync-tutorial-notes.sh" || echo "Warning: tutorial notes sync skipped (source missing?)"
fi

echo "==> Staging site files only (explicit allow-list)"
git add --force \
  .gitignore \
  .nojekyll \
  README.md \
  index.html \
  auth.js \
  assets \
  slides \
  tutorial-notes \
  readings \
  publish.sh \
  publish.bat \
  export-slides.sh \
  sync-tutorial-notes.sh \
  sync-tutorial-notes.bat \
  embed-slide-assets.py \
  package.json \
  package-lock.json

# Never publish secrets / tooling junk
git rm -r --cached node_modules 2>/dev/null || true
git rm --cached start.rtf 2>/dev/null || true
git rm --cached -f *.rtf 2>/dev/null || true

echo "==> Staged files:"
git status --short | head -80

if git diff --cached --quiet; then
  if ! git rev-parse HEAD >/dev/null 2>&1; then
    echo "Error: nothing to commit and no previous commits."
    exit 1
  fi
  echo "==> No new changes; will push existing commits."
else
  echo "==> Committing"
  onedrive_git_preflight
  # Write message via -F so we control the path; still clear COMMIT_EDITMSG first
  MSG_FILE="$(mktemp "${TMPDIR:-/tmp}/sshd5014-commit.XXXXXX")"
  cat > "$MSG_FILE" <<'EOF'
Publish SSHD5014 User-centred Design in Digital Media course website.

EOF
  git commit -F "$MSG_FILE"
  rm -f "$MSG_FILE"
fi

git branch -M "$BRANCH"

if git remote get-url "$REMOTE" >/dev/null 2>&1; then
  echo "==> Updating remote $REMOTE"
  git remote set-url "$REMOTE" "$REPO_URL"
else
  echo "==> Adding remote $REMOTE"
  git remote add "$REMOTE" "$REPO_URL"
fi

echo "==> Pushing to $REMOTE/$BRANCH"
onedrive_git_preflight
git push -u "$REMOTE" "$BRANCH"

PAGES_URL="https://lazaruschan.github.io/2026-1-SSHD5014-USER-CENTRED-DESIGN-IN-DIGITAL-MEDIA-Group-A01-/"
echo ""
echo "Done."
echo "Enable Pages (once): repo Settings → Pages → Deploy from branch → main / (root)"
echo "Site URL: $PAGES_URL"
echo "Site password: 20265014"
