# Repository checks

The repository contains product code, reproducible build assets, synthetic test fixtures and maintained documentation. Keep personal SavedVariables, account paths, screenshots containing real character data, local reports, credentials and environment output outside version control.

Run `python tools/install_hooks.py` once per checkout to enable the versioned pre-push hook. Run `python tools/privacy_guard.py` at any time. The validation and release workflows run the same standard-library check with full Git history.

The guard checks tracked files and nonignored new files in the current working tree. It also reads every added or changed blob from every commit after the fixed historical baseline, including changes relative to each merge parent. A secret added in one commit and removed in a later commit still blocks the push. File names, recognizable personal paths, common secret formats and literal secret assignments are checked; diagnostics report the rule and file, never the matched secret value.

Existing published history at commit `603e7ee7b1523df1a30cb48eb67cc353e14d6ea0` is preserved. Historical commits are grandfathered, but the current tree is always checked. Do not move this baseline to bypass a finding. Existing Git tags and release assets are not rewritten by cleanup.

Ignored local files are not candidates for publication, but force-added files are checked even when an ignore rule matches. Test fixtures must use synthetic data. The guard recognizes common leak patterns; it cannot establish that arbitrary character names or images are safe to publish. Review those assets before committing them.

If a new commit fails, remove the material from all unpublished commits that introduced it, then rerun the guard. If credentials have already been published, revoke them through their provider. The guard never rewrites history or removes files automatically.
