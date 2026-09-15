# Artwork provenance

**Approved direction:** the fourth Hourstone design, a grey teleport stone with a glowing blue rune and a golden foreground hourglass. User approval was received on 2026-09-15 before addon implementation.

`assets/Logo.png` is the approved Imagegen output (1254 × 1254, RGBA). It uses the original [Soundstone icon sheet](https://github.com/krebs3r/soundstone-azeroth-audio/blob/main/docs/icons-source.png) as its visual reference. No artistic edits were applied after generation. The clock arcs and hands from the previous three concepts were rejected; they are not shipped.

The generation prompt is preserved in [LOGO-PROMPT.md](LOGO-PROMPT.md). `tools/assets.py` mechanically resizes the PNG to 256 × 256 and writes an uncompressed 32-bit TGA with alpha for WoW.

`RetailPanel.png`, `ClassicPanel.png`, `HeaderClose.png` and `HeaderHide.png` are copied from [Soundstone's docs/assets](https://github.com/krebs3r/soundstone-azeroth-audio/tree/main/docs/assets) and converted without resizing into TGA. Copyright © 2026 krebs3r, MIT; the license is included at the repository root and in the installable addon. Hourstone renders the frame as nine texture regions, preserving the source corners.

The approved [browser mockup](mockup/index.html) is retained as a self-contained preview. Its comparison includes the Soundstone logo under the same MIT notice. Browser fonts and controls approximate the game and its data is fictional. It must not be described as an in-game screenshot.
