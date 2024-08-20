-- Environnement
-- GLOBALS: LibStub
local addonName, addonTable = ...
local L = LibStub('AceLocale-3.0'):NewLocale(addonName, 'enUS', true)
if not L then
  return
end

-- Main tooltip
L['Name'] = true
L['Cash'] = true
L['Total'] = true

-- Sub tooltip
L['RECORDED_SINCE'] = '> Recorded since %s'
L['LAST_SAVED'] = '> Last seen on %s'
L['DATE_FORMAT'] = '%x'
L['DATE_TIME_FORMAT'] = '%x at %X%p'
L['Current Session'] = true
L['Today'] = true
L['This week'] = true
L['This month'] = true
L['This year'] = true
L['Ever'] = true

-- Options panel
L['Options'] = true

L['OPTIONS_GENERAL'] = 'General'
L['OPTS_SESSION_THRESHOLD'] = 'Session threshold'
L['OPTS_SESSION_THRESHOLD_DESC'] = 'If you log out then back in with the same character before this number of seconds has ellapsed, then the "session" stat will not be reset. See docs for more info.'

L['OPTIONS_LDB'] = 'LDB Display'
L['OPTS_HIGHLIGHT_LDB'] = "Highlight the LDB icon on mouseover."
L['OPTS_HIGHLIGHT_LDB_DESC'] = "For those LDB displays that don't do it themselves."
L['OPTS_SMALL_PARTS'] = 'Show Copper and Silver'
L['OPTS_SMALL_PARTS_DESC'] = 'These will be shown anyway if the gold part is zero.'
L['OPTS_HIDE_MINIMAP_BUTTON'] = 'Hide Minimap Button'
L['OPTS_TEXT_LDB'] = 'Displayed Text'

L['OPTIONS_MENU'] = 'Dropdown Menu'
L['OPTS_DISABLE_IN_COMBAT'] = 'Disable in combat'
L['OPTS_DISABLE_IN_COMBAT_DESC'] = 'Prevents the menu to show while in combat.'
L['Show Details'] = true
L['OPTS_SHOW_DETAILS_DESC'] = 'Display a secondary tooltip with further details when hovering realms and characters.'

L['Characters'] = true
L['OPTS_CHARACTERS_INFO_1'] = 'Select one or more characters in the list below, then select an action to perform on them:'
L['OPTS_CHARACTERS_INFO_2'] = "will reset the characters's stats to 0 but keep them in the database."
L['OPTS_CHARACTERS_INFO_3'] = "will remove the characters's stats from the database. Note that you cannot delete the current character."
L['OPTS_CHARACTERS_INFO_4'] = 'Warning, these actions are irreversible!'
L['Reset'] = true
L['Delete'] = true
L['Notice'] = true
L['NUMSELECTED_0'] = 'None selected'
L['NUMSELECTED_1'] = '1 selected'
L['NUMSELECTED_X'] = '%d selected'
L['RESET_TOON'] = 'Reset this toon:'
L['RESET_TOONS'] = 'Reset %d toons:'
L['DELETE_TOON'] = 'Delete this toon:'
L['DELETE_TOONS'] = 'Delete %d toons:'
L['Are you sure?'] = true

L['WoW Token'] = true
L['Warband Bank'] = true
