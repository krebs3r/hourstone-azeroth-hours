"""Verify actual Lua regions against the checked-in layout targets.

Font rasterization and client-owned artwork still require in-game review.
"""
import json
from pathlib import Path
import sys
import unittest
import math
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/"tests"))
from run import runtime

class Layout(unittest.TestCase):
    def test_baseline_geometry_and_states(self):
        reference=json.loads((ROOT/"tests/fixtures/layout/baseline.json").read_text())
        reference.update(json.loads((ROOT/"tests/fixtures/layout/adjustments.json").read_text()))
        for project in (1,2):
            for locale in ("deDE","enUS"):
                for mode in ("combined","hours"):
                    for population in (0,1,8,20,141):
                        with self.subTest(project=project,locale=locale,mode=mode,population=population):
                            lua=runtime(project,locale)
                            lua.execute('fire("ADDON_LOADED","Hourstone"); fire("PLAYER_ENTERING_WORLD",true,false); fire("TIME_PLAYED_MSG",1125000,200); H.UI:Toggle()')
                            u=lua.globals().H.UI
                            lua.globals().POPULATION=population
                            lua.execute('HourstoneDB.characters={}; for i=1,POPULATION do HourstoneDB.characters["test:"..i]={name=string.rep("Long",8)..i,realm="Realm",seconds=i*1000,level=i,class="MAGE"} end')
                            u.db.settings.format=mode; u.Refresh(u)
                            def bounds(f):
                                if f.id==u.frame.id: return [0,0,f.width,f.height]
                                p=f.points[1]
                                self.assertEqual(p[1],"TOPLEFT"); self.assertEqual(p[3],"TOPLEFT")
                                parent=bounds(p[2])
                                return [parent[0]+p[4],parent[1]-p[5],f.width,f.height]
                            sections={"window":u.frame,"header":u.header,"summary":u.summary,"toolbar":u.toolbar,
                                "table":u.table,"body":u.list,"footer":u.footerFrame,"gear":u.gear,"close":u.close,
                                "search":u.search,"realm":u.realmButton,"format":u.format,"logo":u.logo,"title":u.title,
                                "statTotal":u.total,"statSession":u.session,"settings":u.settings,
                                "minimapToggle":u.minimapToggle,"reset":u.reset,"done":u.done,
                                "combinedButton":u.combined,"hoursButton":u.hours}
                            delta=(8-max(1,min(8,population)))*reference["rowHeight"]
                            for key,f in sections.items():
                                expected=reference[key].copy()
                                if key in ("window","table","body"): expected[3]-=delta
                                if key=="footer": expected[1]-=delta
                                for actual,target in zip(bounds(f),expected):
                                    self.assertLessEqual(abs(actual-target),reference["tolerance"],(key,actual,target))
                            for i in range(1,4):
                                for actual,target in zip(bounds(u.statLabels[i]),reference["statLabels"][i-1]):
                                    self.assertLessEqual(abs(actual-target),1)
                            self.assertEqual(len(u.rows),8)
                            self.assertEqual(u.maxOffset,max(0,population-8))
                            for i in range(1,9):
                                row=u.rows[i]
                                self.assertEqual(row.height,reference["rowHeight"])
                                self.assertEqual(row.played.align,"RIGHT")
                                self.assertEqual(row.shown,i<=population)
                                if row.shown:
                                    self.assertGreaterEqual(row.name.width,190)
                                    self.assertEqual(row.guild.points[1][5],-33)
                                    self.assertLessEqual(33+row.guild.height,row.height-1)
                                    self.assertGreaterEqual(row.guild.width,250)
                                    self.assertLessEqual(row.level.points[1][4]+row.level.width,272)
                            for field,width in zip(("name","seconds","updatedAt"),reference["columnWidths"]):
                                self.assertEqual(u.headers[field].button.width,width)
                            self.assertTrue(u.footer.text.startswith(f"{population} / {population}"))
                            self.assertEqual(u.rows[1].name.font,"Fonts\\FRIZQT__.TTF")
                            self.assertEqual(u.rows[1].updated.font,"Fonts\\FRIZQT__.TTF")
                            self.assertEqual(u.combined.label.text,lua.globals().H.L.combined)
                            # Approximate metrics need headroom for native fonts.
                            # This is a layout check, not a native-font measurement.
                            self.assertGreaterEqual(u.combined.label.width,u.combined.label.GetUnboundedStringWidth(u.combined.label)*1.35+8)
                            # Native 9-slice corners stay the same size at every list height.
                            corner=next(f for f in lua.globals().ALL_FRAMES.values() if f.parent is not None and f.parent.id==u.frame.id and f.kind=="Texture")
                            self.assertEqual(corner.width,7 if project==1 else 10)

    def test_physical_scale_position_and_saved_settings(self):
        lua=runtime(); lua.execute('fire("ADDON_LOADED","Hourstone"); H.UI:Create()')
        u=lua.globals().H.UI; parent=lua.globals().UIParent
        for screen_w,screen_h in ((1920,1080),(2560,1440),(3840,2160)):
            for parent_scale in (.64,.8,1,1.5):
                lua.globals().configure_display(screen_w,screen_h,parent_scale)
                self.assertAlmostEqual(parent.height*parent_scale,768)
                for addon_scale in (.65,1,1.1,1.15,1.2,1.3):
                    for count,height in ((0,262),(1,262),(2,312),(8,612),(20,612)):
                        with self.subTest(resolution=(screen_w,screen_h),ui=parent_scale,addon=addon_scale,count=count):
                            u.db.settings.scale=addon_scale; u.LayoutRows(u,count)
                            lua.execute('fire("UI_SCALE_CHANGED"); fire("DISPLAY_SIZE_CHANGED")')
                            factor=u.frame.GetEffectiveScale(u.frame)*screen_h/768
                            self.assertAlmostEqual(u.frame.width*factor,720*addon_scale)
                            self.assertAlmostEqual(u.frame.height*factor,height*addon_scale)
                            u.frame.ClearAllPoints(u.frame)
                            u.frame.SetPoint(u.frame,"CENTER",parent,"CENTER",117,-53)
                            u.SavePosition(u); u.Position(u)
                            self.assertAlmostEqual(u.db.settings.position.x,117)
                            self.assertAlmostEqual(u.db.settings.position.y,-53)
                            self.assertEqual(u.db.settings.position.height,height)
                            self.assertAlmostEqual(u.frame.points[1][4],117)
                            self.assertAlmostEqual(u.frame.points[1][5],-53)
        for w,h in ((800,600),(700,900)):
            lua.globals().configure_display(w,h,.8); u.ApplyScale(u)
            factor=u.frame.GetEffectiveScale(u.frame)*h/768
            self.assertLessEqual(u.frame.height*factor,h-20+.0001)
            self.assertLessEqual(u.frame.width*factor,w-20+.0001)
            self.assertEqual(u.db.settings.scale,1.3)

    def test_filter_height_header_anchor_and_data_retention(self):
        lua=runtime()
        lua.execute('''HourstoneDB={settings={position={x=17,y=43},compact=false},characters={}}
            fire("ADDON_LOADED","Hourstone"); fire("PLAYER_ENTERING_WORLD",true,false)
            fire("TIME_PLAYED_MSG",1125000,0); H.UI:Toggle()''')
        u=lua.globals().H.UI
        top=lambda: u.frame.points[1][5]+u.frame.height/2
        initial_top=top()
        lua.execute('''local original=HourstoneDB.characters
            for i=1,20 do original["test:"..i]={name="Other"..i,realm="Other Realm",seconds=i*1000,level=i} end
            H.UI:Refresh(); assert(original==HourstoneDB.characters)''')
        self.assertEqual(u.frame.height,612); self.assertAlmostEqual(top(),initial_top)
        u.search.SetText(u.search,"Elarion")
        self.assertEqual(u.frame.height,262); self.assertAlmostEqual(top(),initial_top)
        self.assertIn(lua.globals().H.L.filteredTime.split(":")[0],u.footer.text)
        u.search.SetText(u.search,"missing")
        self.assertTrue(u.empty.shown); self.assertEqual(u.frame.height,262)
        u.clearSearch.scripts.OnClick()
        self.assertEqual(u.frame.height,612)
        u.Scroll(u,999); offset=u.offset
        lua.execute('tick(2)'); self.assertEqual(u.offset,offset)
        self.assertEqual(u.db.version,2)
        self.assertFalse(u.db.settings.compact)
        self.assertEqual(dict(u.db.settings.position.items()),{"x":17,"y":43})
        self.assertEqual(u.db.characters["test:20"].seconds,20000)

    def test_fixed_text_heart_and_reload_with_missing_font_metrics(self):
        def saved_table(value):
            return {k:saved_table(v) for k,v in value.items()} if hasattr(value,"items") else value
        for project in (1,2,5,19):
            for locale in ("deDE","enUS"):
                lua=runtime(project,locale)
                lua.execute('ZERO_HIDDEN_FONT_METRICS=true; ZERO_FONT_METRICS=true; fire("ADDON_LOADED","Hourstone"); fire("PLAYER_ENTERING_WORLD",true,false); fire("TIME_PLAYED_MSG",10000,200); H.UI:Toggle()')
                for opening in ("first","reopen","reload"):
                    with self.subTest(project=project,locale=locale,opening=opening):
                        u=lua.globals().H.UI
                        self.assertEqual(u.title.text,"Hourstone – Azeroth Hours")
                        self.assertEqual(u.title.width,588)
                        self.assertEqual(u.title.font,"Fonts\\FRIZQT__.TTF")
                        for i,key in enumerate(("total","characters","session"),1):
                            self.assertEqual(u.statLabels[i].text,lua.globals().H.L[key])
                            self.assertGreater(u.statLabels[i].width,120)
                        self.assertGreaterEqual(u.rows[1].name.width,190)
                        version,heart,author=u.creditVersion,u.creditHeart,u.creditAuthor
                        self.assertEqual((heart.width,heart.height),(9,9))
                        self.assertTrue(heart.texture.endswith("Heart.tga"))
                        self.assertAlmostEqual(heart.points[1][4]-version.points[1][4]-version.width,5)
                        self.assertAlmostEqual(author.points[1][4]-heart.points[1][4]-heart.width,5)
                        self.assertEqual(u.settings.height,190)
                        self.assertIsNone(u.densityToggle)
                        lua.globals().ZERO_FONT_METRICS=False
                        self.assertLess(u.title.GetUnboundedStringWidth(u.title),u.title.width)
                        u.Refresh(u)
                        self.assertEqual(u.title.width,588)
                        lua.globals().ZERO_FONT_METRICS=True
                    if opening=="first":
                        lua.execute('H.UI:Toggle(); H.UI:Toggle()')
                    elif opening=="reopen":
                        lua.execute('HourstoneDB.settings.compact=false; HourstoneDB.settings.scale=.9; HourstoneDB.settings.format="hours"; HourstoneDB.settings.position={x=117,y=-53}; advance(42); fire("PLAYER_LOGOUT")')
                        saved=saved_table(lua.globals().HourstoneDB)
                        lua=runtime(project,locale); lua.globals().HourstoneDB=lua.table_from(saved,recursive=True)
                        lua.execute('ZERO_HIDDEN_FONT_METRICS=true; ZERO_FONT_METRICS=true; advance(42); fire("ADDON_LOADED","Hourstone"); fire("PLAYER_ENTERING_WORLD",false,true); H.UI:Toggle()')
                        restored=saved_table(lua.globals().HourstoneDB)
                        for key in ("characters","settings","version"):
                            self.assertEqual(restored[key],saved[key])
                        self.assertEqual(lua.globals().H.T.Session(lua.globals().H.T),42)
                        self.assertEqual(lua.globals().H.UI.frame.height,262)

    def test_minimap_full_art_clearance(self):
        lua=runtime(); lua.execute('fire("ADDON_LOADED","Hourstone")')
        button=lua.globals().H.UI.minimap; icon=button.icon
        im=Image.open(ROOT/"Hourstone/Media/Logo.tga").convert("RGBA")
        radius=max(math.hypot((x+.5)/im.width-.5,(y+.5)/im.height-.5)
            for y in range(im.height) for x in range(im.width) if im.getpixel((x,y))[3]>0)*icon.width
        inner_radius=28/64*28 # inner edge of the shipped 64px border texture
        self.assertLessEqual(radius,inner_radius-2)
        self.assertEqual(button.width,28)
        self.assertEqual(icon.width,18)
        self.assertEqual(icon.width,icon.height)
        self.assertEqual(icon.mask.width,24)
        self.assertEqual(icon.points[1][4]+icon.width/2,14)
        self.assertEqual(-icon.points[1][5]+icon.height/2,14)
        self.assertEqual(button.highlight.allPoints.id,button.id)
        self.assertTrue(button.highlight.texture.endswith("MinimapHover.tga"))
        for frame in lua.globals().ALL_FRAMES.values():
            if frame.parent is not None and frame.parent.id==button.id and frame.texture is not None:
                if frame.texture.endswith(("MinimapBackground.tga","MinimapBorder.tga")):
                    self.assertEqual((frame.width,frame.height),(28,28))
        for scale in (.65,.8,1,1.3,1.5,2):
            lua.globals().Minimap.SetScale(lua.globals().Minimap,scale)
            self.assertAlmostEqual(button.GetEffectiveScale(button),scale)
            self.assertLess(radius*scale,inner_radius*scale)


if __name__=="__main__": unittest.main()
