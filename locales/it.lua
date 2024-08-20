-- Environnement
-- GLOBALS: LibStub
local addonName, addonTable = ...
local L = LibStub('AceLocale-3.0'):NewLocale(addonName, 'itIT')
if not L then
  return
end

-- Main tooltip
L['Name'] = 'Nome'
L['Cash'] = 'Contanti'
L['Total'] = 'Totale'

-- Sub tooltip
L['RECORDED_SINCE'] = '> Registrato dal %s'
L['LAST_SAVED'] = '> Ultimo salvataggio il %s'
L['DATE_FORMAT'] = '%x'
L['DATE_TIME_FORMAT'] = '%x alle %X%p'
L['Current Session'] = 'Sessione corrente'
L['Today'] = 'Oggi'
L['This week'] = 'Questa settimana'
L['This month'] = 'Questo mese'
L['This year'] = "Quest'anno"
L['Ever'] = 'Sempre'

-- Options panel
L['Options'] = 'Opzioni'

L['OPTIONS_GENERAL'] = 'Generale'
L['OPTS_SESSION_THRESHOLD'] = 'Soglia della sessione'
L['OPTS_SESSION_THRESHOLD_DESC'] = 'Se ti disconnetti e riconnetti con lo stesso personaggio prima che trascorrano questi secondi, la statistica della "sessione" non verrà reimpostata. Per maggiori informazioni, consulta la documentazione.'

L['OPTIONS_LDB'] = 'Visualizzazione LDB'
L['OPTS_HIGHLIGHT_LDB'] = "Evidenzia l'icona LDB al passaggio del mouse."
L['OPTS_HIGHLIGHT_LDB_DESC'] = "Per quelle visualizzazioni LDB che non lo fanno da sole."
L['OPTS_SMALL_PARTS'] = 'Mostra rame e argento'
L['OPTS_SMALL_PARTS_DESC'] = 'Questi verranno comunque mostrati se la parte in oro è zero.'
L['OPTS_HIDE_MINIMAP_BUTTON'] = 'Nascondi pulsante sulla minimappa'
L['OPTS_TEXT_LDB'] = 'Testo visualizzato'

L['OPTIONS_MENU'] = 'Menu a tendina'
L['OPTS_DISABLE_IN_COMBAT'] = 'Disabilita in combattimento'
L['OPTS_DISABLE_IN_COMBAT_DESC'] = 'Impedisce la visualizzazione del menu durante il combattimento.'
L['Show Details'] = 'Mostra dettagli'
L['OPTS_SHOW_DETAILS_DESC'] = 'Visualizza un tooltip secondario con ulteriori dettagli quando si passa il mouse su reami e personaggi.'

L['Characters'] = 'Personaggi'
L['OPTS_CHARACTERS_INFO_1'] = "Seleziona uno o più personaggi nell'elenco sottostante, quindi seleziona un'azione da eseguire su di essi:"
L['OPTS_CHARACTERS_INFO_2'] = "reimposterà le statistiche dei personaggi a 0 ma li manterrà nel database."
L['OPTS_CHARACTERS_INFO_3'] = "rimuoverà le statistiche dei personaggi dal database. Nota che non puoi eliminare il personaggio corrente."
L['OPTS_CHARACTERS_INFO_4'] = 'Attenzione, queste azioni sono irreversibili!'
L['Reset'] = 'Reimposta'
L['Delete'] = 'Elimina'
L['Notice'] = 'Avviso'
L['NUMSELECTED_0'] = 'Nessuno selezionato'
L['NUMSELECTED_1'] = '1 selezionato'
L['NUMSELECTED_X'] = '%d selezionati'
L['RESET_TOON'] = 'Reimposta questo personaggio:'
L['RESET_TOONS'] = 'Reimposta %d personaggi:'
L['DELETE_TOON'] = 'Elimina questo personaggio:'
L['DELETE_TOONS'] = 'Elimina %d personaggi:'
L['Are you sure?'] = 'Sei sicuro?'

L['WoW Token'] = 'Gettone WoW'
L['Warband Bank'] = 'Banca della Brigata'
