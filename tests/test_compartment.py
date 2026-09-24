"""One-time Addons menu migration across reloads, with and without the menu."""
from pathlib import Path
import re
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tests"))
from run import FOREVER, runtime


def saved_table(value):
    return {k: saved_table(v) for k, v in value.items()} if hasattr(value, "items") else value


def load(project, interface, saved, compartment=None):
    lua = runtime(project, "enUS", interface=interface, compartment=compartment)
    if saved is not None:
        lua.globals().HourstoneDB = lua.table_from(saved, recursive=True)
    lua.execute('fire("ADDON_LOADED","Hourstone"); fire("PLAYER_ENTERING_WORLD",false,true)')
    return lua, lua.globals().H.UI, lua.globals().HourstoneDB.settings


class CompartmentMigration(unittest.TestCase):
    CLIENTS = (("Retail", 1, None), ("WoW Forever", 1, FOREVER), ("Mists Classic", 19, None),
               ("TBC Anniversary", 5, None), ("Classic Era", 2, None))

    def test_menu_hides_minimap_once_and_keeps_later_opt_in(self):
        for name, project, interface in self.CLIENTS:
            has_menu = project == 1
            with self.subTest(client=name):
                saved = {"version": 3, "visibility": {}, "settings": {"minimap": True, "minimapAngle": 90}}
                lua, ui, settings = load(project, interface, saved)
                self.assertEqual(ui.compartment is True, has_menu)
                self.assertEqual(len(lua.globals().COMPARTMENT), 1 if has_menu else 0)
                self.assertIs(settings.minimap, not has_menu)
                self.assertEqual(settings.compartmentMigrated, True if has_menu else None)
                self.assertIs(ui.minimap.IsShown(ui.minimap), not has_menu)
                self.assertEqual(settings.minimapAngle, 90)
                if has_menu:
                    lua.globals().SlashCmdList.HOURSTONE("minimap")
                    self.assertIs(settings.minimap, True)
                saved = saved_table(lua.globals().HourstoneDB)
                for _ in range(2):  # repeated reloads keep the user's choice
                    lua, ui, settings = load(project, interface, saved)
                    self.assertIs(settings.minimap, True)
                    self.assertIs(ui.minimap.IsShown(ui.minimap), True)
                    self.assertEqual(settings.minimapAngle, 90)
                    self.assertEqual(len(lua.globals().COMPARTMENT), 1 if has_menu else 0)
                    saved = saved_table(lua.globals().HourstoneDB)

    def test_hidden_minimap_and_first_install_stay_consistent(self):
        for name, project, interface in self.CLIENTS[:2]:
            with self.subTest(client=name, state="hidden before update"):
                lua, ui, settings = load(project, interface, {"settings": {"minimap": False}})
                self.assertIs(settings.minimap, False)
                self.assertIs(settings.compartmentMigrated, True)
            with self.subTest(client=name, state="first install"):
                lua, ui, settings = load(project, interface, None)
                self.assertIs(settings.minimap, False)
                self.assertIs(ui.minimap.IsShown(ui.minimap), False)
                self.assertIs(settings.compartmentMigrated, True)

    def test_client_without_menu_migrates_when_menu_appears(self):
        lua, ui, settings = load(1, None, {"settings": {"minimap": True}}, compartment=False)
        self.assertIs(settings.minimap, True)
        self.assertIsNone(settings.compartmentMigrated)
        lua, ui, settings = load(1, None, saved_table(lua.globals().HourstoneDB))
        self.assertIs(settings.minimap, False)
        self.assertIs(settings.compartmentMigrated, True)

    def test_menu_icon_matches_toc(self):
        toc = (ROOT / "Hourstone/Hourstone.toc").read_text(encoding="utf-8")
        icon = re.search(r"^## IconTexture: (.+)$", toc, re.M)[1].strip()
        lua, ui, settings = load(1, None, None)
        self.assertEqual(lua.globals().COMPARTMENT[1].icon, icon)

    def test_forever_interface_is_declared(self):
        toc = (ROOT / "Hourstone/Hourstone.toc").read_text(encoding="utf-8")
        interfaces = {int(i) for i in re.search(r"^## Interface: (.+)$", toc, re.M)[1].split(",")}
        self.assertIn(FOREVER, interfaces)
        self.assertNotRegex(toc, r"(?im)^## AddonCompartment")


if __name__ == "__main__":
    unittest.main()
