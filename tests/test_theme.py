"""The standard look draws exactly what 0.3.7 drew, and the Forever palette keeps its rule.

Every visible region (position, size, layer, color and alpha, texture, texture
coordinates, desaturation, text, font size) is compared with the tagged release on the
four client families, each in its own look, and on WoW: Forever with the standard look
applied after Forever's frame was built, in the states listed below, and in Retail's
progress view and its tooltip. No difference is allowed, apart from the version the footer
names: each build shows its own.
"""
import math
import re
import subprocess
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
import preview  # noqa: E402

RELEASE = "v0.3.7"
VERSION = re.search(r"^## Version: (\d+\.\d+\.\d+)$", (ROOT / "Hourstone/Hourstone.toc").read_text(encoding="utf-8"), re.M)[1]
FOREVER = 16001
PROGRESS = (ROOT / "tests/fixtures/progress/preview.lua").read_text(encoding="utf-8")
STATES = (
    ("overview", {}),
    ("settings", {"settings": True}),
    ("client menu", {"after": "H.UI.clientMenu:Show()"}),
    ("realm menu", {"after": "H.UI:ToggleRealms()"}),
    ("sort menu", {"after": "H.UI.sortMenu:Show()"}),
    ("delete dialog", {"after": "H.UI:ConfirmRemoval(HourstoneDB.characters['test:2'])"}),
    ("sorted by level, sort menu", {"after": "H.UI:SetSort('level'); H.UI.sortMenu:Show()"}),
    ("search text", {"after": "H.UI.search:SetText('Example')"}),
    # 0.3.7's toggles have no hover script; under the standard look the new one changes nothing visible.
    ("hovered gear and control", {"after": "H.UI.gear.scripts.OnEnter(H.UI.gear); local enter=H.UI.hours.scripts.OnEnter; if enter then enter(H.UI.hours) end"}),
)
WARRIOR = (198, 155, 109)


def lab(rgb):
    def linear(c):
        c = c / 255
        return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
    r, g, b = (linear(c) for c in rgb)
    x, y, z = (r * 0.4124564 + g * 0.3575761 + b * 0.1804375) / 0.95047, r * 0.2126729 + g * 0.7151522 + b * 0.0721750,         (r * 0.0193339 + g * 0.1191920 + b * 0.9503041) / 1.08883
    f = lambda t: t ** (1 / 3) if t > 216 / 24389 else (24389 / 27 * t + 16) / 116
    return 116 * f(y) - 16, 500 * (f(x) - f(y)), 200 * (f(y) - f(z))


def ciede2000(c1, c2):
    """CIEDE2000 distance of two sRGB colors (D65)."""
    (l1, a1, b1), (l2, a2, b2) = lab(c1), lab(c2)
    cb = (math.hypot(a1, b1) + math.hypot(a2, b2)) / 2
    g = 0.5 * (1 - math.sqrt(cb ** 7 / (cb ** 7 + 25 ** 7)))
    a1, a2 = (1 + g) * a1, (1 + g) * a2
    c1p, c2p = math.hypot(a1, b1), math.hypot(a2, b2)
    h1, h2 = math.degrees(math.atan2(b1, a1)) % 360, math.degrees(math.atan2(b2, a2)) % 360
    dh = 0 if c1p * c2p == 0 else (h2 - h1 if abs(h2 - h1) <= 180 else h2 - h1 - 360 if h2 > h1 else h2 - h1 + 360)
    dl, dc, dhh = l2 - l1, c2p - c1p, 2 * math.sqrt(c1p * c2p) * math.sin(math.radians(dh / 2))
    lb, cbp = (l1 + l2) / 2, (c1p + c2p) / 2
    hb = h1 + h2 if c1p * c2p == 0 else ((h1 + h2) / 2 if abs(h1 - h2) <= 180 else (h1 + h2 + 360) / 2 if h1 + h2 < 360 else (h1 + h2 - 360) / 2)
    t = 1 - 0.17 * math.cos(math.radians(hb - 30)) + 0.24 * math.cos(math.radians(2 * hb)) + 0.32 * math.cos(math.radians(3 * hb + 6)) - 0.20 * math.cos(math.radians(4 * hb - 63))
    rt = -math.sin(math.radians(60 * math.exp(-((hb - 275) / 25) ** 2))) * 2 * math.sqrt(cbp ** 7 / (cbp ** 7 + 25 ** 7))
    sl, sc, sh = 1 + 0.015 * (lb - 50) ** 2 / math.sqrt(20 + (lb - 50) ** 2), 1 + 0.045 * cbp, 1 + 0.015 * cbp * t
    return math.sqrt((dl / sl) ** 2 + (dc / sc) ** 2 + (dhh / sh) ** 2 + rt * (dc / sc) * (dhh / sh))


def release_files():
    try:
        subprocess.run(["git", "-C", str(ROOT), "rev-parse", "--verify", f"{RELEASE}^{{commit}}"], check=True, capture_output=True)
    except (OSError, subprocess.CalledProcessError):
        return None
    return preview.release(RELEASE)


def unversioned(regions, version):
    """The footer's version text, which names each build's own version, as one placeholder."""
    return [tuple("v<version>" if value == f"v{version}" else value for value in region) for region in regions]


class StandardIsRelease(unittest.TestCase):
    def compare(self, project, interface, locale, theme, state, options, setup=""):
        old = preview.render(project, locale, interface=interface, read=self.release, raw=True,
                             setup=setup or None, **options)
        # theme None: the client's own look, nothing applied.
        theme_setup = f'H.UI:ApplyTheme("{theme}")\n' if theme else ""
        new = preview.render(project, locale, interface=interface, raw=True,
                             setup=(theme_setup + setup) or None, **options)
        new, old = unversioned(new, VERSION), unversioned(old, RELEASE[1:])
        self.assertEqual(sorted(new, key=repr), sorted(old, key=repr), (project, interface, locale, theme, state))

    def setUp(self):
        self.release = release_files()
        if self.release is None:
            self.skipTest(f"{RELEASE} is not available in this checkout")

    def test_the_clients_look_outside_forever_and_standard_on_forever(self):
        # Outside Forever the client's own look is the standard one; on Forever the standard look,
        # applied over the frame already built, must still be 0.3.7's.
        families = [(1, None), (19, None), (5, None), (2, None), (18, FOREVER)]
        for project, interface in families:
            themes = ("standard",) if interface == FOREVER else (None, "standard")
            locales = ("enUS", "deDE") if project in (1, 18) else ("enUS",)
            for theme in themes:
                for locale in locales:
                    for state, options in STATES:
                        with self.subTest(project=project, theme=theme, locale=locale, state=state):
                            self.compare(project, interface, locale, theme, state, options)

    def test_retail_progress_view_and_its_tooltip(self):
        for theme in (None, "standard"):
            for options in ({"view": "progress"}, {"view": "progress", "tooltip": "dungeon"}):
                with self.subTest(theme=theme, options=options):
                    self.compare(1, None, "enUS", theme, "progress", options, setup=PROGRESS)


class ForeverPalette(unittest.TestCase):
    def test_bronze_accent_and_muted_stay_away_from_the_warrior(self):
        # A warrior's name must never read as part of the frame: every bronze, accent and
        # muted value, laid over the surface, stays at least 11 CIEDE2000 from 198/155/109.
        self.assertAlmostEqual(ciede2000(WARRIOR, (154, 128, 92)), 11.23, places=2)  # Umbra's published value
        lua = preview.runtime(18, "enUS", interface=FOREVER)
        palette = lua.globals().H.Theme.palettes.forever
        surface = [palette.surface[i] * 255 for i in (1, 2, 3)]
        keys = ("lineTop", "lineSide", "outline", "value", "hover", "chosenLabel", "primaryLabel", "unchosenLabel", "muted",
                "header", "level", "secondary", "updated", "guild", "hint", "footer", "credit", "statLabel", "settingsLabel",
                "arrow", "gear", "scrollThumb", "sliderEdge", "sliderFill", "sliderThumb", "title", "heading",
                "buttonIcon", "trackFill")
        for key in keys:
            color = palette[key]
            alpha = color[4] if color[4] is not None else 1
            rgb = tuple(alpha * color[i] * 255 + (1 - alpha) * surface[i - 1] for i in (1, 2, 3))
            with self.subTest(key=key):
                self.assertGreaterEqual(ciede2000(WARRIOR, rgb), 11, (key, rgb))


if __name__ == "__main__":
    unittest.main()
