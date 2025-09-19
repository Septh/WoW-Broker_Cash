-- Environnement
-- GLOBALS: LibStub
local addonName, addonTable = ...
local L = LibStub('AceLocale-3.0'):NewLocale(addonName, 'ruRU')
if not L then
  return
end

-- Main tooltip
L['Name'] = 'Имя'
L['Cash'] = 'Деньги'
L['Total'] = 'Всего'

-- Sub tooltip
L['RECORDED_SINCE'] = '> Записано с %s'
L['LAST_SAVED'] = '> Последний раз сохранено %s'
L['DATE_FORMAT'] = '%x'
L['DATE_TIME_FORMAT'] = '%x в %X%p'
L['Current Session'] = 'Текущая сессия'
L['Today'] = 'Сегодня'
L['This week'] = 'Эта неделя'
L['This month'] = 'Этот месяц'
L['This year'] = 'Этот год'
L['Ever'] = 'Всегда'

-- Options panel
L['Options'] = 'Настройки'

L['OPTIONS_GENERAL'] = 'Общие'
L['OPTS_SESSION_THRESHOLD'] = 'Порог сессии'
L['OPTS_SESSION_THRESHOLD_DESC'] = 'Если вы выйдете из игры и войдете снова за того же персонажа до истечения этого количества секунд, статистика "сессии" не будет сброшена. Подробности см. в документации.'

L['OPTIONS_LDB'] = 'Отображение LDB'
L['OPTS_HIGHLIGHT_LDB'] = "Подсвечивать иконку LDB при наведении мыши."
L['OPTS_HIGHLIGHT_LDB_DESC'] = "Для тех отображений LDB, которые не делают это сами."
L['OPTS_SMALL_PARTS'] = 'Показать медь и серебро'
L['OPTS_SMALL_PARTS_DESC'] = 'Они все равно будут показаны, если часть золота равна нулю.'
L['OPTS_HIDE_MINIMAP_BUTTON'] = 'Скрыть кнопку на мини-карте'
L['OPTS_TEXT_LDB'] = 'Отображаемый текст'

L['OPTIONS_MENU'] = 'Выпадающее меню'
L['OPTS_DISABLE_IN_COMBAT'] = 'Отключить в бою'
L['OPTS_DISABLE_IN_COMBAT_DESC'] = 'Предотвращает появление меню во время боя.'
L['Show Details'] = 'Показать детали'
L['OPTS_SHOW_DETAILS_DESC'] = 'Отображать вторичную подсказку с дополнительными деталями при наведении на миры и персонажей.'

L['Characters'] = 'Персонажи'
L['OPTS_CHARACTERS_INFO_1'] = 'Выберите одного или нескольких персонажей в списке ниже, затем выберите действие для них:'
L['OPTS_CHARACTERS_INFO_2'] = "сбросит статистику персонажей до 0, но сохранит их в базе данных."
L['OPTS_CHARACTERS_INFO_3'] = "удалит статистику персонажей из базы данных. Обратите внимание, что текущего персонажа удалить нельзя."
L['OPTS_CHARACTERS_INFO_4'] = 'Внимание, эти действия необратимы!'
L['Reset'] = 'Сбросить'
L['Delete'] = 'Удалить'
L['Notice'] = 'Уведомление'
L['NUMSELECTED_0'] = 'Не выбрано'
L['NUMSELECTED_1'] = 'Выбран 1'
L['NUMSELECTED_X'] = 'Выбрано %d'
L['RESET_TOON'] = 'Сбросить этого персонажа:'
L['RESET_TOONS'] = 'Сбросить %d персонажей:'
L['DELETE_TOON'] = 'Удалить этого персонажа:'
L['DELETE_TOONS'] = 'Удалить %d персонажей:'
L['Are you sure?'] = 'Вы уверены?'

L['WoW Token'] = 'Жетон WoW'
L['Warband Bank'] = 'банка отряда'

L['Character: Cash'] = "Персонаж: Наличные"
L['Account: Cash'] = "Аккаунт: Наличные"
L['Character: Today'] = "Персонаж: Сегодня"
L['Account: Today'] = "Аккаунт: Сегодня"
