
local addon = LibStub('AceAddon-3.0'):NewAddon('Broker_Cash', 'AceConsole-3.0', 'AceEvent-3.0')
local L     = LibStub('AceLocale-3.0'):GetLocale('Broker_Cash')

local libDataBroker = LibStub('LibDataBroker-1.1')
local libQTip       = LibStub('LibQTip-1.0')

local FIRST_DAY_OF_WEEK  = 2	-- Lundi par défaut

local GOLD_ICON_STRING   = '|TInterface\\MoneyFrame\\UI-GoldIcon:14:14:2:0|t'
local SILVER_ICON_STRING = '|TInterface\\MoneyFrame\\UI-SilverIcon:14:14:2:0|t'
local COPPER_ICON_STRING = '|TInterface\\MoneyFrame\\UI-CopperIcon:14:14:2:0|t'

local SILVER_PER_GOLD    = _G.SILVER_PER_GOLD
local COPPER_PER_SILVER  = _G.COPPER_PER_SILVER
local COPPER_PER_GOLD    = _G.COPPER_PER_SILVER * _G.SILVER_PER_GOLD

local COLOR_RED          = RED_FONT_COLOR_CODE
local COLOR_GREEN        = GREEN_FONT_COLOR_CODE
local COLOR_YELLOW       = YELLOW_FONT_COLOR_CODE
local COLOR_END          = FONT_COLOR_CODE_CLOSE

-------------------------------------------------------------------------------
local defaults = {
	global = {
		firstDoW  = FIRST_DAY_OF_WEEK,
		showDay   = true,
		showWeek  = true,
		showMonth = true,
		showYear  = true
	},
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

-------------------------------------------------------------------------------
local function GetCoinTextureString(money)

	local gold   = math.floor(money / COPPER_PER_GOLD)
	local silver = math.floor((money - (gold * COPPER_PER_GOLD)) / COPPER_PER_SILVER)
	local copper = money % COPPER_PER_SILVER

	local str = string.format('%02d%s', copper, COPPER_ICON_STRING)
	if silver > 0 or gold > 0 then
		str = string.format('%02d%s ', silver, SILVER_ICON_STRING) .. str
	end
	if gold > 0 then
		str = string.format('%s%s ', BreakUpLargeNumbers(gold), GOLD_ICON_STRING) .. str
	end
	return str
end

local function GetMoneyVariationString(money)
	if money == 0 then
		return COLOR_YELLOW .. '0' .. COLOR_END
	elseif money < 0 then
		return COLOR_RED .. '-' .. GetCoinTextureString(-money) .. COLOR_END
	else
		return COLOR_GREEN .. '+' .. GetCoinTextureString(money) .. COLOR_END
	end
end

-------------------------------------------------------------------------------
function addon:OnInitialize()

	-- Royaume et perso courants
	self.charRealm = GetRealmName()
	self.charName  = UnitName('player')
	self.charKey   = self.charName .. ' - ' .. self.charRealm
	self.session   = 0

	-- Charge ou crée les données sauvegardées
	self.db = LibStub('AceDB-3.0'):New('Broker_CashDB', defaults, true)
	self.db.char.since = self.db.char.since		-- S'assure que les tables AceDB sont initialisées
												-- si c'est la première fois qu'on charge ce personnage

	-- Recense les royaumes et les personnages connus
	self.sortedRealms = {}
	self.sortedChars  = {}
	do
		local h = {}
		for charKey,_ in pairs(rawget(Broker_CashDB, 'char')) do
			local charName, _, charRealm = strsplit(' ', charKey, 3)	-- strsplit(' - ', charKey) ne fonctionne pas

			-- Nom du royaume (unique)
			if not h[charRealm] then
				h[charRealm] = true
				table.insert(self.sortedRealms, charRealm)
			end

			-- Nom du personnage
			self.sortedChars[charRealm] = self.sortedChars[charRealm] or {}
			table.insert(self.sortedChars[charRealm], charName)
		end

		-- Trie les royaumes par ordre alphabétique, le royaume courant en premier
		table.sort(self.sortedRealms, function(r1, r2)
			if r1 == addon.charRealm then
				return true
			elseif r2 == addon.charRealm then
				return false
			else
				return r1 < r2
			end
		end)
	end

	-- Crée l'icône LDB
	self.dataObject = libDataBroker:NewDataObject('Broker_Cash', {
		type    = 'data source',
		-- icon    = 'Interface\\MoneyFrame\\UI-GoldIcon',
		icon    = 'Interface\\MINIMAP\\TRACKING\\Banker',
		text    = 'Cash',
		OnEnter = function(f) addon:ShowMainTooltip(f) end
	})
end

-------------------------------------------------------------------------------
function addon:OnEnable()

	-- Première connexion avec ce perso ?
	if self.db.char.money == -1 then
		self.db.char.money     = GetMoney()
		self.db.char.since     = time()
		self.db.char.lastSaved = time()
	end

	-- Sauve les données actuelles
	-- (fait ici car l'addon peut être activé/désactivé à tout moment)
	self:PLAYER_MONEY()

	-- Surveille les événements
	self:RegisterEvent('PLAYER_MONEY')
end

function addon:OnDisable()

	-- Ferme et libère les deux tooltips
	if self.subTooltip then
		libQTip:Release(self.subTooltip)
		self.subTooltip = nil
	end

	if self.mainTooltip then
		libQTip:Release(self.mainTooltip)
		self.mainTooltip = nil
	end
end

-------------------------------------------------------------------------------
function addon:PLAYER_MONEY()

	-- Vérifie s'il faut réinitialiser les statistiques
	self:CheckStatResets(self.db.char)

	-- Enregistre la dépense / recette
	local money = GetMoney()
	local diff  = money - self.db.char.money

	-- Met à jour la stat de session
	self.session = self.session + diff

	-- Et les stats quotidienne/habdomadaire/mensuelle/annuelle
	self.db.char.money     = money
	self.db.char.day       = self.db.char.day   + diff
	self.db.char.week      = self.db.char.week  + diff
	self.db.char.month     = self.db.char.month + diff
	self.db.char.year      = self.db.char.year  + diff
	self.db.char.lastSaved = time()

	-- Met à jour le texte du LDB
	local txt = GetCoinTextureString(money)
	if diff ~= 0 then
		txt = txt .. ' (' .. GetMoneyVariationString(diff) .. ')'
	end
	self.dataObject.text = txt
end

-------------------------------------------------------------------------------
function addon:CheckStatResets(charData)

	-- Calcule les dates de réinitialisation des statistiques
	self:CalcResetDates()

	-- Réinitialise à 0 les stats qui ont dépassé leur date limite
	local charLastSaved = charData.lastSaved or 0
	charData.day   = (charData.day   and charLastSaved >= self.startOfDay)   and charData.day   or 0	-- Quotidienne
	charData.week  = (charData.week  and charLastSaved >= self.startOfWeek)  and charData.week  or 0 	-- Hebdomadaire
	charData.month = (charData.month and charLastSaved >= self.startOfMonth) and charData.month or 0 	-- Mensuelle
	charData.year  = (charData.year  and charLastSaved >= self.startOfYear)  and charData.year  or 0 	-- Annuelle
end

-------------------------------------------------------------------------------
function days_in_month(mnth, yr)
	return date('*t', time( {year = yr, month = mnth + 1, day = 0 }))['day']
end

function addon:CalcResetDates()

	-- On recalcule seulement si on a changé de jour
	-- depuis le dernier appel à la fonction
	local today = date('*t')
	if (self.yday or 0) == today.yday then return end
	self.yday = today.yday

	-- Toutes les limites sont calculées à 00:00:00
	local limit = {
		hour  = 0,
		min   = 0,
		sec   = 0,
		isdst = today.isdst
	}

	-- Début du jour courant
	limit.day   = today.day
	limit.month = today.month
	limit.year  = today.year
	self.startOfDay = time(limit)

	-- Début de la semaine courante
	limit.day   = today.day - (today.wday >= self.db.global.firstDoW and (today.wday - self.db.global.firstDoW) or (7 - today.wday))
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
	self.startOfWeek = time(limit)

	-- Début du mois courant
	limit.day   = 1
	limit.month = today.month
	limit.year  = today.year
	self.startOfMonth = time(limit)

	-- Début de l'année courante
	limit.day   = 1
	limit.month = 1
	limit.year  = today.year
	self.startOfYear = time(limit)
end

-------------------------------------------------------------------------------
local function MainTooltip_OnEnterLine(lineFrame, charKey)
	addon:ShowSubTooltip(lineFrame, charKey)
end

local function MainTooltip_OnLeaveLine(lineFrame)
	addon:HideSubTooltip()
end

function addon:ShowMainTooltip(LDBFrame)
	if self.mainTooltip and self.mainTooltip:IsShown() then return end

	-- Prépare le tooltip
	self.mainTooltip = libQTip:Acquire('BrokerCash_MainTooltip', 2, 'LEFT', 'RIGHT')
	self.mainTooltip:SmartAnchorTo(LDBFrame)
	self.mainTooltip:SetAutoHideDelay(0.1, LDBFrame, function() addon:HideMainTooltip() end)
	self.mainTooltip:Clear()
	self.mainTooltip:SetCellMarginH(4)

	-- Header
	self.mainTooltip:AddHeader(L['Name'], L['Cash'])
	self.mainTooltip:AddSeparator()

	-- Prépare les données. Obligé de le faire ici dynamiquement
	-- car les stats de tous les persos peuvent changer à tout moment
	local charsDB, realmMoney, totalMoney = rawget(Broker_CashDB, 'char'), 0, 0

	-- Liste tous les personnages, par ordre des royaumes triés au début
	local rln, ln
	for _,realm in ipairs(self.sortedRealms) do
		self.mainTooltip:AddLine(' ', ' ')					-- Ligne vide

		rln = self.mainTooltip:AddLine()					-- Nom du royaume
		self.mainTooltip:SetCell(rln, 1, realm, 2)			-- Sur 2 cols...
		-- self.mainTooltip:SetLineTextColor(rln, 1, 1, 0, 1)	-- et en jaune

		-- Trie les personnages de ce royaume par ordre de richesse décroissante
		table.sort(self.sortedChars[realm], function(c1, c2)
			return charsDB[c1 .. ' - ' .. realm].money > charsDB[c2 .. ' - ' .. realm].money
		end)

		-- Et les ajoute au tooltip
		realmMoney = 0
		for _,name in ipairs(self.sortedChars[realm]) do
			local charKey = name .. ' - ' .. realm

			-- Vérifie s'il faut réinitialiser les statistiques de ce personnage
			local charData = charsDB[charKey]
			self:CheckStatResets(charData)

			-- Ajoute le personnage (avec une marge de 10 pixels à gauche)
			ln = self.mainTooltip:AddLine()
			self.mainTooltip:SetCell(ln, 1, name, 1, 10)
			self.mainTooltip:SetCell(ln, 2, GetCoinTextureString(charData.money))

			-- Surligne la ligne si c'est le perso courant
			if realm == self.charRealm and name == self.charName then
				self.mainTooltip:SetLineColor(ln, 1, 1, 0, 0.25)
				-- self.mainTooltip:SetLineTextColor(ln, 1, 1, 0, 1)
			end

			-- Gestion du second tooltip pour cette ligne
			self.mainTooltip:SetLineScript(ln, 'OnEnter', MainTooltip_OnEnterLine, charKey)
			self.mainTooltip:SetLineScript(ln, 'OnLeave', MainTooltip_OnLeaveLine)

			-- Comptabilise la richesse par royaume / totale
			realmMoney = realmMoney + charData.money
			totalMoney = totalMoney + charData.money
		end

		-- Ajoute le total du royaume
		rln = self.mainTooltip:AddLine()
		self.mainTooltip:SetCell(rln, 1, L['Total'], 'LEFT', 1, 10)
		self.mainTooltip:SetCell(rln, 2, GetCoinTextureString(realmMoney))
		self.mainTooltip:SetLineTextColor(rln, 0.81, 0.81, 0.18, 1)
	end

	-- Ajoute le grand total
	self.mainTooltip:AddLine(' ')
	self.mainTooltip:AddSeparator()
	self.mainTooltip:AddLine(L['Total'], GetCoinTextureString(totalMoney))

	self.mainTooltip:Show()
end

function addon:HideMainTooltip()

	self:HideSubTooltip()
	if self.mainTooltip then
		self.mainTooltip:Release()
	end
	self.mainTooltip = nil
end

-------------------------------------------------------------------------------
function addon:ShowSubTooltip(mainTooltipLine, charKey)

	-- Affiche (ou déplace) le sous-tooltip
	if not self.subTooltip then
		self.subTooltip = libQTip:Acquire('BrokerCash_SubTooltip', 2, 'LEFT', 'RIGHT')
		self.subTooltip:SetFrameLevel(self.mainTooltip:GetFrameLevel() + 1)
	end
	self.subTooltip:SetPoint('TOPLEFT', mainTooltipLine, 'TOPRIGHT', 0, 10)
	self.subTooltip:Clear()
	self.subTooltip:SetFont(GameTooltipTextSmall)
	self.subTooltip:SetCellMarginH(10)

	-- Affiche les données du personnage
	local charData = rawget(Broker_CashDB, 'char')[charKey]

	-- Un bug dans LibQTip() tronque le texte de la cellule si on utilise le colspan... Tant pis :(
	local ln = self.subTooltip:AddLine()
	self.subTooltip:SetCell(ln, 1, charKey, 'LEFT')

	ln = self.subTooltip:AddLine()
	self.subTooltip:SetCell(ln, 1, (L['Since']):format(date(L['DateFormat'], charData.since)))

	ln = self.subTooltip:AddLine()
	self.subTooltip:SetCell(ln, 1, (L['LastSaved']):format(date(L['DateFormat'], charData.lastSaved)))

	self.subTooltip:AddSeparator()
	self.subTooltip:AddLine()

	-- Affiche les stats du personnage
	if charKey == self.charKey then
		self.subTooltip:AddLine(L['Session'], GetMoneyVariationString(self.session))
	end

	self.subTooltip:AddLine(L['Day'],   GetMoneyVariationString(charData.day))
	self.subTooltip:AddLine(L['Week'],  GetMoneyVariationString(charData.week))
	self.subTooltip:AddLine(L['Month'], GetMoneyVariationString(charData.month))
	self.subTooltip:AddLine(L['Year'],  GetMoneyVariationString(charData.year))
	self.subTooltip:Show()
end

function addon:HideSubTooltip()

	if self.subTooltip then
		self.subTooltip:Release()
	end
	self.subTooltip = nil
end
