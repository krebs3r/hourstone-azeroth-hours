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
from run import FOREVER, runtime

class Layout(unittest.TestCase):
    def test_baseline_geometry_and_states(self):
        reference=json.loads((ROOT/"tests/fixtures/layout/baseline.json").read_text())
        reference.update(json.loads((ROOT/"tests/fixtures/layout/adjustments.json").read_text()))
        for project in (1,2,5,19):
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
                                "search":u.search,"realm":u.realmButton,"client":u.clientButton,"format":u.format,"logo":u.logo,"title":u.title,
                                "statTotal":u.total,"statSession":u.session,"settings":u.settings,
                                "minimapToggle":u.minimapToggle,"reset":u.reset,"done":u.done,
                                "combinedButton":u.combined,"hoursButton":u.hours}
                            delta=(8-max(1,min(8,population)))*reference["rowHeight"]
                            for key,f in sections.items():
                                expected=reference[key].copy()
                                if key in ("window","table","body"): expected[3]-=delta
                                if key=="footer": expected[1]-=delta
                                if project==1:
                                    if key=="window": expected[3]+=reference["retailTabHeight"]
                                    if key in ("toolbar","table","body","footer","search","realm","client","format","combinedButton","hoursButton"): expected[1]+=reference["retailTabHeight"]
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
                            for field,width in zip(("name","flavor","seconds","updatedAt"),reference["columnWidths"]):
                                self.assertEqual(u.headers[field].button.width,width)
                            self.assertEqual(u.headers.seconds.button.label.align,"RIGHT")
                            self.assertEqual(u.headers.flavor.button.label.align,"LEFT")
                            self.assertLessEqual(bounds(u.rows[1].realm)[0]+u.rows[1].realm.width,bounds(u.rows[1].client)[0])
                            self.assertLessEqual(bounds(u.rows[1].client)[0]+u.rows[1].client.width,bounds(u.rows[1].played)[0])
                            self.assertLessEqual(bounds(u.rows[1].played)[0]+u.rows[1].played.width,bounds(u.rows[1].updated)[0])
                            self.assertEqual(u.menu.parent.id,u.realmButton.id)
                            self.assertEqual(u.clientMenu.parent.id,u.clientButton.id)
                            self.assertGreater(bounds(u.menu)[1],bounds(u.realmButton)[1]+u.realmButton.height)
                            self.assertGreater(bounds(u.clientMenu)[1],bounds(u.clientButton)[1]+u.clientButton.height)
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
        for project in (1,2,5,19):
            lua=runtime(project); lua.execute('fire("ADDON_LOADED","Hourstone"); H.UI:Create()')
            u=lua.globals().H.UI; parent=lua.globals().UIParent
            for screen_w,screen_h in ((800,600),(700,900),(1920,1080),(2560,1440),(3840,2160)):
                for parent_scale in (.64,.8,1,1.5):
                    lua.globals().configure_display(screen_w,screen_h,parent_scale)
                    self.assertAlmostEqual(parent.height*parent_scale,768)
                    for addon_scale in (.65,1,1.3,1.5,1.75,2):
                        for view in (("played","progress") if project==1 else ("played",)):
                            u.db.settings.view=view
                            row_height=64 if view=="progress" else 50
                            base=244 if project==1 else 212
                            for count in (0,1,2,8,20):
                                with self.subTest(resolution=(screen_w,screen_h),ui=parent_scale,addon=addon_scale,count=count,view=view,project=project):
                                    lua.globals().POPULATION=count
                                    lua.execute('HourstoneDB.characters={}; for i=1,POPULATION do HourstoneDB.characters["c:"..i]={name="Character"..i,realm="Realm",seconds=i*1000} end')
                                    u.db.settings.scale=addon_scale
                                    lua.execute('fire("UI_SCALE_CHANGED"); fire("DISPLAY_SIZE_CHANGED")')
                                    slots=max(1,min(8,count,math.floor(((screen_h-20)/addon_scale-base)/row_height)))
                                    height=base+slots*row_height
                                    actual_scale=min(addon_scale,(screen_w-20)/720,(screen_h-20)/height)
                                    factor=u.frame.GetEffectiveScale(u.frame)*screen_h/768
                                    self.assertEqual(u.slots,slots)
                                    self.assertAlmostEqual(factor,actual_scale)
                                    self.assertAlmostEqual(u.frame.height*factor,height*actual_scale)
                                    self.assertLessEqual(u.frame.width*factor,screen_w-20+.0001)
                                    self.assertLessEqual(u.frame.height*factor,screen_h-20+.0001)
                                    self.assertEqual(u.db.settings.scale,addon_scale)
                                    self.assertEqual(u.maxOffset,max(0,count-slots))
                                    u.Scroll(u,999)
                                    if count: self.assertIsNotNone(u.rows[min(count,slots)].entry)
                                    if slots<8: self.assertFalse(u.rows[slots+1].shown)
                                    # Deliberately oversized saved offsets must be clamped within screen margins.
                                    u.db.settings.position=lua.table_from({"x":9999,"y":-9999,"height":height})
                                    u.Position(u)
                                    x,y=u.frame.points[1][4],u.frame.points[1][5]
                                    self.assertLessEqual((abs(x)+360)*factor,(screen_w-20)/2+.0001)
                                    self.assertLessEqual((abs(y)+height/2)*factor,(screen_h-20)/2+.0001)
                                    u.SavePosition(u)
                                    self.assertAlmostEqual(u.db.settings.position.x,x)
                                    self.assertAlmostEqual(u.db.settings.position.y,y)
                                    self.assertEqual(u.db.settings.position.height,height)

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
        self.assertEqual(u.frame.height,644); self.assertAlmostEqual(top(),initial_top)
        u.search.SetText(u.search,"Elarion")
        self.assertEqual(u.frame.height,294); self.assertAlmostEqual(top(),initial_top)
        self.assertIn(lua.globals().H.L.filteredTime.split(":")[0],u.footer.text)
        u.search.SetText(u.search,"missing")
        self.assertTrue(u.empty.shown); self.assertEqual(u.frame.height,294)
        u.clearSearch.scripts.OnClick()
        self.assertEqual(u.frame.height,644)
        u.Scroll(u,999); offset=u.offset
        lua.execute('tick(2)'); self.assertEqual(u.offset,offset)
        self.assertEqual(u.db.version,3)
        self.assertFalse(u.db.settings.compact)
        self.assertEqual(dict(u.db.settings.position.items()),{"x":17,"y":43})
        self.assertEqual(u.db.characters["test:20"].seconds,20000)

    def test_progress_mockup_geometry_and_view_reload(self):
        reference=json.loads((ROOT/"tests/fixtures/layout/adjustments.json").read_text())["progress"]
        for locale in ("deDE","enUS"):
            lua=runtime(1,locale)
            lua.execute('''HourstoneDB={settings={view="progress"},characters={}}
                fire("ADDON_LOADED","Hourstone"); fire("PLAYER_ENTERING_WORLD",true,false)
                for i=1,12 do HourstoneDB.characters["f:"..i]={name="Character"..i,realm="Realm",flavor="retail",level=80,seconds=10} end
                H.UI:Toggle()''')
            u=lua.globals().H.UI
            self.assertTrue(u.IsProgress(u))
            self.assertEqual((u.tabs.height,u.tabs.points[1][5]),(32,-114))
            self.assertEqual(u.frame.height,reference["baseHeight"]+8*reference["rowHeight"])
            self.assertFalse(u.format.shown)
            self.assertEqual(u.sort,"name")
            widths=reference["columns"]
            for i,field in enumerate(("name","flavor","seconds","updatedAt")):
                button=u.headers[field].button
                self.assertEqual(button.width,widths[i])
                self.assertEqual(button.points[1][4],sum(widths[:i]))
                self.assertEqual(button.label.align,"LEFT")
            for i in range(1,9):
                row=u.rows[i]
                self.assertEqual(row.height,64)
                self.assertEqual(row.points[1][5],-(i-1)*64)
                self.assertEqual(row.guild.points[1][5],-42)
                self.assertLessEqual(42+row.guild.height,63)
                self.assertLessEqual(row.level.points[1][4]+row.level.width,230)
                self.assertLessEqual(row.realm.points[1][4]+row.realm.width,230)
                self.assertFalse(row.client.shown)
                self.assertTrue(row.progress.shown)
                for index,category in enumerate(("dungeon","raid","world")):
                    group=row.vault[category]
                    self.assertEqual(group.points[1][5],-5-index*18)
                    for slot in range(1,4):
                        box=group.slots[slot]
                        self.assertEqual((box.width,box.height),(16,16))
                        self.assertEqual(box.points[1][4],80+(slot-1)*23)
                        self.assertLess(230+group.points[1][4]+box.points[1][4]+16,u.scroll.points[1][4])
            self.assertTrue(u.scrollUp.shown and u.scrollDown.shown)
            self.assertEqual(u.scroll.width,14)
            u.SetView(u,"played")
            self.assertEqual(u.rowHeight,50)
            self.assertTrue(u.format.shown)
            self.assertFalse(u.scrollUp.shown)
            u.SetView(u,"progress")
            self.assertEqual(u.db.settings.view,"progress")
            self.assertEqual(u.scaleMin.text,"65 %")
            self.assertEqual(u.scaleMax.text,"200 %")

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
                        version,credit_with,heart,author=u.creditVersion,u.creditWith,u.creditHeart,u.creditAuthor
                        self.assertEqual((heart.width,heart.height),(9,9))
                        self.assertTrue(heart.texture.endswith("Heart.tga"))
                        self.assertEqual(credit_with.text,"with")
                        self.assertAlmostEqual(credit_with.points[1][4]-version.points[1][4]-version.width,5)
                        self.assertAlmostEqual(heart.points[1][4]-credit_with.points[1][4]-credit_with.width,5)
                        self.assertAlmostEqual(author.points[1][4]-heart.points[1][4]-heart.width,5)
                        self.assertLess(u.footer.points[1][4]+u.footer.width,version.points[1][4])
                        self.assertEqual(u.settings.height,214)
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
                        self.assertEqual(lua.globals().H.UI.frame.height,294 if project==1 else 262)

    def test_minimap_full_art_clearance(self):
        im=Image.open(ROOT/"Hourstone/Media/Logo.tga").convert("RGBA")
        normalized_radius=max(math.hypot((x+.5)/im.width-.5,(y+.5)/im.height-.5)
            for y in range(im.height) for x in range(im.width) if im.getpixel((x,y))[3]>0)
        for project,interface in ((1,None),(1,FOREVER),(2,None),(5,None),(19,None),(999,None)):
            with self.subTest(project=project,interface=interface):
                lua=runtime(project,interface=interface); lua.execute('fire("ADDON_LOADED","Hourstone")')
                u=lua.globals().H.UI; button=u.minimap; icon=button.icon
                retail=project==1 and interface is None # WoW: Forever keeps the Classic geometry
                radius=normalized_radius*icon.width
                self.assertLess(radius,button.mask.width/2)
                self.assertEqual((button.width,button.height),(31,31))
                self.assertEqual((icon.width,icon.height),(18,18) if retail else (17,17))
                self.assertIsNone(icon.uv) # use the complete Hourstone motif
                self.assertEqual((icon.mask.width,icon.mask.height),(24,24))
                self.assertEqual(icon.mask.points[1][2].id,icon.id)
                self.assertEqual((icon.mask.points[1][1],icon.mask.points[1][3]),("CENTER","CENTER"))
                self.assertEqual((button.border.width,button.border.height),(50,50) if retail else (53,53))
                self.assertEqual(button.border.texture,136430)
                self.assertEqual(button.border.points[1][1],"TOPLEFT")
                self.assertEqual((button.border.points[1][4],button.border.points[1][5]),(0,0))
                self.assertEqual(button.background.texture,136467)
                self.assertEqual((button.background.width,button.background.height),(24,24) if retail else (20,20))
                self.assertEqual(button.highlight.texture,136477)
                self.assertEqual(button.highlight.allPoints.id,button.id)
                if retail:
                    self.assertEqual(icon.points[1][1],"CENTER")
                    self.assertEqual(button.background.points[1][1],"CENTER")
                else:
                    self.assertEqual((icon.points[1][4],icon.points[1][5]),(7,-6))
                    self.assertEqual((button.background.points[1][4],button.background.points[1][5]),(7,-5))
                for frame in lua.globals().ALL_FRAMES.values():
                    if frame.parent is not None and frame.parent.id==button.id and isinstance(frame.texture,str):
                        self.assertFalse(frame.texture.endswith(("MinimapBackground.tga","MinimapBorder.tga","MinimapHover.tga")))
                u.db.settings.minimapAngle=127.5
                u.UpdateMinimap(u)
                x,y=button.points[1][4],button.points[1][5]
                self.assertAlmostEqual(math.hypot(x,y),lua.globals().Minimap.width/2+7)
                for scale in (.65,.8,1,1.3,1.5,2):
                    lua.globals().Minimap.SetScale(lua.globals().Minimap,scale)
                    self.assertAlmostEqual(button.GetEffectiveScale(button),scale)
                    self.assertEqual(u.db.settings.minimapAngle,127.5)
                    self.assertLess(radius*scale,button.mask.width/2*scale)


if __name__=="__main__": unittest.main()
