local _, H = ...
local de = GetLocale() == "deDE"
H.de = de
local en = {
    tagline = "Your characters. Your time.", total = "Total playtime", characters = "Characters",
    session = "Current session", allTracked = "All tracked characters", character = "Character",
    level = "Level", realm = "Realm", played = "Playtime", updated = "Updated",
    allRealms = "All realms", search = "Search character…", combined = "Days + hours", hours = "Hours",
    unavailable = "Not yet available", daysUnit = "d", hoursUnit = "hr", minutesUnit = "min",
    now = "Now", minuteAgo = "%d min ago", hourAgo = "%d hr ago", dayAgo = "%d d ago",
    visible = "%d / %d characters · Visible: %s", partial = " (%d without playtime)",
    hint = "Other characters appear after their first login with Hourstone.",
    empty = "No matching characters.", settings = "Settings", minimap = "Minimap button",
    on = "On", off = "Off", scale = "Window scale", reset = "Reset position", done = "Done",
    density = "Row spacing", comfortable = "Normal", compact = "Compact", realms = "%d realms",
    open = "Left click: open / close", move = "Drag: move minimap button", commands = "/hourstone or /azerothhours",
    active = "Current character", estimate = "Counted locally since the last known value.",
    sync = "Last server sync: %s", noSync = "Waiting for the server's /played value.",
    known = "Last known value; this character is offline.", fullTime = "Total: %s",
    request = "Sync requested", requestWait = "Sync queued (60-second request interval)",
    futureDB = "Hourstone: saved data is from a newer addon version. Please update Hourstone.",
}
local german = {
    tagline = "Deine Charaktere. Deine Spielzeit.", total = "Gesamte Spielzeit", characters = "Charaktere",
    session = "Aktuelle Sitzung", allTracked = "Alle erfassten Charaktere", character = "Charakter",
    level = "Level", realm = "Realm", played = "Spielzeit", updated = "Aktualisiert",
    allRealms = "Alle Realms", search = "Charakter suchen…", combined = "Tage + Std.", hours = "Stunden",
    unavailable = "Noch nicht verfügbar", daysUnit = "T.", hoursUnit = "Std.", minutesUnit = "Min.",
    now = "Jetzt", minuteAgo = "vor %d Min.", hourAgo = "vor %d Std.", dayAgo = "vor %d T.",
    visible = "%d / %d Charaktere · Sichtbar: %s", partial = " (%d ohne Spielzeit)",
    hint = "Weitere Charaktere erscheinen nach dem ersten Login mit Hourstone.",
    empty = "Keine passenden Charaktere.", settings = "Einstellungen", minimap = "Minimap-Button",
    on = "An", off = "Aus", scale = "Fensterskalierung", reset = "Position zurücksetzen", done = "Fertig",
    density = "Zeilenabstand", comfortable = "Normal", compact = "Kompakt", realms = "%d Realms",
    open = "Linksklick: öffnen / schließen", move = "Ziehen: Minimap-Button verschieben", commands = "/hourstone oder /azerothhours",
    active = "Aktueller Charakter", estimate = "Seit dem letzten bekannten Wert lokal weitergezählt.",
    sync = "Letzter Serverabgleich: %s", noSync = "Warte auf den /played-Wert des Servers.",
    known = "Letzter bekannter Stand; dieser Charakter ist offline.", fullTime = "Gesamt: %s",
    request = "Abgleich angefragt", requestWait = "Abgleich vorgemerkt (60 Sekunden Anfrageabstand)",
    futureDB = "Hourstone: Die gespeicherten Daten stammen aus einer neueren Addon-Version. Bitte Hourstone aktualisieren.",
}
H.L = setmetatable(de and german or en, { __index = en })
