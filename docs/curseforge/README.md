# Publishing Hourstone on CurseForge

Project: [Hourstone – Azeroth Hours](https://www.curseforge.com/wow/addons/hourstone-azeroth-hours), ID **1697059**. [project.json](project.json) contains the configured game versions and public project metadata.

## Setup and release

1. Create a dedicated token in the [CurseForge token settings](https://authors-old.curseforge.com/account/api-tokens) and save it as the repository Actions secret `CF_API_TOKEN`. Run **Check CurseForge connection** to verify authentication and configured versions without uploading.
2. Update the TOC version, release notes, changelog and confirmed game-version configuration. Complete automated and native-client validation.
3. Push the matching `vX.Y.Z` tag or run **Release** with that tag. The workflow checks repository privacy, runs tests, builds the ZIP and SHA-256, and publishes the GitHub release.
4. The dependent CurseForge job downloads that exact ZIP, verifies its checksum and GitHub asset digest, checks the embedded TOC version, then uploads the release notes and configured game versions through the [CurseForge Upload API](https://support.curseforge.com/support/solutions/articles/9000197321).

The resulting `curseforge-upload.json` release asset records the file ID and ZIP hash. Check moderation and public availability separately. A workflow triggered by a manually created GitHub release is not configured; use the tag or workflow above.

## Interrupted uploads and retries

The job creates `curseforge-upload-pending.json` on the GitHub release without overwriting it before sending an upload. A completed receipt makes retries a no-op. The minimal [historical receipt](releases/v0.1.1.json) protects the first published upload from duplication.

If a token or other pre-upload check fails, correct it and re-run failed jobs. Re-running the whole release job stops at an existing GitHub release to preserve published assets.

An interrupted upload with a pending marker requires inspection of the [authors dashboard](https://authors.curseforge.com/#/projects/1697059/files), including processing files. If upload succeeded, restore the verified receipt from the Actions artifact or reconstruct its file ID from the confirmed matching upload. Only remove a pending marker when the earlier job has stopped and absence of an upload has been established. Never treat a timeout as proof that no upload occurred.

Published ZIPs and historical release tags remain immutable. `logo-400.png` is a proportional export of the Hourstone logo. [description.md](description.md) contains public product copy; real character databases, capture logs and local publishing credentials are not repository assets.
