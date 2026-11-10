"""Render a layout approximation from the real Lua UI frames for visual review.

This is a development preview with fictional data, never an in-game screenshot.
"""
import base64
import argparse
import html
from pathlib import Path
import sys
import re
import subprocess

ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/"tests"))
from run import runtime

ANCHORS={"TOPLEFT":(0,0),"TOP":(.5,0),"TOPRIGHT":(1,0),"LEFT":(0,.5),"CENTER":(.5,.5),"RIGHT":(1,.5),"BOTTOMLEFT":(0,1),"BOTTOM":(.5,1),"BOTTOMRIGHT":(1,1)}

def render(project,locale,settings=False,mode='combined',population=8,addon_scale=1,minimap=False,
           view='played',screen=(2560,1440),setup=None,tooltip=None,interface=None,after=None,read=None,raw=False):
    # read supplies the addon's files (for example a release's); raw returns every visible
    # region as a tuple instead of HTML, for tests that compare two builds region by region.
    lua=runtime(project,locale,interface=interface,read=read)
    lua.globals().PREVIEW_COUNT=population
    lua.execute('''fire("ADDON_LOADED","Hourstone"); fire("PLAYER_ENTERING_WORLD",true,false)
        local chars={{"ExampleDruid","Example Realm A",90,3042900,"DRUID",2},{"ExampleWarrior","Example Realm B",90,1923600,"WARRIOR",1},
        {"ExamplePriest","Example Realm C",86,976620,"PRIEST",7},{"ExampleHunter","Example Realm C",80,532080,"HUNTER",12},
        {"ExampleHero","Example Realm B",74,261240,"DEMONHUNTER",3},{"ExamplePaladin","Example Realm A",42,78180,"ROGUE",24},
        {"ExampleMage","Example Realm A",16,12900,"PALADIN",5}}
        advance(300)
        IDENTITY.name="ExamplePlayer"; IDENTITY.level=11; IDENTITY.realm="Example Realm D"; IDENTITY.class="DEMONHUNTER"
        IN_GUILD=true; GUILD_NAME="Dawnwatch"; H.T:UpdateIdentity(); H.T:UpdateGuild(false); fire("TIME_PLAYED_MSG",39720,200)
        local clients={"retail","mists","tbc","era"}
        for i,c in ipairs(chars) do if i<PREVIEW_COUNT then HourstoneDB.characters["test:"..i]={name=c[1],realm=c[2],
            level=WOW_PROJECT_ID==1 and c[3] or math.floor(c[3]*60/90+.5),seconds=c[4],class=c[5],
            flavor=clients[(i-1)%4+1],updatedAt=EPOCH-c[6]*86400} end
        end
        local sampleGuilds={"Dawnwatch","",false,"A very long synthetic guild name for layout review","Evening Watch","",false}
        for i,guild in ipairs(sampleGuilds) do
            local char=HourstoneDB.characters["test:"..i]
            if char and guild~=false then char.guild=guild; char.guildUpdatedAt=EPOCH-i*60 end
        end
        for i=9,PREVIEW_COUNT do HourstoneDB.characters["test:"..i]={name="Longcharactername"..i,realm="Realm "..i,level=60,seconds=i*1000,class="MAGE",flavor=clients[(i-1)%4+1],updatedAt=EPOCH-3000} end
        if PREVIEW_COUNT==0 then HourstoneDB.characters={} end
        configure_display(2560,1440,.8); H.UI:Toggle()''')
    u=lua.globals().H.UI
    if setup:
        lua.execute(setup)
    lua.globals().configure_display(screen[0],screen[1],.8)
    if hasattr(u,'SetView') and u.SetView is not None:
        u.SetView(u,view)
    u.db.settings.format=mode
    u.db.settings.scale=addon_scale; u.ApplyScale(u); u.SettingsText(u)
    u.LayoutRows(u); u.Refresh(u)
    if settings: u.ToggleSettings(u)
    if tooltip: u.ProgressTooltip(u,u.rows[1],tooltip)
    if after: lua.execute(after)
    frames=list(lua.globals().ALL_FRAMES.values())
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
        if f.get("layer")=="HIGHLIGHT" and not raw: continue
        x,y,w,h=pos(idx)
        parent=f.get("parent"); level=0
        while parent is not None and parent.id!=root:
            level=max(level,records[parent.id].get("frameLevel",1)); parent=records[parent.id].get("parent")
        z=level*10+{"BACKGROUND":0,"BORDER":1,"ARTWORK":2,"OVERLAY":3}.get(f.get("layer"),4)
        style=f"left:{x}px;top:{y}px;width:{w}px;height:{h}px;z-index:{z};"
        opacity=f.get("alpha",1)
        ancestor=f.get("parent")
        while ancestor is not None:
            opacity*=records[ancestor.id].get("alpha",1)
            ancestor=records[ancestor.id].get("parent")
        style+=f"opacity:{opacity};"
        color=f.get("color")
        rgba=list(color.values()) if color is not None else [1,1,1,1]
        if len(rgba)==3: rgba.append(1)
        css=f"rgba({int(rgba[0]*255)},{int(rgba[1]*255)},{int(rgba[2]*255)},{rgba[3]})"
        if raw:
            uv=tuple(round(v,6) for v in f["uv"].values()) if f.get("uv") is not None else None
            texture=f.get("texture"); texture=None if texture is None else str(texture)
            pieces.append((f["kind"],f.get("layer"),round(x,3),round(y,3),round(w,3),round(h,3),z,round(opacity,6),
                tuple(round(c,6) for c in rgba),texture,f.get("atlas"),uv,bool(f.get("desaturated")),
                f.get("text") if f["kind"]=="FontString" else None,f.get("fontSize"),f.get("align")))
            continue
        if f["kind"]=="FontString":
            value=html.escape(f.get("text",""))
            value=re.sub(r"\|c[0-9a-fA-F]{2}([0-9a-fA-F]{6})(.*?)\|r",r'<i style="color:#\1;font-style:normal">\2</i>',value)
            family="Georgia,serif"
            line_height=f.get("fontSize",12)*1.2 if f.get("wordWrap") else h
            whitespace='pre-wrap' if f.get("wordWrap") else 'pre'
            pieces.append(f'<span style="{style}white-space:{whitespace};color:{css};font-family:{family};line-height:{line_height}px;font-size:{f.get("fontSize",12)}px;text-align:{f.get("align","LEFT").lower()}">{value}</span>')
        elif f.get("texture"):
            native={136430:"MiniMap-TrackingBorder",136467:"UI-Minimap-Background",136477:"UI-Minimap-ZoomButton-Highlight"}
            name=native.get(f["texture"],str(f["texture"]).split("\\")[-1].replace(".tga",".png"))
            path=ROOT/"docs/assets"/name
            if path.exists():
                image=base64.b64encode(path.read_bytes()).decode()
                uv=list(f["uv"].values()) if f.get("uv") is not None else [0,1,0,1]
                u1,u2,v1,v2=uv
                iw,ih=w/abs(u2-u1),h/abs(v2-v1)
                transform=f'scale({-1 if u2<u1 else 1},{-1 if v2<v1 else 1})'
                tint="filter:grayscale(1) brightness(.6);" if f.get("desaturated") else ""
                pieces.append(f'<div style="{style}overflow:hidden;transform:{transform};{tint}"><img alt="" src="data:image/png;base64,{image}" style="position:absolute;width:{iw}px;height:{ih}px;left:{-min(u1,u2)*iw}px;top:{-min(v1,v2)*ih}px"></div>')
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
            elif name=="UI-Minimap-Background":
                pieces.append(f'<div style="{style}border-radius:50%;background:#10161a"></div>')
            elif name=="WHITE8X8":
                pieces.append(f'<div style="{style}background:{css}"></div>')
            elif name=="MiniMap-TrackingBorder":
                # Approximate only the visible rim. The native texture has
                # transparent padding; compare its actual shape inside WoW.
                pieces.append(f'<div style="{style}"><div style="width:31px;height:31px;box-sizing:border-box;border-radius:50%;border:3px solid #9b8b70;box-shadow:inset 0 0 1px #ede2c2,0 0 1px #000"></div></div>')
        elif color is not None: pieces.append(f'<div style="{style}background:{css}"></div>')
    if raw: return pieces
    # Project native UI coordinates into physical pixels; do not assume effectiveScale=1.
    screen_h=lua.globals().GetPhysicalScreenSize()[1]
    factor=target.GetEffectiveScale(target)*screen_h/768
    width,height=target.width*factor,target.height*factor
    return f'<div class="window" data-physical-width="{width:g}" data-physical-height="{height:g}" style="width:{width}px;height:{height}px"><div class="canvas" style="transform:scale({factor});width:{target.width}px;height:{target.height}px">'+''.join(pieces)+'</div></div>'

def product_pages():
    """Write clean documentation views from the shipping Lua UI and sample data.

    Keep provenance in the surrounding documentation caption: these browser
    renders approximate client-owned fonts/artwork and are not in-game captures.
    Product images contain only the addon, without development banners.
    """
    version=re.search(r'^## Version: (.+)$',(ROOT/'Hourstone/Hourstone.toc').read_text(),re.M)[1]
    setup=(ROOT/'tests/fixtures/progress/preview.lua').read_text(encoding='utf-8')
    css='body{margin:0;background:#10171d;color:#eee}.product{width:max-content;padding:40px;background:radial-gradient(ellipse at 50% 0%,#25323b 0%,#111a21 65%,#10171d 100%)}.window,.canvas{position:relative}.window{box-shadow:0 16px 36px #0006}.canvas{transform-origin:top left}.canvas>span,.canvas>div{position:absolute;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;font-family:Georgia,serif}'
    destination=ROOT/"dist"; destination.mkdir(exist_ok=True)
    for locale,language in (("deDE","de"),("enUS","en")):
        variants=[('overview',dict(view='played',screen=(1920,1080))),
                  ('progress',dict(view='progress',screen=(1280,650)))]
        if language=='de':
            variants.append(('settings',dict(view='progress',settings=True,addon_scale=2,screen=(1920,1080))))
        for name,options in variants:
            content=render(1,locale,setup=setup,**options)
            page=f'<!doctype html><html lang="{language}"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Hourstone {version} · {name} · {language.upper()}</title><style>{css}</style><main class="product">{content}</main></html>'
            suffix='' if name=='overview' else f'{name}-'
            path=destination/f'addon-product-{suffix}{language}.html'
            path.write_text(page,encoding='utf-8'); print(path)


def progress_pages():
    """Render shipping Lua frames with synthetic progress for design acceptance."""
    version=re.search(r'^## Version: (.+)$',(ROOT/'Hourstone/Hourstone.toc').read_text(),re.M)[1]
    setup=(ROOT/'tests/fixtures/progress/preview.lua').read_text(encoding='utf-8')
    css='body{margin:24px;background:#171c22;color:#eee;font-family:Segoe UI,sans-serif}h1{font-size:18px;font-weight:500}p{font-size:12px;color:#aaa}.window,.canvas{position:relative}.canvas{transform-origin:top left}.canvas>span,.canvas>div{position:absolute;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;font-family:Georgia,serif}'
    destination=ROOT/'dist/design'; destination.mkdir(exist_ok=True,parents=True)
    for language,locale in (('de','deDE'),('en','enUS')):
        for name,options in (
            ('progress',dict(view='progress',screen=(1280,650))),
            ('tooltip',dict(view='progress',screen=(1920,1080),tooltip='dungeon')),
            ('settings',dict(view='progress',settings=True,addon_scale=2,screen=(1920,1080))),
            ('played',dict(view='played',screen=(1920,1080))),
        ):
            content=render(1,locale,setup=setup,**options)
            label=f'Hourstone {version} · {name} · {language.upper()}'
            page=f'<!doctype html><html lang="{language}"><meta charset="utf-8"><title>{label}</title><style>{css}</style><h1>{label}</h1>{content}<p>Synthetic data · Actual Lua frame layout · Browser approximation, not an in-game capture.</p></html>'
            path=destination/f'{name}-{language}.html'; path.write_text(page,encoding='utf-8'); print(path)


FOREVER_SAMPLE='''
-- Forever has no demon hunters. Besides the current character, which Forever
-- marks itself, two more rows carry the WoW: Forever label.
RAID_CLASS_COLORS.WARLOCK={r=.53,g=.53,b=.93}
for key,char in pairs(HourstoneDB.characters) do
    if char.class=="DEMONHUNTER" then char.class="WARLOCK" end
    if key=="test:1" or key=="test:5" then char.client="forever" end
end
'''
# The browser cannot draw the client's atlases, so the sheet shows WoW: Forever's fallback: the
# look applied again as if the client had none of Forever's art.
FOREVER_FALLBACK='ATLAS_MISSING=setmetatable({},{__index=function() return true end}); H.UI:ApplyTheme()'

def release(tag):
    """The addon's files as a tagged release has them, for render(read=...)."""
    def read(relative):
        return subprocess.run(["git","-C",str(ROOT),"show",f"{tag}:{relative}"],check=True,capture_output=True).stdout.decode("utf-8")
    return read

def forever_pages(before="v0.3.7"):
    """Lay WoW: Forever as a release drew it, WoW: Forever now and Retail now side by side.

    The first column runs the release's own files, the others the working tree, each with
    the look of its client; the browser cannot draw Forever's atlases, so the Forever column
    shows the flat fallback, not the window frame. Writes two HTML pages to dist/design: the full windows, and
    the top of each state. Lossless browser captures of them, the full sheet at a device
    pixel ratio of 1 and the detail sheet at 2 (Chromium: --headless --screenshot
    --disable-lcd-text --force-device-scale-factor=N), stay local and are not part of the
    repository (docs/FOREVER-THEME.md, decision 7).
    """
    previous=release(before)
    states=(("Overview: eight synthetic characters, combined format",{},330),
            ("Settings and the client filter, drawn together for the sheet (the addon shows one at a time)",{"settings":True,"after":"H.UI.clientMenu:Show()"},330),
            ("Delete confirmation",{"after":"H.UI:ConfirmRemoval(HourstoneDB.characters['test:2'])"},250))
    columns=((f"WoW: Forever, {before[1:]}","Soundstone's Classic sprites"),
             ("WoW: Forever, this version","the flat fallback, where Forever's art is missing"),
             ("Retail, this version","the standard look"))
    css=('body{margin:0;background:#2b3036;color:#e8e4da;font-family:Segoe UI,sans-serif}'
         '.sheet{display:grid;grid-template-columns:repeat(3,max-content);gap:18px 24px;padding:24px;width:max-content}'
         '.head{font-size:14px;font-weight:600;color:#f2efe8}.head small{display:block;font-weight:400;color:#b9b4aa;font-size:12px}'
         '.row,.foot{grid-column:1/-1;width:0;min-width:100%;font-size:12px;line-height:1.5;color:#b9b4aa}.row{margin-top:6px}'
         '.window,.canvas{position:relative}.canvas{transform-origin:top left}'
         '.canvas>span,.canvas>div{position:absolute;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;font-family:Georgia,serif}')
    note=(f'Synthetic characters. Rendered from the Lua frames by tools/preview.py, the first column from the {before} files. '
          'Browser approximation, not an in-game capture: Georgia stands in for the client font, no code tint reaches a '
          'picture (the sort and dropdown arrows are white and the gear is one fixed picture in every column), the checkbox '
          'is a stand-in and the dimmed toggle a gray filter. The browser cannot draw the client\'s atlases, so the middle '
          'column shows the flat look Forever falls back to, not Forever\'s window frame. At 100 % Hourstone size one UI unit '
          'is one physical pixel')
    rows=[]
    for label,options,cut in states:
        cells=[render(18,'enUS',setup=FOREVER_SAMPLE,interface=16001,read=previous,**options),
               render(18,'enUS',setup=FOREVER_SAMPLE+FOREVER_FALLBACK,interface=16001,**options),
               render(1,'enUS',**options)]
        rows.append((label,cells,cut))
    destination=ROOT/'dist/design'; destination.mkdir(exist_ok=True,parents=True)
    for name,detail in (('forever-theme-preview',False),('forever-theme-preview-detail',True)):
        body=''.join(f'<div class="head">{title}<small>{sub}</small></div>' for title,sub in columns)
        for label,cells,cut in rows:
            body+=f'<div class="row">{label}'+(f' (top {cut} units)' if detail else '')+'</div>'
            body+=''.join(f'<div style="height:{cut}px;overflow:hidden">{cell}</div>' if detail else f'<div>{cell}</div>' for cell in cells)
        page=(f'<!doctype html><html lang="en"><meta charset="utf-8"><title>Hourstone · WoW: Forever theme preview</title>'
              f'<style>{css}</style><div class="sheet">{body}<div class="foot">{note}'
              +('; this sheet is meant to be captured at twice the size, one unit to two image pixels.' if detail else '.')
              +'</div></div></html>')
        path=destination/f'{name}.html'; path.write_text(page,encoding='utf-8'); print(path)


def main():
    page='<!doctype html><html lang="de"><meta charset="utf-8"><title>Hourstone · Lua-Vorschau</title><style>body{background:#171c22;color:#eee;font-family:Segoe UI,sans-serif;padding:24px;max-width:900px;margin:auto}h1{font-size:22px}h2{font-size:16px;color:#aaa}p{font-size:13px;color:#aaa;line-height:1.6}.window{position:relative;margin-bottom:32px}.canvas{position:relative;transform-origin:top left}.canvas>span,.canvas>div{position:absolute;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;font-family:Georgia,serif}</style><h1>Hourstone · Lua-Vorschau</h1><p>Layoutvorschau mit synthetischen Charakterdaten aller vier Clientfamilien. 100 % ist die Standardgröße. Größenvergleich aus dem Lua-Simulator bei 1440p und 80 % globaler UI-Skalierung. Fiktive Daten; Georgia, Zahnrad, Checkbox und Minimaprahmen sind Browser-Näherungen an WoW-eigene Ressourcen. Keine Ingame-Aufnahmen.</p>'
    families={1:"Retail",19:"Mists Classic",5:"TBC Anniversary",2:"Classic Era"}
    profiles=[(2,"deDE",False,"combined",1,1),(2,"deDE",False,"combined",1,1.1),(2,"deDE",False,"combined",1,1.2),(2,"deDE",True,"combined",1,1.1),
        (1,"deDE",False,"combined",8,1),(19,"enUS",False,"hours",8,1),(5,"deDE",False,"combined",8,1),(2,"enUS",False,"hours",20,1),(1,"enUS",True,"hours",0,1)]
    for project,locale,settings,mode,population,scale in profiles:
        page+=f'<h2>{families[project]} · {locale} · {population} Charaktere · {scale*100:g} %'+(' · Einstellungen' if settings else '')+'</h2>'+render(project,locale,settings,mode,population,scale)
    for project in families:
        page+=f'<h2>Minimap · {families[project]} · 31 UI-Einheiten · Textur-Näherung</h2>'+render(project,'deDE',minimap=True)
    page+='</html>'
    dest=ROOT/"dist/lua-ui-preview.html"; dest.parent.mkdir(exist_ok=True); dest.write_text(page,encoding="utf-8")
    print(dest)

if __name__=="__main__":
    parser=argparse.ArgumentParser()
    parser.add_argument("--product-pages",action="store_true",help="Also write clean documentation views of the implemented UI with sample data")
    parser.add_argument("--progress-pages",action="store_true",help="Also render the real progress UI, tooltip and scaling states")
    parser.add_argument("--forever-theme",action="store_true",help="Also render Forever as 0.3.7 drew it, Forever's fallback now and Retail now side by side")
    args=parser.parse_args(); main()
    if args.product_pages: product_pages()
    if args.forever_theme: forever_pages()
    if args.progress_pages: progress_pages()
