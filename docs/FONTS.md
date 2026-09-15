# Font provenance

**Mockup 05 / test 3:** the addon uses `STANDARD_TEXT_FONT` (fallback `Fonts\FRIZQT__.TTF`) from the installed WoW client. It does not load Gelasio or Selawik. Mockup 05 and the Lua-derived browser preview use Georgia as a visual approximation. No WoW or operating-system font file is redistributed.

The older Mockup 04 font assets below remain byte-identical in the source/package for reproducible historical references and test metrics. Their licenses are retained. No system-wide font installation is required.

| Role | File | Official source | License |
| --- | --- | --- | --- |
| Titles, values, character rows, controls | Gelasio-Regular.ttf | [SorkinType/Gelasio](https://github.com/SorkinType/Gelasio/blob/main/fonts/ttf/Gelasio-Regular.ttf), Git blob 13757bd94745beb3f95adcfb87936bd9909f554d | [Gelasio OFL](../Hourstone/Media/Fonts/Gelasio-OFL.txt) |
| Uppercase statistics labels, table headings, update timestamps, scale label | Selawik-Regular.ttf | [Microsoft Selawik 1.01](https://github.com/microsoft/Selawik/releases/tag/1.01), original selawk.ttf from Selawik_Release.zip | [Selawik OFL](../Hourstone/Media/Fonts/Selawik-OFL.txt) |

Selawik's file is only renamed for clarity; font tables and names are unchanged. Sizes and SHA-256 hashes are recorded in font-manifest.json. Packaging preserves TTF/TGA bytes and normalizes only text files. MIT licensing of addon code does not replace these font licenses.
