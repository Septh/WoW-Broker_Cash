
local addon = LibStub('AceAddon-3.0'):NewAddon('Broker_Cash', 'AceConsole-3.0', 'AceEvent-3.0')

local libDataBroker = LibStub('LibDataBroker-1.1')
local libQTip       = LibStub('LibQTip-1.0')

local FIRST_DAY_OF_WEEK = 2	-- Lundi

local C_RED    = RED_FONT_COLOR_CODE
local C_GREEN  = GREEN_FONT_COLOR_CODE
local C_YELLOW = YELLOW_FONT_COLOR_CODE
local C_END    = FONT_COLOR_CODE_CLOSE

-------------------------------------------------------------------------------
local defaults = {
	global = {
		showDay = true,
		showWeek = true,
		showMonth = true,
		showYear = true
	}
}

-------------------------------------------------------------------------------
function addon:OnInitialize()

	-- Royaume et perso courants
	self.realmName = GetRealmName()
	self.toonName  = UnitName('player')

	-- Charge ou crée les données sauvegardées
	self.db = LibStub('AceDB-3.0'):New('Broker_Cash_DB', defaults, true)

	-- Crée l'icône LDB
	self.dataObject = libDataBroker:NewDataObject('Broker_Cash', {
		type    = 'data source',
		icon    = 'Interface\\MoneyFrame\\UI-SilverIcon',
		text    = 'Cash',
		OnEnter = function(f) addon:ShowTooltip(f) end
	})
end

-------------------------------------------------------------------------------
function addon:OnEnable()

	-- Nouveau perso ?
	if not self.db.realm[self.toonName] then
		local now = time()
		self.db.realm[self.toonName] = {
			since     = now,
			lastSaved = now,
			total     = GetMoney(),
			session   = 0,
			day       = 0,
			week      = 0,
			month     = 0,
			year      = 0
		}
	end
	self.toonData = self.db.realm[self.toonName]

	-- Vérifie s'il faut réinitialiser les données
	self:CheckResets(true)

	-- Surveille les événements
	self:RegisterEvent('PLAYER_MONEY')
	self:RegisterEvent('PLAYER_LOGOUT')
end

function addon:OnDisable()
end

-------------------------------------------------------------------------------
function addon:PLAYER_MONEY()

	-- Vérifie s'il faut réinitialiser les données
	self:CheckResets()

	-- Enregistre la dépense / recette
	local total = GetMoney()
	local diff  = total - self.toonData.total

	self.toonData.total     = total
	self.toonData.session   = self.toonData.session + diff
	self.toonData.day       = self.toonData.day     + diff
	self.toonData.week      = self.toonData.week    + diff
	self.toonData.month     = self.toonData.month   + diff
	self.toonData.year      = self.toonData.year    + diff
	self.toonData.lastSaved = time()
end

-------------------------------------------------------------------------------
function addon:PLAYER_LOGOUT()
	-- Petit nettoyage
	self.toonData.session = nil
end

-------------------------------------------------------------------------------
function addon:CheckResets(isOnLoad)

	-- Pas besoin de recalculer si on n'a pas changé de jour
	local today = date('*t')
	if (self.currDay or 0) == today.yday then return end
	self.currDay = today.yday

	local temp = { hour = 0, min = 0, sec = 0 }

	-- 1/ Réinitialise les données sur la session à chaque démarrage ou /reload
	if isOnLoad then
		self.toonData.session = 0
	end

	-- 2/ Réinitialise le montant du jour si on a changé de jour
	--    ou si on n'a pas actualisé depuis plus d'un jour
	temp.day   = today.day
	temp.month = today.month
	temp.year  = today.year
	local startOfDay = time(temp)

	if self.toonData.lastSaved < startOfDay then
		self.toonData.day = 0
	end

	-- 3/ Réinitialise le montant de la semaine en début de semaine
	--    ou si on n'a pas actualisé depuis plus d'une semaine
	temp.day   = today.day - today.wday + FIRST_DAY_OF_WEEK
	temp.month = today.month
	temp.year  = today.year
	if (temp.day < 1) then
		temp.day = 1
		temp.month = temp.month - 1
		if temp.month < 1 then
			temp.month = 1
			temp.year = temp.year - 1
		end
	end
	local startOfWeek = time(temp)

	if today.wday == FIRST_DAY_OF_WEEK or self.toonData.lastSaved < startOfWeek then
		self.toonData.week = 0
	end

	-- 4/ Réinitialise le montant du mois en début de mois
	--    ou si on n'a pas actualisé depuis plus d'un mois
	temp.day   = 1
	temp.month = today.month
	temp.year  = today.year
	local startOfMonth = time(temp)

	if today.day == 1 or self.toonData.lastSaved < startOfMonth then
		self.toonData.month = 0
	end

	-- 5/ Réinitialise le montant de l'année en début d'année
	--  ou si on n'a pas actualisé depuis plus d'une année
	temp.day   = 1
	temp.month = 1
	temp.year  = today.year
	local startOfYear = time(temp)

	if (today.day == 1 and today.month == 1) or self.toonData.lastSaved < startOfYear then
		self.toonData.year = 0
	end
end

-------------------------------------------------------------------------------
function addon:ShowTooltip(LDBFrame)

	self:CheckResets()

	-- Prépare les données
	local function color(n)
		if n < 0 then
			return C_RED .. n .. C_END
		elseif n > 0 then
			return C_GREEN .. '+' .. n .. C_END
		else
			return C_YELLOW .. n .. C_END
		end
	end

	local toons, sorted, total = rawget(Broker_Cash_DB, 'realm')[self.realmName], {}, 0
	for name, data in pairs(toons) do
		table.insert(sorted, { name,				-- Col 1
		                       color(data.session),	-- Col 2
		                       color(data.day),		-- Col 3
							   color(data.week),	-- Col 4
							   color(data.month),	-- COl 5
							   color(data.year),	-- Col 6
							   data.total			-- Col 7
							})
		total = total + data.total
	end

	-- Trie par ordre décroissant de la richesse
	local function cmp(a, b)
		return a[7] > b[7]
	end
	table.sort(sorted, cmp)

	-- Affiche le tooltip
	self.tooltip = libQTip:Acquire('Broker_Cash', 7, 'LEFT', 'RIGHT', 'RIGHT', 'RIGHT', 'RIGHT', 'RIGHT', 'RIGHT')
	self.tooltip:SmartAnchorTo(LDBFrame)
	self.tooltip:SetAutoHideDelay(0.1, LDBFrame, function() addon.tooltip = nil end)

	self.tooltip:Clear()
	self.tooltip:SetCellMarginH(4)

	-- Header
	local ln = self.tooltip:AddHeader('Nom', 'Session', 'Jour', 'Semaine', 'Mois', 'Année', 'Total')
	self.tooltip:AddSeparator()

	-- Personnages de ce royaume
	for k,v in ipairs(sorted) do
		ln = self.tooltip:AddLine(unpack(v))

		if v[1] == self.toonName then
			self.tooltip:SetLineColor(ln, 1, 1, 0, 0.25)
			self.tooltip:SetLineTextColor(ln, 1, 1, 0, 1)
		end
	end

	self.tooltip:AddSeparator()
	self.tooltip:AddLine('Total', '', '', '', '', '', total)

	self.tooltip:Show()
end
