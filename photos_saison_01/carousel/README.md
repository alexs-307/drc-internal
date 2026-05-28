# Saison 01 — carousel photos

## How to add a photo

The carousel has 9 cards total: the first 4 are existing real photos hardcoded
in `index.html` (not drop-ins). The remaining 5 are drop-in slots mapped to
fixed filenames:

    carousel-01.jpg
    carousel-02.jpg
    carousel-03.jpg
    carousel-04.jpg
    carousel-05.jpg

Drop the correctly named file into this folder. When a file with the right name
exists, it auto-fills that slot and covers the numbered placeholder tile — no
markup change needed.

## How to edit a caption

Each slot's caption is hardcoded inline in `index.html`. Search for the carousel
block (look for the comment `SAISON 01 — CAROUSEL`) and change the `<figcaption>`
text for the matching card.

## Recommended image spec

- **Aspect ratio:** portrait, roughly 3:4 (e.g. 900 × 1200 px)
- **Max width:** 1200 px (the slot never renders wider than ~280 px on screen)
- **Format:** JPG or WebP
- **File size target:** under 300 KB per photo

Keeping images portrait-ish preserves the film-contact-sheet rhythm of the row.
Landscape images will display with `object-fit: cover` and may crop significantly.
