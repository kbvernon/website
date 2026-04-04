# CLAUDE.md

See @README.md for project overview.

## Workflow

All rendering is driven by `render.R`, which runs as a GitHub Action. To render 
locally, run `Rscript render.R` from the project root (requires environment 
variables to be set). The entire process includes the following steps:

1.  **DOWNLOAD DATA.** The render script first fetches publication and
    presentation data from the Zotero API and writes it as CSL-JSON and BibTeX
    to `data/`.
2.  **COMPILE TEMPLATES.** The JSON is then passed to Tera templates (via
    extera) to render HTML and to the Typst template (via a typst system call)
    to render PDF.
3.  **DEPLOY SITE.** All rendered materials and assets required for serving
    HTML, including PDFs and BibTeX files, are then copied to `_site/`, which is
    deployed to GitHub Pages.

## Directory structure

Primary root files:

-   `render.R` — main rendering script
-   `config.json` — site configuration

Static folders:

-   `.github/` — GitHub Actions workflow that runs `render.R` on push or monthly
-   `pdfs/` — PDF copies of publications and presentations served from the site.
-   `templates/` — HTML templates and Typst CV source used by `render.R`.
-   `typst/` — Typst packages and fonts for CV rendering
-   `web/` — Static web assets

## Metadata

Site metadata is split between two sources. `config.json` holds static
configuration: personal details (name, current position), social and academic
profile links, and Open Graph metadata for social previews. Environment
variables hold secrets and dynamic configuration used at render time, primarily
credentials and collection IDs for interacting with the Zotero API.