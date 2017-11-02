
-- Environnement
-- GLOBALS: LibStub
local addon   = LibStub('AceAddon-3.0'):NewAddon('Broker_Cash', 'AceConsole-3.0', 'AceEvent-3.0')
local L       = LibStub('AceLocale-3.0'):GetLocale('Broker_Cash')
local libLDB  = LibStub('LibDataBroker-1.1')
local libQTip = LibStub('LibQTip-1.0')

-- Upvalues
local GetAddOnMetadata, UnitName, GetRealmName = GetAddOnMetadata, UnitName, GetRealmName
local GetMoney, BreakUpLargeNumbers = GetMoney, BreakUpLargeNumbers
local CreateColor, tDeleteItem = CreateColor, tDeleteItem
local UIParent, GameTooltipText, GameTooltipTextSmall = UIParent, GameTooltipText, GameTooltipTextSmall

-- Textures
local tth = select(2, GameTooltipText:GetFontObject():GetFont())
local GOLD_ICON_STRING    = ('|TInterface\\MoneyFrame\\UI-GoldIcon:%d:%d:2:0|t'):format(tth, tth)
local SILVER_ICON_STRING  = ('|TInterface\\MoneyFrame\\UI-SilverIcon:%d:%d:2:0|t'):format(tth, tth)
local COPPER_ICON_STRING  = ('|TInterface\\MoneyFrame\\UI-CopperIcon:%d:%d:2:0|t'):format(tth, tth)
local PLUS_BUTTON_STRING  = ('|TInterface\\Buttons\\UI-PlusButton-Up:%d:%d:2:0|t'):format(tth, tth)
local MINUS_BUTTON_STRING = ('|TInterface\\Buttons\\UI-MinusButton-Up:%d:%d:2:0|t'):format(tth, tth)

-- Montants
local SILVER_PER_GOLD   = SILVER_PER_GOLD
local COPPER_PER_SILVER = COPPER_PER_SILVER
local COPPER_PER_GOLD   = COPPER_PER_SILVER * SILVER_PER_GOLD

-- Couleurs
local COLOR_RED    = CreateColor(0.8, 0.1, 0.1, 1)
local COLOR_GREEN  = CreateColor(0.1, 0.8, 0.1, 1)
local COLOR_YELLOW = CreateColor(0.8, 0.8, 0.1, 1)

-- Gestion des statistiques
local FIRST_DAY_OF_WEEK = 2	-- Lundi
local yday, startOfDay, startOfWeek, startOfMonth, startOfYear

-- Données des personnages
local currentChar    = UnitName('player')
local currentRealm   = GetRealmName()
local currentCharKey = currentChar .. ' - ' .. currentRealm
local sessionMoney   = 0
local allRealms, allChars, realmWeath = {}, {}, {}

-- Données sauvegardées
local sv_defaults = {
	char = {
		money     = 0,
		since     = 0,
		lastSaved = 0,
		day       = 0,
		week      = 0,
		month     = 0,
		year      = 0
	},
	global = {
		ldb = {
			showCopper  = true,
			showSilver  = true,
			showSilverAndCopper = true,
		},
		menu = {
			showCopper = true,
			showSilver = true,
			showSilverAndCopper = true,
			showSubTooltips = true,
		}
	}
}

-- Panneau des options
local options_panel = {
	name    = 'Broker_Cash v' .. GetAddOnMetadata('Broker_Cash', 'Version'),
	handler = addon,
	type    = 'group',
	childGroups = 'tab',
	args = {
		options = {
			name  = L['Options'],
			type  = 'group',
			order = 1,
			get   = 'ConfigPanel_GetOpt',
			set   = 'ConfigPanel_SetOpt',
			args  = {
				ldb = {
					name   = L['Options_LDB'],
					type   = 'group',
					inline = true,
					order  = 10,
					args   = {
						showSilverAndCopper = {
							name  = L['OPTS_SMALL_PARTS'],
							desc  = L['OPTS_SMALL_PARTS_DESC'],
							descStyle = 'inline',
							type  = 'toggle',
							width = 'full',
							order = 1,
						},
					},
				},
				menu = {
					name   = L['Options_Menu'],
					type   = 'group',
					inline = true,
					order  = 20,
					args   = {
						showSilverAndCopper = {
							name = L['OPTS_SMALL_PARTS'],
							desc   = L['OPTS_SMALL_PARTS_DESC'],
							descStyle = 'inline',
							type = 'toggle',
							width = 'full',
							order = 1,
						},
						showSubTooltips = {
							name = L['Show Details'],
							desc  = L['OPTS_SHOW_DETAILS_DESC'],
							descStyle = 'inline',
							type  = 'toggle',
							width = 'full',
							order = 2,
						}
					},
				},
			},
		},
		database = {
			name  = L['Characters'],
			type  = 'group',
			order = 2,
			args  = {
				infos = {
					type   = 'group',
					name   = L['Notice'],
					inline = true,
					order  = 1,
					args   = {
						line1 = {
							type     = 'description',
							name     = L['OPTS_CHARACTERS_INFO_1'],
							fontSize = 'medium',
							order    = 1,
						},
						line2 = {
							type     = 'description',
							name     = string.format('> ' .. YELLOW_FONT_COLOR_CODE .. '%s' .. FONT_COLOR_CODE_CLOSE .. ' %s', L['Reset'], L['OPTS_CHARACTERS_INFO_2']),
							fontSize = 'medium',
							order    = 2,
						},
						line3 = {
							type     = 'description',
							name     = string.format('> ' .. YELLOW_FONT_COLOR_CODE .. '%s' .. FONT_COLOR_CODE_CLOSE .. ' %s', L['Delete'], L['OPTS_CHARACTERS_INFO_3']),
							fontSize = 'medium',
							order    = 3,
						},
						line4 = {
							type     = 'description',
							name     = string.format('\n' .. ORANGE_FONT_COLOR_CODE .. '%s' .. FONT_COLOR_CODE_CLOSE, L['OPTS_CHARACTERS_INFO_4']),
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
				-- Les personnages sont insérés ici ultérieurement
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
							type     = 'description',
							name     = function() return addon:ConfigPanel_GetNumSelected() end,
							width    = 'fill',				-- Valeur magique dans AceConfigDialog-3.0
							order    = 1,
							fontSize = 'medium',
						},
						reset = {
							type     = 'execute',
							name     = L['Reset'],
							order    = 2,
							disabled = 'ConfigPanel_IsActionDisabled',
							confirm  = 'ConfigPanel_ConfirmAction',
							func     = 'ConfigPanel_DoResetCharacters',
						},
						delete = {
							type     = 'execute',
							name     = L['Delete'],
							order    = 3,
							disabled = 'ConfigPanel_IsActionDisabled',
							confirm  = 'ConfigPanel_ConfirmAction',
							func     = 'ConfigPanel_DoDeleteCharacters',
						},
					}
				}
			}
		}
	}
}
local selectedToons, numSelectedToons = nil, 0

-- Tooltips
local mainTooltip, subTooltip
local unfoldedRealms = {}

local highlightTexture = UIParent:CreateTexture(nil, 'OVERLAY')
highlightTexture:SetTexture('Interface\\QuestFrame\\UI-QuestTitleHighlight')
highlightTexture:SetBlendMode('ADD')
highlightTexture:Hide()

-------------------------------------------------------------------------------
-- Fonctions utilitaires
-------------------------------------------------------------------------------
local function MakeCharKey(charName, charRealm)
	return charName:trim() .. ' - ' .. charRealm:trim()
end

local function SplitCharKey(charKey)
	local charName, charRealm = ('-'):split(charKey, 2)
	return charName:trim(), charRealm:trim()
end

local function InvertCharKey(charKey)
	return charKey:gsub('(%S+) %- (%S+)', '%2 - %1')
end

local function GetAbsoluteMoneyString(amount, showSilverAndCopper)
	amount = amount or 0

	local gold   = math.floor(amount / COPPER_PER_GOLD)
	local silver = math.floor(amount / SILVER_PER_GOLD) % SILVER_PER_GOLD
	local copper = amount % COPPER_PER_SILVER

	local tbl = {}
	if gold > 0 then
		table.insert(tbl, BreakUpLargeNumbers(gold) .. GOLD_ICON_STRING)
	end
	if showSilverAndCopper or gold == 0 then
		if silver > 0 then
			table.insert(tbl, silver .. SILVER_ICON_STRING)
		end
		table.insert(tbl, copper .. COPPER_ICON_STRING)
	end
	return table.concat(tbl, ' ')
end

local function GetRelativeMoneyString(amount, showSilverAndCopper)
	if (amount or 0) == 0 then
		return COLOR_YELLOW:WrapTextInColorCode('0')
	elseif amount < 0 then
		return COLOR_RED:WrapTextInColorCode('-' .. GetAbsoluteMoneyString(-amount, showSilverAndCopper))
	else
		return COLOR_GREEN:WrapTextInColorCode('+' .. GetAbsoluteMoneyString(amount, showSilverAndCopper))
	end
end

-------------------------------------------------------------------------------
-- Gestion du panneau de configuration
-------------------------------------------------------------------------------

-- Supprime les personnages sélectionnés des données sauvegardées
function addon:ConfigPanel_DoDeleteCharacters(info, value)
	local sv = self.sv
	for key in pairs(selectedToons) do
		sv.char[key] = nil
		sv.profileKeys[key] = nil

		-- Supprime aussi dans la table des options
		local name, realm = SplitCharKey(key)

		tDeleteItem(allChars[realm], name)
		if #allChars[realm] == 0 then
			allChars[realm] = nil

			tDeleteItem(allRealms, realm)
			options_panel.args.database.args[realm] = nil
		else
			options_panel.args.database.args[realm].values[name] = nil
		end
	end

	-- Recalcule la richesse des royaumes
	self:CountWealth()

	-- Déselectionne tous les personnages et redessine le panneau des options
	numSelectedToons = #wipe(selectedToons)
	LibStub('AceConfigRegistry-3.0'):NotifyChange('Broker_Cash')
end

-- Réinitialise les statistiques des personnages sélectionnés
function addon:ConfigPanel_DoResetCharacters(info, value)
	local sv = self.sv
	for key in pairs(selectedToons) do
		sv.char[key].lastSaved = time()
		sv.char[key].money     = 0
		sv.char[key].day       = nil
		sv.char[key].week      = nil
		sv.char[key].month     = nil
		sv.char[key].year      = nil
	end

	-- Recalcule la richesse des royaumes
	self:CountWealth()

	-- Déselectionne tous les personnages
	numSelectedToons = #wipe(selectedToons)
end

-- Affiche une demande de confirmation avant réinitialisation/suppression
function addon:ConfigPanel_ConfirmAction(info)

	-- str = RESET_TOON(S) ou DELETE_TOON(S)
	local str = L[info[#info]:upper() .. '_TOON' .. (numSelectedToons > 1 and 'S' or '')]
	str = str:format(numSelectedToons)

	-- Construit la demande de confirmation
	local toons = {}
	for k in pairs(selectedToons) do
		table.insert(toons, k)
	end
	table.sort(toons, function(t1, t2)
		return InvertCharKey(t1) < InvertCharKey(t2)
	end)
	return str .. '\n\n' .. table.concat(toons, '\n') .. '\n\n' .. L['Are you sure?']
end

-- Vérifie si les boutons Supprimer et Réinitialiser doivent être désactivés
function addon:ConfigPanel_IsActionDisabled(info)
	-- True si (aucune sélection) OU (le bouton est 'Supprimer' ET le personnage courant fait partie des sélectionnés)
	return numSelectedToons == 0 or (info[#info] == 'delete' and selectedToons[currentCharKey])
end

-- Sélectionne / désélectionne un personnage
function addon:ConfigPanel_IsToonSelected(info, key)
	return selectedToons[MakeCharKey(key, info[#info])]
end

function addon:ConfigPanel_SetToonSelected(info, key, value)
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
function addon:ConfigPanel_GetNumSelected(info)
	local num = numSelectedToons or 0
	local fmt = L['NUMSELECTED_' .. (num > 1 and 'X' or num)]
	return fmt:format(num)
end

function addon:ConfigPanel_GetOpt(info)
	return self.opts[info[#info-1]][info[#info]]
end

function addon:ConfigPanel_SetOpt(info, value)
	self.opts[info[#info-1]][info[#info]] = value

	-- Rafraîchit l'icône LDB
	if info[#info-1] == 'ldb' then
		self:PLAYER_MONEY()
	end
end

-- Affiche le dialogue de réinitialisation/suppression de personnages
function addon:ChatCmdHandler(msg)

	-- Construit le dialogue si ce n'est pas déjà fait
	if not selectedToons then
		selectedToons = {}

		-- Insère les royaumes et leurs personnages dans le panneau d'options
		for i,realm in ipairs(allRealms) do
			options_panel.args.database.args[realm] = {
				type   = 'multiselect',
				name   = realm,
				style  = 'radio',
				get    = 'ConfigPanel_IsToonSelected',
				set    = 'ConfigPanel_SetToonSelected',
				values = {},
				order  = 10 + i
			}

			for _,name in ipairs(allChars[realm]) do
				options_panel.args.database.args[realm].values[name] = name
			end
		end
		LibStub('AceConfig-3.0'):RegisterOptionsTable('Broker_Cash', options_panel)
	end

	-- Affiche le dialogue, sans aucun personnage sélectionné à l'ouverture
	numSelectedToons = #wipe(selectedToons)
	LibStub('AceConfigDialog-3.0'):Open('Broker_Cash')
end

-------------------------------------------------------------------------------
-- Gestion du tooltip secondaire
-------------------------------------------------------------------------------
function addon:HideSubTooltip()
	if subTooltip then
		subTooltip:Release()
	end
	subTooltip = nil
end

-------------------------------------------------------------------------------
function addon:PrepareSubTooltip(mainTooltipLine)

	if not self.opts.menu.showSubTooltips then return end

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

-------------------------------------------------------------------------------
-- Affiche le sous-tooltip pour un royaume
function addon:ShowRealmTooltip(realmLineFrame, selectedRealm)

	-- Affiche le tooltip
	local stt = self:PrepareSubTooltip(realmLineFrame)
	if not stt then return end

	-- Calcule et affiche les données du royaume
	local realmDay, realmWeek, realmMonth, realmYear = 0, 0, 0, 0
	for key,data in pairs(self.sv.char) do
		local _, realm = SplitCharKey(key)

		if realm == selectedRealm then
			realmDay   = realmDay   + (data.day   or 0)
			realmWeek  = realmWeek  + (data.week  or 0)
			realmMonth = realmMonth + (data.month or 0)
			realmYear  = realmYear  + (data.year  or 0)
		end
	end

	local showSilverAndCopper = self.opts.menu.showSilverAndCopper
	stt:AddLine(L['Today'],      GetRelativeMoneyString(realmDay,   showSilverAndCopper))
	stt:AddLine(L['This week'],  GetRelativeMoneyString(realmWeek,  showSilverAndCopper))
	stt:AddLine(L['This month'], GetRelativeMoneyString(realmMonth, showSilverAndCopper))
	stt:AddLine(L['This year'],  GetRelativeMoneyString(realmYear,  showSilverAndCopper))
	stt:Show()
end

-------------------------------------------------------------------------------
-- Affiche le sous-tooltip pour un personnage
function addon:ShowCharTooltip(charLineFrame, selectedCharKey)

	-- Affiche le sous-tooltip
	local stt = self:PrepareSubTooltip(charLineFrame)
	if not stt then return end

	-- Affiche les données du personnage
	local data = self.sv.char[selectedCharKey]
	local ln
	ln = stt:AddLine(); stt:SetCell(ln, 1, selectedCharKey, 2)
	ln = stt:AddLine(); stt:SetCell(ln, 1, string.format(L['RECORDED_SINCE'], date(L['DATE_FORMAT'],      data.since)),     2)
	ln = stt:AddLine(); stt:SetCell(ln, 1, string.format(L['LAST_SAVED'],     date(L['DATE_TIME_FORMAT'], data.lastSaved)), 2)

	stt:AddLine(''); stt:AddSeparator(); stt:AddLine('')

	local showSilverAndCopper = self.opts.menu.showSilverAndCopper
	if selectedCharKey == currentCharKey then
		stt:AddLine(L['Current Session'], GetRelativeMoneyString(sessionMoney, showSilverAndCopper))
	end
	stt:AddLine(L['Today'],      GetRelativeMoneyString(data.day,   showSilverAndCopper))
	stt:AddLine(L['This week'],  GetRelativeMoneyString(data.week,  showSilverAndCopper))
	stt:AddLine(L['This month'], GetRelativeMoneyString(data.month, showSilverAndCopper))
	stt:AddLine(L['This year'],  GetRelativeMoneyString(data.year,  showSilverAndCopper))
	stt:Show()
end

-------------------------------------------------------------------------------
-- Gestion du tooltip principal
-------------------------------------------------------------------------------
function addon:HideMainTooltip()
	self:HideSubTooltip()

	if mainTooltip then
		mainTooltip:Release()

		-- Cache le surlignage
		highlightTexture:SetParent(UIParent)
		highlightTexture:Hide()
	end
	mainTooltip = nil
end

-------------------------------------------------------------------------------
-- Déplie/replie un royaume dans le tooltip
local function MainTooltip_OnClickRealm(realmLineFrame, realm, button)
	unfoldedRealms[realm] = not unfoldedRealms[realm]
	addon:UpdateMainTooltip()
end

-- Affiche le tooltip secondaire pour un royaume
local function MainTooltip_OnLeaveRealm(realmLineFrame)
	addon:HideSubTooltip()
end

local function MainTooltip_OnEnterRealm(realmLineFrame, realm)
	addon:ShowRealmTooltip(realmLineFrame, realm)
end

-- Affiche le tooltip secondaire pour un personnage
local function MainTooltip_OnLeaveChar(charLineFrame)
	addon:HideSubTooltip()
end

local function MainTooltip_OnEnterChar(charLineFrame, charKey)
	addon:ShowCharTooltip(charLineFrame, charKey)
end

-- Affiche le tooltip principal
function addon:UpdateMainTooltip()
	local sv = self.sv
	local showSilverAndCopper = self.opts.menu.showSilverAndCopper
	local mtt = mainTooltip
	local ln, rln

	-- Construit le tooltip
	mtt:Hide()
	mtt:Clear()
	mtt:SetCellMarginV(3)

	-- Header
	mtt:AddHeader(L['Name'], L['Cash'])
	mtt:AddSeparator(); mtt:AddLine('')

	-- Personnage courant en premier
	mtt:AddLine(currentCharKey, GetAbsoluteMoneyString(self.db.char.money, showSilverAndCopper))
	ln = mtt:AddLine(); mtt:SetCell(ln, 1, L['Current Session'], GameTooltipTextSmall, 1, 20); mtt:SetCell(ln, 2, GetRelativeMoneyString(sessionMoney,       showSilverAndCopper), GameTooltipTextSmall)
	ln = mtt:AddLine(); mtt:SetCell(ln, 1, L['Today'],           GameTooltipTextSmall, 1, 20); mtt:SetCell(ln, 2, GetRelativeMoneyString(self.db.char.day,   showSilverAndCopper), GameTooltipTextSmall)
	ln = mtt:AddLine(); mtt:SetCell(ln, 1, L['This week'],       GameTooltipTextSmall, 1, 20); mtt:SetCell(ln, 2, GetRelativeMoneyString(self.db.char.week,  showSilverAndCopper), GameTooltipTextSmall)
	ln = mtt:AddLine(); mtt:SetCell(ln, 1, L['This month'],      GameTooltipTextSmall, 1, 20); mtt:SetCell(ln, 2, GetRelativeMoneyString(self.db.char.month, showSilverAndCopper), GameTooltipTextSmall)
	ln = mtt:AddLine(); mtt:SetCell(ln, 1, L['This year'],       GameTooltipTextSmall, 1, 20); mtt:SetCell(ln, 2, GetRelativeMoneyString(self.db.char.year,  showSilverAndCopper), GameTooltipTextSmall)
	mtt:AddLine(''); mtt:AddSeparator(); mtt:AddLine('')

	-- Trie les royaumes par ordre décroissant de richesse
	-- (à faire ici car l'ordre peut changer à tout instant)
	table.sort(allRealms, function(r1, r2)
		return realmWeath[r1] > realmWeath[r2]
	end)

	-- Ajoute tous les personnages, royaume par royaume
	local realmMoney, totalMoney = 0, 0
	for _,realm in ipairs(allRealms) do

		-- Trie les personnages du royaume par ordre décroissant de richesse
		-- (à faire ici car l'ordre peut changer à tout instant)
		table.sort(allChars[realm], function(n1, n2)
			return ((sv.char[n1 .. ' - ' .. realm].money) or 0) > ((sv.char[n2 .. ' - ' .. realm].money) or 0)
		end)

		-- 1/ Nom du royaume + nombre de personnages (la richesse est ajoutée après la boucle)
		rln = mtt:AddLine()
		mtt:SetCell(rln, 1, string.format('%s %s (%d)', unfoldedRealms[realm] and MINUS_BUTTON_STRING or PLUS_BUTTON_STRING, realm, #allChars[realm]))
		mtt:SetCellTextColor(rln, 1, COLOR_YELLOW:GetRGBA())
		mtt:SetLineScript(rln, 'OnEnter',     MainTooltip_OnEnterRealm, realm)
		mtt:SetLineScript(rln, 'OnLeave',     MainTooltip_OnLeaveRealm)
		mtt:SetLineScript(rln, 'OnMouseDown', MainTooltip_OnClickRealm, realm)

		-- 2/ Tous les personnages de ce royaume
		realmMoney = 0
		for _,name in ipairs(allChars[realm]) do
			local key  = MakeCharKey(name, realm)
			local data = sv.char[key]
			local money = data.money or 0

			-- Vérifie s'il faut réinitialiser les statistiques de ce personnage
			self:CheckStatResets(data)

			-- Ajoute le personnage (avec une marge à gauche)
			if unfoldedRealms[realm] then
				ln = mtt:AddLine()
				mtt:SetCell(ln, 1, name, 1, 20)
				mtt:SetCell(ln, 2, GetAbsoluteMoneyString(money, showSilverAndCopper))
				mtt:SetLineScript(ln, 'OnEnter', MainTooltip_OnEnterChar, key)
				mtt:SetLineScript(ln, 'OnLeave', MainTooltip_OnLeaveChar)
			end

			-- Comptabilise la richesse par royaume / totale
			realmMoney = realmMoney + money
			totalMoney = totalMoney + money
		end
		if unfoldedRealms[realm] then
			mtt:AddLine('')
		end

		-- 3/ Richesse de ce royaume
		mtt:SetCell(rln, 2, GetAbsoluteMoneyString(realmMoney, showSilverAndCopper))
		mtt:SetCellTextColor(rln, 2, COLOR_YELLOW:GetRGBA())
		-- mtt:AddLine('')
	end

	-- Ajoute le grand total
	mtt:AddLine(''); mtt:AddSeparator(); mtt:AddLine('')
	mtt:AddLine(L['Total'], GetAbsoluteMoneyString(totalMoney, showSilverAndCopper))

	-- Fini
	mtt:Show()
end

-------------------------------------------------------------------------------
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
			highlightTexture:Show()
		end
	end
	self:UpdateMainTooltip()
end

-------------------------------------------------------------------------------
-- Gestion des statistiques des personnages
-------------------------------------------------------------------------------
function addon:CheckStatResets(charData)

	-- On recalcule les dates de réinitialisation des statistiques
	-- seulement si on a changé de jour depuis le dernier calcul
	local today = date('*t')
	if (yday or -1) == today.yday then return end
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
	startOfDay  = time(limit)

	-- Début de la semaine courante
	limit.day   = today.day - (today.wday >= FIRST_DAY_OF_WEEK and (today.wday - FIRST_DAY_OF_WEEK) or (7 - today.wday))
	limit.month = today.month
	limit.year  = today.year
	if limit.day < 1 then
		limit.month = limit.month - 1
		if limit.month < 1 then
			limit.month = 12
			limit.year = limit.year - 1
		end
		limit.day = date('*t', time( { year = limit.year, month = limit.month + 1, day = 0 } ))['day'] - limit.day	-- D'après http://lua-users.org/wiki/DayOfWeekAndDaysInMonthExample
	end
	startOfWeek = time(limit)

	-- Début du mois courant
	limit.day    = 1
	limit.month  = today.month
	limit.year   = today.year
	startOfMonth = time(limit)

	-- Début de l'année courante
	limit.day   = 1
	limit.month = 1
	limit.year  = today.year
	startOfYear = time(limit)

	-- Réinitialise les stats qui ont dépassé leur date limite
	-- (à nil plutôt que 0 pour rester consistant avec AceDB)
	local charLastSaved = charData.lastSaved or 0
	if charLastSaved < startOfDay   then charData.day   = nil end	-- Quotidienne
	if charLastSaved < startOfWeek  then charData.week  = nil end 	-- Hebdomadaire
	if charLastSaved < startOfMonth then charData.month = nil end 	-- Mensuelle
	if charLastSaved < startOfYear  then charData.year  = nil end 	-- Annuelle
end

-------------------------------------------------------------------------------
-- Calcule la richesse globale de chaque royaume
function addon:CountWealth()

	-- Efface tout
	table.wipe(allChars)
	table.wipe(allRealms)
	table.wipe(realmWeath)

	-- Recalcule tout
	for charKey,charData in pairs(self.sv.char) do
		local name, realm = SplitCharKey(charKey)

		if allChars[realm] then
			table.insert(allChars[realm], name)
		else
			allChars[realm] = { name }
			table.insert(allRealms, realm)
		end

		realmWeath[realm] = (realmWeath[realm] or 0) + (charData.money or 0)
	end
end

-------------------------------------------------------------------------------
-- Mise à jour des données du personnage courant à chaque gain ou perte d'argent
-------------------------------------------------------------------------------
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

	-- Et la richesse du royaume
	realmWeath[currentRealm] = realmWeath[currentRealm] + diff

	-- Met à jour le texte du LDB
	self.dataObject.text = GetAbsoluteMoneyString(money, self.opts.ldb.showSilverAndCopper)
end

-------------------------------------------------------------------------------
-- Activation/désactivation de l'addon
-------------------------------------------------------------------------------
function addon:OnDisable()
	self:HideMainTooltip()
end

-------------------------------------------------------------------------------
function addon:OnEnable()

	-- Première connexion avec ce personnage ?
	-- (fait ici car GetMoney() n'est pas fiable avant PLAYER_ENTERING_WORLD)
	if self.db.char.lastSaved == 0 then
		self.db.char.lastSaved = time()
		self.db.char.money     = GetMoney()
		self.db.char.since     = self.db.char.lastSaved
	end

	-- Sauve les données actuelles
	-- (fait ici car l'addon peut être activé/désactivé à tout moment)
	self:PLAYER_MONEY()

	-- Surveille les événements
	self:RegisterEvent('PLAYER_MONEY')
end

-------------------------------------------------------------------------------
-- Initialisation
-------------------------------------------------------------------------------
function addon:OnInitialize()

	-- Charge ou crée les données sauvegardées
	self.db = LibStub('AceDB-3.0'):New('Broker_CashDB', sv_defaults, true)
	local _ = self.db.char.dummy	-- S'assure que la table self.db.char est initialisée

	-- conversion des options v1.3.3 => v1.4.0
	self.opts = self.db.global
	do
		local opts = self.opts
		if opts.ldb.showSilver == false or opts.ldb.showCopper == false then
			opts.ldb.showSilverAndCopper = false
			opts.ldb.showSilver = sv_defaults.global.ldb.showSilver
			opts.ldb.showCopper = sv_defaults.global.ldb.showCopper
		end

		if opts.menu.showSilver == false or opts.menu.showCopper == false then
			opts.menu.showSilverAndCopper = false
			opts.menu.showSilver = sv_defaults.global.menu.showSilver
			opts.menu.showCopper = sv_defaults.global.menu.showCopper
		end
	end

	-- Garde une référence directe sur les données sauvegardées
	self.sv = _G.Broker_CashDB

	-- Recense tous les personnages connus et calcule la richesse de chaque royaume
	self:CountWealth()

	-- Crée l'icône LDB
	self.dataObject = libLDB:NewDataObject('Broker_Cash', {
		type    = 'data source',
		icon    = 'Interface\\MINIMAP\\TRACKING\\Banker',
		text    = 'Cash',
		OnEnter = function(f) addon:ShowMainTooltip(f) end
	})

	-- Commandes
	for _,cmd in ipairs({ 'brokercash', 'bcash', 'cash', 'bc' }) do
		self:RegisterChatCommand(cmd, 'ChatCmdHandler')
	end
end

-----------------------------------------------------------------------------
-- GLOBALS: IsAddOnLoaded, LoadAddOn, DevTools_Dump
function addon:Dump(x)
    if not IsAddOnLoaded('Blizzard_DebugTools') then LoadAddOn('Blizzard_DebugTools') end
    DevTools_Dump(x)
end
--
