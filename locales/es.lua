-- Environnement
-- GLOBALS: LibStub
local addonName, addonTable = ...
local L = LibStub('AceLocale-3.0'):NewLocale(addonName, 'esES')
if not L then
  return
end

-- Main tooltip
L['Name'] = 'Nombre'
L['Cash'] = 'Efectivo'
L['Total'] = 'Total'

-- Sub tooltip
L['RECORDED_SINCE'] = '> Registrado desde %s'
L['LAST_SAVED'] = '> Última vez visto %s'
L['DATE_FORMAT'] = '%x'
L['DATE_TIME_FORMAT'] = '%x a las %X%p'
L['Current Session'] = 'Sesión actual'
L['Today'] = 'Hoy'
L['This week'] = 'Esta semana'
L['This month'] = 'Este mes'
L['This year'] = 'Este año'
L['Ever'] = 'Siempre'

-- Options panel
L['Options'] = 'Opciones'

L['OPTIONS_GENERAL'] = 'General'
L['OPTS_SESSION_THRESHOLD'] = 'Umbral de sesión'
L['OPTS_SESSION_THRESHOLD_DESC'] = 'Si cierra sesión y luego vuelve a iniciar sesión con el mismo personaje antes de que haya transcurrido este número de segundos, la estadística de "sesión" no se restablecerá. Ver documentos para más información.'

L['OPTIONS_LDB'] = 'Mostrar LDB'
L['OPTS_SMALL_PARTS'] = 'Mostrar cobre y plata'
L['OPTS_SMALL_PARTS_DESC'] = 'Esto se mostrará de todos modos si el oro es cero.'
L['OPTS_HIDE_MINIMAP_BUTTON'] = 'Ocultar el botón del minimapa'
L['OPTS_TEXT_LDB'] = 'Texto mostrado'

L['OPTIONS_MENU'] = 'Menu desplegable'
L['OPTS_DISABLE_IN_COMBAT'] = 'Deshabilitar en combate'
L['OPTS_DISABLE_IN_COMBAT_DESC'] = 'Evita que salga el menu en combate.'
L['Show Details'] = 'Mostrar detalles'
L['OPTS_SHOW_DETAILS_DESC'] = 'Muestra una información emergente secundaria con más detalles al pasar el ratón por reinos y personajes.'

L['Characters'] = 'Personajes'
L['OPTS_CHARACTERS_INFO_1'] = 'Seleccione uno o más personajes de la lista a continuación, luego seleccione una acción para realizar en ellos:'
L['OPTS_CHARACTERS_INFO_2'] = "Reiniciará las estadísticas de los personajes a 0 pero los mantendrá en la base de datos."
L['OPTS_CHARACTERS_INFO_3'] = "Eliminará las estadísticas de los personajes de la base de datos. Tenga en cuenta que no puede eliminar el personaje actual."
L['OPTS_CHARACTERS_INFO_4'] = 'Aviso, estas acciones son irreversibles!'
L['Reset'] = 'Reiniciar'
L['Delete'] = 'Eliminar'
L['Notice'] = 'Aviso'
L['NUMSELECTED_0'] = 'Ninguno seleccionado'
L['NUMSELECTED_1'] = '1 seleccionado'
L['NUMSELECTED_X'] = '%d seleccionado'
L['RESET_TOON'] = 'Reiniciar personaje:'
L['RESET_TOONS'] = 'Reiniciar %d personajes:'
L['DELETE_TOON'] = 'Eliminar this personaje:'
L['DELETE_TOONS'] = 'Eliminar %d personajes:'
L['Are you sure?'] = '¿Está seguro?'

L['WoW Token'] = 'Ficha de WoW'
L['Guild Bank'] = 'Banco del Gremio'
