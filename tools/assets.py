"""Build approved artwork and code-defined UI primitives (uncompressed BGRA TGA)."""
from pathlib import Path
import math
import struct
import base64
import hashlib
import io
import json
from PIL import Image, ImageDraw

ROOT=Path(__file__).resolve().parents[1]
SIZES={"Logo":256,"RetailPanel":512,"ClassicPanel":512,"HeaderClose":128}

def save(name,im):
    im=im.convert("RGBA"); w,h=im.size
    target=ROOT/"Hourstone/Media"; target.mkdir(parents=True,exist_ok=True)
    header=struct.pack("<BBBHHBHHHHBB",0,0,2,0,0,0,0,0,w,h,32,40)
    (target/f"{name}.tga").write_bytes(header+im.tobytes("raw","BGRA"))

def primitive(name,draw,size=64):
    factor=4
    im=Image.new("RGBA",(size*factor,size*factor))
    draw(ImageDraw.Draw(im),factor)
    im=im.resize((size,size),Image.Resampling.LANCZOS)
    im.save(ROOT/"docs/assets"/f"{name}.png"); save(name,im)

def controls():
    palettes={
        "ControlRetail":("#0d1114","#0d1114","#757262",1),
        "ControlClassic":("#121311","#121311","#777568",1),
        "ToggleOn":("#71332c","#421a18","#72664c",1),
        "ToggleOff":("#181b1b","#181b1b","#72664c",1),
        "SettingsRetail":("#171b1c","#171b1c","#9d8959",2),
        "SettingsClassic":("#1a1b18","#1a1b18","#8b8a7e",2)}
    for name in ("ToggleOn","ToggleOff"):
        for side in ("Left","Right"): palettes[name+side]=palettes[name]
    for name,(top,bottom,border,stroke) in palettes.items():
        im=Image.new("RGBA",(256,64))
        a=tuple(bytes.fromhex(top[1:])); b=tuple(bytes.fromhex(bottom[1:]))
        d=ImageDraw.Draw(im)
        for y in range(64):
            d.line((0,y,255,y),fill=tuple(round(a[i]+(b[i]-a[i])*y/63) for i in range(3))+(255,))
        mask=Image.new("L",im.size); ImageDraw.Draw(mask).rounded_rectangle((0,0,255,63),radius=3,fill=255)
        im.putalpha(mask); d.rounded_rectangle((0,0,255,63),radius=3,outline=border,width=stroke)
        # Joined segments have square internal corners and one shared divider.
        if name.endswith(("Left","Right")):
            left,right=(253,255) if name.endswith("Left") else (0,2)
            for y in range(64):
                color=tuple(round(a[i]+(b[i]-a[i])*y/63) for i in range(3))+(255,)
                d.line((left,y,right,y),fill=border if y in (0,63) else color)
            if name.endswith("Right"): d.line((0,0,0,63),fill=border)
        im.save(ROOT/"docs/assets"/f"{name}.png"); save(name,im)

def build():
    for name,size in SIZES.items():
        im=Image.open(ROOT/"docs/assets"/f"{name}.png").convert("RGBA")
        save(name,im.resize((size,size),Image.Resampling.LANCZOS))
    manifest=json.loads((ROOT/"docs/mockup-05/soundstone-assets.json").read_text(encoding="utf-8"))
    for name,entry in manifest["assets"].items():
        data=base64.b64decode(entry["base64"],validate=True)
        blob=b"blob "+str(len(data)).encode()+b"\0"+data
        if hashlib.sha1(blob).hexdigest()!=entry["sha"]:
            raise ValueError(f"Soundstone asset hash mismatch: {name}")
        (ROOT/"docs/assets"/f"{name}.png").write_bytes(data)
        save(name,Image.open(io.BytesIO(data)))
    controls()
    primitive("Arrow",lambda d,s:d.polygon([(0,0),(32*s,0),(16*s,32*s)],fill="white"),32)
    primitive("LiveDot",lambda d,s:d.ellipse((0,0,64*s-1,64*s-1),fill="#6ce1b3"))
    primitive("Grip",lambda d,s:d.ellipse((0,0,16*s-1,16*s-1),fill=(168,171,169,178)),16)
    primitive("Check",lambda d,s:d.line([(10*s,31*s),(25*s,46*s),(54*s,15*s)],fill="#ffe3a1",width=8*s))
    def heart(d,s):
        points=[]
        for i in range(180):
            t=2*math.pi*i/180
            x=16+14*math.sin(t)**3
            y=16-.85*(13*math.cos(t)-5*math.cos(2*t)-2*math.cos(3*t)-math.cos(4*t))
            points.append((x*s,y*s))
        d.polygon(points,fill="#a75466")
    primitive("Heart",heart,32)
    primitive("CircleMask",lambda d,s:d.ellipse((0,0,64*s-1,64*s-1),fill="white"))
    primitive("MinimapBackground",lambda d,s:d.ellipse((s,s,64*s-s-1,64*s-s-1),fill="#10161a"))
    def ring(d,s,hover=False):
        d.ellipse((0,0,64*s-1,64*s-1),outline=(230,195,110,160) if hover else "#343332",width=s)
        d.ellipse((s,s,63*s-1,63*s-1),outline=(255,225,155,100) if hover else "#ad9460",width=3*s)
    primitive("MinimapBorder",ring)
    primitive("MinimapHover",lambda d,s:ring(d,s,True))
    def gear(d,s):
        pts=[]
        for i in range(64):
            a=math.pi*2*i/64
            r=29 if i%8 in (1,2,3,4) else 23
            pts.append(((32+math.cos(a)*r)*s,(32+math.sin(a)*r)*s))
        d.polygon(pts,fill="#bead7c")
        d.ellipse((15*s,15*s,49*s,49*s),fill=(0,0,0,0))
        d.ellipse((21*s,21*s,43*s,43*s),outline="#bead7c",width=4*s)
    primitive("Gear",gear)
    print("Built approved artwork and UI primitives.")

if __name__=="__main__": build()
