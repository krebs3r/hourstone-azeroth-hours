"""Convert approved PNG masters into uncompressed 32-bit WoW TGA textures."""
from pathlib import Path
import struct
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SIZES = {"Logo": 256, "RetailPanel": 512, "ClassicPanel": 512, "HeaderClose": 128, "HeaderHide": 128}

def build():
    target = ROOT / "Hourstone" / "Media"
    target.mkdir(parents=True, exist_ok=True)
    for name, size in SIZES.items():
        source = Image.open(ROOT / "docs" / "assets" / f"{name}.png").convert("RGBA")
        if source.size != (size, size):
            source = source.resize((size, size), Image.Resampling.LANCZOS)
        # Type 2, BGRA, top-left origin, eight alpha bits. No optional TGA footer.
        header = struct.pack("<BBBHHBHHHHBB", 0, 0, 2, 0, 0, 0, 0, 0, size, size, 32, 40)
        (target / f"{name}.tga").write_bytes(header + source.tobytes("raw", "BGRA"))
        print(f"{name}: {size} × {size}, RGBA")

if __name__ == "__main__":
    build()
