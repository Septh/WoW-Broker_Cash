
local L = LibStub('AceLocale-3.0'):NewLocale('Broker_Cash', 'enUS', true)
if not L then return end

-- Main tooltip
L['Name'] = true
L['Cash'] = true
L['Total'] = true

-- Sub tooltip
L['Since'] = '> Recorded since %s'
L['LastSaved'] = '> Last seen on %s'
L['DateFormat'] = '%x'
L['DateTimeFormat'] = '%x, %X'
L['Session'] = 'Current session'
L['Day'] = 'Today'
L['Week'] = 'This week'
L['Month'] = 'This month'
L['Year'] = 'This year'

-- Dialog
L['Database'] = true
L['Reset'] = true
L['Delete'] = true
L['DLGINFO0'] = 'Notice'
L['DLGINFO1'] = 'Select one or more characters in the list below, then select an action to perform on them:'
L['DLGINFO2'] = "will reset the characters's stats to 0 but keep them in the database."
L['DLGINFO3'] = "will remove the characters's stats from the database. Note that you cannot delete the current character."
L['DLGINFO4'] = 'Warning, these actions are irreversible!'
L['NUMSELECTED'] = '%d selected'
L['RESET_TOON'] = 'Reset this toon:'
L['RESET_TOONS'] = 'Reset %d toons:'
L['DELETE_TOON'] = 'Delete this toon:'
L['DELETE_TOONS'] = 'Delete %d toons:'
L['Are you sure?'] = true

L['Options'] = true
L['Options_LDB'] = 'LDB Display'
L['Options_Menu'] = 'Dropdown Menu'
L['DLGINFO10'] = 'You may want to hide the silver and copper parts of every money string displayed by Broker_Cash, but please note that these will be shown anyway if the gold part is zero.'
L['Show Copper'] = true
L['Show Silver'] = true
L['Show Silver and Copper'] = true
