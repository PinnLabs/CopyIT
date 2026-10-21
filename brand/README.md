# CopyIT brand

The CopyIT mark is two stacked cards (copy) with a text cursor (IT) on the front card.

## Files

| Path | What it is |
| --- | --- |
| `logo/mark-dark.svg` | App icon master. Ink body, paper card. Use this by default. |
| `logo/mark-light.svg` | Inverted icon for dark backgrounds. |
| `logo/mark-small.svg` | Simplified icon used at 16–32 px (no back card, heavier cursor). |
| `logo/wordmark-dark.svg` / `wordmark-light.svg` | "CopyIT" in outlines, for light / dark backgrounds. |
| `logo/lockup-dark.svg` / `lockup-light.svg` | Icon + wordmark, for light / dark backgrounds. |
| `menubar/MenuBarIcon.svg` | Monochrome menu bar glyph, rendered as a template image. |
| `social/social-preview.svg` | GitHub social preview, 1280 × 640. |
| `export/` | Generated PNGs. Do not edit by hand. |

The SVGs are the source of truth. After changing one, run:

```sh
make icons
```

This regenerates `AppIcon.appiconset`, `MenuBarIcon.imageset` and everything in `export/`. It needs `rsvg-convert` (`brew install librsvg`) or `cairosvg` (`pip install cairosvg`).

## Colors

| Name | Hex | Use |
| --- | --- | --- |
| Ink | `#15171C` | Icon body, text |
| Paper | `#F7F7F5` | Card, light backgrounds |
| Accent | `#EE5A24` | Cursor and "IT" only |
| Graphite | `#5B5F68` | Secondary text |

## Type

- **Space Grotesk Bold**, tracking −3%: wordmark and headings.
- **JetBrains Mono**: labels and code.

Both are licensed under the SIL Open Font License 1.1. The wordmark SVGs are already converted to outlines, so they don't need the font installed.

## Usage

- Keep clear space around the mark equal to the height of the cursor.
- At 32 px and below, use `mark-small.svg` instead of the full mark.
- Don't recolor, stretch, rotate, add effects or rebuild the wordmark in another typeface.
- Use the accent color only on the cursor and the "IT".

## License

The code in this repository is MIT-licensed. The logo files in `brand/` are licensed separately under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/): you may use them to refer to CopyIT, in articles, tutorials and integrations.

The CopyIT name and logo may not be used in a way that suggests endorsement by the project, or as the name or icon of a fork or derivative app. Forks should ship their own name and icon.
