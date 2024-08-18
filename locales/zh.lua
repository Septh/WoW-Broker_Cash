-- Environnement
-- GLOBALS: LibStub
local addonName, addonTable = ...
local L = LibStub('AceLocale-3.0'):NewLocale(addonName, 'zhCN')
if not L then
  return
end

-- Main tooltip
L['Name'] = '名字'
L['Cash'] = '现金'
L['Total'] = '总计'

-- Sub tooltip
L['RECORDED_SINCE'] = '> 记录自 %s'
L['LAST_SAVED'] = '> 最后保存于 %s'
L['DATE_FORMAT'] = '%x'
L['DATE_TIME_FORMAT'] = '%x %X%p'
L['Current Session'] = '当前会话'
L['Today'] = '今天'
L['This week'] = '本周'
L['This month'] = '本月'
L['This year'] = '今年'
L['Ever'] = '总是'

-- Options panel
L['Options'] = '选项'

L['OPTIONS_GENERAL'] = '通用'
L['OPTS_SESSION_THRESHOLD'] = '会话阈值'
L['OPTS_SESSION_THRESHOLD_DESC'] = '如果在此秒数内注销并重新登录同一个角色，“会话”统计将不会重置。更多信息请参见文档。'

L['OPTIONS_LDB'] = 'LDB 显示'
L['OPTS_HIGHLIGHT_LDB'] = '鼠标悬停时高亮显示 LDB 图标。'
L['OPTS_HIGHLIGHT_LDB_DESC'] = '对于那些不自动高亮显示的 LDB 显示。'
L['OPTS_SMALL_PARTS'] = '显示铜和银'
L['OPTS_SMALL_PARTS_DESC'] = '如果金币部分为零，这些仍将显示。'
L['OPTS_HIDE_MINIMAP_BUTTON'] = '隐藏小地图按钮'
L['OPTS_TEXT_LDB'] = '显示的文本'

L['OPTIONS_MENU'] = '下拉菜单'
L['OPTS_DISABLE_IN_COMBAT'] = '战斗中禁用'
L['OPTS_DISABLE_IN_COMBAT_DESC'] = '防止在战斗中显示菜单。'
L['Show Details'] = '显示详细信息'
L['OPTS_SHOW_DETAILS_DESC'] = '当鼠标悬停在领域和角色上时，显示一个带有更多详细信息的辅助工具提示。'

L['Characters'] = '角色'
L['OPTS_CHARACTERS_INFO_1'] = '在下方列表中选择一个或多个角色，然后选择要对它们执行的操作：'
L['OPTS_CHARACTERS_INFO_2'] = '将角色的统计数据重置为 0，但保留在数据库中。'
L['OPTS_CHARACTERS_INFO_3'] = '将角色的统计数据从数据库中删除。请注意，无法删除当前角色。'
L['OPTS_CHARACTERS_INFO_4'] = '警告，这些操作是不可逆的！'
L['Reset'] = '重置'
L['Delete'] = '删除'
L['Notice'] = '通知'
L['NUMSELECTED_0'] = '未选择'
L['NUMSELECTED_1'] = '选择了 1 个'
L['NUMSELECTED_X'] = '选择了 %d 个'
L['RESET_TOON'] = '重置该角色：'
L['RESET_TOONS'] = '重置 %d 个角色：'
L['DELETE_TOON'] = '删除该角色：'
L['DELETE_TOONS'] = '删除 %d 个角色：'
L['Are you sure?'] = '你确定吗？'

L['WoW Token'] = '魔兽世界时光徽章'
L['Guild Bank'] = '公会银行'
L['Warband Bank'] = '战团银行'
