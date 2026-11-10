# WoW: Forever theme: inventory and plan

**Status: the revision was approved as recommended on 10 November 2026 and is implemented; not yet released. The author first saw the frame in the game the same day, on one screenshot, and asked for three changes, all made the same day: the format toggle and the search field wear Forever's dropdown field (decisions 8 and 9), and the table lies on the window's own rock, darkened to 45 %, instead of the inset's cool marble (decision 4, now D). Nothing of the frame has been measured yet, and the three changes have not been seen in the game.** On WoW: Forever the window now wears the client's own window frame, as Soundstone 0.4.0 does, and the flat look this document first proposed is the fallback for each piece of Forever's art a client lacks. The switch (`/hourstone theme` and the settings' theme row) is gone: the look follows the client. See [Revision: Forever's own frames](#revision-forevers-own-frames). The sections after it describe the flat look as approved on 8 November 2026 and built and measured on 9 November 2026; where they speak of the switch, of `auto` or of the theme row, the revision supersedes them. Hourstone 0.3.7 shows WoW: Forever the Classic look, built from Soundstone's sprites, because `C.RetailStyle()` is false there. This document proposed the theme that gives the window Forever's own design language on Forever and leaves Retail, Mists, Anniversary and Classic Era exactly as they are. It lists what the window wore in 0.3.7, what Forever's art actually measures, the palette with the origin of every value, the files it touches, the risks, a test plan per client and the open questions, with the answers given so far.

A comparison sheet is drawn from the Lua frames with synthetic characters: `python tools/preview.py --forever-theme` writes it as HTML to `dist/design`, with Forever as 0.3.7 drew it, Forever's fallback now and Retail now. A browser cannot draw the client's atlases, so the sheet shows the flat fallback, not Forever's frame. It is a browser approximation, not an in-game capture: Georgia stands in for the client font, no code tint reaches a picture, the checkbox is a stand-in and the dimmed unchosen toggle a gray filter. The sheet and its PNG captures stay local and are not part of the repository (decision 7 of the revision); an in-game screenshot of the frame will take their place once the frame is accepted.

## Revision: Forever's own frames

**Status: proposed and approved as recommended on 10 November 2026 (see *Decisions*), implemented the same day, not yet released.** The automated checks pass (see *Tests*). Every position below is computed from Soundstone's measurements or checked in the simulation; the author's first look in the game on 10 November 2026 measured nothing, and *In the game* lists what is to be measured. *As built* records where the build details or departs from the plan.

**Why.** Soundstone wore the same flat look on 9 November 2026. Seen in the game next to Forever's own windows, it read as foreign: the character frame, the bags (drawn by Baganator) and Blizzard's settings all wear a thick bronze frame with a dark title strip. Soundstone 0.4.0, released on 10 November 2026, therefore puts its mixer and options in Forever's own window frame and keeps the flat look only where a piece of the client's art is missing. Hourstone follows it: on the Forever client the window wears the same frame as Soundstone's mixer, and the flat look of this document stays as the fallback, piece by piece.

What stays:
- Retail, Mists Classic, TBC Anniversary and Classic Era look exactly as in 0.3.7. The test that compares every visible region with 0.3.7 stays green, now without the theme row's exception (see *No switch*).
- A look changes the surface, never the information: class colors, the current character's marker, Vault states and the heart keep their colors.

### What Soundstone 0.4.0 builds, and what of it is confirmed

Sizes are UI units of the frame that carries the art. The measurements are **Soundstone's**, taken on lossless screenshots at 1.3125 physical pixels per unit and written down in its own theme plan (section *Revision: Forever's own frames*); Hourstone has measured none of them itself.

- **Border frame:**
  - a frame of its own over the content: frame level +10, `EnableMouse(false)`;
  - on it `NineSliceUtil.ApplyLayoutByName(border, "ButtonFrameTemplateNoPortrait")`;
  - anchored TOPLEFT (−4.4, −3.35) and BOTTOMRIGHT (+0.5, +0.35), so the opaque metal ends on the frame's own edges and the frame keeps its size.
- **Corners:** `NineSliceUtil.UpdateCornerCropping` only where it exists (on the `forever` branch only), in `pcall`, with the border's height.
- **Ground:** `Interface\FrameGeneral\UI-Background-Rock`, tiled (BACKGROUND −6), from the border's TOPLEFT (7, −21) to its BOTTOMRIGHT (−2, 2); over it `_UI-Frame-TopTileStreaks` (BACKGROUND −5), 43 high, tiled horizontally, from (6, −21) to (−2, −21). Soundstone gives the ground as 52/48/41 on Forever.
- **Measured bands:** metal 6.1 wide with 5.3-unit chamfers; the title strip 2.8 to 19.6 below the border's top, the separator ending at 25.7, flat ground from 26.4; at the bottom 8.3 for band and shade; inside the side metal about 2.5 of shade. Measured from the frame's own top, that is a strip from 6.15 to 22.95, a separator ending at 29.05 and ground from 29.75 (computed). Content therefore starts about 30 below the top, ends at least 8.3 above the bottom and stays about 8.6 in from the sides.
- **Title:** size 12 in the strip, in `NORMAL_FONT_COLOR` read at runtime (fallback `#FFD200`); the strip drags the window. Small windows such as Soundstone's options: title centered, 6 below the border's top.
- **Close button:** a button of its own, 28 × 28 at the border's TOPRIGHT (0, 3), atlases `RedButton-Exit`, `RedButton-exit-pressed` and `RedButton-Highlight` (ADD), with its own `OnClick`, because the stock one calls `HideUIPanel`. Forever's own `UIPanelCloseButtonDefaultAnchorsMixin` uses the same size and place (`Blizzard_SharedXML/Camelot/SharedUIPanelTemplates.lua`).
- **Header buttons:** `UIPanelButtonTemplate` at 32 × 22 without text, with a gold symbol (255/230/128) of 16 units (the gear 17), 0.8 units below the rectangle's center because the button art sits that low; the first at the border's TOPLEFT (8, 1), a right-hand group against the close button (TOPRIGHT −28, 1). Header buttons and title on frame level +12.
- **Slider:** the track from `Minimal_SliderBar_Left`, `_Minimal_SliderBar_Middle` and `Minimal_SliderBar_Right` at atlas size, the fill 4 units in from both ends; the thumb `Minimal_SliderBar_Button` through `GetThumbTexture():SetAtlas(name, true, nil, true)` (the last argument resets the old sprite's texture coordinates), OVERLAY 7, BLEND.
- **Detection:** Forever's art only on the Forever client (`C.IsForever()`), because other clients ship other art under some of the names. There, every atlas is checked with `C_Texture.GetAtlasInfo`, together with `NineSliceUtil.ApplyLayoutByName` and `NineSliceLayouts[...]`; each piece falls back to the flat look on its own; Forever's pieces are built the first time the look is applied and never exist on the other clients.

Confirmed in the game, per Soundstone's acceptance record of 10 November 2026: the frames of the mixer and the compact bar, at client scale 0.7 and Soundstone size 100 %, and the symbols on the bar's red buttons, counted at 3 rows above and 2 below. **Not documented:** the options window in the frame. **Simulated only:** Soundstone's drag fix. **Not needed here:** the bar's cut band (`SetTexCoord` before `SetAtlas`, `SetTexelSnappingBias(0)`, `SetSnapToPixelGrid(false)`) and the icon frames (`UI-HUD-ActionBar-IconFrame`), because Hourstone has no compact bar and no icon buttons.

### Each surface on Forever

"Fallback" is what a surface wears when its piece of the client's art is missing: the flat look of this document, as built and measured on 9 November 2026.

| Surface | Recommended | Fallback | What is known |
| --- | --- | --- | --- |
| Main window (720 wide) | **Window frame**, as Soundstone's mixer; the header moves into the title strip (see *The window inside the frame*) | Flat plate with the flat header | Soundstone's mixer: accepted in the game |
| Settings | **Window frame**, as Soundstone's options: title centered, red close button | Flat plate | Soundstone's options in the frame: no documented in-game check |
| Delete dialog | **Window frame**, title centered; no close button, because Cancel is there, as in 0.3.7 | Flat plate | Not seen anywhere |
| Client, realm and sort menus | **Forever's dropdown list:** the atlas `common-dropdown-bg`, placed as Blizzard's `MenuStyle1Mixin` places it (10 beyond the sides, 3 above and below, alpha 0.925); the rows keep their inset of 8, the bottom inset grows to Blizzard's 15 | Flat plate | Soundstone captured this art on 8 November 2026 as its device list (Blizzard's menu): a one-pixel line, `#92744C` on top to `#755B3A` at the bottom. Soundstone does not wear it on surfaces of its own |
| Realm and client buttons | **Forever's dropdown field**, as `WowStyle1DropdownTemplate` draws it: `common-dropdown-textholder` from (−8, 7) to (8, −9) and the arrow `common-dropdown-a-button` with its `-hover`, `-pressed` and `-open` states; Hourstone's own arrow is hidden. Only the art is taken; the menus stay Hourstone's | Flat control | Soundstone's device field shows this art on Forever (captured 8 November 2026: ground `#110E09` inside a double bronze line, gold arrow) |
| Reset position, Done, Deleted characters; Cancel and Delete | **`UIPanelButtonTemplate`** with text, at today's rectangles, as Soundstone's Reset buttons: Forever draws Retail's red art, a gold label, white under the pointer | Flat control | Captured by Soundstone on 8 November 2026 |
| Gear | Red `UIPanelButtonTemplate`, 32 × 22, gold gear of 17 | The flat look's muted gear | As Soundstone's mixer |
| Close buttons (window, settings) | Forever's red close button, 28 × 28 | The flat `×` | As Soundstone's mixer |
| Size slider | Forever's track and copper diamond; the fill 4 units in from each end, in Soundstone's 255/176/33, so both addons' size sliders look the same | The flat track and thumb | Seen on Soundstone's mixer on a screenshot of 9 November 2026 |
| Format toggle (Combined, Hours) | **One of Forever's dropdown fields** over both halves, without an arrow, where the filter fields lie; a one-pixel divider in the gap between the halves; the chosen half in the text color, the other muted, the accent under the pointer (decision 8) | The flat toggle: dark ground, one-pixel outline, accent underline when chosen | The flat toggle was measured in the game on 9 November 2026; inside the frame the author found it out of place on 10 November 2026 and chose this variant from a montage made from that screenshot. The field itself is not yet seen in the game |
| Search field | **Forever's dropdown field**, as on the realm and client buttons and without an arrow (decision 9); text, hint and clear button as before | The flat field | The author chose it on 10 November 2026 from a montage made from the first in-game screenshot; the field art is the filters'. Blizzard's own search box (`SearchBoxTemplate`: `common-search-border-*`, 20 units high, a magnifying glass and a clear button) has not been seen on Forever |
| Scroll thumb | The flat thumb | — | — |
| Minimap checkbox | `UICheckButtonTemplate`, unchanged | — | As Soundstone |
| Game tooltip, minimap button, Addons menu entry | Unchanged | — | — |
| Logo in the header | **Hidden** inside the frame (decision 5) | Shown, as in the flat look | Blizzard's frames without a portrait show none; Soundstone's mixer shows none |
| Header rule | Hidden inside the frame; the frame's separator takes its place | The flat rule | As Soundstone |
| Summary dividers, table and row rules | The flat look's muted rules, one unit | — | — |
| Ground under the character table | **Blizzard's inset frame** (`InsetFrameTemplate`'s nine-slice) over the window's own rock, darkened to 45 % (decision 4, D) | No inset: the rock ground | The template's marble measured about 14/14/14 to 20/20/20, neutral gray, on the author's lossy screenshot of 10 November 2026, beside the rock's warm 36/32/29 to 55/50/45; see *Class colors on the rock ground* |
| Tabs, progress view, Vault, progress tooltip | Retail only; Forever has no progress view, and without a switch the Forever look never reaches them. They keep the standard look; their flat variant stays reachable in the tests | — | — |

The menus and the dropdown buttons go one step beyond Soundstone, which wears no dropdown art on surfaces of its own. They are recommended because Soundstone's options window shows exactly this art in its device field and list, so Hourstone's settings and filters would match it. Decision 3 can keep both flat instead.

### The window inside the frame

Positions in the window's own units, computed from the anchors above; none of them has been seen in the game.

- **Header:** the red gear at the border's TOPLEFT (8, 1), that is 3.6 to 35.6 from the left and 2.35 to 24.35 below the top; the red close button at the border's TOPRIGHT (0, 3), that is 692.5 to 720.5 from the left; between them the title strip, which drags the window and carries "Hourstone – Azeroth Hours" at size 12, centered. Gear, close button and strip on frame level +12. The 17-unit title, the logo, the rivets, the header rule and the old gear and close button are hidden.
- **Content:** the summary starts 30 below the top instead of 50; toolbar, table and footer move up by the same 20 units. The window becomes 20 units shorter: 192 units plus the rows instead of 212 (decision 6). `U:Position` keeps the top edge where it was, because it already anchors by the saved height; its lower bound for a saved height (248) drops to the framed window's 242.
- **Clearance:** the content keeps 10 units from the sides (needed: about 8.6) and the footer ends 10 above the bottom (needed: 8.3).
- **Settings:** at (10, 28), aligned with the content's left edge and below the gear; 214 high, they end flush with the bottom of a one-row window. Their controls stay where 0.3.7 puts them: the first one starts 35 below their top (needed: about 30), the last ends 12 above their bottom.
- **Delete dialog:** where it is (110, 30); its body starts 49 below its top and its buttons end 16 above its bottom.
- **Levels:** border +10 over the window's content; menus +30, settings +35 and dialog +50 stay above it; the settings' and dialog's own borders sit 10 above them, under their header controls at +12.
- **Corner cropping:** called again whenever the window's height changes (`U:LayoutRows`). At 242 units and more it probably crops nothing.
- **Fitting text:** "Hourstone – Azeroth Hours", "Settings"/"Einstellungen" and the dialog's title fit their strips at size 12 by a wide margin, so Soundstone's `FitText` is not needed.

### Scale (decision 1)

Hourstone's window divides out the UI scale (`U:ApplyScale`): one unit is *min(size, fit)* physical pixels on every screen. Blizzard's frame art scales with its frame. Forever's own windows have *UI scale × physical height / 768* pixels per unit.

- **A. The art in Hourstone's units (recommended).** The border is a plain child of the window. The metal is 6.1 × Hourstone size pixels: 6.1 at 100 %, 7.9 at 130 %, 12.2 at 200 %. Next to Forever's own windows it is equal at 100 % wherever those windows have one pixel per unit, and elsewhere at the Hourstone size that matches their pixels per unit. On a 1440-pixel screen at UI scale 0.7 (1.3125 pixels per unit) Forever's metal is 8.0 pixels; Hourstone matches it at 130 % to within 1 %. Soundstone does the same: its frame scales with Soundstone's own 75–150 %. Frame, buttons, fonts and gaps keep one proportion at every size.
- **B. A border with its own scale**, so the metal is always as thick as Forever's. Then the strip, the header buttons and every clearance would be in other units than the content, and their ratio would change with the size: at 65 % on that screen the strip would be twice as tall as the content around it suggests. Every offset of the content would have to be computed again on each size change. Not recommended.

### No switch (decision 2)

Soundstone removed `/soundstone theme` on 10 November 2026: the look follows the client, because the other clients cannot draw Forever's frame (Mists, the Anniversary realms and Era ship other art under `ButtonFrameTemplateNoPortrait`, and `RedButton-Exit` is referenced only on `live` and `forever`). 1:1 here means:
- `/hourstone theme` and the settings' theme row go away. The settings return to 0.3.7's 214 units, with Reset, Done and Deleted characters at their 0.3.7 places, and their clamp to the screen goes too. The identity test drops its theme-row exception.
- `M.Init` no longer keeps `settings.theme` and removes a leftover value: only development builds ever wrote one.
- The look is `forever` on the Forever client and `standard` everywhere else. `Th.Apply(name)` stays in the code for the tests, which apply both looks and back on every configuration.
- Everything else of the flat look stays, as the fallback.

### Detection, fallback and creation

`Th.Art()` returns which of Forever's pieces the client can draw, on the Forever client only; elsewhere it returns nothing. Each group falls back alone:

| Group | Needs | Without it |
| --- | --- | --- |
| `window` | `NineSliceUtil.ApplyLayoutByName`, `NineSliceLayouts.ButtonFrameTemplateNoPortrait` and the atlas of every piece; `RedButton-Exit`, `RedButton-exit-pressed`, `RedButton-Highlight` | Main window, settings and dialog in the flat plate with the flat header; the push buttons and the gear flat as well, and the window keeps 0.3.7's height |
| `streaks` | `_UI-Frame-TopTileStreaks`, and the `window` group | The frame without streaks |
| `inset` | `NineSliceLayouts.InsetFrameTemplate` and its atlases, and the `window` group | No inset: the table on the window's rock at full brightness |
| `menu` | `common-dropdown-bg` | The menus in the flat plate |
| `dropdown` | `common-dropdown-textholder`, `common-dropdown-a-button` and its three states | Realm and client buttons, the format toggle and the search field as flat controls |
| `track`, `thumb` | The three track pieces; `Minimal_SliderBar_Button` | The flat track; the flat thumb |

`UI-Background-Rock` is a file, not an atlas, and cannot be checked; it is used together with the frame, as in Soundstone.

As in Soundstone, Forever's pieces are created the first time the Forever look is applied: the frame, every atlas piece and now also the flat plates of the fallback. The draft creates the flat plates on every client and hides them; with no switch, they need not exist outside Forever. On the other four clients no piece of either kind exists, which a test asserts.

### Dragging

Soundstone's drag problem does not exist here. Soundstone's root lies on the MEDIUM strata, where Forever's action bars are too: `MultiActionBars.xml` sets MEDIUM on the `forever` branch, and neither `MainActionBar` nor its templates set a strata, so it takes UIParent's. Within one strata the frame level decides; per Soundstone, the buttons draw their text at level 500, so a dragged Soundstone slipped behind them. Hourstone's window lies on the DIALOG strata, which is drawn above MEDIUM and HIGH whatever the frame levels; the border and header buttons are its children and inherit it. Hourstone needs no `BringToFront`. Checked in the source only; dragging across the action bars belongs to the in-game check.

### Class colors on the rock ground (decision 4)

The rock ground is lighter than the flat plate. WCAG contrast, computed from the values (the rock as Soundstone's 52/48/41; the flat plate as measured, 23/19/15; 0.3.7's Classic panel center 26/26/26):

| Over | Text | Muted | Faint | Death Knight | Demon Hunter | Shaman | Warlock |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Rock 52/48/41 | 10.9 | 5.0 | 3.5 | 2.2 | 2.4 | 2.7 | 4.2 |
| Flat plate 23/19/15 | 15.3 | 7.1 | 4.5 | 3.2 | 3.4 | 3.8 | 6.0 |
| 0.3.7 Classic 26/26/26 | 14.4 | 6.7 | 4.3 | 3.0 | 3.2 | 3.6 | 5.6 |

Soundstone shows no class colors, so it never met this. Names are information; on the rock, a Death Knight's name loses a quarter of its contrast against 0.3.7.

- **A. Blizzard's inset (recommended).** `ButtonFrameTemplate` itself carries an `InsetFrameTemplate` (`UI-Background-Marble` with an inner nine-slice) for the content of the windows built on it. Hourstone would set the table (column headers and rows) in one, on Forever only. Its art on Forever has not been captured, so its ground has to be measured; if it is not darker than about 30/30/30, B or C follows.
- **B. The rock ground, as in Soundstone (1:1).** Death Knight 2.2, Demon Hunter 2.4, Shaman 2.7.
- **C. The flat plate's surface behind the table**, inside the bronze frame. The contrasts of the flat look, but chrome that Forever does not have.
- **D. The inset's frame over the window's rock, darkened to 45 %** (black at 0.55 where the template has its marble). Added on 10 November 2026: on the first in-game screenshot the author found the marble out of place, cool gray beside the warm rock, and chose D from a montage of B, D and C. Computed from that lossy screenshot's rock (55/50/45, darkened to about 25/22/20): Shaman 3.7, Death Knight 3.1, the guild line 4.5, against 4.0, 3.3 and 4.6 on the marble (about 16/16/16) and 2.6, 2.2 and 3.4 on the full rock. Not measured in the game.

### API per client

Checked in Gethe/wow-ui-source on 10 November 2026, branches `live`, `forever`, `classic` (Mists), `classic_anniversary` and `classic_era`. Every new call runs on the Forever client only.

| What | `live` | `forever` | `classic`, `classic_anniversary`, `classic_era` |
| --- | --- | --- | --- |
| `NineSliceUtil.ApplyLayoutByName`, `NineSliceUtil.GetLayout` | yes | yes | yes |
| `NineSliceUtil.UpdateCornerCropping` | — | yes | — |
| `NineSliceLayouts.ButtonFrameTemplateNoPortrait` | `UI-Frame-Metal-*` | `UI-Frame-Metal-*`, offsets changed by `Camelot/NineSliceLayoutOverrides.lua` (top right −2; bottom corners y −8, bottom right −2) | other atlases (`UI-Frame-TopLeftCornerNoPortrait`, …) |
| `NineSliceLayouts.InsetFrameTemplate` | yes | yes | yes |
| `RedButton-Exit`, `RedButton-exit-pressed` referenced | yes | yes | — |
| `RedButton-Highlight` referenced | yes | yes | yes |
| `Minimal_SliderBar_*` referenced (`MinimalSlider.xml`) | yes | yes | yes |
| `common-dropdown-textholder`, `common-dropdown-a-button*`, `common-dropdown-bg` | yes | yes | — (`common-dropdown-classic-*`) |
| `UI-Background-Rock`, `_UI-Frame-TopTileStreaks` referenced | yes | yes | yes |
| `UIPanelButtonTemplate`, `InsetFrameTemplate` | yes | yes | yes |
| `Texture:SetAtlas(atlas, useAtlasSize, filterMode, resetTexCoords, …)` | yes | yes | yes |
| `SetHorizTile`, `SetVertTile`, `SetTexCoord`, `SetBlendMode`, `SetDrawLayer` | yes | yes | yes |
| `Button:SetNormalAtlas`, `SetPushedAtlas`, `SetHighlightAtlas` | yes | yes | yes |
| `C_Texture.GetAtlasInfo` | yes | yes | yes |
| Added while building (checked the same day): `Frame:HookScript`, `Frame:GetScript` used in Blizzard's own code | yes | yes | not looked up: not called there |
| `Button:GetFontString`, `Region:GetPoint`, `Frame:CreateTexture(name, layer, template, subLevel)` in the generated API documentation | yes | yes | yes |

"Referenced" means the UI source uses the name; whether a client really draws an atlas is known only from `C_Texture.GetAtlasInfo` in the game, which is why it is checked at runtime. `HookScript` and `GetScript` are not in the generated documentation; they were confirmed by their use in Blizzard's code on `live` and `forever` (`Blizzard_PTRFeedback_Events.lua`, `SharedUIPanelTemplates.lua`), and Hourstone calls them only on pieces it builds on the Forever client.

### Files

| File | Change |
| --- | --- |
| `Hourstone/Theme.lua` | Art names (`Th.ART`) and `Th.Art()`; the look by client (`forever` on Forever, `standard` elsewhere) instead of the saved choice; `buttonIcon` 255/230/128, `trackFill` 255/176/33 and `insetShade` (black at 0.55) in the palette; plates registered on every client but built only when the forever look is first applied, `Th.Later` for other flat pieces, `Th.Cover` where Forever's art takes a surface |
| `Hourstone/UI.lua` | The frame on window, settings and dialog; gear, close button and title strip; the framed layout (content 20 up, height −20, settings at (10, 28)); push buttons, dropdown and menu art, slider track and thumb, inset; `U:BuildArt`, `U:ApplyLook`, `U:ApplyThumb` and `U:ApplyTheme(name)` for the tests. Removed: the theme row, `U:SetTheme`, `U:ThemeCommand`, `U:ApplySkin`, the settings' clamp |
| `Hourstone/Core.lua`, `Hourstone/Locale.lua` | Back to 0.3.7: the theme command and its strings go |
| `Hourstone/Model.lua` | `M.Init` removes a leftover `settings.theme` |
| `tests/wow_mock.lua` | `C_Texture.GetAtlasInfo` with stand-in sizes and a switchable set of missing names, `Texture:SetAtlas` recording its arguments, `Button:Set*Atlas`, `NineSliceUtil` and `NineSliceLayouts` (with Camelot's offsets and `UpdateCornerCropping` on the Forever configurations only), `UIPanelButtonTemplate`, `HookScript`, `GetScript`, tiling, sublevels, blend modes and the strata |
| `tests/test_theme.lua`, `tests/test_theme.py` | See *Tests*; the identity test loses the theme-row exception |
| `tests/test_compartment.lua`, `tests/test_ui.lua`, `tests/test_forever.py` | The Forever pins follow the frame: the thumb atlas, the window 20 units shorter, the fill 4 units in, the client menu's bottom inset of 15 |
| `tests/test_layout.py`, `tests/fixtures/layout/adjustments.json` | Back to 0.3.7: the settings' height and button places |
| `tools/preview.py` | The raw region data includes the atlas; the Forever sheet applies the look as if the client had no art and says that it shows the fallback |
| Docs | `CHANGELOG.md`, this document, `docs/VALIDATION.md`, `README.md`, `docs/DEUTSCH.md`, `docs/curseforge/description.md`, `docs/ARTWORK.md` (client-owned atlases, referenced, not shipped), and the in-game checklist below |

**No new assets.** Every piece of the frame is the client's own art; Hourstone ships none of it.

### As built

Where the build details the plan or departs from it:

- **Groups.** The streaks and the inset need the `window` group as well as their own art: without the frame the window wears the flat plate, which takes neither. The plan listed the inset alone.
- **Creation.** `Th.Plate` registers a plate on every client and creates its regions only when the forever look is applied for the first time; the flat `×` of the close buttons waits the same way (`Th.Later`). Forever's own pieces are built by `U:BuildArt`, each group once and only when the client has its art. On the other clients neither kind exists.
- **Header.** The header frame itself moves into the strip: TOPLEFT of the border (40, 1), 656.9 × 22 units, level +12, and it still drags the window. The title is centred on the border, 6 below its top, at size 12, with 560 units reserved for its width (190 on the settings, 440 on the dialog) and no fixed height.
- **Push buttons.** Each `UIPanelButtonTemplate` button sits over the hidden flat control, at its rectangle. Its click calls the control's own `OnClick`, its tooltip is the control's; its label keeps the control's size (11, Reset position 10) through `SetFont`, as Soundstone sets 10, and the template's own colors. Whether the size holds while the pointer is over the button is to be seen in the game.
- **Dropdown arrow.** It follows Blizzard's order in `GetWowStyle1ArrowButtonState`: pressed under the pointer (`-pressedhover`), under the pointer (`-hover`), pressed (`-pressed`), menu open (`-open`), at rest. The plan named three states; `-pressedhover` is checked as well. Hourstone's own hover tint on these buttons is hidden where the art is; Blizzard's field shows hover through the arrow alone.
- **Format toggle** (decision 8, after the first look in the game). The field is `common-dropdown-textholder` on the toggle's frame, anchored at (−8, 7.5) and (8, −9.5): the toggle stands half a unit lower and one unit shorter than the filter buttons, so its field covers the same rows as theirs. The divider is one physical pixel wide (measured again with the flat skin's lines), 15 units high on the field's middle, at 112.5 units, the middle of the 3-unit gap, in `outline` (104/80/52); the montage used 92/83/62, which is that outline as the lossy screenshot showed it. Both halves keep their rectangles and clicks; their flat plates and hover tint are hidden under the field, the chosen label takes `text` and the other `unchosenLabel`, and the accent shows under the pointer as on every control. The atlas is drawn 8 units beyond the toggle on each side, as on the filter buttons, whose visible edge lies about 3 units inside their own rectangles on the author's screenshot; the clearance test therefore checks the toggle's rectangle, not the atlas box.
- **Menus.** With Blizzard's bottom inset of 15 the menus grow by 7 units: the client and realm menus to 23 units plus 25 per row, the sort menu to 98.
- **Slider.** The track pieces lie on the slider's vertical centre in its BACKGROUND layer, under the fill. The fill is 3 units high on that centre (7.5 below the slider's top), 4 units in from each end, 218 units at 200 %. The diamond keeps a white vertex color; the flat look tints its square.
- **Inset.** A frame at the window's own level, anchored to the table (column headers and rows), with `InsetFrameTemplate`'s nine-slice. Where the template has its marble (BACKGROUND −5), a color texture in `insetShade`, black at 0.55, darkens the window's own rock (BACKGROUND −6, which runs on under the table) to 45 %; one texture, so the rock has no seam at the inset's edge (decision 4, D).
- **Search field** (decision 9). `common-dropdown-textholder` on the search field, anchored at (−8, 7) and (8, −9) as on the filter buttons, whose height and row it shares; its flat plate is hidden under the field, and its text, hint and clear button are unchanged.
- **Saved position.** The lower bound for a saved height drops to 242 only while the window is framed; the other clients keep 0.3.7's 248.

### Tests

Built and passing on 10 November 2026: 154 Lua scenario suites in the seven configurations of `tests/run.py` (each with and without `BackdropTemplate`) and 77 Python tests. The mock's atlas sizes are stand-ins, not the client's; no test claims a size of Blizzard's art.

- **Art unknown at load** (every name missing from the mocked `C_Texture.GetAtlasInfo`): on Forever the flat look as built on 9 November 2026, on every client no atlas, no nine-slice call and no template button. On the other clients no flat plate has a region and the close buttons have no `×`. A development build's `settings.theme` is removed; `/hourstone theme` is an unknown word that opens the window, as in 0.3.7.
- **The flat look** on every client: palette closure, information colors, the palette pinned key by key, one-pixel lines and inner shadow at 65, 100, 135 and 200 % on three screen heights and three UI scales, also after only an event; the looks applied in every direction with the settings, each menu, the dialog and Retail's progress tooltip open, without building anything; `NORMAL_FONT_COLOR` and its fallback; the hover label across a Refresh; Retail's Vault colors.
- **Art known** (Forever configurations): the border on window, settings and dialog with its layout, anchors and level +10, its top frame at +12; ground and streaks with their files, tiling, anchors and sublevels; the flat plates covered; corner cropping with the border's height at build and on every height change, and no call where the function is missing; the gear at 32 × 22 from 3.6 to 35.6 and 2.35 below the top, its 17-unit symbol 0.8 below the centre in 255/230/128; the close button at 692.5, its three atlases and its own click; the title strip, the title at size 12 in `NORMAL_FONT_COLOR`; logo, old title, old gear, old close and the header rule hidden; summary at 30, toolbar at 94, table at 132, footer and sort menu 20 units up, the window 192 units plus the rows; a saved height of 262 keeps the top edge, 242 is accepted; the settings at (10, 28), 214 high; the titles of settings and dialog, the settings' close button, no close button on the dialog; every visible region of window, settings and dialog at least 29.75 below its top, 8.3 above its bottom and 8.6 from its sides, at one to eight rows; the five push buttons at their controls' rectangles, with label, size and click; the dropdown field, the arrow through all five states; the format toggle's field on the filter fields' rows, its divider at 112.5 one pixel wide at 65 to 200 %, both plates and hover tints hidden, the chosen label in `text`, the other muted, the accent under the pointer and a click that switches; the menus' art, alpha, anchors, level and heights; the track pieces, the fill's place, width and color, the thumb's atlas, `resetTexCoords`, layer, blend and color; the search field in the dropdown field, its plate hidden, hint, text and clear button shown; the inset's level, anchors and nine-slice, its shade at BACKGROUND −5 over the window's rock, which covers the table; class colors unchanged.
- **Each group missing alone:** only its pieces fall back, and the window keeps 0.3.7's height without the frame; nothing new is built.
- **Round trip:** forever → standard → forever restores every visible region and the saved position, and builds nothing. Under standard on Forever, after the frame was built, every visible region in nine window states matches `v0.3.7` (`tests/test_theme.py`).
- **Other clients:** their own look matches `v0.3.7` in every visible region, in nine states and in Retail's progress view and its tooltip, now without any exception.
- **Dragging:** the window's strata is DIALOG, the border and the header strip are its children, and the strip still starts and ends a drag.

### In the game

Only screenshots from the game count for the frame; `tools/preview.py` can show no more than the fallback. Each step on lossless screenshots (`/console screenshotFormat png`), measured with Pillow, at Hourstone 100 % and at a size that is not a whole number, such as 130 %; note the client build, the UI scale and the screen height with each capture. Nothing below has been done yet.

**WoW: Forever**

1. **Load.** First login after the update: the frame without `/reload`. `/dump C_Texture.GetAtlasInfo("UI-Frame-Metal-CornerBottomLeft")`, and the same for `RedButton-Exit`, `_UI-Frame-TopTileStreaks`, `UI-Frame-InnerTopLeft`, `common-dropdown-bg`, `common-dropdown-a-button-open`, `_Minimal_SliderBar_Middle` and `Minimal_SliderBar_Button`: each must return a table, or that piece shows the flat fallback.
2. **Frame.** A crop of the window next to a Blizzard or Baganator window at the same pixels per unit (Hourstone 130 % beside UI scale 0.7 on a 1440-pixel screen): the metal flush with Hourstone's edges and about as thick as theirs; nothing of the content in the band, the strip or the corners; the corners not cut wrongly at one row (242 units) and at eight rows.
3. **Header.** Title centred and whole, `#FFD200`; gear and close button as Baganator's, the gear symbol with 3 rows of red above and 2 below at 1.3125 pixels per unit, as Soundstone counted; hover and click on both; dragging by the strip, with the window staying in front of the action bars while it moves.
4. **Layout.** Summary, toolbar, table and footer clear of the frame; the top edge where it was before the update (with a saved position); `/hourstone reset`.
5. **Settings and dialog.** Both in the frame, title centred, the settings' red close button; the red push buttons with hover, the label size unchanged while the pointer is over them; *Deleted characters* and back; Cancel and Delete in the dialog.
6. **Filters and menus.** The realm and client buttons in Forever's dropdown field, the arrow at rest, hovered, pressed and open; the format toggle in the same field, its ends as round as the filters' although it is 46 units wider, the divider one sharp pixel, Combined and Hours each chosen and hovered; the search field in the same field, empty with its hint, with text and its clear button, and focused; each menu in Forever's list with one row hovered; the realm menu scrolled with the wheel.
7. **Slider.** The track and the copper diamond; the fill inside the track at 65 %, 100 % and 200 %, in 255/176/33; dragging the diamond.
8. **Colors.** The ground under the rows measured inside the inset (the rock at 45 %) and, beside it, the rock at full brightness, with no seam at the inset's edge; Death Knight, Demon Hunter and Shaman names legible; a warrior's name, the current character's marker and the heart unchanged. If the names do not read well on the darkened rock, decision 4 falls to C.
9. **Sizes.** 65 % and 200 %, a change of UI scale and of resolution while the window is open: the frame and the content keep their proportions.

**Retail, Mists Classic, TBC Anniversary and Classic Era**

10. Window, settings, a menu and the dialog, cropped: identical to 0.3.7 apart from the version number. No `/hourstone theme` reply: the word opens the window, as in 0.3.7.

### Not known without the game

- How the frame reads around a 720-unit window and around popups 205 to 214 units tall (Soundstone's windows are 300 wide).
- Whether 10 units clear the corner pieces, which are larger than the bands.
- How the dropdown field and list art look at Hourstone's sizes and behind its rows, and whether the field's ends stretch over the format toggle's 201-unit box (the filter fields' boxes are 155), and the red buttons at 25 and 27 units high (Soundstone's: 20 and 22).
- The inset's nine-slice on Forever, and how the darkened rock reads behind the rows.
- How Blizzard's art renders at Hourstone sizes that do not land on whole pixels; its lines are not the flat look's exact pixels.

### Decisions

Proposed with the recommendation first; on 10 November 2026 every recommendation was approved.

1. **Scale:** the art in Hourstone's units (A), or a border with its own scale (B). *Decided: A.*
2. **Switch:** remove `/hourstone theme` and the theme row, as Soundstone did; keep `Th.Apply(name)` for the tests. *Decided: removed.*
3. **Surfaces:** as in the table. In particular: Forever's dropdown art for the menus and the realm and client buttons (or keep both flat), and red `UIPanelButtonTemplate` push buttons (or keep them flat). *Decided: as in the table.*
4. **Ground under the table:** Blizzard's inset (A), the rock as in Soundstone (B), or the flat surface (C). *Decided: A; changed to D after the first look in the game.*
5. **Logo:** hidden inside the frame, or a 16-unit logo left of the title in the strip. *Decided: hidden.*
6. **Height:** the framed window 20 units shorter, or the same height with the gained space left empty. *Decided: 20 units shorter.*
7. **Preview images** (open question 8 below): keep them local and replace the sheet in this document with an in-game screenshot once the frame is accepted; they show only the fallback now. *Decided: kept local.*

After the author's first look in the game on 10 November 2026:

8. **Format toggle:** two dropdown fields without an arrow (A), one field with a divider (B), or B with the chosen half in `NORMAL_FONT_COLOR` (C); red push buttons were weighed and not chosen. *Decided: B.*
9. **Search field:** Forever's dropdown field, as on the filters (S1), or Blizzard's search box, not yet seen on Forever. *Decided: S1.*

Decision 4 was reopened: the author found the marble out of place and chose D (the rock at 45 %) over B (the rock) and C (the flat surface).

Open question 6 below is settled by Soundstone 0.4.0. Open question 7 stays open and outside this revision.

## What Forever's own art measures

Measured with Pillow from lossless screenshots of the live Forever client taken on 7 and 8 November 2026, at two UI scales, about 1.3 and 2.15 physical pixels per UI unit. Forever's tooltip, zone plaque and minimap ring are the art Umbra borrowed; its native windows were measured too.

| Subject | Measured | What it means |
| --- | --- | --- |
| Tooltip line | One UI unit, rendered as two antialiased pixels. Full-coverage color `#E9CBA4` on top, `#B48F61` on the left, right and bottom; both top corners carry a pale specular (top left `#E8CCA1`, top right `#EFCCA0`) | The tooltip is lit from the **top**, not the top left. The `#9A846B` (top) and `#8B6E4A` (bottom) quoted for Forever's lines are partial-coverage pixels of this one-unit line, not a gradient |
| Tooltip inner band | A black ramp **inside** the line, 4–5 px: pixel/body ratio 0.05, 0.23, 0.46, 0.68, 0.82, the same over a dark and an orange world | A multiplicative shadow, not a flat `10/8/6` band. Outside the line there is only a 2 px soft drop shadow |
| Tooltip body | Translucent: alpha ≈ 0.77 over a navy base ≈ `#0D0D1C` | `#161017` is a composite over a dark brown world; Forever's tooltips read `#161717` over grass and `#33221F` over an orange floor |
| Zone plaque | Translucent textured sprite, alpha ≈ 0.6 over a warm base ≈ `#1B1409`; soft line, darkest on the right; top-left corner specular `#FCF5D4` | Lit from the top left. `#110D09` appears only in two rows over a near-black sky |
| Minimap ring | Lip highlight median `#E8C092`, peaks `#EEC696`, at 108–136° | Top-left light |
| `NORMAL_FONT_COLOR` | `#FFD200` on "Aktive Quests" and on a window title | Confirmed. Forever itself also uses it for button labels and field labels |
| Native window (pet training) | Textured bronze-metal nine-slice, ≈ 5-unit frame, red square close button, gold title, parchment list, gray-faced "Filter" button with a 2 px bronze rim (`#755B3B` top to `#53340C` bottom) | Forever's own **windows** are not flat. The flat near-black look with a bronze line is the language of its tooltips and HUD plaques |
| Umbra 0.9 on Forever | Rim `154/128/92`, `128/104/72`, `104/80/52`, each exactly 1 physical px; plate `21/18/15` at 0.96 confirmed over grass and snow; text `#F0E9DA`, muted `#A6A094` exact | Umbra's values render as written. They are Umbra's choices derived from Forever's art, not Forever's own colors |

Forever's UI source (`forever` branch of wow-ui-source, 1.60.1.70862) defines no flat or bronze-line style anywhere: Forever keeps Retail's atlas names and swaps the art behind them, and its tooltip still uses `TooltipDefaultLayout`. A flat Forever theme is therefore an interpretation of Forever's HUD art, as Umbra's is.

## Inventory: the window on Forever in 0.3.7

Every element of `Hourstone/UI.lua` as 0.3.7 renders it on Forever, with its source and its treatment under `forever`. Line numbers refer to the `v0.3.7` tag. "Sprite" means a TGA from Soundstone (Toggle, ToggleRed, Rivet and the two thumbs pinned in [the manifest](assets/soundstone-manifest.json); RetailPanel, ClassicPanel and HeaderClose copied as PNGs, see [artwork](ARTWORK.md)) or generated by `tools/assets.py`; "Blizzard" means client-owned art or templates. Elements marked *Retail only* are not shown on Forever (no keystones or Great Vault), but the theme can be forced on Retail, so they are covered.

| Element | 0.3.7 on Forever | Source | Under `forever` |
| --- | --- | --- | --- |
| Window surface and rim (`UI.lua:246-247`) | `ClassicPanel` nine-slice: gray stone center (mean 26/26/26), gray-bronze metal rim, riveted corner plates squeezed to 10 units | Sprite, Soundstone | Plate: surface, inner ramp, 1 px line, lit from the top |
| Menus, settings, delete dialog, progress tooltip (`:429`, `:448`, `:461`, `:469`, `:534`, `:546`) | Same `ClassicPanel` | Sprite, Soundstone | Same plate |
| Header rivets (`:255-258`) | `Rivet.tga`, 3×3, alpha 0.75 | Sprite, Soundstone | Hidden |
| Gear (`:259-264`) | `GEAR_64GREY`, tint 230/204/145, hover untinted | Blizzard texture, code tint | Tint muted, hover accent |
| Logo (`:265`) | `Logo.tga` | Sprite, Hourstone | Unchanged |
| Window title (`:266`) | 255/213/116 | Code | `NORMAL_FONT_COLOR` |
| Close buttons (`:267`, `:471`) | `HeaderClose.tga`: gold frame, red face, gold X; hover `ButtonHilight-Square` | Sprite, Soundstone; Blizzard highlight | Ground square with a muted `×` glyph, hover accent |
| Header and summary rules (`:268`, `:276`, `:287`) | 166/162/148 at 0.50; 146/137/120 and 150/144/128 at 0.26 | Code | Muted at 0.30 (header), 0.18 (summary) |
| Summary labels (`:274`) | 196/192/178 | Code | Muted |
| Summary values (`:277-280`) | Gold 243/206/112 | Code | Accent |
| Realm count (`:279`) | 169/170/162 | Code | Muted |
| Search field (`:296-311`) | `Toggle.tga`: slate fill, gold bevel; text 231/225/206; hint 143/140/130; `×` 169/170/162 | Sprite, Soundstone; code | Ground with a muted ring; text; faint hint; muted `×` |
| Realm and client dropdowns (`:312-317`) | `Toggle.tga`; label gold; arrow tinted 197/191/171 | Sprite; code | Ground, 1 px outline, text label, muted arrow |
| Control hover glow (`:77`) | 255/230/153 at 0.12 | Code | Accent at 0.06, label accent |
| Format toggle (`:319-320`, `:80-85`) | `ToggleRed.tga`; unchosen desaturated and dimmed; labels 255/227/156 and 184/175/160 | Sprite, Soundstone; code | Chosen: accent tint 0.12, 2-unit accent underline, accent label; unchosen: muted label |
| Tabs, *Retail only* (`:289-293`) | `ToggleRed.tga`, same states | Sprite | Same as the format toggle |
| Column headers and sort arrows (`:328-330`, `:755-759`) | 197/191/171; sorted gold; arrows `Arrow.tga` tinted | Code; generated sprite | Muted; sorted accent |
| Table header rule (`:339`) | 169/160/139 at 0.40 | Code | Muted at 0.30 |
| Column dividers, *Retail only* (`:341`, `:351`) | 110/117/110 at 0.4 and 0.3 | Code | Muted at 0.12 |
| Row zebra (`:771`) | White at 3/255 | Code | Unchanged |
| Row separator (`:349`) | 141/138/114 at 0.23 | Code | Muted at 0.10 |
| Row hover (`:392`) | 203/184/130 at 12/255 | Code | Accent at 12/255 |
| **Current character**: tint, bar, live dot, "Just now" (`:348`, `:352`, `:770`, `:788`) | 104/184/208 at 18/255; 104/202/232; `LiveDot.tga` 108/225/179; 156/194/176 | Code; generated sprite | **Unchanged** (information) |
| **Character name** (`:777`) | `RAID_CLASS_COLORS` | Blizzard | **Unchanged** (information) |
| Level (`:354`) | 196/184/154, 12.5 CIEDE2000 from the warrior color next to it | Code | Muted (14.6) |
| Realm, client, updated (`:355`, `:357`, `:359`) | 168/170/165, 167/171/165 | Code | Muted |
| Guild (`:356`) | 150/165/156 | Code | Faint |
| Played time (`:358`) | 238/225/187 | Code | Text |
| Empty message (`:408`) | 169/170/162 | Code | Muted |
| Keystone and week texts, *Retail only* (`:361-365`, `:620-624`) | Gold, 214/219/219, muted | Code | Accent, text, muted |
| Vault category labels, *Retail only* (`:375`) | 199/204/204 | Code | Muted |
| **Vault boxes, checks, `?`, stale alpha**, *Retail only* (`:381-386`, `:633-637`) | Edge 128/110/64 or unlocked 242/179/64; fill; `Check.tga`; `?` 169/170/162 | Code; generated sprite | **Unchanged** (information) |
| Scroll thumb (`:412-413`) | `WHITE8X8` tinted 140/128/97 at 0.9 | Blizzard texture, code tint | 128/104/72 at 0.9 |
| Scroll buttons, *Retail only* (`:417-422`) | `Toggle.tga` with arrows | Sprite | Ground, 1 px outline |
| Footer count, credits (`:424`, `:442-445`) | 166/166/155; 156/158/146 at 0.85 | Code | Muted; muted at 0.85 |
| **Heart** (`:444`) | `Heart.tga` `#A75466` | Generated sprite | **Unchanged** |
| Menu rows (`:433`, `:452`, `:464`, `:597`, `:761`) | 238/233/218 or 228/215/180; chosen realm and sort gold | Code | Text; chosen accent |
| Menu row hover (`:434`, `:453`, `:465`) | 187/161/102 at 37/255 | Code | Accent at 0.12 |
| Settings title (`:470`) | Gold 243/206/112 | Code | `NORMAL_FONT_COLOR` |
| Minimap checkbox (`:478-483`) | `UICheckButtonTemplate` | Blizzard template | Unchanged: Blizzard's template keeps its own look |
| Minimap label; size label and value; min/max (`:484-487`, `:522-523`) | 238/233/218; 215/201/157; 169/170/162 | Code | Text; muted; muted |
| Size slider track, fill (`:491-493`) | 131/119/89 around 39/38/31; fill 194/142/35 | Code | Control plate (ground, 1 px outline); accent fill inset by 1 px |
| Size slider thumb (`:494-496`) | `SilverThumb.tga` 10×18 | Sprite, Soundstone | Flat accent thumb |
| Reset, Deleted characters, Cancel (`:524`, `:527`, `:538`) | `Toggle.tga`; gold label | Sprite; code | Ground, 1 px outline, text label |
| Done, Delete (`:526`, `:539`) | `ToggleRed.tga`; gold label | Sprite; code | Primary: accent label and 2-unit accent underline |
| Delete dialog title, body (`:535-536`) | Gold; 238/233/218 | Code | `NORMAL_FONT_COLOR`; text |
| Progress tooltip title, lines, rules, *Retail only* (`:547-549`, `:719`) | Gold; 217/222/227; 153/128/71 at 0.7 | Code | Text; text, footer accent; muted at 0.18 |
| **Progress tooltip slot marks**, *Retail only* (`:710-717`) | Edge 128/110/64, fill 9/15/17, `Check.tga`, alpha 0.38 when stale | Code; generated sprite | **Unchanged** (information) |
| Game tooltip (`:96-103`) | Blizzard `GameTooltip`, lines 240/232/214 | Blizzard frame, code color | Unchanged (Forever's own tooltip); line color maps to text, about 1 CIEDE2000 away |
| Minimap button (`:869-886`) | Blizzard 136467 / 136430 / 136477 in Classic geometry, hidden by default since the Addons menu exists | Blizzard textures | Unchanged by the theme; see *Findings outside the theme* |
| Addons menu entry (`:849-858`) | Blizzard's menu with `Logo.tga` | Blizzard | Unchanged |
| Font (`:5`) | `STANDARD_TEXT_FONT` | Blizzard | Unchanged |

`RetailPanel`, `GoldThumb` and the Retail minimap geometry are the only differences in artwork between Retail and Classic (`C.RetailStyle()`, in 0.3.7 `UI.lua:246`, `:494-496`, `:873`); every color literal is shared by both. The *Retail only* elements come from `C.RetailProgress()`.

## Proposal

*The flat look as proposed and approved on 8 November 2026. Since the revision of 10 November 2026 it is the fallback where Forever's art is missing; the switch, `auto` and the theme row described here are gone, and the settings keep 0.3.7's height.*

### What changes, and what does not

On WoW: Forever, with the default `auto`, the window and every popover wear a flat near-black plate with an inner shadow and a one-pixel bronze line; controls become flat fields with a thin bronze outline; window titles take `NORMAL_FONT_COLOR`; interface text takes a warm white, a muted warm gray and a pale gold accent; the Soundstone sprites, rivets and the silver thumb are not shown.

What does **not** change, on any client:

- Information: class colors of names, the current character's tint, bar, dot and "Just now", Vault states and their stale alpha, the heart, the logo. A theme changes the interface, never the information.
- Geometry: sizes, positions, row heights, fonts, texts and behavior are those of 0.3.7. The only layout change is the theme row in the settings, on every client (see *Detection and the switch*): the settings grow by 44 units, and Reset, Done and Deleted characters move 44 units down. With one visible row the window is 262 units tall (294 on Retail), and the settings now hang below it, as the client and realm menus already do in 0.3.7; they are clamped to the screen.
- Blizzard-owned furniture: `GameTooltip`, `UICheckButtonTemplate`, the Addons menu and the minimap button art keep the client's own look.
- Retail, Mists, Anniversary and Classic Era with `auto`: every region keeps its exact 0.3.7 texture, color, alpha, texture coordinates and geometry, apart from the theme row, the three settings buttons below it and the settings' height. `tests/test_theme.py` compares them with 0.3.7 after hiding the row. The sheet's Retail column shows this version, with the row.

### Palette

| Key | Value | Used for | Origin |
| --- | --- | --- | --- |
| `surface` | 21/18/15 at 0.96 | Window, menus, settings, dialog, progress tooltip | **Umbra**, confirmed in game over two worlds. Deviates on purpose from Forever's translucent tooltip (navy, α ≈ 0.77) and plaque (α ≈ 0.6): eight rows of 10–13 pt text need a near-opaque ground; the warm hue follows the plaque, not the tooltip's navy |
| `lineTop` | 154/128/92 | Top line of every plate, 1 physical px | **Umbra** `rimTop`. Forever's own top line is brighter (`#E9CBA4` at full coverage); Umbra's darker value is kept so both addons draw the same bronze |
| `lineSide` | 128/104/72 | Left, right and bottom lines | **Umbra** `rimRight`, placed by **measurement**: Forever's tooltip is lit from the top, with left, right and bottom alike. Forever's own side color `#B48F61` is only 4.5 CIEDE2000 from the warrior and is not used. Deviates from Umbra's windows (one color on all four sides) and frames (lit from the top left, no left line) |
| `ramp` | Black at 0.95, 0.77, 0.54, 0.32, 0.18, one physical px each, inside the line | Plates | Alphas **measured** on Forever's tooltip at about 1.3 px per unit, where each step is one pixel (≈ 0.76 unit). One physical pixel per step at every Hourstone size is **assumed**. Replaces the flat `10/8/6` band |
| `ground` | 10/8/6 | Fill of buttons, dropdowns, the search field, the close square and the slider track | **Umbra** `border`, the fill of every Umbra control |
| `outline` | 104/80/52 | 1 px outline of buttons, dropdowns and the size slider's track | **Umbra** `rimBottom`; lies within the bronze rim of Forever's own "Filter" button (`#755B3B` top to `#53340C` bottom, 4.2 and 9.8 CIEDE2000 from those ends) |
| `fieldRing` | 166/160/148 at 0.35 | Search field | **Umbra** checkbox ring; tells the field apart from buttons |
| `text` | 240/233/218 | Labels, played time, menu rows, dialog body | **Umbra**; Hourstone's own 238/233/218 is less than 1 CIEDE2000 away. Forever's tooltip text is white; the warm white is kept for the hierarchy |
| `muted` | 166/160/148 | Secondary text, column headers, levels, realms, footer, `×` | **Umbra** |
| `faint` | `muted` at 0.75 | Guild line, search hint | **Assumed**: keeps today's third text level |
| `accent` | 240/204/140 | Summary values, sorted column, chosen and hover states, primary buttons, slider fill and thumb | **Umbra**, whose stated source is the minimap ring's lip and the plaque's corner. Measured here: the lip median `#E8C092` and the tooltips' top-right corners `#EFCCA0`/`#F0CDA0` lie 4.6–5.6 CIEDE2000 from the accent (red and green within 0–12, blue 6–20 higher than the accent's); the plaque's corner `#FCF5D4` is far paler (13.5) |
| `title` | `NORMAL_FONT_COLOR`, read at runtime; fallback 255/210/0 | The window title, the settings title, the delete dialog's title, nothing else | **Measured** `#FFD200`. It is a database color on every client (`Blizzard_SharedXMLBase/Color.lua`), so it is read, not copied |
| Rules | `muted` at 0.30, 0.18, 0.12, 0.10, one UI unit as in 0.3.7 | Header and table header; summary and progress tooltip; column dividers; row separators | **Umbra** rule (`muted` at 0.18; Umbra too keeps its rules in units); the other alphas are **assumed** and keep 0.3.7's order |
| `thumb` | 128/104/72 at 0.9 | Scroll thumb | **Assumed** |
| Hover | `accent` at 12/255 (rows), 0.12 (menus), 0.06 plus an accent label (controls) | | **Umbra** for the accent label only: Umbra has no hover fill, and its 0.12 tint marks the chosen segment. The menu and control fills are **assumed** (0.12 reuses that tint, 0.06 is half of it); the row alpha is today's |
| Chosen | `ground` with `accent` at 0.12, a 2-unit `accent` underline, `accent` label; unchosen `muted` | Format toggle, tabs, theme switch | **Umbra** segments |

Distance from the warrior color 198/155/109 (CIEDE2000, sRGB, D65, computed from the values): `lineTop` 11.2, `accent` 13.6, `muted` 14.6, `faint` 19.8 (over the surface), `lineSide` 20.5, `text` 22.7, `title` 22.8, `outline` 31.3. Every bronze, accent and muted value stays at least 11 away, so a warrior's name never reads as part of the frame. The level beside the name moves from 12.5 to 14.6. Across all classes, the closest pair is the priest's white to `text` (8.2; today's text is 8.1 from it), and `text` is the played time in the priest's own row, warm white beside white as today. Among the bronze, accent, muted and title values, the closest is the rogue to `title` (11.3), and titles never sit beside a name.

### Detection and the switch

*Superseded by the revision: the look follows the client (`forever` where `C.IsForever()` is true), there is no saved setting and no switch, and `M.Init` removes a value a development build saved.*

- **Detection:** `auto` picks `forever` when `C.IsForever()` is true, which tests the interface number (16000–16999) and does not depend on the project ID; it already holds for builds reporting `WOW_PROJECT_CAMELOT` and for earlier ones reporting Mainline. Everywhere else `auto` is `standard`, which is today's look: Retail sprites on Retail, Classic sprites on the Classic clients.
- **Saved setting:** `HourstoneDB.settings.theme` holds `auto`, `forever` or `standard`. `M.Init` turns a missing or unknown value into `auto`, without a schema change; releases up to 0.3.7 ignore the key, so a downgrade is safe. An update therefore changes Forever's look; the changelog says so, and `standard` brings 0.3.7's look back.
- **The switch:** `/hourstone theme` prints the setting and what `auto` resolves to; `/hourstone theme auto|forever|standard` sets it. The settings gain a three-way row, *Theme: Auto · Forever · Standard* (German *Thema*), which raises the settings from 214 to 258 units on every client, as the preview's middle column shows. A fixed theme without a switch would save the row, but take away the way back to 0.3.7's look and the means to check the Forever look on the other clients.

### Switching without `/reload`

*Since the revision only the tests apply a look after load (`U:ApplyTheme(name)`); the mechanism below stays, with `U:ApplyLook` in place of `U:ApplySkin`, and the flat plates are built the first time the forever look is applied.*

Following Umbra's proven pattern:

- `Hourstone/Theme.lua`, loaded after `Compat.lua` and before `UI.lua`, holds two palettes with the same keys. `standard` carries today's literals exactly, so `standard` draws 0.3.7's colors and art by construction; only the theme row differs. The live palette tables are rewritten in place, never replaced, because hover scripts read them when the pointer arrives.
- Every color painted at build time goes through `Th.Paint(region, key, method)`, which remembers the region in a weak-keyed table; information colors go through `Th.Raw`, which forgets the region. `Th.Apply(settings)` runs in `U:Init` before anything is built and again from `U:SetTheme` on every switch. It rewrites the palette, repaints every remembered region (each in `pcall`), shows one of the two skins on every plate and control, sizes the lines again and then calls `U:Refresh()`, which puts the chosen format and tab, the sorted column and sort row and the current character back after the repaint, and `U:RenderRealms()` when the realm menu is open, as Umbra learned the order must be.
- `skin()` builds both the nine-slice sprites and the flat plate once; the theme only shows one and hides the other, so a switch builds nothing. The rivets are shown or hidden the same way; the close sprite and its Blizzard highlight are muted by alpha, because a button shows and hides its own textures; the slider thumb, a single texture, has its art swapped by `U:ApplySkin`. A control remembers the pointer, so its accent hover label survives the Refresh that runs every second.
- Nothing involved is protected: the frames are Hourstone's own and not secure, so a switch works in combat as well. That has not been tried yet.

### One physical pixel

`U:ApplyScale` gives the window an effective scale of *min(size, fit) × 768 / physical height*, where fit keeps the window on the screen (`UI.lua:158-160`), and it divides out the UI scale. One UI unit is therefore *min(size, fit)* physical pixels at any UI scale: one pixel at 100 %, but 0.65 to 2 pixels between 65 % and 200 %, where a one-unit line renders one pixel in one place and two in the next. Every plate line, every control and field outline (the size slider's track included) and each step of the inner shadow are therefore one physical pixel. The low-alpha rules keep 0.3.7's one unit, as Umbra keeps its rules:

- Width `d = PixelUtil.GetPixelToUIUnitFactor() / region:GetEffectiveScale()`, which is `1 / min(size, fit)` for the window and every child. `GetPixelToUIUnitFactor` is `768 / physical height` on all five branches; where `PixelUtil` is missing, the same formula is used with `GetPhysicalScreenSize()`, which Hourstone already calls. Not `PixelUtil.GetNearestPixelSize(1, …)`, which rounds one UI unit and can give two pixels, and not `PixelUtil.SetSize`/`SetPoint`, which are marked deprecated on `live` and `forever`.
- The lines lie inside the plate's own edge, like the line on Forever's tooltip and Umbra's frame rims: every edge stays where the metrics put it, and nothing is drawn outside a frame that is clamped to the screen.
- `d` is measured again in `U:ApplyScale`, which already runs on `UI_SCALE_CHANGED` and `DISPLAY_SIZE_CHANGED` (`Core.lua:44`), after every size change and at the end of a size drag; a plate is placed again only when its pixel changes.
- The window is anchored at a saved center offset, so its edges can fall between pixels at sizes other than 100 %. Umbra saw exact one-pixel lines at arbitrary positions at 1.3125 and about 2.15 px per unit. If an in-game measurement shows a doubled or blurred line, `U:Position` rounds the offset to whole physical pixels under `forever` as a second step.

### Files and assets

| File | Change |
| --- | --- |
| `Hourstone/Theme.lua` (new), `Hourstone/Hourstone.toc` | Palettes, theme name, `Paint`, plates and lines, pixel size, `ApplyTheme`; one TOC line after `Compat.lua` (`tools/package.py` requires the TOC to list every top-level Lua file) |
| `Hourstone/UI.lua` | Color literals become palette keys; `skin()`, `control()`, `selected()`, `closeButton()`, the rivets, the slider and the thumb get their flat variant; `Th.Apply` in `U:Init`; `ApplyScale` sizes the lines; the theme row in the settings, which are clamped to the screen; `U:SetTheme`, `U:ThemeCommand`, `U:ApplySkin`, `U:SizeScaleFill` |
| `Hourstone/Model.lua` | Normalize `settings.theme` |
| `Hourstone/Core.lua` | `/hourstone theme` |
| `Hourstone/Locale.lua` | Theme row, choices and slash replies in English and German |
| `Hourstone/Compat.lua` | Only a comment: `RetailStyle()` keeps choosing the sprite set under `standard` |
| `tests/wow_mock.lua` | `PixelUtil.GetPixelToUIUnitFactor`, `NORMAL_FONT_COLOR` (with `GetRGB`) and `GetHighlightTexture`, used to mute the close sprite's highlight |
| `tests/test_theme.lua`, `tests/test_theme.py` (new) | See the test plan |
| `tests/test_compartment.lua`, `tests/test_ui.lua`, `tests/test_layout.py`, `tests/fixtures/layout/adjustments.json` | Forever's `SilverThumb` pin moves under `standard`; the slider fill's width follows its inset; the settings height (214 → 258) and the Reset and Done positions (44 units lower) |
| `tools/preview.py` | `render()` takes `interface`, `after`, `read` (another build's files) and `raw` (every visible region as data, for the identity test); `--forever-theme` writes `forever-theme-preview.html` and `forever-theme-preview-detail.html` to `dist/design`, the first column from `v0.3.7` |
| `README.md`, `docs/DEUTSCH.md`, `docs/VALIDATION.md`, `docs/curseforge/description.md`, `CHANGELOG.md` | They stated that Forever keeps the Classic design; now they describe the theme and the switch, and the changelog has an *Unreleased* entry |
| `docs/ARTWORK.md` | The flat Forever skin, drawn in code, beside the Soundstone sprites |

**No new sprites.** Every surface, line and outline is a `SetColorTexture` region and the close button is the `×` glyph the search field already uses. A sprite would scale with Hourstone's size and blur the one-pixel line; drawn in code it stays exact at every size. `tools/assets.py`, the Soundstone manifest and the package's TGA table do not change.

### Risks

1. **A literal missed.** One color left outside the palette shows the old look inside the new one. A test walks every visible region under `forever` and allows only palette values and the listed information colors.
2. **The standard look drifts.** A test renders every region under `standard` on Retail, Mists, Anniversary, Classic Era and Forever, and under `auto` on the four others, and compares texture, color, alpha, texture coordinates and geometry with tag `v0.3.7`, allowing only the theme row and the three settings buttons below it (the runtime already loads older releases' files for the protocol tests).
3. **Lines between pixels** at sizes other than 100 %; see *One physical pixel*.
4. **Forever's language for windows is ambiguous.** Its tooltips and HUD are flat bronze, its own windows are metal frames with a red close button. The proposal follows the HUD and Umbra; Blizzard's windows on Forever will look different from Hourstone's.
5. **Forever's art changes.** The palette is fixed in code and does not follow a later art pass; the values were taken from screenshots of 7 and 8 November 2026.
6. **Blizzard furniture inside a flat window.** The `UICheckButtonTemplate` box is Forever's own art and has not been seen next to the flat plate.
7. **Soundstone diverges.** Soundstone has no Forever theme and draws the same Classic sprites; on Forever, its bar and Hourstone's window would no longer match.
8. **Update surprise.** Existing Forever installs change look with the update; the changelog and the README say so and name `/hourstone theme standard`.
9. **Combat and instances.** Switching changes only colors and visibility of Hourstone's own regions and should work anywhere; it has not been tried in combat or in an instance.

### Seen in the game

WoW: Forever, 9 November 2026, measured with Pillow on six lossless screenshots at 135 % Hourstone size, where one UI unit is 1.35 physical pixels. The window was switched between *Standard*, *Forever* and *Auto* in the settings; the switch was reported working, and every state appears in the screenshots.

| Measured | Result |
| --- | --- |
| Top line | One pixel of exactly 154/128/92, 972 px long: 720 units × 1.35 |
| Left, right and bottom lines | One pixel each of exactly 128/104/72, along the full height |
| Inner shadow | 1/1/1, 5/4/4, 10/9/7, 15/13/10, 18/15/12 against the plate's 23/19/15, one pixel per step: ratios 0.04, 0.22, 0.43, 0.65, 0.78, against Forever's tooltip 0.05, 0.23, 0.46, 0.68, 0.82 |
| Surface | 23/19/15 over the dark interior, as 21/18/15 at 0.96 over the world gives |
| Window titles | Exactly 255/210/0: the client's `NORMAL_FONT_COLOR` on Forever is `#FFD200` |
| Control outlines | One pixel of 104/80/52; the size slider's track has one pixel of outline above and below its 10/8/6 ground. The format toggles end half a unit above the dropdowns beside them, as in 0.3.7, so their bottom lines fall on neighboring rows |
| `standard` | Soundstone's Classic sprites, with the theme row in the settings drawn as red toggles |
| Game tooltip | Forever's own tooltip with Hourstone's lines over the flat window |

Not checked yet: Retail, Mists, the Anniversary realms and Classic Era; 100 % Hourstone size; a change of UI scale or resolution while the window is open; the hover label across a Refresh; a switch in combat.

### Test plan

**Automated** (`tests/test_theme.lua` in all seven configurations of `tests/run.py`, and `tests/test_theme.py`; both pass): palette closure under `forever`, with information colors tied to the regions that carry them, recorded Vault progress included and also after a repaint without a Refresh; the settings clamped to the screen; the forever palette pinned key by key, the line colors per side and the ramp's alphas; identity with `v0.3.7`, apart from the theme row, under `standard` and under `auto` outside Forever; line width equal to one physical pixel and every line anchored inside the edge, on every plate at 65, 100, 135 and 200 % on three screen heights and three UI scales, and when only `UI_SCALE_CHANGED` or `DISPLAY_SIZE_CHANGED` reports a change; a saved theme applied at load; `/hourstone theme` before the window exists; switching `forever → standard → auto → forever` with the settings, each menu, the dialog and Retail's progress tooltip open, without building any frame; chosen, primary, plain and sorted states after a switch; the hover label across a Refresh; the warrior rule (at least 11 CIEDE2000); `NORMAL_FONT_COLOR` read at runtime and the fallback without it; `PixelUtil` missing; settings normalization and the slash command.

**In the game,** each step on a lossless PNG screenshot measured with Pillow, at 100 % Hourstone size and at a size that is not a whole number, such as 135 %. Hourstone's window divides out the UI scale, so its own pixels depend on its size; the UI scale matters for Blizzard's art beside it:

| Client | Measured |
| --- | --- |
| Retail 120105 | `auto`: the window, menus, dialog and progress view match 0.3.7 pixel for pixel at the same position, size and data, and so do the settings apart from the theme row. `forever`: each line one pixel wide, top 154/128/92, other sides 128/104/72; ramp ratios; title equal to a Blizzard `NORMAL_FONT_COLOR` label on screen; progress view and its tooltip in the plate. Back to `auto`: identical to the first capture |
| WoW: Forever 16001 | `auto` is `forever`, at a fractional UI scale and at one with exactly 2.0 px per unit for Blizzard's art; Hourstone's own pixels follow its size. Line width and colors on all four sides at three window positions; ramp; surface over a dark and a bright world (expected 0.96 composites); title `#FFD200`; a warrior's name color unchanged next to the bronze; the `UICheckButtonTemplate` box next to the plate. Lines measured again after a UI-scale change and a window resize. `standard` matches a 0.3.7 capture apart from the theme row. Switching with the settings open, and once in combat |
| Mists 50504, Anniversary 20506, Classic Era 11509 | `auto` matches 0.3.7 pixel for pixel, apart from the theme row. `forever`: one-pixel lines and the palette, which also exercises `PixelUtil` there. Back to `auto` |

## Findings outside the theme

- **No Retail behavior is lost on Forever.** `C.Retail()` already counts `WOW_PROJECT_CAMELOT` and any project on a 16xxx interface. `RetailStyle()` false is the look this plan changes; `RetailProgress()` false is right for keystones: Blizzard's own `Blizzard_ChallengesUI` is limited to `standard, mists` and does not load on Forever. `Blizzard_WeeklyRewards` still ships without a game-type gate on the `forever` branch, so the Great Vault's absence rests on the game, not on the source, and has not been checked in the client.
- **The minimap button probably uses the wrong geometry on Forever.** Hourstone picks the Classic offsets for Blizzard's `MiniMap-TrackingBorder` because `RetailStyle()` is false, but Forever's minimap is the Mainline one with Forever overrides (`Blizzard_Minimap`, `[Family]` Mainline plus `[Game]` Camelot), and LibDBIcon 1.0 version 57 now gives Forever the Retail geometry by asking whether `AddonCompartmentFrame` exists. Keying the geometry on `C.HasAddonCompartment()` would change only Forever. Not verified in the game; the button is hidden by default on Forever since the Addons menu exists. A separate fix, not part of the theme. Soundstone has the same switch.
- **The client filter never marks the chosen client**, while the realm and sort menus mark theirs in gold. Not part of the theme.

## Open questions

The plan was approved as proposed on 8 November 2026, which settled the first five:

1. **Which language for a window?** The flat bronze of Forever's tooltips, HUD and Umbra. *Decided.*
2. **Switch:** slash command and a settings row, with `auto`, `forever` and `standard`. *Decided; reversed on 10 November 2026 by the revision: no switch.*
3. **Line colors:** Umbra's darker bronze. *Decided.*
4. **Inner shadow:** the measured five-pixel ramp. *Decided.*
5. **Close button:** the flat `×`. *Decided.*
6. **Should Soundstone follow** with the same palette, so both addons match on Forever? *Settled by Soundstone 0.4.0, which wears Forever's own frame; Hourstone follows it (see the revision).*
7. **The minimap geometry finding:** fix it separately, here and in Soundstone? *Open.*
8. **The preview images** (2.5 MB and 3.6 MB) and the preview tooling: commit them, or keep them local like the approved Progress mockup in `dist/design`? *Decided on 10 November 2026: the images stay local; the tooling stays in `tools/preview.py`.*

**Still to capture on Forever,** each as a lossless PNG:

1. Hourstone 0.3.7 itself over a plain dark background, at 100 % and at 135 % Hourstone size: the window; the settings open; the client menu open with one row hovered; the delete dialog. No Forever screenshot shows Hourstone yet, so today's look exists only as the preview.
2. Hourstone's minimap button (`/hourstone minimap`) beside a LibDBIcon button such as Questie's, for the geometry finding.
3. A Forever checkbox unchecked, checked and hovered (*Options › Game*), and the slider with its thumb (*Options › Audio*, master volume). For items 3 to 5, once at a fractional UI scale and once at a UI scale with exactly 2.0 px per unit, so Blizzard's one-unit lines land on whole pixels.
4. A Forever edit box empty and focused (the AddOn list's search), and an open dropdown menu with one row hovered.
