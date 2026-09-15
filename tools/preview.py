"""Render a layout approximation from the real Lua UI frames for visual review.

This is a development preview with fictional data, never an in-game screenshot.
"""
import base64
import html
from pathlib import Path
import sys

ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/"tests"))
from run import runtime

ANCHORS={"TOPLEFT":(0,0),"TOP":(.5,0),"TOPRIGHT":(1,0),"LEFT":(0,.5),"CENTER":(.5,.5),"RIGHT":(1,.5),"BOTTOMLEFT":(0,1),"BOTTOM":(.5,1),"BOTTOMRIGHT":(1,1)}

def render(project,locale,settings=False):
    lua=runtime(project,locale)
    lua.execute('''fire("ADDON_LOADED","Hourstone"); fire("PLAYER_ENTERING_WORLD",true,false)
        fire("TIME_PLAYED_MSG",1125000,200)
        local chars={{"Schattenlaeuferlangname","Die Aldor",89,800000,"WARRIOR"},{"Moonwhisper","Blackhand",90,690000,"MAGE"},
        {"Same","Antonidas",80,320000,"MAGE"},{"Same","Die Aldor",32,128000,"WARRIOR"},{"Newcomer","Blackhand",1,nil,"MAGE"}}
        for i,c in ipairs(chars) do HourstoneDB.characters["test:"..i]={name=c[1],realm=c[2],level=c[3],seconds=c[4],class=c[5],updatedAt=EPOCH-i*7200} end
        advance(8040); H.UI:Toggle()''')
    if settings: lua.execute("H.UI:ToggleSettings()")
    frames=list(lua.globals().ALL_FRAMES.values())
    root=lua.globals().H.UI.frame.id
    records={f.id:dict(f.items()) for f in frames}
    bounds={root:(0,0,940,620)}
    def pos(idx):
        if idx in bounds: return bounds[idx]
        f=records[idx]
        if f.get("allPoints") is not None:
            result=pos(f["allPoints"].id); bounds[idx]=result; return result
        w,h=f.get("width",0),f.get("height",0) or f.get("fontSize",12)*1.3
        if f["kind"]=="FontString" and not h: h=f.get("fontSize",12)*1.3
        constraints=[[],[]]
        for point in f["points"].values():
            p,relative,rp,x,y=[point[i] for i in range(1,6)]
            if relative is None: relative=f.get("parent")
            if relative is None: continue
            rx,ry,rw,rh=pos(relative.id)
            ax,ay=ANCHORS[p]; bx,by=ANCHORS[rp]
            constraints[0].append((ax,rx+bx*rw+x)); constraints[1].append((ay,ry+by*rh-y))
        def axis(entries,size):
            if not entries: return 0,size
            a,b=entries[0]
            if not size:
                for c,d in entries[1:]:
                    if c!=a: size=(d-b)/(c-a); break
            return b-a*size,size
        x,w=axis(constraints[0],w); y,h=axis(constraints[1],h)
        bounds[idx]=(x,y,w,h); return bounds[idx]
    def visible(idx):
        if idx==root: return True
        f=records[idx]
        parent=f.get("parent")
        return bool(f.get("shown") and parent is not None and visible(parent.id)) if parent and parent.id!=idx else False
    pieces=[]
    for idx,f in records.items():
        if not visible(idx) or f["kind"] not in ("Texture","FontString"): continue
        if f.get("layer")=="HIGHLIGHT": continue
        x,y,w,h=pos(idx)
        parent=f.get("parent"); level=0
        while parent is not None and parent.id!=root:
            level=max(level,records[parent.id].get("frameLevel",1)); parent=records[parent.id].get("parent")
        z=level*10+{"BACKGROUND":0,"BORDER":1,"ARTWORK":2,"OVERLAY":3}.get(f.get("layer"),4)
        style=f"left:{x}px;top:{y}px;width:{w}px;height:{h}px;z-index:{z};"
        color=f.get("color")
        rgba=list(color.values()) if color is not None else [1,1,1,1]
        if len(rgba)==3: rgba.append(1)
        css=f"rgba({int(rgba[0]*255)},{int(rgba[1]*255)},{int(rgba[2]*255)},{rgba[3]})"
        if f["kind"]=="FontString":
            value=html.escape(f.get("text",""))
            pieces.append(f'<span style="{style}color:{css};font-size:{f.get("fontSize",12)}px;text-align:{f.get("align","LEFT").lower()}">{value}</span>')
        elif f.get("texture"):
            name=f["texture"].split("\\")[-1].replace(".tga",".png")
            path=ROOT/"docs/assets"/name
            if path.exists():
                image=base64.b64encode(path.read_bytes()).decode()
                uv=list(f["uv"].values()) if f.get("uv") is not None else [0,1,0,1]
                u1,u2,v1,v2=uv
                iw,ih=w/(u2-u1),h/(v2-v1)
                pieces.append(f'<div style="{style}overflow:hidden"><img alt="" src="data:image/png;base64,{image}" style="position:absolute;width:{iw}px;height:{ih}px;left:{-u1*iw}px;top:{-v1*ih}px"></div>')
            elif "GEAR" in name: pieces.append(f'<span style="{style}color:#e9c46e;font-size:27px">⚙</span>')
        elif color is not None: pieces.append(f'<div style="{style}background:{css}"></div>')
    return '<div class="window">'+''.join(pieces)+'</div>'

def main():
    page='<!doctype html><html lang="en"><meta charset="utf-8"><title>Hourstone Lua UI — development preview</title><style>body{background:#171c22;color:#eee;font-family:Segoe UI,sans-serif;padding:24px}h1{font-size:22px}h2{font-size:16px;color:#aaa}.window{position:relative;width:940px;height:620px;margin-bottom:32px}.window>span,.window>div{position:absolute;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;font-family:Georgia,serif}</style><h1>Hourstone — Lua UI development preview</h1><p>Fictional data. Generated from addon frame definitions; approximate fonts. Not an in-game screenshot.</p>'
    for project,locale,settings in [(1,"deDE",False),(2,"enUS",False),(1,"deDE",True)]:
        page+=f'<h2>{"Retail" if project==1 else "Classic"} · {locale}'+(' · Settings' if settings else '')+'</h2>'+render(project,locale,settings)
    page+='</html>'
    dest=ROOT/"dist/lua-ui-preview.html"; dest.parent.mkdir(exist_ok=True); dest.write_text(page,encoding="utf-8")
    print(dest)

if __name__=="__main__": main()
