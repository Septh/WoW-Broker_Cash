-- Environnement
-- GLOBALS: LibStub
local addonName, addonTable = ...
local L = LibStub('AceLocale-3.0'):NewLocale(addonName, 'ptBR')
if not L then
  return
end

-- Main tooltip
L['Name'] = 'Nome'
L['Cash'] = 'Dinheiro'
L['Total'] = 'Total'

-- Sub tooltip
L['RECORDED_SINCE'] = '> Registrado desde %s'
L['LAST_SAVED'] = '> Última vez salvo em %s'
L['DATE_FORMAT'] = '%x'
L['DATE_TIME_FORMAT'] = '%x às %X%p'
L['Current Session'] = 'Sessão atual'
L['Today'] = 'Hoje'
L['This week'] = 'Esta semana'
L['This month'] = 'Este mês'
L['This year'] = 'Este ano'
L['Ever'] = 'Sempre'

-- Options panel
L['Options'] = 'Opções'

L['OPTIONS_GENERAL'] = 'Geral'
L['OPTS_SESSION_THRESHOLD'] = 'Limite de sessão'
L['OPTS_SESSION_THRESHOLD_DESC'] = 'Se você sair e entrar novamente com o mesmo personagem antes que este número de segundos tenha decorrido, a estatística de "sessão" não será redefinida. Consulte a documentação para mais informações.'

L['OPTIONS_LDB'] = 'Exibição LDB'
L['OPTS_HIGHLIGHT_LDB'] = "Destacar o ícone LDB ao passar o mouse."
L['OPTS_HIGHLIGHT_LDB_DESC'] = "Para aquelas exibições LDB que não fazem isso por conta própria."
L['OPTS_SMALL_PARTS'] = 'Mostrar Cobre e Prata'
L['OPTS_SMALL_PARTS_DESC'] = 'Eles serão mostrados de qualquer forma se a parte de ouro for zero.'
L['OPTS_HIDE_MINIMAP_BUTTON'] = 'Ocultar botão do minimapa'
L['OPTS_TEXT_LDB'] = 'Texto exibido'

L['OPTIONS_MENU'] = 'Menu suspenso'
L['OPTS_DISABLE_IN_COMBAT'] = 'Desabilitar em combate'
L['OPTS_DISABLE_IN_COMBAT_DESC'] = 'Impede que o menu apareça durante o combate.'
L['Show Details'] = 'Mostrar detalhes'
L['OPTS_SHOW_DETAILS_DESC'] = 'Exibe uma dica de ferramenta secundária com mais detalhes ao passar o mouse sobre reinos e personagens.'

L['Characters'] = 'Personagens'
L['OPTS_CHARACTERS_INFO_1'] = 'Selecione um ou mais personagens na lista abaixo e depois selecione uma ação para realizar com eles:'
L['OPTS_CHARACTERS_INFO_2'] = "redefinirá as estatísticas dos personagens para 0, mas os manterá no banco de dados."
L['OPTS_CHARACTERS_INFO_3'] = "removerá as estatísticas dos personagens do banco de dados. Observe que você não pode excluir o personagem atual."
L['OPTS_CHARACTERS_INFO_4'] = 'Atenção, estas ações são irreversíveis!'
L['Reset'] = 'Redefinir'
L['Delete'] = 'Excluir'
L['Notice'] = 'Aviso'
L['NUMSELECTED_0'] = 'Nenhum selecionado'
L['NUMSELECTED_1'] = '1 selecionado'
L['NUMSELECTED_X'] = '%d selecionados'
L['RESET_TOON'] = 'Redefinir este personagem:'
L['RESET_TOONS'] = 'Redefinir %d personagens:'
L['DELETE_TOON'] = 'Excluir este personagem:'
L['DELETE_TOONS'] = 'Excluir %d personagens:'
L['Are you sure?'] = 'Você tem certeza?'

L['WoW Token'] = 'Ficha de WoW'
L['Guild Bank'] = 'Banco da Guilda'
L['Warband Bank'] = 'Banco do Bando de Guerra'
