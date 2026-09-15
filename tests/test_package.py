import importlib.util
from pathlib import Path
import uuid
import shutil
import unittest
import zipfile

ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location("package",ROOT/"tools/package.py")
package=importlib.util.module_from_spec(spec)
spec.loader.exec_module(package)

class Packaging(unittest.TestCase):
    def test_tag_mismatch_is_rejected(self):
        with self.assertRaisesRegex(ValueError,"does not match"):
            package.validate(tag="v9.9.9")

    def test_reproducible_install_archive(self):
        base=(ROOT/"dist/package-tests").resolve()
        root=base/uuid.uuid4().hex
        root.mkdir(parents=True)
        try:
            shutil.copytree(ROOT/"Hourstone",root/"Hourstone")
            archive=package.package(root,tag="v0.1.0")
            first=archive.read_bytes()
            package.package(root,tag="v0.1.0")
            self.assertEqual(first,archive.read_bytes())
            with zipfile.ZipFile(archive) as z:
                self.assertIn("Hourstone/Media/Logo.tga",z.namelist())
                self.assertIn("Hourstone/LICENSE.txt",z.namelist())
                self.assertFalse(any("docs/" in n or "tests/" in n for n in z.namelist()))
            (root/"Hourstone/Model.lua").unlink()
            with self.assertRaisesRegex(ValueError,"Invalid TOC source"):
                package.validate(root)
        finally:
            assert root.resolve().is_relative_to(base) and root.resolve()!=base
            shutil.rmtree(root)

if __name__=="__main__": unittest.main()
