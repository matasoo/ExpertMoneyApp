# ExpertMoney — presentation site

Static landing page for the ExpertMoney mobile app. No build step, no dependencies.
Production domain: **https://expert-money.com**

```
site-web/
├── index.html          Landing page
├── privacy.html        Privacy Policy
├── terms.html          Terms of Service
├── 404.html            Not-found page (uses absolute paths — works at any URL depth)
├── robots.txt          Allows all crawlers, points at the sitemap
├── sitemap.xml         3 URLs
├── favicon.ico         Multi-size: 16 / 32 / 48 / 64
├── css/style.css       All styles
├── js/main.js          All interactions
└── assets/
    ├── logo-32.png     <link rel="icon">
    ├── logo-180.png    apple-touch-icon
    ├── logo-192.png    In-page logo (nav + footer)
    └── og-image.png    1200×630 social share card
```

Total ~233 KB. First paint pulls ~90 KB (HTML + CSS + JS + logo) plus Manrope from Google Fonts.

## Run locally

```bash
cd site-web
python -m http.server 8000
# http://localhost:8000
```

Serve it rather than opening `index.html` from disk — `404.html` uses absolute paths and only
renders correctly over HTTP.

## Page structure

Hero (phone mockup: Dashboard / Budgets / Goals) → trust strip → 6 feature cards →
how it works → three showcase sections (Budgets, Goals, Reports) → security → FAQ →
download CTA → footer.

No AI features and no pricing are presented anywhere on the site.

## Responsible person

ExpertMoney is operated by **Voinea David Adrian** as a private individual, not a company. Both
legal pages are written in the first person singular and name him as the data controller; no
postal address is published, only `support@expert-money.com`.

## Still open

- [ ] **`support@expert-money.com` must actually receive mail.** It appears 6 times across the site
      and is the only contact channel — including for GDPR requests in the Privacy Policy.
- [ ] **Turn the store buttons into real links** after publishing. In `index.html`, swap
      `<span class="store-btn is-soon">` for `<a class="store-btn" href="...">` and drop the
      `<i>Coming soon to</i>` line.
- [ ] Swap the CSS phone mockup for real screenshots after launch.

### Defaults chosen — change if they do not match your intent

| Where | Value |
|---|---|
| Both pages, "Last updated" | 25 August 2026 |
| Minimum age | 16 |
| Account deletion window | 30 days |
| Backup rotation | 90 days |
| Response to data requests | 30 days (GDPR requires one month) |
| Governing law | Romania |
| Data location | Google Cloud western Europe (EU) for Firestore + Storage |

## Design

Mirrors the app's theme (`lib/core/theme/app_colors.dart`):

| Token | Value | Used for |
|---|---|---|
| `--primary` | `#2ECC71` | Accent, CTAs, progress |
| `--primary-dk` | `#27AE60` | Gradients |
| `--surface` | `#202022` | Phone mockup screen |
| `--surface-2` | `#2C2C2E` | Cards inside mockup |
| `--muted` | `#A0A0A0` | Secondary text |

Font is Manrope, same as the app.

## Deploy

Any static host works. All internal links assume the site sits at the **domain root**.

- **Firebase Hosting** — you already use Firebase: `firebase init hosting` with `site-web` as the
  public directory. Add this to `firebase.json` so the 404 page is served:
  ```json
  "hosting": { "public": "site-web", "cleanUrls": true,
               "ignore": ["firebase.json", "**/.*"] }
  ```
  Firebase serves `404.html` automatically. Then `firebase deploy --only hosting`.
- **Netlify / Vercel** — drag the folder in; both pick up `404.html` automatically.
- **GitHub Pages** — serves `404.html` automatically; point Pages at this folder.

After deploying, submit `https://expert-money.com/sitemap.xml` in Google Search Console.

## Regenerating images

`favicon.ico` and everything in `assets/` are generated from `assets/images/logo.png` in the
Flutter project root (1254×1254, no alpha). See the Pillow snippets in the git history for this
folder if you need to rebuild them at different sizes.
