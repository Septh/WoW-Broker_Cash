
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
L['Day'] = 'Today'
L['Week'] = 'This week'
L['Month'] = 'This month'
L['Year'] = 'This year'

-- Other
L['Session'] = 'Current session'
L['NoStat'] = 'N/A'
