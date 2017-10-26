
local L = LibStub('AceLocale-3.0'):NewLocale('Broker_Cash', 'frFR')
if not L then return end

-- Tooltip principal
L['Name'] = 'Nom'
L['Cash'] = 'Solde'
L['Total'] = 'Total'

-- Tooltip secondaire
L['Since'] = '> Suivi depuis %s'
L['LastSaved'] = '> Dernier relevé %s'
L['DateFormat'] = 'le %d/%m/%Y'
L['DateTimeFormat'] = 'le %d/%m/%Y à %X'
L['Session'] = 'Session courante'
L['Day'] = "Aujourd'hui"
L['Week'] = 'Cette semaine'
L['Month'] = 'Ce mois'
L['Year'] = 'Cette année'

-- Dialogue
L['Database'] = 'Personnages'
L['Reset'] = 'Réinitialiser'
L['Delete'] = 'Supprimer'
L['DLGINFO0'] = 'Notice'
L['DLGINFO1'] = "Sélectionnez un ou plusieurs personnages puis cliquez sur l'action à entreprendre :"
L['DLGINFO2'] = 'remet les données à 0 sans supprimer les personnages de la base.'
L['DLGINFO3'] = 'efface les personnages de la base. Vous ne pouvez pas supprimer le personnage actuellement connecté.'
L['DLGINFO4'] = 'Attention, ces actions sont irréversibles !'
L['NUMSELECTED'] = '%d sélectionnés'
L['RESET_TOON'] = 'Êtes-vous sûr de vouloir\nréitinialiser ce personnage ?'
L['RESET_TOONS'] = 'Êtes-vous sûr de vouloir\nréinitialiseer ces %d personnages ?'
L['DELETE_TOON'] = 'Êtes-vous sûr de vouloir\nsupprimer ce personnage ?'
L['DELETE_TOONS'] = 'Êtes-vous sûr de vouloir\nsupprimer ces %d personnages ?'
L['Are you sure?'] = '' --Êtes-vous sûr ?'

L['Options'] = true
L['Options_LDB'] = 'Icône LDB'
L['Options_Menu'] = 'Menu déroulant'
L['DLGINFO10'] = "Vous pouvez choisir de masquer les montants d'argent et de bronze, mais ces montants seront tout de même affichés si le montant d'or est égal à zéro."
L['Show Copper'] = 'Afficher le bronze'
L['Show Silver'] = "Afficher l'argent"
L['Show Silver and Copper'] = "Afficher l'argent et le bronze"
