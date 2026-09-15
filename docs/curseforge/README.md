# Publishing Hourstone on CurseForge

Project: [Hourstone – Azeroth Hours](https://www.curseforge.com/wow/addons/hourstone-azeroth-hours), ID **1697059**. Current status is recorded in [STATUS.md](STATUS.md).

For 0.1.1 the user requested a GitHub release and CurseForge upload, and confirmed Retail and TBC Anniversary. [Acceptance](acceptance/v0.1.1.md) records the exact commit and package hash.

1. Run the tests and package checks; obtain user confirmation for the intended client versions.
2. Publish the matching GitHub tag using the Release workflow. CI tests and builds the ZIP and SHA-256.
3. Compare the release asset digest with the local verified ZIP. Never change the contents of an already published version.
4. In the existing CurseForge authors project, upload that ZIP once, with matching version and release notes. Select only confirmed game versions and automatic publication after approval.
5. Record the actual file ID and moderation status in `releases/`. Check existing pending files before any retry; do not submit a duplicate when the outcome is unclear.
6. Verify the public file and, when accessible, its CDN checksum after moderation. CurseForge-app installation is a separate distribution check.

This project currently uses a manual CurseForge upload. GitHub build/release automation is enabled; no CurseForge API token or automatic CurseForge upload has been configured. The source link and English/German description refer to GitHub; bugs go to GitHub Issues. Do not copy Soundstone credentials into this repository.

`logo-400.png` is a proportional export of the approved logo, with the motif unchanged. `screenshots/compact-ingame.png` is the actual user-supplied **test3** capture, captioned in the gallery as predating the final label, checkbox and minimap corrections. Browser mockups are not presented as native screenshots.
