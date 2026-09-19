# SSHD5014 User-centred Design in Digital Media — Course Website

PolyU CPCE / HKCC · Semester One 2026/2027  
Subject Leader & Lecturer: CHAN, Long-fung Lazarus

Static site ready for **GitHub Pages**. Lecture HTML (weeks 1–12) is **self-contained** (images embedded as base64). Week 13 is final presentation — no lecture deck is published.

## Password gate

The whole site (home + slides) asks for a password before content is shown.

- **Password:** `20265014`
- Unlock lasts for the browser tab session (`sessionStorage`).
- This is **client-side only** (suitable for casual course access, not strong security).

To change the password, edit `PASSWORD_HASH` in [`auth.js`](auth.js):

```bash
python3 -c "import hashlib; print(hashlib.sha256(b'YOUR_PASSWORD').hexdigest())"
```

## Publish with script (Mac)

**Windows (recommended on this machine):** double-click `publish.bat`, or:

```bat
cd Github\SSHD5014
publish.bat
```

**Mac / Git Bash:**

```bash
cd Github/SSHD5014
./publish.sh
# or: npm run publish
```

Syncs tutorial worksheet PDFs from `Notes/.../Tutorial/pdf` into `tutorial-notes/`, then pushes to [2026-1-SSHD5014-USER-CENTRED-DESIGN-IN-DIGITAL-MEDIA-Group-A01-](https://github.com/Lazaruschan/2026-1-SSHD5014-USER-CENTRED-DESIGN-IN-DIGITAL-MEDIA-Group-A01-). Sign in if Git prompts you. Then enable Pages once: **Settings → Pages → main / (root)**.

```bat
npm run sync-tutorial-notes   REM refresh tutorial-notes/ only
npm run publish               REM Windows: runs publish.bat
```

## Publish on GitHub Pages (simplest)

1. Create a new empty GitHub repository (or use the existing Group-A01 repo).
2. Upload **the contents of this folder** as the repo root (not the parent `Github/` folder).
   - Include: `index.html`, `auth.js`, `.nojekyll`, `assets/`, `slides/`, `tutorial-notes/`, `readings/`, `README.md`
   - Do **not** upload `node_modules/`
3. In the repo: **Settings → Pages → Build and deployment**
   - Source: **Deploy from a branch**
   - Branch: `main` (or `master`), folder: **/ (root)**
4. Wait a minute, then open `https://<user>.github.io/<repo>/`

`.nojekyll` is included so GitHub Pages serves files as-is (no Jekyll processing).

## Open locally

Open [`index.html`](index.html) in a browser, or:

```bash
cd Github/SSHD5014
python3 -m http.server 8080
```

Visit `http://localhost:8080`.

- Lecture decks: [`slides/week-01.html`](slides/week-01.html) … [`slides/week-12.html`](slides/week-12.html)
- Tutorial notes: [`tutorial-notes/`](tutorial-notes/) (weekly worksheet PDFs; see **Tutorial Notes** tab)
- Readings: [`readings/`](readings/) (weekly PDFs; see **Reading** and **Resources** tabs on the site)

## Rebuild slides from Marp sources (maintainers)

Requires Node (nvm) and source files under `Notes/User-centred_Design_in_Digital_Media/`.

```bash
cd Github/SSHD5014
npm install
./export-slides.sh
```

This regenerates weeks 1–12, embeds local images into the HTML, and removes any temporary `slides/images` folder.

## Site structure (publish)

```
SSHD5014/
  index.html
  auth.js                 Password gate (required)
  .nojekyll
  .gitignore
  README.md
  assets/briefs/          Assessment briefs (optional)
  slides/
    week-01.html … week-12.html   (self-contained)
  tutorial-notes/
    SHDS5014_tutorial_week_01_….pdf … week_12_….pdf
  readings/
    *.pdf                 Assigned reading PDFs
    README.md             Week-by-week page map
```
