-- Environnement
-- GLOBALS: LibStub
local addonName, addonTable = ...
local L = LibStub('AceLocale-3.0'):NewLocale(addonName, 'deDE')
if not L then
  return
end

-- Main tooltip
L['Name'] = true
L['Cash'] = true
L['Total'] = true

-- Sub tooltip
L['RECORDED_SINCE'] = '> Aufgenommen seit %s'
L['LAST_SAVED'] = '> Zuletzt gesehen am %s'
L['DATE_FORMAT'] = '%x'
L['DATE_TIME_FORMAT'] = '%x at %X%p'
L['Current Session'] = 'Aktuelle Sitzung'
L['Today'] = 'Heute'
L['This week'] = 'Diese Woche'
L['This month'] = 'Diesen Monat'
L['This year'] = 'Dieses Jahr'
L['Ever'] = 'Immer'

-- Options panel
L['Options'] = 'Optionen'
L['OPTIONS_LDB'] = 'LDB Anzeige'
L['OPTS_SMALL_PARTS'] = 'Zeige Kupfer und Silber'
L['OPTS_SMALL_PARTS_DESC'] = 'Diese werden trotzdem angezeigt wenn der Goldwert Null entspricht.'
L['OPTS_HIDE_MINIMAP_BUTTON'] = 'Minimap-Schaltfläche ausblenden'
L['OPTIONS_MENU'] = 'Aufklappmenü'
L['OPTS_DISABLE_IN_COMBAT'] = 'Im Kampf deaktivieren'
L['OPTS_DISABLE_IN_COMBAT_DESC'] = 'Verhindert dass das Menu im Kampf gezeigt wird.'
L['Show Details'] = 'Details anzeigen'
L['OPTS_SHOW_DETAILS_DESC'] = 'Zeige ein zweites Tooltip mit mehr Infos wenn der Mauszeiger über Realms und Charakteren hovert.'
L['OPTS_TEXT_LDB'] = 'Angezeigter Text'

L['Characters'] = 'Charaktere'
L['OPTS_CHARACTERS_INFO_1'] = 'Wähle einen oder mehrer Charakter in der folgenden Liste, wähle anschliessen eine Aktion die mit diesen ausgeführt werden sollen:'
L['OPTS_CHARACTERS_INFO_2'] = "setzt die Charakter-Statistik auf 0, behält diese aber in der Datenbank."
L['OPTS_CHARACTERS_INFO_3'] = "Entfernt die Charakter-Statistik aus der Datenbank. Beachte dass du den aktuell ausgewählten Charakter nicht löschen kannst."
L['OPTS_CHARACTERS_INFO_4'] = 'Achtung, diese Aktion kann nicht rückgängig gemacht werden!'
L['Reset'] = 'Zurücksetzen'
L['Delete'] = 'Löschen'
L['Notice'] = 'Hinweis'
L['NUMSELECTED_0'] = 'Keine ausgewählt'
L['NUMSELECTED_1'] = '1 ausgewählt'
L['NUMSELECTED_X'] = '%d ausgewählt'
L['RESET_TOON'] = 'Charakter zurücksetzen:'
L['RESET_TOONS'] = 'Setze %d Charaktere zurück:'
L['DELETE_TOON'] = 'Lösche diesen Charakter:'
L['DELETE_TOONS'] = 'Lösche %d Charaktere:'
L['Are you sure?'] = 'Sind Sie sicher?'

L['WoW Token'] = 'WoW-Marke'
L['Guild Bank'] = 'Gildenbank'
L['Warband Bank'] = 'Kriegsmeutenbank'
