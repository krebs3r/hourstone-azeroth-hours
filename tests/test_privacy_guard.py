import importlib.util
import io
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("privacy_guard", ROOT / "tools/privacy_guard.py")
guard = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = guard
spec.loader.exec_module(guard)


class PrivacyGuard(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.git("init", "--quiet")
        self.git("config", "user.name", "Fixture Author")
        self.git("config", "user.email", "fixture@example.invalid")
        self.write("README.md", "Public baseline\n")
        self.baseline = self.commit("Baseline")

    def git(self, *args):
        return subprocess.run(["git", "-C", str(self.root), *args], check=True,
                              stdout=subprocess.PIPE, stderr=subprocess.PIPE).stdout.decode().strip()

    def write(self, path, data):
        target = self.root / path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(data, encoding="utf-8")

    def commit(self, message):
        self.git("add", "--all")
        self.git("-c", "commit.gpgsign=false", "commit", "--quiet", "-m", message)
        return self.git("rev-parse", "HEAD")

    def test_intermediate_secret_is_rejected_after_later_removal(self):
        self.write("example.txt", "gh" + "p_" + "A" * 36)
        self.commit("Add temporary material")
        (self.root / "example.txt").unlink()
        self.commit("Remove temporary material")
        self.assertEqual(guard.current_tree(self.root), [])
        findings = guard.introduced_blobs(self.root, baseline=self.baseline)
        self.assertTrue(any(item.rule == "GitHub credential" for item in findings))
        self.assertTrue(all("A" * 36 not in str(item) for item in findings))

    def test_ignored_local_file_is_excluded_but_force_added_file_is_checked(self):
        self.write(".gitignore", ".env*\n")
        self.write(".env.local", "LOCAL_EXAMPLE=1\n")
        self.assertEqual(guard.current_tree(self.root), [])
        self.git("add", "--force", ".env.local")
        self.assertTrue(any(item.rule == "local environment file" for item in guard.current_tree(self.root)))

    def test_original_history_is_grandfathered_but_not_current_contents(self):
        self.write("old.txt", "gh" + "p_" + "B" * 36)
        historical = self.commit("Historical fixture")
        self.assertEqual(guard.introduced_blobs(self.root, baseline=historical), [])
        self.assertTrue(guard.current_tree(self.root))
        (self.root / "old.txt").unlink()
        self.commit("Clean current tree")
        self.assertEqual(guard.introduced_blobs(self.root, baseline=historical), [])

    def test_no_baseline_checks_initial_commit_and_handles_unborn_repository(self):
        self.write("initial.txt", "gh" + "p_" + "D" * 36)
        self.commit("Content to check")
        self.assertTrue(guard.introduced_blobs(self.root, baseline=None))
        unborn = self.root / "unborn"
        unborn.mkdir()
        subprocess.run(["git", "-C", str(unborn), "init", "--quiet"], check=True)
        self.assertEqual(guard.introduced_blobs(unborn, baseline=None), [])

    def test_side_branch_blob_is_checked_even_when_merge_removes_it(self):
        original_branch = self.git("branch", "--show-current")
        self.git("checkout", "-q", "-b", "side")
        self.write("temporary.txt", "sk" + "-" + "C" * 32)
        self.commit("Side branch material")
        self.git("checkout", "-q", original_branch)
        self.write("public.txt", "Independent public change\n")
        self.commit("Main change")
        self.git("-c", "commit.gpgsign=false", "merge", "--no-ff", "--no-commit", "side")
        (self.root / "temporary.txt").unlink()
        self.commit("Merge without temporary file")
        findings = guard.introduced_blobs(self.root, baseline=self.baseline)
        self.assertTrue(any(item.rule == "service credential" for item in findings))

    def test_personal_paths_and_private_files_are_rejected(self):
        personal = ("C:" + "\\" + "Users" + "\\" + "example-person" + "\\" + "Documents").encode()
        self.assertTrue(guard.inspect("notes.md", personal))
        self.assertTrue(guard.inspect("WTF/Account/Example/SavedVariables/data.lua", b"synthetic"))
        self.assertTrue(guard.inspect("docs/" + "mock" + "up-05/index.html", b"draft"))
        self.assertTrue(guard.inspect("local.log", b"output"))

    def test_synthetic_protocol_data_and_public_sources_are_allowed(self):
        source = b'{"machineId":"fixture-pc-a","guid":"Player-1-EXAMPLE","serverSeconds":42}'
        self.assertEqual(guard.inspect("tests/fixtures/sync/example.json", source), [])
        self.assertEqual(guard.inspect("docs/FONTS.md", b"https://github.com/microsoft/Selawik"), [])

    def test_pre_push_checks_every_updated_ref_and_skips_deletion(self):
        lines = f"refs/heads/main {'1' * 40} refs/heads/main {'2' * 40}\nrefs/tags/v1 {'3' * 40} refs/tags/v1 {'0' * 40}\nrefs/heads/old {'0' * 40} refs/heads/old {'4' * 40}\n"
        self.assertEqual(guard.pushed_heads(io.StringIO(lines)), ["1" * 40, "3" * 40])


if __name__ == "__main__":
    unittest.main()
