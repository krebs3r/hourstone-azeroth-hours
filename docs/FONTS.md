# Font provenance

The addon uses the installed WoW client's `STANDARD_TEXT_FONT`, falling back to `Fonts\FRIZQT__.TTF`. No WoW or operating-system font file is redistributed.

The fonts below remain in the package for compatibility and reproducible development checks. Gelasio approximates font metrics in the Lua UI simulator; the runtime does not load either bundled font. No system-wide font installation is required.

| Font file | Source | License |
| --- | --- | --- |
| Gelasio-Regular.ttf | [SorkinType/Gelasio](https://github.com/SorkinType/Gelasio/blob/main/fonts/ttf/Gelasio-Regular.ttf), Git blob `13757bd94745beb3f95adcfb87936bd9909f554d` | [Gelasio OFL](../Hourstone/Media/Fonts/Gelasio-OFL.txt) |
| Selawik-Regular.ttf | [Microsoft Selawik 1.01](https://github.com/microsoft/Selawik/releases/tag/1.01), `selawk.ttf` from `Selawik_Release.zip` | [Selawik OFL](../Hourstone/Media/Fonts/Selawik-OFL.txt) |

Selawik's file is renamed only; font tables and names are unchanged. [The manifest](font-manifest.json) records source URLs, byte lengths and SHA-256 hashes. Package tests verify the shipped bytes, sizes and license texts directly. Packaging preserves font and texture bytes and normalizes only text line endings. The addon's MIT license does not replace these font licenses.
