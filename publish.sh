#!/usr/bin/env bash
# Publish three AI Education lessons to GitHub Pages.
# Follows the gh-pages-publish skill: gh checks → git init → main commit
# → orphan gh-pages branch → public repo create → push → enable Pages → URLs.
set -euo pipefail

REPO="ai-education-lessons"
LESSONS=(index.html shape-of-meaning.html shape-of-meaning-bilingual.html oma-explainer.html)

cd "$(dirname "$0")"
echo "=> working directory: $(pwd)"

# --- 1. gh installed & authenticated -----------------------------------------
echo
echo "=> Step 1: gh CLI checks"
if ! command -v gh >/dev/null; then
  echo "ERROR: gh CLI not installed."
  echo "  macOS:  brew install gh"
  echo "  see:    https://cli.github.com"
  exit 1
fi
gh --version | head -1
if ! gh auth status >/dev/null 2>&1; then
  echo "ERROR: gh is not authenticated. Run: gh auth login"
  exit 1
fi
OWNER=$(gh api user -q .login)
echo "   authenticated as: $OWNER"

# --- 2. confirm files --------------------------------------------------------
echo
echo "=> Step 2: confirm staged files"
for f in "${LESSONS[@]}"; do
  [ -f "$f" ] || { echo "ERROR: missing $f"; exit 1; }
  printf "   %s (%s bytes)\n" "$f" "$(wc -c < "$f")"
done

# --- 3. fresh git repo on main ----------------------------------------------
echo
echo "=> Step 3: initialize git on main"
rm -rf .git
git init -b main >/dev/null
git config user.email "${GIT_AUTHOR_EMAIL:-$OWNER@users.noreply.github.com}"
git config user.name  "${GIT_AUTHOR_NAME:-$OWNER}"
git add -A
git commit -m "Initial commit: three interactive AI Education lessons" >/dev/null
echo "   committed $(git rev-list --count main) commit(s) on main"

# --- 4. orphan gh-pages branch with the three lessons at root ---------------
echo
echo "=> Step 4: create orphan gh-pages branch"
git checkout --orphan gh-pages >/dev/null 2>&1
git rm -rf --cached . >/dev/null 2>&1 || true
# Stage only the lessons (no README/.gitignore on the deploy branch)
for f in "${LESSONS[@]}"; do
  git add "$f"
done
# Reset working tree to remove README/.gitignore from disk on this branch
# but keep them as untracked (we'll restore main's tree at the end).
git -c core.quotePath=false ls-files --others --exclude-standard | xargs -I{} sh -c 'rm -f "{}" 2>/dev/null || true'
git commit -m "Initial gh-pages deploy: three lessons" >/dev/null
echo "   gh-pages: $(git ls-files | wc -l | tr -d ' ') files"

# Switch back to main so the user lands on a normal working tree
git checkout main >/dev/null 2>&1

# --- 5. create the public repo + push main ----------------------------------
echo
echo "=> Step 5: create the GitHub repo (public)"
if gh repo view "$OWNER/$REPO" >/dev/null 2>&1; then
  echo "   repo already exists at github.com/$OWNER/$REPO — pushing to it"
  gh repo set-default "$OWNER/$REPO" >/dev/null 2>&1 || true
  git remote remove origin 2>/dev/null || true
  git remote add origin "https://github.com/$OWNER/$REPO.git"
  git push -u origin main --force-with-lease 2>&1 | tail -2
else
  gh repo create "$REPO" --public --source=. --remote=origin --push 2>&1 | tail -3
fi

# --- 6. push the gh-pages branch --------------------------------------------
echo
echo "=> Step 6: push gh-pages branch"
git push -u origin gh-pages 2>&1 | tail -2

# --- 7. enable GitHub Pages via the API -------------------------------------
echo
echo "=> Step 7: enable GitHub Pages (gh-pages branch, root)"
ENABLE_RESULT=$(gh api -X POST "repos/$OWNER/$REPO/pages" \
  -F "source[branch]=gh-pages" \
  -F "source[path]=/" 2>&1) || true

if echo "$ENABLE_RESULT" | grep -q '"html_url"'; then
  echo "   enabled."
elif echo "$ENABLE_RESULT" | grep -qi "already exists"; then
  echo "   already enabled (no-op)."
else
  echo "   enable response: $ENABLE_RESULT"
fi

# --- 8. fetch live URL + per-lesson links -----------------------------------
SITE_URL=$(gh api "repos/$OWNER/$REPO/pages" -q .html_url 2>/dev/null || echo "https://$OWNER.github.io/$REPO/")
SITE_URL="${SITE_URL%/}"
echo
echo "=> Live site (landing page lists all three lessons):"
echo "     $SITE_URL/"
echo
echo "=> Direct lesson URLs:"
for f in "${LESSONS[@]}"; do
  echo "     $SITE_URL/$f"
done

# --- 9. wait for first deploy ------------------------------------------------
echo
echo "=> Step 9: waiting for first deploy (up to ~2 min)…"
DEADLINE=$((SECONDS + 130))
while (( SECONDS < DEADLINE )); do
  CODE=$(curl -s -o /dev/null -w "%{http_code}" "$SITE_URL/${LESSONS[0]}")
  if [[ "$CODE" == "200" ]]; then
    echo "   live ✓ (HTTP 200 on shape-of-meaning.html)"
    break
  fi
  printf "."
  sleep 5
done
echo

echo "Repo:  https://github.com/$OWNER/$REPO"
echo "Done."
