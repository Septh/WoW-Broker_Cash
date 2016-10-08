
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

	return string.format('%s %02d%s %02d%s', gold > 0 and BreakUpLargeNumbers(gold) .. GOLD_ICON_STRING or '',
	                                         silver, SILVER_ICON_STRING,
										     copper, COPPER_ICON_STRING)
end

local function GetMoneyVariationString(money)
	if money == 0 then
		return COLOR_YELLOW .. '--' .. COLOR_END
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
		icon    = 'Interface\\MoneyFrame\\UI-SilverIcon',
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
		sec   = 0
	}

	-- Début du jour courant
	limit.day   = today.day
	limit.month = today.month
	limit.year  = today.year
	self.startOfDay = time(limit)

	-- Début de la semaine courante
	limit.day   = today.day - today.wday + self.db.global.firstDoW
	limit.month = today.month
	limit.year  = today.year
	if (limit.day < 1) then
		limit.day = 1
		limit.month = limit.month - 1
		if limit.month < 1 then
			limit.month = 1
			limit.year = limit.year - 1
		end
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
function addon:ShowMainTooltip(LDBFrame)

	if self.mainTooltip and self.mainTooltip:IsShown() then return end

	-- Prépare le tooltip
	self.mainTooltip = libQTip:Acquire('BrokerCash_MainTooltip', 2, 'LEFT', 'RIGHT')
	self.mainTooltip:SmartAnchorTo(LDBFrame)
	self.mainTooltip:SetAutoHideDelay(0.1, LDBFrame, function() addon:HideMainTooltip() end)
	-- self.mainTooltip.OnRelease = function() addon.mainTooltip = nil end,
	self.mainTooltip:Clear()
	self.mainTooltip:SetCellMarginH(4)

	-- Header
	self.mainTooltip:AddHeader(L['Name'], L['Cash'])
	self.mainTooltip:AddSeparator()

	-- Prépare les données. Obligé de le faire ici dynamiquement
	-- car les stats des persos peuvent changer à tout moment
	local charsDB, realmMoney, totalMoney = rawget(Broker_CashDB, 'char'), 0, 0

	-- Liste tous les personnages, par ordre des royaumes triés au début
	local rln, ln
	for _,realm in ipairs(self.sortedRealms) do
		self.mainTooltip:AddLine(' ', ' ')					-- Ligne vide
		rln = self.mainTooltip:AddLine(realm)				-- Nom du royaume
		self.mainTooltip:SetLineTextColor(rln, 1, 1, 0, 1)	-- (en jaune)

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

			-- Ajoute le personnage
			ln = self.mainTooltip:AddLine()
			self.mainTooltip:SetCell(ln, 1, name, nil, nil, nil, nil, 10)
			self.mainTooltip:SetCell(ln, 2, GetCoinTextureString(charData.money))

			-- Gestion du second tooltip pour cette ligne
			self.mainTooltip:SetLineScript(ln, 'OnEnter', function(lineFrame, charKey) addon:ShowSubTooltip(lineFrame, charKey) end, charKey)
			self.mainTooltip:SetLineScript(ln, 'OnLeave', function() addon:HideSubTooltip() end)

			-- Surligne la ligne si c'est le perso courant
			if realm == self.charRealm and name == self.charName then
				self.mainTooltip:SetLineColor(ln, 1, 1, 0, 0.25)
				-- self.mainTooltip:SetLineTextColor(ln, 1, 1, 0, 1)
			end

			-- Comptabilise la richesse par royaume / totale
			realmMoney = realmMoney + charData.money
			totalMoney = totalMoney + charData.money
		end

		-- Ajoute le total du royaume à côté de son nom
		self.mainTooltip:SetCell(rln, 2, GetCoinTextureString(realmMoney))
	end

	-- Ajoute le grand total
	self.mainTooltip:AddLine(' ')
	self.mainTooltip:AddSeparator()
	self.mainTooltip:AddLine('Total', GetCoinTextureString(totalMoney))

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
	self.subTooltip:SetCellMarginH(10)

	-- Affiche les données du personnage
	local charData = rawget(Broker_CashDB, 'char')[charKey]
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
