local _, H = ...
-- Looks. Two sets of colors for Hourstone's window and two skins for its surfaces, chosen by the
-- client, not by the player. `standard` is the look every release has worn: Soundstone's Retail or
-- Classic sprites and the colors below, which are the literals of 0.3.7. `forever` is WoW: Forever's
-- own look, on the Forever client only: the windows wear the client's bronze window frame, as
-- Forever's own windows and Soundstone 0.4.0 do, and the menus, dropdown buttons, push buttons and
-- the slider the client's own art. Where a piece of that art is missing, the flat look stands in,
-- piece by piece: a near-black plate with an inner shadow and a one-pixel bronze line, flat controls
-- with a bronze outline, NORMAL_FONT_COLOR on window titles only.
--
-- A look changes the interface, never the information: class colors, the current character's
-- marker, Vault states and the heart are painted outside this file.
-- The values and their origins are in docs/FOREVER-THEME.md.
local Th = {}
H.Theme = Th

local function rgb(r, g, b, a) return {r / 255, g / 255, b / 255, a or 1} end
local function rel(r, g, b, a) return {r, g, b, a or 1} end
local GOLD, MUTED = rgb(243, 206, 112), rgb(169, 170, 162)

-- Keys only the forever look draws: the flat skin, the symbols on the red header buttons (gold, as
-- Baganator's and Soundstone's on Forever), the fill over Forever's slider track (Soundstone's) and
-- the shade that darkens the rock under the table to 45 %.
-- `standard` carries them too, so every table exists from the start and applying a look leaves
-- nothing of the other palette behind.
local SHARED = {
    surface = rgb(21, 18, 15, .96), ground = rgb(10, 8, 6),
    lineTop = rgb(154, 128, 92), lineSide = rgb(128, 104, 72), outline = rgb(104, 80, 52),
    fieldRing = rgb(166, 160, 148, .35), tint = rgb(240, 204, 140, .12), underline = rgb(240, 204, 140),
    hover = rgb(240, 204, 140), buttonIcon = rgb(255, 230, 128), trackFill = rgb(255, 176, 33),
    insetShade = rgb(0, 0, 0, .55),
}

local standard = {
    text = rgb(238, 233, 218), title = rgb(255, 213, 116), heading = GOLD, tipTitle = GOLD, value = GOLD,
    label = GOLD, primaryLabel = GOLD, chosenLabel = rgb(255, 227, 156), unchosenLabel = rgb(184, 175, 160),
    muted = MUTED, statLabel = rgb(196, 192, 178), header = rgb(197, 191, 171), level = rgb(196, 184, 154),
    secondary = rgb(168, 170, 165), updated = rgb(167, 171, 165), guild = rgb(150, 165, 156), played = rgb(238, 225, 187),
    footer = rgb(166, 166, 155), credit = rgb(156, 158, 146, .85), searchText = rgb(231, 225, 206), hint = rel(.56, .55, .51),
    menuText = rgb(228, 215, 180), settingsLabel = rgb(215, 201, 157), tipText = rel(.85, .87, .89), vaultLabel = rel(.78, .8, .8),
    noKey = rel(.84, .86, .86), tooltipText = rel(.94, .91, .84), arrow = rgb(197, 191, 171),
    gear = rel(.9, .8, .57), gearHover = rel(1, 1, 1),
    ruleHeader = rgb(166, 162, 148, 128 / 255), ruleSummary = rgb(146, 137, 120, 66 / 255), ruleSummaryBottom = rgb(150, 144, 128, 66 / 255),
    ruleTable = rgb(169, 160, 139, 101 / 255), ruleColumnHeader = rel(.43, .46, .43, .4), ruleColumn = rel(.43, .46, .43, .3),
    ruleRow = rgb(141, 138, 114, 59 / 255), tipRule = rel(.6, .5, .28, .7), scrollThumb = rel(.55, .5, .38, .9),
    sliderEdge = rgb(131, 119, 89), sliderTrack = rgb(39, 38, 31), sliderFill = rgb(194, 142, 35), sliderThumb = rel(1, 1, 1),
    hoverRow = rgb(203, 184, 130, 12 / 255), hoverMenu = rgb(187, 161, 102, 37 / 255), hoverControl = rel(1, .9, .6, .12),
}

-- WoW: Forever. Surface, lines, ground, outline, text, muted and accent are Umbra
-- Unit Frames 0.9's palette; the line runs lit from the top, as Forever's tooltip
-- measures; the ramp's alphas are measured. Every bronze, accent and muted value stays
-- at least 11 CIEDE2000 from the warrior's 198/155/109, so a warrior's name never
-- reads as part of the frame.
local TEXT, MUTE, ACCENT = rgb(240, 233, 218), rgb(166, 160, 148), rgb(240, 204, 140)
local function dim(alpha) return {MUTE[1], MUTE[2], MUTE[3], alpha} end
local forever = {
    text = TEXT, title = rgb(255, 210, 0), heading = rgb(255, 210, 0), tipTitle = TEXT, value = ACCENT,
    label = TEXT, primaryLabel = ACCENT, chosenLabel = ACCENT, unchosenLabel = MUTE,
    muted = MUTE, statLabel = MUTE, header = MUTE, level = MUTE,
    secondary = MUTE, updated = MUTE, guild = dim(.75), played = TEXT,
    footer = MUTE, credit = dim(.85), searchText = TEXT, hint = dim(.75),
    menuText = TEXT, settingsLabel = MUTE, tipText = TEXT, vaultLabel = MUTE,
    noKey = TEXT, tooltipText = TEXT, arrow = MUTE,
    gear = MUTE, gearHover = ACCENT,
    ruleHeader = dim(.30), ruleSummary = dim(.18), ruleSummaryBottom = dim(.18),
    ruleTable = dim(.30), ruleColumnHeader = dim(.12), ruleColumn = dim(.12),
    ruleRow = dim(.10), tipRule = dim(.18), scrollThumb = rgb(128, 104, 72, .9),
    sliderEdge = SHARED.outline, sliderTrack = SHARED.ground, sliderFill = ACCENT, sliderThumb = ACCENT,
    hoverRow = rgb(240, 204, 140, 12 / 255), hoverMenu = rgb(240, 204, 140, .12), hoverControl = rgb(240, 204, 140, .06),
}
for key, color in pairs(SHARED) do standard[key] = color; forever[key] = color end
Th.palettes = {standard = standard, forever = forever}

-- The live palette. Rewritten in place, never replaced: regions, hover scripts and
-- state code keep these tables and read them when they need a color.
Th.colors = {}
for key, color in pairs(standard) do Th.colors[key] = {color[1], color[2], color[3], color[4]} end
Th.name, Th.flat, Th.art = "standard", false, {}

function Th.Color(key) local c = Th.colors[key]; return c[1], c[2], c[3], c[4] end

-- The look of this client: `forever` on WoW: Forever, `standard` everywhere else.
function Th.Name() return H.C.IsForever() and "forever" or "standard" end

-- Forever's own art. Other clients ship other art under some of these names (Mists, the
-- Anniversary realms and Era draw ButtonFrameTemplateNoPortrait with their own border), so it is
-- used on the Forever client only. `UI-Background-Rock` is a file and cannot be checked; it goes with
-- the frame, as in Blizzard's own template. The inset takes the frame's rock instead of its marble.
Th.ART = {
    window = {layout = "ButtonFrameTemplateNoPortrait", ground = "Interface\\FrameGeneral\\UI-Background-Rock",
        close = {normal = "RedButton-Exit", pushed = "RedButton-exit-pressed", highlight = "RedButton-Highlight"}},
    streaks = "_UI-Frame-TopTileStreaks",
    inset = {layout = "InsetFrameTemplate"},
    menu = "common-dropdown-bg",
    dropdown = {field = "common-dropdown-textholder", normal = "common-dropdown-a-button", hover = "common-dropdown-a-button-hover",
        pressed = "common-dropdown-a-button-pressed", pressedHover = "common-dropdown-a-button-pressedhover",
        open = "common-dropdown-a-button-open"},
    track = {left = "Minimal_SliderBar_Left", middle = "_Minimal_SliderBar_Middle", right = "Minimal_SliderBar_Right"},
    thumb = "Minimal_SliderBar_Button",
}
function Th.AtlasInfo(name)
    if type(C_Texture) ~= "table" or type(C_Texture.GetAtlasInfo) ~= "function" then return nil end
    local ok, info = pcall(C_Texture.GetAtlasInfo, name)
    return ok and type(info) == "table" and info or nil
end
local function knownAll(list)
    for _, name in pairs(list) do if not Th.AtlasInfo(name) then return false end end
    return true
end
-- A nine-slice layout the client can draw: NineSliceUtil, the layout and the atlas of every piece.
local function layout(name)
    local util, layouts = NineSliceUtil, NineSliceLayouts
    if type(util) ~= "table" or type(util.ApplyLayoutByName) ~= "function" or type(layouts) ~= "table" then return false end
    local pieces = layouts[name]
    if type(pieces) ~= "table" then return false end
    for _, piece in pairs(pieces) do
        if type(piece) == "table" and piece.atlas and not Th.AtlasInfo(piece.atlas) then return false end
    end
    return true
end
-- Which of Forever's pieces the client can draw, on the Forever client only; elsewhere none.
-- Each group falls back to the flat look on its own. The streaks and the inset belong to the
-- frame: without the frame, the window wears the flat plate and neither.
function Th.Art()
    local art, A = {}, Th.ART
    if not H.C.IsForever() then return art end
    art.window = layout(A.window.layout) and knownAll(A.window.close)
    art.streaks = art.window and Th.AtlasInfo(A.streaks) ~= nil
    art.inset = art.window and layout(A.inset.layout)
    art.menu = Th.AtlasInfo(A.menu) ~= nil
    art.dropdown = knownAll(A.dropdown)
    art.track = knownAll(A.track)
    art.thumb = Th.AtlasInfo(A.thumb) ~= nil
    return art
end

-- NORMAL_FONT_COLOR is a client database color on every client, so it is read rather
-- than copied. Forever measures #FFD200; that is the fallback.
local function normalFont()
    local color = NORMAL_FONT_COLOR
    if type(color) == "table" and type(color.GetRGB) == "function" then
        local ok, r, g, b = pcall(color.GetRGB, color)
        if ok and type(r) == "number" and type(g) == "number" and type(b) == "number" then return r, g, b end
    end
    return 1, 210 / 255, 0
end

-- Paint(region, key, method, alpha) paints a region from the palette and remembers
-- it, so applying a look can paint it again. The last call for a region wins. `method`
-- is "text" for FontStrings and EditBoxes, "vertex" for textures that carry art of
-- their own, and nil for color textures. Raw(...) paints a color from outside the
-- palette and forgets the region, so a repaint never covers information.
local painted = setmetatable({}, {__mode = "k"})
local function apply(region, entry)
    local c = Th.colors[entry.key]
    local r, g, b, a = c[1], c[2], c[3], entry.alpha or c[4]
    if entry.method == "text" then region:SetTextColor(r, g, b, a)
    elseif entry.method == "vertex" then region:SetVertexColor(r, g, b, a)
    else region:SetColorTexture(r, g, b, a) end
end
function Th.Paint(region, key, method, alpha)
    local entry = {key = key, method = method, alpha = alpha}
    painted[region] = entry; apply(region, entry)
    return region
end
function Th.Raw(region, method, r, g, b, a)
    painted[region] = nil
    if method == "text" then region:SetTextColor(r, g, b, a)
    elseif method == "vertex" then region:SetVertexColor(r, g, b, a)
    else region:SetColorTexture(r, g, b, a) end
    return region
end

-- One physical pixel in a region's own units. Hourstone's window divides out the UI
-- scale, so this is 1 / its size there. PixelUtil.GetPixelToUIUnitFactor() is
-- 768 / physical height on every client; the same formula stands in without it.
function Th.Pixel(region)
    local util = type(PixelUtil) == "table" and PixelUtil
    local factor = util and type(util.GetPixelToUIUnitFactor) == "function" and util.GetPixelToUIUnitFactor()
    if type(factor) ~= "number" or factor <= 0 then
        local _, height = GetPhysicalScreenSize()
        factor = type(height) == "number" and height > 0 and 768 / height or nil
    end
    local scale = region:GetEffectiveScale()
    if not factor or type(scale) ~= "number" or scale <= 0 then return 1 end
    return factor / scale
end

-- Plates are the flat skin of a surface. "panel": surface, the inner black ramp and
-- the bronze line, lit from the top, as Forever's tooltip is. "control": ground and a
-- one-pixel outline, plus the chosen tint and the accent underline. "field": ground
-- and a muted ring. "square": ground only. Every line lies inside the frame's own edge.
-- Sprites are the standard skin; each set is shown only under its own look. A plate is
-- registered on every client, but its regions are created only the first time the forever
-- look is applied, so they never exist on the other clients. A plate is covered where
-- Forever's own art takes its surface.
local RAMP = {.95, .77, .54, .32, .18}
local SIDES = {"top", "left", "right", "bottom"}
local LINES = {
    panel = {top = "lineTop", left = "lineSide", right = "lineSide", bottom = "lineSide"},
    control = {top = "outline", left = "outline", right = "outline", bottom = "outline"},
    field = {top = "fieldRing", left = "fieldRing", right = "fieldRing", bottom = "fieldRing"},
}
local plates, sprites, flats, muted, pending = {}, {}, {}, {}, {}
local built = false
Th.plates = plates

local function span(t, frame, p1, x1, y1, p2, x2, y2)
    t:ClearAllPoints(); t:SetPoint(p1, frame, p1, x1, y1); t:SetPoint(p2, frame, p2, x2, y2)
end
-- Anchored to both ends, the lines follow every change of size on their own; they
-- are placed again only when the pixel itself changes.
local function size(plate)
    if not plate.built then return end
    local f, d = plate.anchor, Th.Pixel(plate.frame)
    if plate.d == d then return end
    plate.d = d
    local lines = plate.lines
    if lines then
        span(lines.top, f, "TOPLEFT", 0, 0, "TOPRIGHT", 0, 0); lines.top:SetHeight(d)
        span(lines.bottom, f, "BOTTOMLEFT", 0, 0, "BOTTOMRIGHT", 0, 0); lines.bottom:SetHeight(d)
        span(lines.left, f, "TOPLEFT", 0, -d, "BOTTOMLEFT", 0, d); lines.left:SetWidth(d)
        span(lines.right, f, "TOPRIGHT", 0, -d, "BOTTOMRIGHT", 0, d); lines.right:SetWidth(d)
    end
    for i, strip in ipairs(plate.ramp) do
        local o = i * d
        span(strip.top, f, "TOPLEFT", o, -o, "TOPRIGHT", -o, -o); strip.top:SetHeight(d)
        span(strip.bottom, f, "BOTTOMLEFT", o, o, "BOTTOMRIGHT", -o, o); strip.bottom:SetHeight(d)
        span(strip.left, f, "TOPLEFT", o, -o - d, "BOTTOMLEFT", o, o + d); strip.left:SetWidth(d)
        span(strip.right, f, "TOPRIGHT", -o, -o - d, "BOTTOMRIGHT", -o, o + d); strip.right:SetWidth(d)
    end
    if plate.tint then span(plate.tint, f, "TOPLEFT", d, -d, "BOTTOMRIGHT", -d, d) end
    if plate.underline then span(plate.underline, f, "BOTTOMLEFT", d, d, "BOTTOMRIGHT", -d, d); plate.underline:SetHeight(2) end
end
local function texture(plate, layer, key)
    local t = plate.frame:CreateTexture(nil, layer)
    if key then Th.Paint(t, key) end
    plate.textures[#plate.textures + 1] = t
    return t
end
local function build(plate)
    if plate.built then return end
    plate.built = true
    local kind = plate.kind
    local fill = texture(plate, "BACKGROUND", kind == "panel" and "surface" or "ground"); fill:SetAllPoints(plate.anchor)
    if kind == "panel" then
        for i, alpha in ipairs(RAMP) do
            local strip = {}
            for _, side in ipairs(SIDES) do strip[side] = texture(plate, "BORDER"); strip[side]:SetColorTexture(0, 0, 0, alpha) end
            plate.ramp[i] = strip
        end
    end
    if LINES[kind] then
        plate.lines = {}
        for _, side in ipairs(SIDES) do plate.lines[side] = texture(plate, "BORDER", LINES[kind][side]) end
    end
    if kind == "control" then
        plate.tint = Th.Paint(plate.frame:CreateTexture(nil, "BORDER"), "tint")
        plate.underline = Th.Paint(plate.frame:CreateTexture(nil, "ARTWORK"), "underline")
    end
    size(plate)
end
local function show(plate)
    local flat = Th.flat and not plate.covered
    for _, t in ipairs(plate.textures) do t:SetShown(flat) end
    for _, t in ipairs(plate.sprites) do t:SetShown(not Th.flat) end
    if plate.tint then
        local owner = plate.frame
        plate.tint:SetShown(flat and owner.chosen == true)
        plate.underline:SetShown(flat and (owner.chosen == true or owner.primary == true))
    end
end

-- Plate(frame, kind, sprites, anchor): the flat skin for `frame`, beside its sprite
-- textures. Its regions belong to `frame` and cover `anchor` (a region of it), or all of it.
function Th.Plate(frame, kind, spriteTextures, anchor)
    local plate = {frame = frame, anchor = anchor or frame, kind = kind, textures = {}, ramp = {}, sprites = spriteTextures or {}}
    frame.plate = plate; plates[#plates + 1] = plate
    if built then build(plate) end
    show(plate)
    return plate
end
-- State textures of a control (chosen tint, underline) after its state changed.
function Th.Update(frame) if frame.plate then show(frame.plate) end end
-- Cover(frame, covered): Forever's own art takes the surface of `frame`; its plate hides.
function Th.Cover(frame, covered)
    local plate = frame.plate
    if plate then plate.covered = covered and true or nil; show(plate) end
end
-- Regions drawn only by one skin. A button's own normal and highlight textures are
-- muted by alpha instead, because the button shows and hides those itself.
function Th.Sprite(region) sprites[#sprites + 1] = region; region:SetShown(not Th.flat); return region end
function Th.Flat(region) flats[#flats + 1] = region; region:SetShown(Th.flat); return region end
function Th.Mute(region) muted[#muted + 1] = region; region:SetAlpha(Th.flat and 0 or 1); return region end
-- Later(build): builds pieces of the forever look the first time it is applied, or now if it was.
function Th.Later(fn) if built then fn() else pending[#pending + 1] = fn end end
-- Whether the forever look's pieces exist (it was applied at least once).
function Th.Built() return built end

-- Measures every plate again: after a change of size, UI scale or resolution.
function Th.SizeAll() for _, plate in ipairs(plates) do size(plate) end end

-- Apply(name) applies a look, the client's by default: rewrites the palette in place,
-- builds the forever look's pieces the first time, paints every remembered region again
-- (one refusal does not stop the rest) and shows each skin under its own look. The caller
-- shows Forever's art and puts state colors back afterwards (UI's ApplyLook and Refresh),
-- as the order requires.
function Th.Apply(name)
    if not Th.palettes[name] then name = Th.Name() end
    local palette = Th.palettes[name]
    Th.name, Th.flat = name, name == "forever"
    Th.art = Th.flat and Th.Art() or {}
    for key, from in pairs(palette) do
        local into = Th.colors[key]
        into[1], into[2], into[3], into[4] = from[1], from[2], from[3], from[4]
    end
    if Th.flat then
        local r, g, b = normalFont()
        for _, key in ipairs({"title", "heading"}) do local c = Th.colors[key]; c[1], c[2], c[3], c[4] = r, g, b, 1 end
        if not built then
            built = true
            for _, plate in ipairs(plates) do build(plate) end
            local queue = pending; pending = {}
            for _, fn in ipairs(queue) do fn() end
        end
    end
    for region, entry in pairs(painted) do pcall(apply, region, entry) end
    for _, plate in ipairs(plates) do show(plate) end
    for _, region in ipairs(sprites) do region:SetShown(not Th.flat) end
    for _, region in ipairs(flats) do region:SetShown(Th.flat) end
    for _, region in ipairs(muted) do region:SetAlpha(Th.flat and 0 or 1) end
    return name
end
