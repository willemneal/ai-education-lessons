# AI Education — Interactive Lessons

Three interactive HTML lessons on how language models work.

- **shape-of-meaning.html** — A 7-chapter Three.js walkthrough of word embeddings, vector arithmetic, and how meaning becomes geometry.
- **shape-of-meaning-bilingual.html** — English, Dutch, and Spanish adaptation with a language toggle.
- **oma-explainer.html** — A kitchen-table version for non-technical readers, in five gentle steps. EN, NL, and ES — three languages.

## Live site

The landing page lists all three lessons:

- **<https://willemneal.github.io/ai-education-lessons/>**

Direct lesson URLs:

- `https://willemneal.github.io/ai-education-lessons/shape-of-meaning.html`
- `https://willemneal.github.io/ai-education-lessons/shape-of-meaning-bilingual.html`
- `https://willemneal.github.io/ai-education-lessons/oma-explainer.html`

Append `?lang=nl` (Dutch) or `?lang=es` (Spanish) to either page to open it in that language.

## Deploy

- `./publish.sh` is the one-time bootstrap: it creates the public repo, seeds the `gh-pages` branch, and enables GitHub Pages.
- After that, every push to `main` is auto-deployed by `.github/workflows/deploy.yml`.
- Every pull request gets a preview at `…/pr-preview/pr-N/`, posted to the PR by `.github/workflows/pr-preview.yml`.
