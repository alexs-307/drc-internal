# Saison 01 — carousel photos

## How it works

The carousel shows 9 real portrait photos, all living in this folder, named
`01-…` through `09-…`. They are displayed in numeric filename order. Each photo
is explicitly referenced by its exact filename from a `<figure>` in `index.html`
— there are no auto-filled drop-in slots.

## How to add or replace a photo

Drop the file into this folder, then update the matching `<figure>` in
`index.html`: change its `<img src>` to the new filename and its `<figcaption>`.
Search for the carousel block (look for the comment `SAISON 01 — CAROUSEL`) to
find the cards.

## How to edit a caption

Each card's caption is hardcoded inline in `index.html`. Find the matching
`<figure>` in the carousel block and change its `<figcaption>` text.

## Recommended image spec

- **Aspect ratio:** portrait, roughly 3:4 (e.g. 900 × 1200 px)
- **Max width:** 1200 px (the slot never renders wider than ~280 px on screen)
- **Format:** JPG or WebP
- **File size target:** under 300 KB per photo

Keeping images portrait-ish preserves the film-contact-sheet rhythm of the row.
Landscape images will display with `object-fit: cover` and may crop significantly.
