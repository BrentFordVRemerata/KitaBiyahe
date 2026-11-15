# KitaBiyahe production mark

The route/K symbol in `mark.png` was created with ChatGPT's built-in image generation on November 14, 2026. The developer selected the simple silhouette for small-size recognition and requested a cleanup pass. It is an RGBA master with genuine transparency and generous clear space. It is separate from the preserved original reference mark.

The app header uses the transparent mark with contain sizing. Native launcher exports add a deliberate warm-ivory surface and retain transparent outer corners on Windows/legacy Android. Modern Android uses its own adaptive background, safe-area foreground and monochrome layer. The generated symbol is not redrawn by the export script.

App builds use the checked-in icon exports and require no image-generation service or Python. To regenerate native formats after an approved master replacement, install the optional dependencies in `scripts/requirements-brand.txt` and run `python scripts/EXPORT_BRAND_ASSETS.py` from the source root.

The symbol is a project identity, not evidence of trademark registration or exclusive rights.

See [LICENSING.md](../../LICENSING.md) for the offered rights and the separate scope of third-party material. No trademark or endorsement rights are granted by the project license.
