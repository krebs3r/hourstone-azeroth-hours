"""Validate and reproducibly package the addon. No third-party dependencies."""
import argparse
import hashlib
from pathlib import Path
import re
import struct
import zipfile

ROOT = Path(__file__).resolve().parents[1]
EXPECTED_INTERFACES = {120100, 50504, 20506, 11509, 16001}

def validate(root=ROOT, tag=None):
    addon = root / "Hourstone"
    toc = (addon / "Hourstone.toc").read_text(encoding="utf-8")
    match = re.search(r"^## Version: (\d+\.\d+\.\d+)$", toc, re.M)
    if not match:
        raise ValueError("TOC requires a semantic version")
    version = match[1]
    if tag is not None and tag != f"v{version}":
        raise ValueError(f"Tag {tag!r} does not match addon version v{version}")
    interfaces = re.search(r"^## Interface: (.+)$", toc, re.M)
    if not interfaces or {int(i.strip()) for i in interfaces[1].split(",")} != EXPECTED_INTERFACES:
        raise ValueError("Unexpected client interface metadata")
    if "## SavedVariables: HourstoneDB" not in toc:
        raise ValueError("Account-wide saved variable declaration missing")
    sources = [line.strip() for line in toc.splitlines() if line.strip() and not line.startswith("#")]
    for source in sources:
        if not (addon / source).is_file() or Path(source).is_absolute() or ".." in Path(source).parts:
            raise ValueError(f"Invalid TOC source: {source}")
    actual = {p.name for p in addon.glob("*.lua")}
    if actual != set(sources):
        raise ValueError("TOC and Lua source files disagree")
    sizes={"Logo":(256,256),"RetailPanel":(512,512),"ClassicPanel":(512,512),"HeaderClose":(128,128),
        "ControlRetail":(256,64),"ControlClassic":(256,64),"ToggleOn":(256,64),"ToggleOff":(256,64),
        "SettingsRetail":(256,64),"SettingsClassic":(256,64),"Arrow":(32,32),"Grip":(16,16),"Heart":(32,32)}
    for name in ("LiveDot","Check","Gear","CircleMask","MinimapBackground","MinimapBorder","MinimapHover"):
        sizes[name]=(64,64)
    for name in ("ToggleOn","ToggleOff"):
        for side in ("Left","Right"): sizes[name+side]=(256,64)
    for name in ("Toggle","ToggleRed","GoldThumb","SilverThumb"):
        sizes[name]=(128,128)
    sizes["Rivet"]=(64,64)
    for name, (width,height) in sizes.items():
        data = (addon / "Media" / f"{name}.tga").read_bytes()
        fields = struct.unpack("<BBBHHBHHHHBB", data[:18])
        if fields[:3] != (0,0,2) or fields[8:12] != (width,height,32,40) or len(data)!=18+width*height*4:
            raise ValueError(f"Invalid RGBA TGA: {name}")
    for name in ("Gelasio","Selawik"):
        font=(addon/"Media/Fonts"/f"{name}-Regular.ttf").read_bytes()
        if font[:4] != b"\x00\x01\x00\x00":
            raise ValueError(f"Invalid TrueType font: {name}")
        if "SIL OPEN FONT LICENSE" not in (addon/"Media/Fonts"/f"{name}-OFL.txt").read_text(encoding="utf-8"):
            raise ValueError(f"Missing font license: {name}")
    return version

def package(root=ROOT, tag=None):
    version = validate(root, tag)
    target = root / "dist"
    target.mkdir(exist_ok=True)
    archive = target / f"Hourstone-{version}.zip"
    sources = sorted(p for p in (root/"Hourstone").rglob("*") if p.is_file())
    with zipfile.ZipFile(archive,"w",compression=zipfile.ZIP_DEFLATED,compresslevel=9) as z:
        for source in sources:
            if source.suffix not in {".lua", ".toc", ".tga", ".txt", ".ttf"}:
                raise ValueError(f"Unexpected install file: {source}")
            info=zipfile.ZipInfo(source.relative_to(root).as_posix(), (2026,1,1,0,0,0))
            info.compress_type=zipfile.ZIP_DEFLATED
            info.create_system=3
            info.external_attr=0o100644<<16
            data=source.read_bytes()
            if source.suffix in {".lua", ".toc", ".txt"}:
                data=data.replace(b"\r\n",b"\n")
            z.writestr(info,data,compresslevel=9)
    with zipfile.ZipFile(archive) as z:
        if z.testzip() or "Hourstone/Hourstone.toc" not in z.namelist() or any(not n.startswith("Hourstone/") for n in z.namelist()):
            raise ValueError("Broken addon ZIP structure")
    checksum=hashlib.sha256(archive.read_bytes()).hexdigest()
    archive.with_suffix(".zip.sha256").write_text(f"{checksum}  {archive.name}\n",encoding="ascii",newline="\n")
    print(f"PASS {archive.name}: {len(sources)} files, {archive.stat().st_size} bytes\nSHA-256 {checksum}")
    return archive

if __name__=="__main__":
    parser=argparse.ArgumentParser()
    parser.add_argument("--tag")
    args=parser.parse_args()
    package(tag=args.tag)
