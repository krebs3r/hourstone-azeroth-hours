import importlib.util
from pathlib import Path
import uuid
import shutil
import unittest
import zipfile
import hashlib
import json
import base64
import re
import io
from PIL import Image

ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location("package",ROOT/"tools/package.py")
package=importlib.util.module_from_spec(spec)
spec.loader.exec_module(package)

class Packaging(unittest.TestCase):
    def test_soundstone_asset_pixels_and_provenance(self):
        manifest=json.loads((ROOT/"docs/mockup-05/soundstone-assets.json").read_text(encoding="utf-8"))
        for name,entry in manifest["assets"].items():
            data=base64.b64decode(entry["base64"],validate=True)
            self.assertEqual(hashlib.sha1(b"blob "+str(len(data)).encode()+b"\0"+data).hexdigest(),entry["sha"])
            source=Image.open(io.BytesIO(data)).convert("RGBA")
            shipped=Image.open(ROOT/"Hourstone/Media"/(name+".tga")).convert("RGBA")
            self.assertEqual(source.size,shipped.size)
            self.assertEqual(source.tobytes(),shipped.tobytes())

    def test_tag_mismatch_is_rejected(self):
        with self.assertRaisesRegex(ValueError,"does not match"):
            package.validate(tag="v9.9.9")

    def test_reproducible_install_archive(self):
        base=(ROOT/"dist/package-tests").resolve()
        root=base/uuid.uuid4().hex
        root.mkdir(parents=True)
        try:
            shutil.copytree(ROOT/"Hourstone",root/"Hourstone")
            archive=package.package(root,tag="v0.1.1")
            first=archive.read_bytes()
            package.package(root,tag="v0.1.1")
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
                embedded=re.findall(r"data:font/ttf;base64,([A-Za-z0-9+/=]+)",(ROOT/"docs/mockup/index.html").read_text(encoding="utf-8"))
                self.assertEqual(len(embedded),2)
                for source,entry in zip(embedded,manifest):
                    member="Hourstone/Media/Fonts/"+entry["file"]
                    self.assertEqual(hashlib.sha256(z.read(member)).hexdigest(),entry["sha256"])
                    self.assertEqual(base64.b64decode(source),z.read(member))
                self.assertTrue(all(i.create_system==3 for i in z.infolist()))
                self.assertFalse(any("docs/" in n or "tests/" in n for n in z.namelist()))
            (root/"Hourstone/Model.lua").unlink()
            with self.assertRaisesRegex(ValueError,"Invalid TOC source"):
                package.validate(root)
        finally:
            assert root.resolve().is_relative_to(base) and root.resolve()!=base
            shutil.rmtree(root)

if __name__=="__main__": unittest.main()
