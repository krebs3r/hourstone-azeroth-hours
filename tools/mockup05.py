"""Build the standalone Mockup 05. Does not modify the addon or Mockup 04."""
import base64
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TARGET = ROOT / "docs/mockup-05"

def build():
    assets = {}
    for name in ("Logo", "RetailPanel", "ClassicPanel", "HeaderClose", "Heart",
                 "Check", "MinimapBackground", "MinimapBorder", "MinimapHover"):
        assets[name] = "data:image/png;base64," + base64.b64encode(
            (ROOT / "docs/assets" / (name + ".png")).read_bytes()).decode()
    manifest = json.loads((TARGET / "soundstone-assets.json").read_text(encoding="utf-8"))
    for name, source in manifest["assets"].items():
        data = base64.b64decode(source["base64"], validate=True)
        blob = b"blob " + str(len(data)).encode() + b"\0" + data
        if hashlib.sha1(blob).hexdigest() != source["sha"]:
            raise ValueError(f"Soundstone asset hash mismatch: {name}")
        assets[name] = "data:image/png;base64," + source["base64"]
    template = (TARGET / "template.html").read_text(encoding="utf-8")
    page = template.replace("__ASSETS__", json.dumps(assets, ensure_ascii=True))
    target = TARGET / "index.html"
    target.write_text(page, encoding="utf-8", newline="\n")
    print(f"Built {target} ({target.stat().st_size} bytes); Mockup 04 and addon untouched.")

if __name__ == "__main__":
    build()
