# Homepage hero images

Each image in `Settings.homepage_images` ships as pre-generated WebP derivatives, named `<basename>-wide-<width>w.webp` and `<basename>-narrow.webp`. `HeroHelper` builds the `<picture>` sources from those files, and skips any width that isn't present, so an image that can't fill the whole ladder just gets a shorter srcset.

Original images should be **at least 3200 x 1800 pixels**, sent at original quality.

## Generating derivatives

From a 3200 x 1800 original:

```bash
slug=your-image-name
cwebp -m 6 -q 60 -resize 2400 0 original.jpg -o "${slug}-wide-2400w.webp"
cwebp -m 6 -q 60 -resize 2000 0 original.jpg -o "${slug}-wide-2000w.webp"
cwebp -m 6 -q 60 -resize 1600 0 original.jpg -o "${slug}-wide-1600w.webp"
cwebp -m 6 -q 60 -crop 880 0 1440 1800 -resize 1000 0 original.jpg -o "${slug}-narrow.webp"
```

## Current images

`moelis-reading-room` was built from a 2000 x 1125 original, which is below the criteria above. It has no 2400w, its 2000w is at the original's native width, and its narrow crop is 900px wide rather than 1000. Regenerate it if a larger original turns up.
