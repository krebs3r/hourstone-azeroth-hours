# CurseForge upload records

This branch stores durable upload state separately from user-facing release downloads.
`uploads/<project-id>/<tag>.json` is the authoritative record. A pending record
must exist before an upload; a successful record identifies the uploaded file and
exact ZIP checksum. Never remove a pending record merely because a request timed out.

The 0.3.2 receipt and pending history were migrated from their verified GitHub
release assets. Published addon tags and packages are unchanged.

Historical workflows at v0.3.2 and earlier do not read this branch. Do not rerun
their individual CurseForge jobs after removing their old release records.
Use the current uploader from the default branch for retries or recovery.
