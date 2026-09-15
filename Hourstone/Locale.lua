local _, H = ...
local de = GetLocale() == "deDE"
H.de = de
local en = {
    tagline = "Your characters. Your time.", total = "Total time played", characters = "Characters",
    session = "Current session", allTracked = "All tracked characters", character = "Character",
    level = "Level", realm = "Realm", played = "Time played", updated = "Updated",
    allRealms = "All realms", search = "Search characters …", combined = "Days + hrs", hours = "Hours",
    unavailable = "Not yet available", daysUnit = "d", hoursUnit = "hrs", minutesUnit = "min",
    now = "Just now", minuteAgo = "%d min ago", hourAgo = "%d hr ago", dayAgo = "%d days ago", yesterday = "Yesterday",
    shown = "%d / %d characters shown", filteredTime = "Filtered: %s", oneRealm = "1 realm",
    visible = "%d / %d characters · Visible: %s", partial = " (%d without playtime)",
    hint = "Other characters appear after their first login with Hourstone.",
    name = "Name", noCharacters = "No characters tracked yet.", empty = "No matching characters.", settings = "Settings", minimap = "Show minimap button",
    on = "On", off = "Off", scale = "Hourstone size", reset = "Reset position", done = "Done",
    realms = "%d realms",
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
    allRealms = "Alle Realms", search = "Charakter suchen …", combined = "Tage + Std.", hours = "Stunden",
    unavailable = "Noch nicht verfügbar", daysUnit = "T.", hoursUnit = "Std.", minutesUnit = "Min.",
    now = "Gerade eben", minuteAgo = "vor %d Min.", hourAgo = "vor %d Std.", dayAgo = "Vor %d Tagen", yesterday = "Gestern",
    shown = "%d / %d Charaktere angezeigt", filteredTime = "Gefiltert: %s", oneRealm = "1 Realm",
    visible = "%d / %d Charaktere · Sichtbar: %s", partial = " (%d ohne Spielzeit)",
    hint = "Weitere Charaktere erscheinen nach dem ersten Login mit Hourstone.",
    name = "Name", noCharacters = "Noch keine Charaktere erfasst.", empty = "Keine passenden Charaktere.", settings = "Einstellungen", minimap = "Minimap-Button anzeigen",
    on = "An", off = "Aus", scale = "Hourstone-Größe", reset = "Position zurücksetzen", done = "Fertig",
    realms = "%d Realms",
    open = "Linksklick: öffnen / schließen", move = "Ziehen: Minimap-Button verschieben", commands = "/hourstone oder /azerothhours",
    active = "Aktueller Charakter", estimate = "Seit dem letzten bekannten Wert lokal weitergezählt.",
    sync = "Letzter Serverabgleich: %s", noSync = "Warte auf den /played-Wert des Servers.",
    known = "Letzter bekannter Stand; dieser Charakter ist offline.", fullTime = "Gesamt: %s",
    request = "Abgleich angefragt", requestWait = "Abgleich vorgemerkt (60 Sekunden Anfrageabstand)",
    futureDB = "Hourstone: Die gespeicherten Daten stammen aus einer neueren Addon-Version. Bitte Hourstone aktualisieren.",
}
H.L = setmetatable(de and german or en, { __index = en })
