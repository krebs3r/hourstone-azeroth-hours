"""Render a layout approximation from the real Lua UI frames for visual review.

This is a development preview with fictional data, never an in-game screenshot.
"""
import base64
import html
from pathlib import Path
import sys
import re

ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/"tests"))
from run import runtime

ANCHORS={"TOPLEFT":(0,0),"TOP":(.5,0),"TOPRIGHT":(1,0),"LEFT":(0,.5),"CENTER":(.5,.5),"RIGHT":(1,.5),"BOTTOMLEFT":(0,1),"BOTTOM":(.5,1),"BOTTOMRIGHT":(1,1)}

def render(project,locale,settings=False,mode='combined',population=8,addon_scale=1,minimap=False):
    lua=runtime(project,locale)
    lua.globals().PREVIEW_COUNT=population
    lua.execute('''fire("ADDON_LOADED","Hourstone"); fire("PLAYER_ENTERING_WORLD",true,false)
        local chars={{"ExampleDruid","Example Realm A",90,3042900,"DRUID",2},{"ExampleWarrior","Example Realm B",90,1923600,"WARRIOR",1},
        {"ExamplePriest","Example Realm C",86,976620,"PRIEST",7},{"ExampleHunter","Example Realm C",80,532080,"HUNTER",12},
        {"ExampleHero","Example Realm B",74,261240,"DEMONHUNTER",3},{"ExamplePaladin","Example Realm A",42,78180,"ROGUE",24},
        {"ExampleMage","Example Realm A",16,12900,"PALADIN",5}}
        advance(300)
        IDENTITY.name="ExamplePlayer"; IDENTITY.level=11; IDENTITY.realm="Example Realm D"; IDENTITY.class="DEMONHUNTER"
        IN_GUILD=true; GUILD_NAME="Dawnwatch"; H.T:UpdateIdentity(); H.T:UpdateGuild(false); fire("TIME_PLAYED_MSG",39720,200)
        for i,c in ipairs(chars) do if i<PREVIEW_COUNT then HourstoneDB.characters["test:"..i]={name=c[1],realm=c[2],
            level=WOW_PROJECT_ID==1 and c[3] or math.floor(c[3]*60/90+.5),seconds=c[4],class=c[5],updatedAt=EPOCH-c[6]*86400} end
        end
        local sampleGuilds={"Dawnwatch","",false,"A very long synthetic guild name for layout review","Evening Watch","",false}
        for i,guild in ipairs(sampleGuilds) do
            local char=HourstoneDB.characters["test:"..i]
            if char and guild~=false then char.guild=guild; char.guildUpdatedAt=EPOCH-i*60 end
        end
        for i=9,PREVIEW_COUNT do HourstoneDB.characters["test:"..i]={name="Longcharactername"..i,realm="Realm "..i,level=60,seconds=i*1000,class="MAGE",updatedAt=EPOCH-3000} end
        if PREVIEW_COUNT==0 then HourstoneDB.characters={} end
        configure_display(2560,1440,.8); H.UI:Toggle()''')
    if settings: lua.execute("H.UI:ToggleSettings()")
    frames=list(lua.globals().ALL_FRAMES.values())
    u=lua.globals().H.UI
    u.db.settings.format=mode
    u.db.settings.scale=addon_scale; u.ApplyScale(u); u.SettingsText(u)
    u.LayoutRows(u); u.Refresh(u)
    target=u.minimap if minimap else u.frame
    root=target.id
    records={f.id:dict(f.items()) for f in frames}
    bounds={root:(0,0,target.width,target.height)}
    def pos(idx):
        if idx in bounds: return bounds[idx]
        f=records[idx]
        if f.get("allPoints") is not None:
            result=pos(f["allPoints"].id); bounds[idx]=result; return result
        w,h=f.get("width",0),f.get("height",0)
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
            value=re.sub(r"\|c[0-9a-fA-F]{2}([0-9a-fA-F]{6})(.*?)\|r",r'<i style="color:#\1;font-style:normal">\2</i>',value)
            family="Georgia,serif"
            pieces.append(f'<span style="{style}color:{css};font-family:{family};line-height:{h}px;font-size:{f.get("fontSize",12)}px;text-align:{f.get("align","LEFT").lower()}">{value}</span>')
        elif f.get("texture"):
            name=f["texture"].split("\\")[-1].replace(".tga",".png")
            path=ROOT/"docs/assets"/name
            if path.exists():
                image=base64.b64encode(path.read_bytes()).decode()
                uv=list(f["uv"].values()) if f.get("uv") is not None else [0,1,0,1]
                u1,u2,v1,v2=uv
                iw,ih=w/abs(u2-u1),h/abs(v2-v1)
                transform=f'scale({-1 if u2<u1 else 1},{-1 if v2<v1 else 1})'
                tint="filter:grayscale(1) brightness(.6);" if f.get("desaturated") else ""
                opacity=f.get("alpha",1)
                pieces.append(f'<div style="{style}overflow:hidden;transform:{transform};opacity:{opacity};{tint}"><img alt="" src="data:image/png;base64,{image}" style="position:absolute;width:{iw}px;height:{ih}px;left:{-min(u1,u2)*iw}px;top:{-min(v1,v2)*ih}px"></div>')
            elif "GEAR" in name:
                # Browser-only approximation of the client-owned gear texture.
                gear=base64.b64encode((ROOT/"docs/assets/Gear.png").read_bytes()).decode()
                pieces.append(f'<div style="{style}"><img alt="" src="data:image/png;base64,{gear}" style="width:100%;height:100%"></div>')
            elif name=="UI-CheckBox-Up":
                # The shipped addon uses the real UICheckButtonTemplate. This
                # browser-only drawing is explicitly an approximation of it.
                pieces.append(f'<div style="{style}"><div style="position:absolute;inset:4px;background:#171611;border:1px solid #97866a;box-shadow:inset 1px 1px 2px #000,0 1px 1px #000;box-sizing:border-box"></div></div>')
            elif name=="UI-CheckBox-Check":
                check=base64.b64encode((ROOT/"docs/assets/Check.png").read_bytes()).decode()
                pieces.append(f'<div style="{style}"><img alt="" src="data:image/png;base64,{check}" style="position:absolute;inset:6px;width:12px;height:12px"></div>')
        elif color is not None: pieces.append(f'<div style="{style}background:{css}"></div>')
    # Project native UI coordinates into physical pixels; do not assume effectiveScale=1.
    screen_h=lua.globals().GetPhysicalScreenSize()[1]
    factor=target.GetEffectiveScale(target)*screen_h/768
    width,height=target.width*factor,target.height*factor
    return f'<div class="window" data-physical-width="{width:g}" data-physical-height="{height:g}" style="width:{width}px;height:{height}px"><div class="canvas" style="transform:scale({factor});width:{target.width}px;height:{target.height}px">'+''.join(pieces)+'</div></div>'

def main():
    page='<!doctype html><html lang="de"><meta charset="utf-8"><title>Hourstone · Lua-Vorschau</title><style>body{background:#171c22;color:#eee;font-family:Segoe UI,sans-serif;padding:24px;max-width:900px;margin:auto}h1{font-size:22px}h2{font-size:16px;color:#aaa}p{font-size:13px;color:#aaa;line-height:1.6}.window{position:relative;margin-bottom:32px}.canvas{position:relative;transform-origin:top left}.canvas>span,.canvas>div{position:absolute;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;font-family:Georgia,serif}</style><h1>Hourstone · Lua-Vorschau</h1><p>Layoutvorschau mit synthetischen Charakterdaten. 100 % ist die Standardgröße. Größenvergleich aus dem Lua-Simulator bei 1440p und 80 % globaler UI-Skalierung. Fiktive Daten; Georgia, Zahnrad und Checkbox sind Browser-Näherungen an WoW-eigene Ressourcen. Keine Ingame-Aufnahmen.</p>'
    for project,locale,settings,mode,population,scale in [(2,"deDE",False,"combined",1,1),(2,"deDE",False,"combined",1,1.1),(2,"deDE",False,"combined",1,1.2),(2,"deDE",True,"combined",1,1.1),(1,"deDE",False,"combined",8,1),(2,"enUS",False,"hours",20,1),(1,"enUS",True,"hours",0,1)]:
        page+=f'<h2>{"Retail" if project==1 else "Classic"} · {locale} · {population} Charaktere · {scale*100:g} %'+(' · Einstellungen' if settings else '')+'</h2>'+render(project,locale,settings,mode,population,scale)
    page+='<h2>Minimap · 28 UI-Einheiten · 1440p / 80 % globale UI-Skalierung</h2>'+render(2,'deDE',minimap=True)
    page+='</html>'
    dest=ROOT/"dist/lua-ui-preview.html"; dest.parent.mkdir(exist_ok=True); dest.write_text(page,encoding="utf-8")
    print(dest)

if __name__=="__main__": main()
