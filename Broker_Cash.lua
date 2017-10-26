
-- Upvalues
-- GLOBALS: LibStub
local tInsert, tRemove, tSort = table.insert, table.remove, table.sort
local floor = math.floor

local GetAddOnMetadata, UnitName, GetRealmName = GetAddOnMetadata, UnitName, GetRealmName
local GetMoney, BreakUpLargeNumbers = GetMoney, BreakUpLargeNumbers
local CreateColor, tDeleteItem = CreateColor, tDeleteItem
local UIParent, GameTooltipText, GameTooltipTextSmall = UIParent, GameTooltipText, GameTooltipTextSmall

-- Environnement
local _, addonTable = ...
local Broker_Cash   = LibStub('AceAddon-3.0'):NewAddon(addonTable, 'Broker_Cash', 'AceConsole-3.0', 'AceEvent-3.0')
local L             = LibStub('AceLocale-3.0'):GetLocale('Broker_Cash')
local libDataBroker = LibStub('LibDataBroker-1.1')
local libQTip       = LibStub('LibQTip-1.0')

-- Premier jour de la semaine
local FIRST_DAY_OF_WEEK = 2	-- Lundi
local yday, startOfDay, startOfWeek, startOfMonth, startOfYear

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

-- Données des personnages
local currentChar    = UnitName('player')
local currentRealm   = GetRealmName()
local currentCharKey = currentChar .. ' - ' .. currentRealm
local sessionMoney   = 0
local allRealms, allChars = {}, {}

-- Données sauvegardées
local sv, opts
local db_defaults = {
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
		}
	}
}

-- Dialogue
local dialog_config = {
	name    = 'Broker_Cash v' .. GetAddOnMetadata('Broker_Cash', 'Version'),
	handler = Broker_Cash,
	type    = 'group',
	childGroups = 'tab',
	args = {
		options = {
			name  = L['Options'],
			type  = 'group',
			order = 1,
			get   = 'Dialog_GetOpt',
			set   = 'Dialog_SetOpt',
			args  = {
				infos = {
					type = 'description',
					name = L['DLGINFO10'] .. '\n',
					fontSize = 'medium',
					image = 'Interface\\FriendsFrame\\InformationIcon',
					imageWidth = 24,
					imageHeight = 24,
					order = 1,
				},
				ldb = {
					name   = L['Options_LDB'],
					type   = 'group',
					inline = true,
					order  = 10,
					args   = {
						showSilverAndCopper = {
							name  = L['Show Silver and Copper'],
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
							name = L['Show Silver and Copper'],
							type = 'toggle',
							width = 'full',
							order = 1,
						},
					},
				},
			},
		},
		database = {
			name  = L['Database'],
			type  = 'group',
			order = 2,
			args  = {
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
							type     = 'description',
							name     = function() return Broker_Cash:Dialog_GetNumSelected() end,
							width    = 'fill',					-- Visiblement, une valeur magique dans AceConfigDialog-3.0
							order    = 1,
							fontSize = 'medium',
						},
						reset = {
							type     = 'execute',
							name     = L['Reset'],
							order    = 2,
							disabled = 'Dialog_IsActionDisabled',
							confirm  = 'Dialog_ConfirmAction',
							func     = 'Dialog_DoResetCharacters',
						},
						delete = {
							type     = 'execute',
							name     = L['Delete'],
							order    = 3,
							disabled = 'Dialog_IsActionDisabled',
							confirm  = 'Dialog_ConfirmAction',
							func     = 'Dialog_DoDeleteCharacters',
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
	return charName .. ' - ' .. charRealm
end

local function SplitCharKey(charKey)
	local charName, charRealm = strsplit('-', charKey, 2)
	return strtrim(charName), strtrim(charRealm)
end

local function InvertCharKey(charKey)
	charKey = charKey:gsub('(%S+) %- (%S+)', '%2 - %1')
	return charKey
end

local function days_in_month(m, y)
	-- http://lua-users.org/wiki/DayOfWeekAndDaysInMonthExample
	return date('*t', time( { year = y, month = m + 1, day = 0 } ))['day']
end

local function GetAbsoluteMoneyString(amount, opts)
	amount = amount or 0

	-- D'après FrameXML/MoneyFrame.lua#311
	local gold   = floor(amount / COPPER_PER_GOLD)
	local silver = floor((amount - (gold * COPPER_PER_GOLD)) / COPPER_PER_SILVER)
	local copper = amount % COPPER_PER_SILVER

	local tbl = {}
	if gold > 0 then
		tInsert(tbl, BreakUpLargeNumbers(gold) .. GOLD_ICON_STRING)
	end
	if opts.showSilverAndCopper or gold == 0 then
		if silver > 0 then
			tInsert(tbl, silver .. SILVER_ICON_STRING)
			tInsert(tbl, copper .. COPPER_ICON_STRING)
		else
			tInsert(tbl, copper .. COPPER_ICON_STRING)
		end
	end
	return table.concat(tbl, ' ')
end

local function GetRelativeMoneyString(amount, opts)
	if (amount or 0) == 0 then
		return COLOR_YELLOW:WrapTextInColorCode('0')
	elseif amount < 0 then
		return COLOR_RED:WrapTextInColorCode('-' .. GetAbsoluteMoneyString(-amount, opts))
	else
		return COLOR_GREEN:WrapTextInColorCode('+' .. GetAbsoluteMoneyString(amount, opts))
	end
end

-------------------------------------------------------------------------------
-- Gestion de la boîte de dialogue
-------------------------------------------------------------------------------

-- Supprime les personnages sélectionnés des données sauvegardées
function Broker_Cash:Dialog_DoDeleteCharacters(info, value)
	for key in pairs(selectedToons) do
		sv.char[key] = nil
		sv.profileKeys[key] = nil

		-- Supprime aussi dans la table des options
		local name, realm = SplitCharKey(key)

		tDeleteItem(allChars[realm], name)
		if #allChars[realm] == 0 then
			allChars[realm] = nil

			tDeleteItem(allRealms, realm)
			dialog_config.args.database.args[realm] = nil
		else
			dialog_config.args.database.args[realm].values[name] = nil
		end
	end

	-- Déselectionne tous les personnages et redessine le panneau des options
	numSelectedToons = #wipe(selectedToons)
	LibStub('AceConfigRegistry-3.0'):NotifyChange('Broker_Cash')
end

-- Réinitialise les statistiques des personnages sélectionnés
function Broker_Cash:Dialog_DoResetCharacters(info, value)
	for key in pairs(selectedToons) do
		sv.char[key].lastSaved = time()
		sv.char[key].money     = 0
		sv.char[key].day       = nil
		sv.char[key].week      = nil
		sv.char[key].month     = nil
		sv.char[key].year      = nil
	end

	-- Déselectionne tous les personnages
	numSelectedToons = #wipe(selectedToons)
end

-- Affiche une demande de confirmation avant réinitialisation/suppression
function Broker_Cash:Dialog_ConfirmAction(info)

	-- str = RESET_TOON(S) ou DELETE_TOON(S)
	local str = L[string.upper(info[#info]) .. '_TOON' .. (numSelectedToons > 1 and 'S' or '')]
	str = str:format(numSelectedToons)

	-- Construit la demande de confirmation
	local toons = {}
	for k in pairs(selectedToons) do
		tInsert(toons, k)
	end
	tSort(toons, function(t1, t2)
		return InvertCharKey(t1) < InvertCharKey(t2)
	end)
	return str .. '\n\n' .. table.concat(toons, '\n') .. '\n\n' .. L['Are you sure?']
end

-- Vérifie si les boutons Supprimer et Réinitialiser doivent être désactivés
function Broker_Cash:Dialog_IsActionDisabled(info)
	-- True si (aucune sélection) OU (le bouton est 'Supprimer' ET le personnage courant fait partie des sélectionnés)
	return numSelectedToons == 0 or (info[#info] == 'delete' and selectedToons[currentCharKey])
end

-- Sélectionne / désélectionne un personnage
function Broker_Cash:Dialog_IsToonSelected(info, key)
	return selectedToons[MakeCharKey(key, info[#info])]
end

function Broker_Cash:Dialog_SetToonSelected(info, key, value)
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
function Broker_Cash:Dialog_GetNumSelected(info)
	return string.format(L['NUMSELECTED'], numSelectedToons)
end

function Broker_Cash:Dialog_GetOpt(info)
	return opts[info[#info-1]][info[#info]]			-- opts['ldb'|'menu']['showSilverAndCopper']
end

function Broker_Cash:Dialog_SetOpt(info, value)
	opts[info[#info-1]][info[#info]] = value		-- opts['ldb'|'menu']['showSilverAndCopper']

	-- Rafraîchit le menu
	if info[#info-1] == 'ldb' then
		self:PLAYER_MONEY()
	end
end

-- Affiche le dialogue de réinitialisation/suppression de personnages
function Broker_Cash:ChatCmdHandler(msg)

	-- Construit le dialogue si ce n'est pas déjà fait
	if not selectedToons then
		selectedToons = {}

		-- Insère les royaumes et leurs personnages dans le panneau d'options
		for i,realm in ipairs(allRealms) do
			dialog_config.args.database.args[realm] = {
				type   = 'multiselect',
				name   = realm,
				style  = 'radio',
				get    = 'Dialog_IsToonSelected',
				set    = 'Dialog_SetToonSelected',
				values = {},
				order  = 10 + i
			}

			for _,name in ipairs(allChars[realm]) do
				dialog_config.args.database.args[realm].values[name] = name
			end
		end
		LibStub('AceConfig-3.0'):RegisterOptionsTable('Broker_Cash', dialog_config)
		-- LibStub('AceConfigDialog-3.0'):AddToBlizOptions('Broker_Cash')
	end

	-- Affiche le dialogue, sans aucun personnage sélectionné à l'ouverture
	numSelectedToons = #wipe(selectedToons)
	LibStub('AceConfigDialog-3.0'):Open('Broker_Cash')
end

-------------------------------------------------------------------------------
-- Gestion du tooltip secondaire
-------------------------------------------------------------------------------

-- Affiche le tooltip pour un royaume
function Broker_Cash:ShowRealmTooltip(realmLineFrame, selectedRealm)

	-- Affiche le tooltip
	local stt = self:ShowSubTooltip(realmLineFrame)

	-- Calcule et affiche les données du royaume
	local realmDay, realmWeek, realmMonth, realmYear = 0, 0, 0, 0
	for key,data in pairs(sv.char) do
		local name, realm = SplitCharKey(key)

		if realm == selectedRealm then
			realmDay   = realmDay   + (data.day   or 0)
			realmWeek  = realmWeek  + (data.week  or 0)
			realmMonth = realmMonth + (data.month or 0)
			realmYear  = realmYear  + (data.year  or 0)
		end
	end

	stt:AddLine(L['Day'],   GetRelativeMoneyString(realmDay,   opts.menu))
	stt:AddLine(L['Week'],  GetRelativeMoneyString(realmWeek,  opts.menu))
	stt:AddLine(L['Month'], GetRelativeMoneyString(realmMonth, opts.menu))
	stt:AddLine(L['Year'],  GetRelativeMoneyString(realmYear,  opts.menu))
	stt:Show()
end

-------------------------------------------------------------------------------
-- Affiche le tooltip pour un personnage
function Broker_Cash:ShowCharTooltip(charLineFrame, selectedCharKey)

	-- Affiche le sous-tooltip
	local stt = self:ShowSubTooltip(charLineFrame)

	-- Affiche les données du personnage
	local data = sv.char[selectedCharKey]
	local ln
	ln = stt:AddLine(); stt:SetCell(ln, 1, selectedCharKey, 2)
	ln = stt:AddLine(); stt:SetCell(ln, 1, string.format(L['Since'],     date(L['DateFormat'],     data.since)), 2)
	ln = stt:AddLine(); stt:SetCell(ln, 1, string.format(L['LastSaved'], date(L['DateTimeFormat'], data.lastSaved)), 2)

	stt:AddLine(''); stt:AddSeparator(); stt:AddLine('')

	if selectedCharKey == currentCharKey then
		stt:AddLine(L['Session'], GetRelativeMoneyString(sessionMoney), opts.menu)
	end
	stt:AddLine(L['Day'],   GetRelativeMoneyString(data.day,   opts.menu))
	stt:AddLine(L['Week'],  GetRelativeMoneyString(data.week,  opts.menu))
	stt:AddLine(L['Month'], GetRelativeMoneyString(data.month, opts.menu))
	stt:AddLine(L['Year'],  GetRelativeMoneyString(data.year,  opts.menu))
	stt:Show()
end

-------------------------------------------------------------------------------
function Broker_Cash:HideSubTooltip()
	if subTooltip then
		subTooltip:Release()
	end
	subTooltip = nil
end

-------------------------------------------------------------------------------
function Broker_Cash:ShowSubTooltip(mainTooltipLine)

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
-- Gestion du tooltip principal
-------------------------------------------------------------------------------

-- Déplie/replie un royaume dans le tooltip
local function MainTooltip_OnClickRealm(realmLineFrame, realm, button)
	unfoldedRealms[realm] = not unfoldedRealms[realm]
	Broker_Cash:UpdateMainTooltip()
end

-- Affiche le tooltip secondaire pour un royaume
local function MainTooltip_OnEnterRealm(realmLineFrame, realm)
	Broker_Cash:ShowRealmTooltip(realmLineFrame, realm)
end

local function MainTooltip_OnLeaveRealm(realmLineFrame)
	Broker_Cash:HideSubTooltip()
end

-- Affiche le tooltip secondaire pour un personnage
local function MainTooltip_OnEnterChar(charLineFrame, charKey)
	Broker_Cash:ShowCharTooltip(charLineFrame, charKey)
end

local function MainTooltip_OnLeaveChar(charLineFrame)
	Broker_Cash:HideSubTooltip()
end

-- Affiche le tooltip principal
function Broker_Cash:UpdateMainTooltip()
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
	mtt:AddLine(currentCharKey, GetAbsoluteMoneyString(self.db.char.money, opts.menu))
	mtt:AddLine()
	ln = mtt:AddLine(); mtt:SetCell(ln, 1, L['Session'], GameTooltipTextSmall, 1, 10); mtt:SetCell(ln, 2, GetRelativeMoneyString(sessionMoney,       opts.menu), GameTooltipTextSmall)
	ln = mtt:AddLine(); mtt:SetCell(ln, 1, L['Day'],     GameTooltipTextSmall, 1, 10); mtt:SetCell(ln, 2, GetRelativeMoneyString(self.db.char.day,   opts.menu), GameTooltipTextSmall)
	ln = mtt:AddLine(); mtt:SetCell(ln, 1, L['Week'],    GameTooltipTextSmall, 1, 10); mtt:SetCell(ln, 2, GetRelativeMoneyString(self.db.char.week,  opts.menu), GameTooltipTextSmall)
	ln = mtt:AddLine(); mtt:SetCell(ln, 1, L['Month'],   GameTooltipTextSmall, 1, 10); mtt:SetCell(ln, 2, GetRelativeMoneyString(self.db.char.month, opts.menu), GameTooltipTextSmall)
	ln = mtt:AddLine(); mtt:SetCell(ln, 1, L['Year'],    GameTooltipTextSmall, 1, 10); mtt:SetCell(ln, 2, GetRelativeMoneyString(self.db.char.year,  opts.menu), GameTooltipTextSmall)
	mtt:AddLine(''); mtt:AddSeparator(); mtt:AddLine('')

	-- Ajoute tous les personnages, royaume par royaume
	local realmMoney, totalMoney = 0, 0
	for _,realm in ipairs(allRealms) do

		-- Trie les personnages du royaume par ordre décroissant de richesse
		tSort(allChars[realm], function(n1, n2)
			return ((sv.char[n1 .. ' - ' .. realm].money) or 0) > ((sv.char[n2 .. ' - ' .. realm].money) or 0)
		end)

		-- 1/ Nom du royaume + nombre de personnages (la richesse est ajoutée après la boucle)
		rln = mtt:AddLine()
		mtt:SetCell(rln, 1, string.format('%s %s (%d)', unfoldedRealms[realm] and MINUS_BUTTON_STRING or PLUS_BUTTON_STRING, realm, #allChars[realm]))
		mtt:SetCellTextColor(rln, 1, COLOR_YELLOW:GetRGBA())

		-- Gestion du second tooltip pour cette ligne
		mtt:SetLineScript(rln, 'OnEnter', MainTooltip_OnEnterRealm, realm)
		mtt:SetLineScript(rln, 'OnLeave', MainTooltip_OnLeaveRealm)

		-- Gestion du clic sur cette ligne
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
				mtt:SetCell(ln, 2, GetAbsoluteMoneyString(money, opts.menu))

				-- Gestion du second tooltip pour cette ligne
				mtt:SetLineScript(ln, 'OnEnter', MainTooltip_OnEnterChar, key)
				mtt:SetLineScript(ln, 'OnLeave', MainTooltip_OnLeaveChar)
			end

			-- Comptabilise la richesse par royaume / totale
			realmMoney = realmMoney + money
			totalMoney = totalMoney + money
		end

		-- 3/ Richesse de ce royaume
		mtt:SetCell(rln, 2, GetAbsoluteMoneyString(realmMoney, opts.menu))
		mtt:SetCellTextColor(rln, 2, COLOR_YELLOW:GetRGBA())
		mtt:AddLine('')
	end

	-- Ajoute le grand total
	mtt:AddLine(''); mtt:AddSeparator(); mtt:AddLine('')
	mtt:AddLine(L['Total'], GetAbsoluteMoneyString(totalMoney, opts.menu))

	-- Fini
	mtt:Show()
end

-------------------------------------------------------------------------------
function Broker_Cash:HideMainTooltip()
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
function Broker_Cash:ShowMainTooltip(LDBFrame)
	if not mainTooltip then
		mainTooltip = libQTip:Acquire('BrokerCash_MainTooltip', 2, 'LEFT', 'RIGHT')
		mainTooltip:SmartAnchorTo(LDBFrame)
		mainTooltip:SetAutoHideDelay(0.1, LDBFrame, function() Broker_Cash:HideMainTooltip() end)

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
-- Mise à jour des données du personnage courant à chaque gain ou perte d'argent
-------------------------------------------------------------------------------
local function CalcResetDates()

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
	startOfDay  = time(limit)

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
	limit.day    = 1
	limit.month  = today.month
	limit.year   = today.year
	startOfMonth = time(limit)

	-- Début de l'année courante
	limit.day   = 1
	limit.month = 1
	limit.year  = today.year
	startOfYear = time(limit)
end

-------------------------------------------------------------------------------
function Broker_Cash:CheckStatResets(charData)

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

-------------------------------------------------------------------------------
function Broker_Cash:PLAYER_MONEY()

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
	self.dataObject.text = GetAbsoluteMoneyString(money, opts.ldb)
end

-------------------------------------------------------------------------------
-- Activation/désactivation de l'addon
-------------------------------------------------------------------------------
function Broker_Cash:OnEnable()

	-- Première connexion avec ce personnage ?
	if self.db.char.lastSaved == 0 then
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

-------------------------------------------------------------------------------
function Broker_Cash:OnDisable()
	self:HideMainTooltip()
end

-------------------------------------------------------------------------------
-- Initialisation
-------------------------------------------------------------------------------
function Broker_Cash:OnInitialize()

	-- Charge ou crée les données sauvegardées
	self.db = LibStub('AceDB-3.0'):New('Broker_CashDB', db_defaults, true)
	local _ = self.db.char.dummy	-- S'assure que les tables AceDB sont initialisées (si première utilisation de l'add-on)

	-- => v1.3.4
	-- self.db.global.ldb.showSilverAndCopper = self.db.global.ldb.showSilver or self.db.global.ldb.showCopper
	-- self.db.global.ldb.showSilver = db_defaults.global.ldb.showSilver
	-- self.db.global.ldb.showCopper = db_defaults.global.ldb.showCopper

	-- self.db.global.menu.showSilverAndCopper = self.db.global.menu.showSilver or self.db.global.menu.showCopper
	-- self.db.global.menu.showSilver = db_defaults.global.menu.showSilver
	-- self.db.global.menu.showCopper = db_defaults.global.menu.showCopper

	-- Garde une référence sur les données sauvegardées
	sv = rawget(self.db, 'sv')
	opts = self.db.global

	-- Recense et trie tous les personnages connus
	for key in pairs(sv.char) do
		local name, realm = SplitCharKey(key)

		if allChars[realm] then
			tInsert(allChars[realm], name)
		else
			allChars[realm] = { name }
			tInsert(allRealms, realm)
		end
	end

	-- Trie les royaumes par ordre alphabétique, le royaume courant en premier
	tSort(allRealms, function(r1, r2)
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
		OnEnter = function(f) Broker_Cash:ShowMainTooltip(f) end
	})

	-- Commandes
	self:RegisterChatCommand('brokercash', 'ChatCmdHandler')
	self:RegisterChatCommand('bcash',      'ChatCmdHandler')
	self:RegisterChatCommand('cash',       'ChatCmdHandler')
end
