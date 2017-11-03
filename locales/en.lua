
local L = LibStub('AceLocale-3.0'):NewLocale('Broker_Cash', 'enUS', true)
if not L then return end

-- Main tooltip
L['Name'] = true
L['Cash'] = true
L['Total'] = true

-- Sub tooltip
L['RECORDED_SINCE'] = '> Recorded since %s'
L['LAST_SAVED'] = '> Last seen on %s'
L['DATE_FORMAT'] = '%x'
L['DATE_TIME_FORMAT'] = '%x, %X'
L['Current Session'] = true
L['Today'] = true
L['This week'] = true
L['This month'] = true
L['This year'] = true
L['All times'] = true

-- Options panel
L['Options'] = true
L['Options_LDB'] = 'LDB Display'
L['OPTS_SMALL_PARTS'] = 'Show Copper and Silver'
L['OPTS_SMALL_PARTS_DESC'] = 'These will be shown anyway if the gold part is zero.'
L['Options_Menu'] = 'Dropdown Menu'
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
