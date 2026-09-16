# Publishing Hourstone on CurseForge

Project: [Hourstone – Azeroth Hours](https://www.curseforge.com/wow/addons/hourstone-azeroth-hours), ID **1697059**. Current status is recorded in [STATUS.md](STATUS.md).

For 0.1.1 the user requested a GitHub release and CurseForge upload, and confirmed Retail and TBC Anniversary. On 2026-09-16, the user also confirmed Classic and Classic Era and requested enabling both for the existing release. [Acceptance](acceptance/v0.1.1.md) records the confirmation, exact commit and package hash.

## One-time setup

Create a dedicated **Hourstone GitHub Releases** token in the [CurseForge token settings](https://authors-old.curseforge.com/account/api-tokens), then save it as the repository Actions secret **CF_API_TOKEN** in [GitHub settings](https://github.com/krebs3r/hourstone-azeroth-hours/settings/secrets/actions). Do not commit tokens or reuse Soundstone credentials. Run the **Check CurseForge connection** workflow: it checks authentication and the configured game versions without uploading a file. Project upload permissions and moderation can only be fully verified by an actual release upload.

## Normal releases

1. Update `Hourstone/Hourstone.toc`, `docs/RELEASE-NOTES.md`, and the changelog. Keep `project.json`'s `game_versions` list limited to confirmed clients (currently Retail **12.1.0**, Mists Classic **5.5.4**, TBC Anniversary **2.5.6** and Classic Era **1.15.9**); update this list when support changes. The other TOC interfaces do not automatically opt clients into distribution.
2. Push the matching `vX.Y.Z` tag, or manually run **Release** with that tag. CI tests and builds the ZIP and SHA-256, then publishes the GitHub release.
3. The dependent **Upload release to CurseForge** job downloads that published ZIP, verifies both its checksum file and GitHub asset digest, and checks the embedded TOC version. It sends the GitHub release notes and the configured game versions through the [official CurseForge Upload API](https://support.curseforge.com/support/solutions/articles/9000197321). CurseForge publishes the file after approval.
4. The release asset `curseforge-upload.json` records the actual CurseForge file ID and ZIP hash. The Actions summary links to the file. Verify moderation and CurseForge-app availability separately.

## Failures and retries

The GitHub release remains published if CurseForge fails. After correcting a missing token or a pre-upload error, choose **Re-run failed jobs** on the original Release run. Re-running all jobs stops at the existing GitHub release to preserve its assets. Creating a GitHub release through the website alone does not trigger this workflow; use the tag push or Release workflow above.

Before the upload, the job attaches `curseforge-upload-pending.json` to the GitHub release **without overwrite**. This prevents parallel or repeated attempts from uploading twice. A valid completed receipt makes a retry a no-op; the historical `releases/v0.1.1.json` also protects the first manual upload. The pending marker remains as an audit record after success.

If a request times out or the runner stops after the marker was saved, the next attempt stops for inspection:

- Check the [authors dashboard](https://authors.curseforge.com/#/projects/1697059/files), including processing files. Never assume a timeout means the upload failed.
- If upload succeeded but attaching the receipt failed, download the `curseforge-upload-…` Actions artifact and attach its `curseforge-upload.json` to the matching GitHub release. If the response was lost, copy the pending record, add the verified `file_id` and `status: uploaded-awaiting-approval`, and attach it as `curseforge-upload.json` after confirming the uploaded file matches the ZIP.
- Only when the previous job has stopped **and absence of an upload is confirmed**, remove the pending marker from that release and choose **Re-run failed jobs**. Do not overwrite a published ZIP or retry an ambiguous upload.

Version 0.1.1 was uploaded manually; installing this automation does not upload it again. The source link and English/German description refer to GitHub; bugs go to GitHub Issues.

`logo-400.png` is a proportional export of the approved logo, with the motif unchanged. `screenshots/compact-ingame.png` is the actual user-supplied **test3** capture, captioned in the gallery as predating the final label, checkbox and minimap corrections. Browser mockups are not presented as native screenshots.
