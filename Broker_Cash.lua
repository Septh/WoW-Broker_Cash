
-- Environnement
local addonName, BrokerCash = ...

-- Bibliothèques
local addon                 = LibStub('AceAddon-3.0'):NewAddon(BrokerCash, addonName, 'AceConsole-3.0', 'AceEvent-3.0')
local L                     = LibStub('AceLocale-3.0'):GetLocale('Broker_Cash')
local libDataBroker         = LibStub('LibDataBroker-1.1')
local libQTip               = LibStub('LibQTip-1.0')

-- Premier jour de la semaine
local FIRST_DAY_OF_WEEK    = 2	-- Lundi

-- Textures
local tth = select(2, GameTooltipText:GetFontObject():GetFont())
local GOLD_ICON_STRING      = ('|TInterface\\MoneyFrame\\UI-GoldIcon:%d:%d:2:0|t'):format(tth, tth)
local SILVER_ICON_STRING    = ('|TInterface\\MoneyFrame\\UI-SilverIcon:%d:%d:2:0|t'):format(tth, tth)
local COPPER_ICON_STRING    = ('|TInterface\\MoneyFrame\\UI-CopperIcon:%d:%d:2:0|t'):format(tth, tth)
local PLUS_BUTTON_STRING    = ('|TInterface\\Buttons\\UI-PlusButton-Up:%d:%d:2:0|t'):format(tth, tth)
local MINUS_BUTTON_STRING   = ('|TInterface\\Buttons\\UI-MinusButton-Up:%d:%d:2:0|t'):format(tth, tth)

-- Montants
local SILVER_PER_GOLD       = _G.SILVER_PER_GOLD
local COPPER_PER_SILVER     = _G.COPPER_PER_SILVER
local COPPER_PER_GOLD       = _G.COPPER_PER_SILVER * _G.SILVER_PER_GOLD

-- Couleurs
local COLOR_RED             = CreateColor(1.0, 0.1, 0.1, 1)
local COLOR_RED_DIMMED      = CreateColor(0.8, 0.1, 0.1, 1)
local COLOR_GREEN           = CreateColor(0.1, 1.0, 0.1, 1)
local COLOR_GREEN_DIMMED    = CreateColor(0.1, 0.8, 0.1, 1)
local COLOR_YELLOW          = CreateColor(1.0, 1.0, 0.1, 1)
local COLOR_YELLOW_DIMMED   = CreateColor(0.8, 0.8, 0.1, 1)

-- Personnage courant
local currentChar           = UnitName('player')
local currentRealm          = GetRealmName()
local currentCharKey        = currentChar .. ' - ' .. currentRealm
local sessionMoney          = 0

-- Données de tous les personnages
local raw_db
local allRealms, allChars   = {}, {}

-------------------------------------------------------------------------------
-- Fonctions utilitaires
-------------------------------------------------------------------------------
local function CopyTableSorted(t, f)
	t = CopyTable(t)
	table.sort(t, f)
	return t
end

local function days_in_month(m, y)
	-- http://lua-users.org/wiki/DayOfWeekAndDaysInMonthExample
	return date('*t', time( { year = y, month = m + 1, day = 0 } ))['day']
end

local function MakeCharKey(charName, charRealm)
	return charName .. ' - ' .. charRealm
end

local function SplitCharKey(charKey)
	local charName, _, charRealm = strsplit(' ', charKey, 3)
	return charName, charRealm
end

local function InvertCharKey(charKey)
	charKey = charKey:gsub('(%S+) %- (%S+)', '%2 - %1')
	return charKey
end

local function GetAbsoluteMoneyString(amount)
	-- D'après FrameXML/MoneyFrame.lua#311
	local gold   = math.floor(amount / COPPER_PER_GOLD)
	local silver = math.floor((amount - (gold * COPPER_PER_GOLD)) / COPPER_PER_SILVER)
	local copper = amount % COPPER_PER_SILVER

	local str = string.format('%02d%s', copper, COPPER_ICON_STRING)
	if (silver + gold) > 0 then
		str = string.format('%02d%s ', silver, SILVER_ICON_STRING) .. str
	end
	if gold > 0 then
		str = string.format('%s%s ', BreakUpLargeNumbers(gold), GOLD_ICON_STRING) .. str
	end
	return str
end

local function GetRelativeMoneyString(amount)
	if (amount or 0) == 0 then
		return COLOR_YELLOW_DIMMED:WrapTextInColorCode('0')
	elseif amount < 0 then
		return COLOR_RED_DIMMED:WrapTextInColorCode('-' .. GetAbsoluteMoneyString(-amount))
	else
		return COLOR_GREEN_DIMMED:WrapTextInColorCode('+' .. GetAbsoluteMoneyString(amount))
	end
end

-------------------------------------------------------------------------------
-- Réinitialisation/suppression de personnages
-------------------------------------------------------------------------------
do
	local dialog_config = {
		name    = 'Broker_Cash',
		handler = addon,
		type    = 'group',
		args    = {
			infos = {
				type   = 'group',
				name   = L['DLGINFO0'],
				inline = true,
				order  = 1,
				args   = {
					line1 = {
						type     = 'description',
						name     = L['DLGINFO1'],
						fontSize = 'medium',
						order    = 1,
					},
					line2 = {
						type     = 'description',
						name     = string.format(YELLOW_FONT_COLOR_CODE .. '> %s' .. FONT_COLOR_CODE_CLOSE .. ' %s', L['Reset'], L['DLGINFO2']),
						fontSize = 'medium',
						order    = 2,
					},
					line3 = {
						type     = 'description',
						name     = string.format(YELLOW_FONT_COLOR_CODE .. '> %s' .. FONT_COLOR_CODE_CLOSE .. ' %s', L['Delete'], L['DLGINFO3']),
						fontSize = 'medium',
						order    = 3,
					},
					line4 = {
						type     = 'description',
						name     = string.format('\n' .. ORANGE_FONT_COLOR_CODE .. '%s' .. FONT_COLOR_CODE_CLOSE, L['DLGINFO4']),
						fontSize = 'medium',
						order    = 4,
					},
				}
			},
			sep1 = {
				type  = 'header',
				name  = '',
				order = 2
			},
			--
			-- Les royaumes sont insérés ici ultérieurement
			--
			sep2 = {
				type  = 'header',
				name  = '',
				order = 99,
			},
			actions = {
				type   = 'group',
				name   = function() return false end,	-- Permet d'avoir un groupe sans titre ni cadre
				inline = true,
				order  = 100,
				args   = {
					count = {
						type  = 'description',
						name  = '',
						width = 'fill',					-- Visiblement, une valeur magique dans AceConfigDialog-3.0
						order = 1,
						fontSize = 'medium',
					},
					reset = {
						type  = 'execute',
						name  = L['Reset'],
						order = 2,
					},
					delete = {
						type  = 'execute',
						name  = L['Delete'],
						order = 3,
					},
				}
			}
		}
	}
	local selectedToons, numSelectedToons = nil, 0

	-- Supprime les personnages sélectionnés des données sauvegardées
	local function Dialog_DoDeleteCharacters(info, value)
		for key,_ in pairs(selectedToons) do

			raw_db[key] = nil
			Broker_CashDB.profileKeys[key] = nil

			-- Supprime aussi dans la table des options
			local name, realm = SplitCharKey(key)

			tDeleteItem(allChars[realm], name)
			dialog_config.args[realm].values[name] = nil

			if #allChars[realm] == 0 then
				allChars[realm] = nil

				tDeleteItem(allRealms, realm)
				dialog_config.args[realm] = nil
			end

			-- Supprime aussi de la table des sélectionnés
			selectedToons[key] = nil
			numSelectedToons = numSelectedToons - 1
		end

		-- Redessine le panneau des options
		LibStub('AceConfigRegistry-3.0'):NotifyChange('Broker_Cash')
	end

	-- Réinitialise les statistiques des personnages sélectionnés
	local function Dialog_DoResetCharacters(info, value)
		for key,_ in pairs(selectedToons) do
			raw_db[key].day   = nil
			raw_db[key].week  = nil
			raw_db[key].month = nil
			raw_db[key].year  = nil
		end
	end

	-- Affiche une demande de confirmation avant réinitialisation/suppression
	local function Dialog_ConfirmAction(info)

		-- str = RESET_TOON(S) ou DELETE_TOON(S)
		local str = L[string.upper(info[#info]) .. '_TOON' .. (numSelectedToons > 1 and 'S' or '')]
		str = str:format(numSelectedToons)

		-- Construit la demande de confirmation
		local toons = {}
		for k,_ in pairs(selectedToons) do
			table.insert(toons, InvertCharKey(k))
		end
		table.sort(toons)
		return str .. '\n\n' .. table.concat(toons, '\n') .. '\n\n' .. L['Are you sure?']
	end

	-- Vérifie si les boutons Supprimer / Réinitialiser doivent être désactivés
	local function Dialog_IsActionDisabled(info)
		-- True si (aucune sélection) ou (le bouton est Delete et le personnage courant fait partie des sélectionnés)
		return numSelectedToons == 0 or (info[#info] == 'delete' and selectedToons[currentCharKey])
	end

	-- Sélectionne / désélectionne un personnage
	local function Dialog_IsToonSelected(info, key)
		return selectedToons[MakeCharKey(key, info[#info])]
	end

	local function Dialog_SetToonSelected(info, key, value)
		key = MakeCharKey(key, info[#info])
		if value then
			selectedToons[key] = true
			numSelectedToons   = numSelectedToons + 1
		else
			selectedToons[key] = nil
			numSelectedToons   = numSelectedToons - 1
		end
	end

	-- Met à jour le nombre de personnages sélectionnés dans le dialogue
	local function Dialog_GetNumSelected(info)
		return string.format(L['NUMSELECTED'], numSelectedToons)
	end

	-- Affiche le dialogue de réinitialisation/suppression de personnages
	function addon:ChatCmdHandler(msg)

		-- Construit le dialogue si ce n'est pas déjà fait
		if not selectedToons then
			selectedToons = {}

			-- Ajuste le tableau des options avec les références des fonctions
			dialog_config.args.actions.args.count.name      = Dialog_GetNumSelected

			dialog_config.args.actions.args.reset.disabled  = Dialog_IsActionDisabled
			dialog_config.args.actions.args.reset.confirm   = Dialog_ConfirmAction
			dialog_config.args.actions.args.reset.func      = Dialog_DoResetCharacters

			dialog_config.args.actions.args.delete.disabled = Dialog_IsActionDisabled
			dialog_config.args.actions.args.delete.confirm  = Dialog_ConfirmAction
			dialog_config.args.actions.args.delete.func     = Dialog_DoDeleteCharacters

			-- Insère les royaumes et leurs personnages dans le panneau d'options
			for i,realm in ipairs(CopyTableSorted(allRealms)) do
				dialog_config.args[realm] = {
					type   = 'multiselect',
					name   = realm,
					style  = 'radio',
					get    = Dialog_IsToonSelected,
					set    = Dialog_SetToonSelected,
					values = {},
					order  = 10 + i
				}

				for _,name in ipairs(CopyTableSorted(allChars[realm])) do
					dialog_config.args[realm].values[name] = name
				end
			end
			LibStub('AceConfig-3.0'):RegisterOptionsTable('Broker_Cash', dialog_config)
		end

		-- Affiche le dialogue, sans aucun personnage sélectionné à l'ouverture
		numSelectedToons = #wipe(selectedToons)
		LibStub('AceConfigDialog-3.0'):Open('Broker_Cash')
	end
end

-------------------------------------------------------------------------------
-- Gestion du tooltip secondaire
-------------------------------------------------------------------------------
do
	local subTooltip = nil

	-- Affiche le tooltip pour un royaume
	function addon:ShowRealmTooltip(realmLineFrame, selectedRealm)

		-- Affiche le tooltip
		local stt = self:ShowSubTooltip(realmLineFrame)

		-- Calcule et affiche les données du royaume
		local realmDay, realmWeek, realmMonth, realmYear = 0, 0, 0, 0
		for key,data in pairs(raw_db) do
			local name, realm = SplitCharKey(key)

			if realm == selectedRealm then
				realmDay   = realmDay   + (data['day']   or 0)
				realmWeek  = realmWeek  + (data['week']  or 0)
				realmMonth = realmMonth + (data['month'] or 0)
				realmYear  = realmYear  + (data['year']  or 0)
			end
		end

		stt:AddLine(L['Day'],   GetRelativeMoneyString(realmDay))
		stt:AddLine(L['Week'],  GetRelativeMoneyString(realmWeek))
		stt:AddLine(L['Month'], GetRelativeMoneyString(realmMonth))
		stt:AddLine(L['Year'],  GetRelativeMoneyString(realmYear))
		stt:Show()
	end

	-- Affiche le tooltip pour un personnage
	function addon:ShowCharTooltip(charLineFrame, selectedCharKey)

		-- Affiche le sous-tooltip
		local stt = self:ShowSubTooltip(charLineFrame)

		-- Affiche les données du personnage
		local data = raw_db[selectedCharKey]
		local ln
		ln = stt:AddLine(); stt:SetCell(ln, 1, selectedCharKey, 2)
		ln = stt:AddLine(); stt:SetCell(ln, 1, string.format(L['Since'],     date(L['DateFormat'],     data.since)), 2)
		ln = stt:AddLine(); stt:SetCell(ln, 1, string.format(L['LastSaved'], date(L['DateTimeFormat'], data.lastSaved)), 2)

		stt:AddLine(''); stt:AddSeparator(); stt:AddLine('')

		if selectedCharKey == currentCharKey then
			stt:AddLine(L['Session'], GetRelativeMoneyString(sessionMoney))
		end
		stt:AddLine(L['Day'],   GetRelativeMoneyString(data.day))
		stt:AddLine(L['Week'],  GetRelativeMoneyString(data.week))
		stt:AddLine(L['Month'], GetRelativeMoneyString(data.month))
		stt:AddLine(L['Year'],  GetRelativeMoneyString(data.year))
		stt:Show()
	end

	-- Affiche le tooltip secondaire
	function addon:HideSubTooltip()
		if subTooltip then
			subTooltip:Release()
		end
		subTooltip = nil
	end

	function addon:ShowSubTooltip(mainTooltipLine)

		-- Affiche (ou déplace) le sous-tooltip
		if not subTooltip then
			subTooltip = libQTip:Acquire('BrokerCash_SubTooltip', 2, 'LEFT', 'RIGHT')
			subTooltip:SetFrameLevel(mainTooltipLine:GetFrameLevel() + 1)
		end

		-- Détermine la position du tooltip (à gauche de la ligne parente si pas assez de place à droite)
		local x, y, w, h = mainTooltipLine:GetRect()
		local sw, sh = UIParent:GetSize()

		if (x + w + 200) < sw then
			subTooltip:SetPoint('TOPLEFT', mainTooltipLine, 'TOPRIGHT', 0, 10)
		else
			subTooltip:SetPoint('TOPRIGHT', mainTooltipLine, 'TOPLEFT', 0, 10)
		end
		subTooltip:SetClampedToScreen(true)

		-- Efface le contenu
		subTooltip:Clear()
		subTooltip:SetFont(GameTooltipTextSmall)
		subTooltip:SetCellMarginV(2)

		return subTooltip
	end
end

-------------------------------------------------------------------------------
-- Gestion du tooltip principal
-------------------------------------------------------------------------------
do
	-- Surlignage de l'icône LDB
	local highlightFrame = CreateFrame('Frame')
	highlightFrame:Hide()

	local highlightTexture = highlightFrame:CreateTexture(nil, 'OVERLAY')
	highlightTexture:SetTexture('Interface\\QuestFrame\\UI-QuestTitleHighlight')
	highlightTexture:SetBlendMode('ADD')

	-- Tooltip
	local mainTooltip = nil
	local unfoldedRealms = {}

	-- Déplie/replie un royaume dans le tooltip
	local function MainTooltip_OnClickRealm(realmLineFrame, realm, button)
		unfoldedRealms[realm] = not unfoldedRealms[realm]
		addon:UpdateMainTooltip()
	end

	-- Affiche le tooltip secondaire pour un royaume
	local function MainTooltip_OnEnterRealm(realmLineFrame, realm)
		addon:ShowRealmTooltip(realmLineFrame, realm)
	end

	local function MainTooltip_OnLeaveRealm(realmLineFrame)
		addon:HideSubTooltip()
	end

	-- Affiche le tooltip secondaire pour un personnage
	local function MainTooltip_OnEnterChar(charLineFrame, charKey)
		addon:ShowCharTooltip(charLineFrame, charKey)
	end

	local function MainTooltip_OnLeaveChar(charLineFrame)
		addon:HideSubTooltip()
	end

	-- Affiche le tooltip principal
	function addon:UpdateMainTooltip()

		local mtt = mainTooltip
		local ln, rln

		-- Construit le tooltip
		mtt:Hide()
		mtt:Clear()
		mtt:SetCellMarginV(2)

		-- Header
		mtt:AddHeader(L['Name'], L['Cash'])
		mtt:AddLine(''); mtt:AddSeparator(); mtt:AddLine('')

		-- Personnage courant en premier
		mtt:AddLine(currentCharKey, GetAbsoluteMoneyString(self.db.char.money))
		mtt:AddLine()
		ln = mtt:AddLine(); mtt:SetCell(ln, 1, L['Session'], GameTooltipTextSmall, 1, 10); mtt:SetCell(ln, 2, GetRelativeMoneyString(sessionMoney),       GameTooltipTextSmall)
		ln = mtt:AddLine(); mtt:SetCell(ln, 1, L['Day'],     GameTooltipTextSmall, 1, 10); mtt:SetCell(ln, 2, GetRelativeMoneyString(self.db.char.day),   GameTooltipTextSmall)
		ln = mtt:AddLine(); mtt:SetCell(ln, 1, L['Week'],    GameTooltipTextSmall, 1, 10); mtt:SetCell(ln, 2, GetRelativeMoneyString(self.db.char.week),  GameTooltipTextSmall)
		ln = mtt:AddLine(); mtt:SetCell(ln, 1, L['Month'],   GameTooltipTextSmall, 1, 10); mtt:SetCell(ln, 2, GetRelativeMoneyString(self.db.char.month), GameTooltipTextSmall)
		ln = mtt:AddLine(); mtt:SetCell(ln, 1, L['Year'],    GameTooltipTextSmall, 1, 10); mtt:SetCell(ln, 2, GetRelativeMoneyString(self.db.char.year),  GameTooltipTextSmall)
		mtt:AddLine(''); mtt:AddSeparator(); mtt:AddLine('')

		-- Ajoute tous les personnages, royaume par royaume
		local realmMoney, totalMoney = 0, 0
		for _,realm in ipairs(allRealms) do

			-- Trie les personnages du royaume par ordre décroissant de richesse
			table.sort(allChars[realm], function(n1, n2)
				return raw_db[n1 .. ' - ' .. realm].money > raw_db[n2 .. ' - ' .. realm].money
			end)

			-- 1/ Nom du royaume + nombre de personnages (la richesse est ajoutée après la boucle)
			rln = mtt:AddLine()
			mtt:SetCell(rln, 1, string.format('%s %s (%d)', unfoldedRealms[realm] and MINUS_BUTTON_STRING or PLUS_BUTTON_STRING, realm, #allChars[realm]))
			mtt:SetCellTextColor(rln, 1, COLOR_YELLOW_DIMMED:GetRGBA())

			-- Gestion du second tooltip pour cette ligne
			mtt:SetLineScript(rln, 'OnEnter', MainTooltip_OnEnterRealm, realm)
			mtt:SetLineScript(rln, 'OnLeave', MainTooltip_OnLeaveRealm)

			-- Gestion du clic sur cette ligne
			mtt:SetLineScript(rln, 'OnMouseDown', MainTooltip_OnClickRealm, realm)

			realmMoney = 0
			for _,name in ipairs(allChars[realm]) do

				-- Vérifie s'il faut réinitialiser les statistiques de ce personnage
				local key  = MakeCharKey(name, realm)
				local data = raw_db[key]
				self:CheckStatResets(data)

				if unfoldedRealms[realm] then
					-- Ajoute le personnage (avec une marge à gauche)
					ln = mtt:AddLine()
					mtt:SetCell(ln, 1, name, 1, 20)
					mtt:SetCell(ln, 2, GetAbsoluteMoneyString(data.money))

					-- Gestion du second tooltip pour cette ligne
					mtt:SetLineScript(ln, 'OnEnter', MainTooltip_OnEnterChar, key)
					mtt:SetLineScript(ln, 'OnLeave', MainTooltip_OnLeaveChar)
				end

				-- Comptabilise la richesse par royaume / totale
				realmMoney = realmMoney + data.money
				totalMoney = totalMoney + data.money
			end

			-- 3/ Richesse de ce royaume
			mtt:SetCell(rln, 2, GetAbsoluteMoneyString(realmMoney))
			mtt:SetCellTextColor(rln, 2, COLOR_YELLOW_DIMMED:GetRGBA())
			mtt:AddLine('')
		end

		-- Ajoute le grand total
		mtt:AddLine(''); mtt:AddSeparator(); mtt:AddLine('')
		mtt:AddLine(L['Total'], GetAbsoluteMoneyString(totalMoney))

		-- Fini
		mtt:Show()
	end

	function addon:HideMainTooltip()
		self:HideSubTooltip()
		if mainTooltip then
			mainTooltip:Release()

			-- Cache le surlignage
			highlightTexture:SetParent(highlightFrame)
		end
		mainTooltip = nil
	end

	function addon:ShowMainTooltip(LDBFrame)
		if not mainTooltip then
			mainTooltip = libQTip:Acquire('BrokerCash_MainTooltip', 2, 'LEFT', 'RIGHT')
			mainTooltip:SmartAnchorTo(LDBFrame)
			mainTooltip:SetAutoHideDelay(0.1, LDBFrame, function() addon:HideMainTooltip() end)

			-- Surligne l'icône LDB, sauf si le display est Bazooka (il le fait déjà)
			local LDBFrameName = LDBFrame:GetName() or ''
			if not LDBFrameName:find('Bazooka', 1) then
				highlightTexture:SetParent(LDBFrame)
				highlightTexture:SetAllPoints(LDBFrame)
			end
		end
		self:UpdateMainTooltip()
	end
end

-------------------------------------------------------------------------------
-- Mise à jour des données du personnage courant à chaque gain ou perte d'argent
-------------------------------------------------------------------------------
do
	local yday, startOfDay, startOfWeek, startOfMonth, startOfYear

	function CalcResetDates()

		-- On recalcule seulement si on a changé de jour depuis le dernier calcul
		local today = date('*t')
		if (yday or 0) == today.yday then return end
		yday = today.yday

		-- Toutes les limites sont calculées à 00:00:00
		-- TODO: Gérer l'heure d'été/hiver ? Si oui, comment ?
		local limit = {
			hour = 0,
			min  = 0,
			sec  = 0
		}

		-- Début du jour courant
		limit.day   = today.day
		limit.month = today.month
		limit.year  = today.year
		startOfDay = time(limit)

		-- Début de la semaine courante
		limit.day   = today.day - (today.wday >= FIRST_DAY_OF_WEEK and (today.wday - FIRST_DAY_OF_WEEK) or (7 - today.wday))
		limit.month = today.month
		limit.year  = today.year
		if (limit.day < 1) then
			limit.month = limit.month - 1
			if limit.month < 1 then
				limit.month = 12
				limit.year = limit.year - 1
			end
			limit.day = days_in_month(limit.month, limit.year) - limit.day
		end
		startOfWeek = time(limit)

		-- Début du mois courant
		limit.day   = 1
		limit.month = today.month
		limit.year  = today.year
		startOfMonth = time(limit)

		-- Début de l'année courante
		limit.day   = 1
		limit.month = 1
		limit.year  = today.year
		startOfYear = time(limit)
	end

	function addon:CheckStatResets(charData)

		-- Calcule les dates de réinitialisation des statistiques
		CalcResetDates()

		-- Réinitialise les stats qui ont dépassé leur date limite
		-- (à nil plutôt que 0 pour rester consistant avec AceDB)
		local charLastSaved = charData.lastSaved or 0
		if charLastSaved < startOfDay   then charData.day   = nil end	-- Quotidienne
		if charLastSaved < startOfWeek  then charData.week  = nil end 	-- Hebdomadaire
		if charLastSaved < startOfMonth then charData.month = nil end 	-- Mensuelle
		if charLastSaved < startOfYear  then charData.year  = nil end 	-- Annuelle
	end

	function addon:PLAYER_MONEY()

		-- Vérifie s'il faut réinitialiser les statistiques
		self:CheckStatResets(self.db.char)

		-- Enregistre la dépense / recette
		local money = GetMoney()
		local diff  = money - self.db.char.money

		-- Met à jour la stat de session
		sessionMoney = sessionMoney + diff

		-- Et les stats quotidienne/hebdomadaire/mensuelle/annuelle
		self.db.char.money     = money
		self.db.char.day       = (self.db.char.day   or 0) + diff
		self.db.char.week      = (self.db.char.week  or 0) + diff
		self.db.char.month     = (self.db.char.month or 0) + diff
		self.db.char.year      = (self.db.char.year  or 0) + diff
		self.db.char.lastSaved = time()

		-- Met à jour le texte du LDB
		self.dataObject.text = GetAbsoluteMoneyString(money)
	end
end

-------------------------------------------------------------------------------
-- Activation/désactivation de l'addon
-------------------------------------------------------------------------------
do
	function addon:OnEnable()

		-- Première connexion avec ce personnage ?
		if self.db.char.money == -1 then
			self.db.char.money     = GetMoney()
			self.db.char.since     = time()
			self.db.char.lastSaved = self.db.char.since
		end

		-- Sauve les données actuelles
		-- (fait ici car l'addon peut être activé/désactivé à tout moment)
		self:PLAYER_MONEY()

		-- Surveille les événements
		self:RegisterEvent('PLAYER_MONEY')
	end

	function addon:OnDisable()
		self:HideMainTooltip()
	end
end

-------------------------------------------------------------------------------
-- Initialisation
-------------------------------------------------------------------------------
do
	local db_defaults = {
		char = {
			money     = -1,
			since     = 0,
			lastSaved = 0,
			day       = 0,
			week      = 0,
			month     = 0,
			year      = 0
		}
	}

	function addon:OnInitialize()

		-- Charge ou crée les données sauvegardées
		self.db = LibStub('AceDB-3.0'):New('Broker_CashDB', db_defaults, true)

		-- S'assure que les tables AceDB sont initialisées pour ce personnage (si première connexion)
		self.db.char.since = self.db.char.since

		-- v1.0.2: n'enregistre plus les données de folding du tooltip
		self.db.global.folds = nil

		-- Recense les données de tous les personnages
		raw_db = rawget(Broker_CashDB, 'char')
		for key,_ in pairs(raw_db) do
			local name, realm = SplitCharKey(key)

			if not allChars[realm] then
				allChars[realm] = {}
				table.insert(allRealms, realm)
			end
			table.insert(allChars[realm], name)
		end

		-- Trie les royaumes par ordre alphabétique, le royaume courant en premier
		table.sort(allRealms, function(r1, r2)
			if r1 == currentRealm then
				return true
			elseif r2 == currentRealm then
				return false
			else
				return r1 < r2
			end
		end)

		-- Crée l'icône LDB
		self.dataObject = libDataBroker:NewDataObject('Broker_Cash', {
			type    = 'data source',
			icon    = 'Interface\\MINIMAP\\TRACKING\\Banker',
			text    = 'Cash',
			OnEnter = function(f) addon:ShowMainTooltip(f) end
		})

		-- Commandes
		self:RegisterChatCommand('brokercash', 'ChatCmdHandler')
		self:RegisterChatCommand('bcash',      'ChatCmdHandler')
		self:RegisterChatCommand('cash',       'ChatCmdHandler')
	end
end
