import importlib.util
from pathlib import Path
import uuid
import shutil
import unittest
import zipfile
import hashlib
import json
import base64
import io
from PIL import Image

ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location("package",ROOT/"tools/package.py")
package=importlib.util.module_from_spec(spec)
spec.loader.exec_module(package)

class Packaging(unittest.TestCase):
    def test_soundstone_asset_pixels_and_provenance(self):
        manifest=json.loads((ROOT/"docs/assets/soundstone-manifest.json").read_text(encoding="utf-8"))
        for name,entry in manifest["assets"].items():
            data=base64.b64decode(entry["base64"],validate=True)
            self.assertEqual(hashlib.sha1(b"blob "+str(len(data)).encode()+b"\0"+data).hexdigest(),entry["sha"])
            source=Image.open(io.BytesIO(data)).convert("RGBA")
            shipped=Image.open(ROOT/"Hourstone/Media"/(name+".tga")).convert("RGBA")
            self.assertEqual(source.size,shipped.size)
            self.assertEqual(source.tobytes(),shipped.tobytes())

    def test_protocol4_capability_is_explicit(self):
        toc=(ROOT/"Hourstone/Hourstone.toc").read_text(encoding="utf-8")
        self.assertIn("## X-Hourstone-Sync-Protocol: 4",toc.splitlines())
        self.assertLess(toc.index("ProgressSync.lua"),toc.index("Core.lua"))

    def test_tag_mismatch_is_rejected(self):
        with self.assertRaisesRegex(ValueError,"does not match"):
            package.validate(tag="v9.9.9")

    def test_reproducible_install_archive(self):
        base=(ROOT/"dist/package-tests").resolve()
        root=base/uuid.uuid4().hex
        root.mkdir(parents=True)
        try:
            shutil.copytree(ROOT/"Hourstone",root/"Hourstone")
            version=package.validate(root)
            archive=package.package(root,tag=f"v{version}")
            first=archive.read_bytes()
            package.package(root,tag=f"v{version}")
            self.assertEqual(first,archive.read_bytes())
            with zipfile.ZipFile(archive) as z:
                self.assertIn("Hourstone/Media/Logo.tga",z.namelist())
                self.assertEqual(z.read("Hourstone/Media/Heart.tga"),(ROOT/"Hourstone/Media/Heart.tga").read_bytes())
                self.assertIn("Hourstone/LICENSE.txt",z.namelist())
                for name in ("Toggle","ToggleRed","Rivet","GoldThumb","SilverThumb"):
                    member=f"Hourstone/Media/{name}.tga"
                    self.assertEqual(z.read(member),(ROOT/member).read_bytes())
                self.assertNotIn("Hourstone/Media/HeaderHide.tga",z.namelist())
                for name in ("Gelasio","Selawik"):
                    member=f"Hourstone/Media/Fonts/{name}-Regular.ttf"
                    self.assertEqual(z.read(member),(ROOT/member).read_bytes())
                    self.assertIn(f"Hourstone/Media/Fonts/{name}-OFL.txt",z.namelist())
                manifest=json.loads((ROOT/"docs/font-manifest.json").read_text())
                self.assertEqual({entry["file"] for entry in manifest}, {"Gelasio-Regular.ttf", "Selawik-Regular.ttf"})
                for entry in manifest:
                    member="Hourstone/Media/Fonts/"+entry["file"]
                    font=z.read(member)
                    self.assertEqual(len(font),entry["bytes"])
                    self.assertEqual(hashlib.sha256(font).hexdigest(),entry["sha256"])
                    self.assertTrue(entry["source"].startswith("https://github.com/"))
                    license_name=entry["file"].replace("-Regular.ttf", "-OFL.txt")
                    self.assertIn(b"SIL OPEN FONT LICENSE", z.read("Hourstone/Media/Fonts/"+license_name))
                self.assertTrue(all(i.create_system==3 for i in z.infolist()))
                self.assertFalse(any("docs/" in n or "tests/" in n for n in z.namelist()))
            (root/"Hourstone/Model.lua").unlink()
            with self.assertRaisesRegex(ValueError,"Invalid TOC source"):
                package.validate(root)
        finally:
            assert root.resolve().is_relative_to(base) and root.resolve()!=base
            shutil.rmtree(root)

if __name__=="__main__": unittest.main()
