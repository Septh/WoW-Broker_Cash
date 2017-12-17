
-- Environnement
-- GLOBALS: LibStub
local addonName, addonTable = ...
local L = LibStub('AceLocale-3.0'):NewLocale(addonName, 'frFR')
if not L then return end

-- Tooltip principal
L['Name'] = 'Nom'
L['Cash'] = 'Solde'
L['Total'] = 'Total'

-- Tooltip secondaire
L['RECORDED_SINCE'] = '> Suivi depuis %s'
L['LAST_SAVED'] = '> Dernier relevé %s'
L['DATE_FORMAT'] = 'le %d/%m/%Y'
L['DATE_TIME_FORMAT'] = 'le %d/%m/%Y à %X'
L['Current Session'] = 'Session courante'
L['Today'] = "Aujourd'hui"
L['This week'] = 'Cette semaine'
L['This month'] = 'Ce mois'
L['This year'] = 'Cette année'
L['Ever'] = 'En tout'

-- Panneau de configuration
L['Options'] = true
L['OPTIONS_LDB'] = 'Icône LDB'
L['OPTS_SMALL_PARTS'] = "Afficher l'argent et le bronze"
L['OPTS_SMALL_PARTS_DESC'] = "Ces montants seront tout de même affichés si le montant d'or est égal à zéro."
L['OPTIONS_MENU'] = 'Menu déroulant'
L['OPTS_DISABLE_IN_COMBAT'] = 'Ne pas afficher en combat'
L['OPTS_DISABLE_IN_COMBAT_DESC'] = "Evite de vous perturber pendant le combat..."
L['Show Details'] = 'Détails des royaumes et des personnages'
L['OPTS_SHOW_DETAILS_DESC'] = 'Afficher le second tooltip pour les royaumes et les personnages.'

L['Characters'] = 'Personnages'
L['OPTS_CHARACTERS_INFO_1'] = "Sélectionnez un ou plusieurs personnages puis cliquez sur l'action à entreprendre :"
L['OPTS_CHARACTERS_INFO_2'] = 'remet les données à 0 sans supprimer les personnages de la base.'
L['OPTS_CHARACTERS_INFO_3'] = 'efface les personnages de la base. Vous ne pouvez pas supprimer le personnage actuellement connecté.'
L['OPTS_CHARACTERS_INFO_4'] = 'Attention, ces actions sont irréversibles !'
L['Reset'] = 'Réinitialiser'
L['Delete'] = 'Supprimer'
L['Notice'] = 'Notice'
L['NUMSELECTED_0'] = 'Aucune sélection'
L['NUMSELECTED_1'] = '1 sélectionné'
L['NUMSELECTED_X'] = '%d sélectionnés'
L['RESET_TOON'] = 'Êtes-vous sûr de vouloir\nréitinialiser ce personnage ?'
L['RESET_TOONS'] = 'Êtes-vous sûr de vouloir\nréinitialiseer ces %d personnages ?'
L['DELETE_TOON'] = 'Êtes-vous sûr de vouloir\nsupprimer ce personnage ?'
L['DELETE_TOONS'] = 'Êtes-vous sûr de vouloir\nsupprimer ces %d personnages ?'
L['Are you sure?'] = '' --Êtes-vous sûr ?'
