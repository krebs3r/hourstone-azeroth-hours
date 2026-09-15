"""Rebuild Mockup 04 with the identical fonts shipped by the addon."""
import base64,json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def build():
    assets=json.loads((ROOT/"docs/mockup/assets.json").read_text(encoding="utf-8"))
    for name in ("Heart","MinimapBackground","MinimapBorder","MinimapHover"):
        assets[name]="data:image/png;base64,"+base64.b64encode((ROOT/"docs/assets"/(name+".png")).read_bytes()).decode()
    fonts="".join("@font-face{font-family:"+name+";src:url(data:font/ttf;base64,"+base64.b64encode((ROOT/"Hourstone/Media/Fonts"/(name+"-Regular.ttf")).read_bytes()).decode()+") format('truetype');font-weight:400;font-display:block}" for name in ("Gelasio","Selawik"))
    body=(ROOT/"docs/mockup/template.html").read_text(encoding="utf-8").replace("__HOURSTONE_ASSETS__",json.dumps(assets)).replace("__HOURSTONE_FONTS__",fonts)
    page='<!doctype html><html lang="de"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Hourstone v0.1.1 test2 — Mockup 04 reference</title><style>body{margin:0;padding:26px 22px 30px;background:#111518}</style><body>'+body+'</body></html>'
    (ROOT/"docs/mockup/index.html").write_text(page,encoding="utf-8")
    print("Rebuilt Mockup 04 with bundled fonts; fictional data, not an in-game screenshot.")
if __name__=="__main__": build()
