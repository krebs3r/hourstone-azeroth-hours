import hashlib
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
import zipfile

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("curseforge", ROOT / "tools/curseforge.py")
cf = importlib.util.module_from_spec(spec)
spec.loader.exec_module(cf)


class CurseForgeUpload(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.work = self.root / "dist/curseforge"
        self.work.mkdir(parents=True)
        self.archive = self.work / "Hourstone-0.1.2.zip"
        with zipfile.ZipFile(self.archive, "w") as archive:
            archive.writestr("Hourstone/Hourstone.toc", "## Version: 0.1.2\n")
        self.digest = hashlib.sha256(self.archive.read_bytes()).hexdigest()
        self.checksum = self.archive.with_suffix(".zip.sha256")
        self.checksum.write_text(f"{self.digest}  {self.archive.name}\n")
        self.config = {"project_id": 1697059, "game_versions": ["12.1.0", "2.5.6"]}
        self.release = {
            "isDraft": False, "isPrerelease": False, "body": "Release notes ä\nSecond line",
            "assets": [{"name": self.archive.name, "digest": f"sha256:{self.digest}"},
                       {"name": self.checksum.name}],
        }
        self.uploads = []
        self.gh_mock = patch.object(cf, "gh", side_effect=self.fake_gh).start()
        self.api = patch.object(cf, "api_request", side_effect=self.fake_api).start()
        patch.dict(cf.os.environ, {"CF_API_TOKEN": "test-token"}).start()
        patch.object(cf, "report").start()
        self.addCleanup(patch.stopall)

    def fake_gh(self, *args):
        if args[:2] == ("release", "view"):
            return json.dumps(self.release)
        if args[:2] == ("release", "upload"):
            self.uploads.append(Path(args[3]).name)
        return ""

    def fake_api(self, path, token, data=None, content_type=None):
        if path == "/game/versions":
            return [{"id": 1, "name": "12.1.0", "gameVersionTypeID": 517},
                    {"id": 2, "name": "2.5.6", "gameVersionTypeID": 73246}]
        self.assertEqual(path, "/projects/1697059/upload-file")
        self.assertEqual(self.uploads, [cf.PENDING], "Persistent lock must exist before POST")
        self.assertIn(b'"gameVersions": [1, 2]', data)
        self.assertIn(b'"isMarkedForManualRelease": false', data)
        self.assertIn(self.archive.read_bytes(), data)
        return {"id": 123456}

    def run_publish(self):
        cf.publish("v0.1.2", self.config, self.root)

    def test_success_uploads_exact_zip_and_persists_receipt(self):
        self.run_publish()
        self.assertEqual(self.uploads, [cf.PENDING, cf.RECEIPT])
        receipt = json.loads((self.work / cf.RECEIPT).read_text())
        self.assertEqual(receipt["file_id"], 123456)
        self.assertEqual(receipt["sha256"], self.digest)
        self.assertEqual(self.api.call_count, 2)

    def test_completed_rerun_does_not_upload(self):
        self.run_publish()
        self.release["assets"].extend([{"name": cf.PENDING}, {"name": cf.RECEIPT}])
        self.api.reset_mock()
        self.uploads.clear()
        self.run_publish()
        self.api.assert_not_called()
        self.assertEqual(self.uploads, [])

    def test_pending_attempt_blocks_any_post(self):
        self.release["assets"].append({"name": cf.PENDING})
        with self.assertRaisesRegex(RuntimeError, "earlier upload"):
            self.run_publish()
        self.api.assert_not_called()

    def test_historical_manual_receipt_prevents_duplicate(self):
        records = self.root / "docs/curseforge/releases"
        records.mkdir(parents=True)
        (records / "v0.1.2.json").write_text(json.dumps({
            "tag": "v0.1.2", "project_id": 1697059, "sha256": self.digest, "file_id": 99,
        }))
        self.run_publish()
        self.api.assert_not_called()

    def test_mismatched_receipt_is_rejected(self):
        self.run_publish()
        self.release["assets"].append({"name": cf.RECEIPT})
        path = self.work / cf.RECEIPT
        record = json.loads(path.read_text())
        record["sha256"] = "wrong"
        path.write_text(json.dumps(record))
        self.api.reset_mock()
        with self.assertRaisesRegex(ValueError, "receipt does not match"):
            self.run_publish()
        self.api.assert_not_called()

    def test_checksum_mismatch_stops_before_api(self):
        self.checksum.write_text("incorrect checksum")
        with self.assertRaisesRegex(ValueError, "SHA-256"):
            self.run_publish()
        self.api.assert_not_called()

    def test_github_digest_mismatch_stops_before_api(self):
        self.release["assets"][0]["digest"] = "sha256:wrong"
        with self.assertRaisesRegex(ValueError, "GitHub's asset digest"):
            self.run_publish()
        self.api.assert_not_called()

    def test_tag_must_match_zip(self):
        with self.assertRaisesRegex(ValueError, "TOC version"):
            cf.verify_package(self.archive, self.checksum, "v0.1.3", self.release["assets"])

    def test_unconfirmed_or_ambiguous_versions_fail(self):
        for available in ([], [{"name": "12.1.0", "id": 1, "gameVersionTypeID": 517},
                               {"name": "12.1.0", "id": 2, "gameVersionTypeID": 517}],
                          [{"name": "12.1.0", "id": 1}], [{"name": "12.1.0", "id": 1, "gameVersionTypeID": 1}]):
            with self.subTest(available=available):
                with self.assertRaisesRegex(ValueError, "missing or ambiguous"):
                    cf.resolve_versions(available, ["12.1.0"])

    def test_forever_resolves_only_through_its_family(self):
        available = [{"name": "1.60.1", "id": 99, "gameVersionTypeID": 1},
                     {"name": "1.60.1", "id": 17053, "gameVersionTypeID": 88568},
                     {"name": "1.15.9", "id": 7, "gameVersionTypeID": 67408}]
        self.assertEqual(cf.FAMILIES["forever"], 88568)
        self.assertEqual(cf.resolve_versions(available, ["1.60.1", "1.15.9"]), [17053, 7])

    def test_project_keeps_existing_flavors_and_adds_forever(self):
        config = json.loads((ROOT / "docs/curseforge/project.json").read_text(encoding="utf-8"))
        self.assertEqual(config["game_versions"], ["12.1.0", "2.5.6", "5.5.4", "1.15.9", "1.60.1"])

    def test_missing_token_never_creates_lock(self):
        with patch.dict(cf.os.environ, {"CF_API_TOKEN": ""}):
            with self.assertRaisesRegex(ValueError, "CF_API_TOKEN"):
                self.run_publish()
        self.assertEqual(self.uploads, [])
        self.api.assert_not_called()

    def test_failed_lock_upload_prevents_curseforge_post(self):
        def fail_lock(*args):
            if args[:2] == ("release", "upload"):
                raise RuntimeError("GitHub unavailable")
            return self.fake_gh(*args)
        self.gh_mock.side_effect = fail_lock
        with self.assertRaisesRegex(RuntimeError, "GitHub unavailable"):
            self.run_publish()
        self.assertEqual(self.api.call_count, 1)

    def test_unknown_post_outcome_keeps_lock_without_retry(self):
        self.api.side_effect = [self.fake_api("/game/versions", "test-token"), RuntimeError("timeout")]
        with self.assertRaisesRegex(RuntimeError, "timeout"):
            self.run_publish()
        self.assertEqual(self.api.call_count, 2)
        self.assertEqual(self.uploads, [cf.PENDING])
        self.assertFalse((self.work / cf.RECEIPT).exists())

    def test_receipt_survives_github_failure_after_upload(self):
        def fail_receipt(*args):
            if args[:2] == ("release", "upload") and Path(args[3]).name == cf.RECEIPT:
                raise RuntimeError("GitHub unavailable")
            return self.fake_gh(*args)
        self.gh_mock.side_effect = fail_receipt
        with self.assertRaisesRegex(RuntimeError, "GitHub unavailable"):
            self.run_publish()
        self.assertTrue((self.work / cf.RECEIPT).exists())
        self.assertEqual(self.api.call_count, 2)

    def test_drafts_and_prereleases_are_rejected(self):
        for flag in ("isDraft", "isPrerelease"):
            self.release[flag] = True
            with self.assertRaisesRegex(ValueError, "published stable"):
                self.run_publish()
            self.release[flag] = False
        self.api.assert_not_called()


if __name__ == "__main__":
    unittest.main()
