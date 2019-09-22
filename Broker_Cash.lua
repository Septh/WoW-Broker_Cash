-- Broker: Cash v2.1.1
-- By Septh, BSD licenced
--
-- GLOBALS: LibStub, Broker_CashDB

-- API
local GetAddOnMetadata, UnitName, GetRealmName, InCombatLockdown = GetAddOnMetadata, UnitName, GetRealmName, InCombatLockdown
local GetMoney, BreakUpLargeNumbers = GetMoney, BreakUpLargeNumbers
local CreateColor, CopyTable, tDeleteItem, SecondsToTime = CreateColor, CopyTable, tDeleteItem, SecondsToTime
local UIParent, GameTooltipText, GameTooltipTextSmall = UIParent, GameTooltipText, GameTooltipTextSmall
local GameMenuFrame, InterfaceOptionsFrame = GameMenuFrame, InterfaceOptionsFrame
local SILVER_PER_GOLD, COPPER_PER_GOLD, COPPER_PER_SILVER = SILVER_PER_GOLD, COPPER_PER_GOLD, COPPER_PER_SILVER

-- Environnement
local addonName, addonSpace = ...
local addon   = LibStub('AceAddon-3.0'):NewAddon(addonSpace, addonName, 'AceConsole-3.0', 'AceEvent-3.0', 'AceTimer-3.0')
local L       = LibStub('AceLocale-3.0'):GetLocale(addonName)
local VERSION = GetAddOnMetadata(addonName, 'Version')

-- Bibliothèques
local libLDB  = LibStub('LibDataBroker-1.1')
local libQTip = LibStub('LibQTip-1.0')

-- Textures
local tth = select(2, GameTooltipText:GetFontObject():GetFont())
local GOLD_ICON_STRING    = ('|TInterface\\MoneyFrame\\UI-GoldIcon:%d:%d:2:0|t'):format(tth, tth)
local SILVER_ICON_STRING  = ('|TInterface\\MoneyFrame\\UI-SilverIcon:%d:%d:2:0|t'):format(tth, tth)
local COPPER_ICON_STRING  = ('|TInterface\\MoneyFrame\\UI-CopperIcon:%d:%d:2:0|t'):format(tth, tth)
local PLUS_BUTTON_STRING  = ('|TInterface\\Buttons\\UI-PlusButton-Up:%d:%d:2:0|t'):format(tth, tth)
local MINUS_BUTTON_STRING = ('|TInterface\\Buttons\\UI-MinusButton-Up:%d:%d:2:0|t'):format(tth, tth)

-- Couleurs
local COLOR_RED    = CreateColor(0.8, 0.1, 0.1, 1)
local COLOR_GREEN  = CreateColor(0.1, 0.8, 0.1, 1)
local COLOR_YELLOW = CreateColor(0.8, 0.8, 0.1, 1)

-- Gestion des statistiques
local FIRST_DAY_OF_WEEK = 2	-- Lundi

-- Données des personnages
local currentChar    = UnitName('player')
local currentRealm   = GetRealmName()
local currentCharKey = currentChar .. ' - ' .. currentRealm
local sortedRealms, sortedChars, realmsWealths = {}, {}, {}

-- Données sauvegardées
local MIN_SESSION_THRESHOLD, MAX_SESSION_THRESHOLD = 0, 300

local sv_defaults = {
    global = {
        general = {
            sessionThreshold = 60,
        },
        ldb = {
            showSilverAndCopper = true,
        },
        menu = {
            disableInCombat     = true,
            showSilverAndCopper = true,
            showSubTooltips     = true,
        }
    },
    char = {
        since      = 0,
        lastSaved  = 0,
        money      = 0,
        session    = 0,  -- v2.0.0
        lastLogout = 0,  -- v2.1.0
        day        = 0,
        week       = 0,
        month      = 0,
        year       = 0,
        ever       = 0   -- v1.4.0
    }
}

-- Panneau des options
local options_panel = {
    name    = ('%s v%s'):format(addonName, VERSION),
    handler = addon,
    type    = 'group',
    childGroups = 'tab',
    args = {
        options = {
            name  = L['Options'],
            type  = 'group',
            order = 1,
            get   = 'OptionsPanel_GetOpt',
            set   = 'OptionsPanel_SetOpt',
            args  = {
                general = {
                    name   = L['OPTIONS_GENERAL'],
                    type   = 'group',
                    inline = true,
                    order  = 10,
                    args   = {
                        sessionThreshold = {
                            name    = L['OPTS_SESSION_THRESHOLD'],
                            order   = 1,
                            width   = 'full',
                            type    = 'range',
                            min     = MIN_SESSION_THRESHOLD,
                            max     = MAX_SESSION_THRESHOLD,
                            step    = 1,
                            bigStep = 10
                        },
                        sessionThresholdDesc = {
                            name     = '\n' .. L['OPTS_SESSION_THRESHOLD_DESC'],
                            order    = 2,
                            type     = 'description',
                            fontSize = 'small',
                        }
                    },
                },
                ldb = {
                    name   = L['OPTIONS_LDB'],
                    type   = 'group',
                    inline = true,
                    order  = 20,
                    args   = {
                        showSilverAndCopper = {
                            name      = L['OPTS_SMALL_PARTS'],
                            desc      = L['OPTS_SMALL_PARTS_DESC'],
                            descStyle = 'inline',
                            type      = 'toggle',
                            width     = 'full',
                            order     = 2,
                        },
                    },
                },
                menu = {
                    name   = L['OPTIONS_MENU'],
                    type   = 'group',
                    inline = true,
                    order  = 30,
                    args   = {
                        disableInCombat = {
                            name      = L['OPTS_DISABLE_IN_COMBAT'],
                            desc      = L['OPTS_DISABLE_IN_COMBAT_DESC'],
                            descStyle = 'inline',
                            type      = 'toggle',
                            width     = 'full',
                            order     = 1,
                        },
                        showSilverAndCopper = {
                            name      = L['OPTS_SMALL_PARTS'],
                            desc      = L['OPTS_SMALL_PARTS_DESC'],
                            descStyle = 'inline',
                            type      = 'toggle',
                            width     = 'full',
                            order     = 2,
                        },
                        showSubTooltips = {
                            name      = L['Show Details'],
                            desc      = L['OPTS_SHOW_DETAILS_DESC'],
                            descStyle = 'inline',
                            type      = 'toggle',
                            width     = 'full',
                            order     = 3,
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
                -- sep1 = {
                --     type  = 'header',
                --     name  = '',
                --     order = 2
                -- },
                --
                -- Les personnages sont insérés ici ultérieurement
                --
                -- sep2 = {
                --     type  = 'header',
                --     name  = '',
                --     order = 99,
                -- },
                actions = {
                    type   = 'group',
                    name   = function() return false end,	-- Permet d'avoir un groupe sans titre ni cadre
                    inline = true,
                    order  = 100,
                    args   = {
                        count = {
                            type     = 'description',
                            name     = function() return addon:OptionsPanel_GetNumSelected() end,
                            width    = 'fill',				-- Valeur magique dans AceConfigDialog-3.0
                            order    = 1,
                            fontSize = 'medium',
                        },
                        reset = {
                            type     = 'execute',
                            name     = L['Reset'],
                            order    = 2,
                            disabled = 'OptionsPanel_IsActionDisabled',
                            confirm  = 'OptionsPanel_ConfirmAction',
                            func     = 'OptionsPanel_DoResetCharacters',
                        },
                        delete = {
                            type     = 'execute',
                            name     = L['Delete'],
                            order    = 3,
                            disabled = 'OptionsPanel_IsActionDisabled',
                            confirm  = 'OptionsPanel_ConfirmAction',
                            func     = 'OptionsPanel_DoDeleteCharacters',
                        },
                    }
                }
            }
        },
    }
}
local selectedToons, numSelectedToons = {}, 0

-- Tooltips
local mainTooltip, subTooltip
local unfoldedRealms = {}

local highlightTexture = UIParent:CreateTexture(nil, 'OVERLAY')
highlightTexture:SetTexture('Interface\\QuestFrame\\UI-QuestTitleHighlight')
highlightTexture:SetBlendMode('ADD')

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

-------------------------------------------------------------------------------
if (GetLocale() == 'frFR') then
    -- Fixe un bug dans le GlobalStrings.lua français
    BreakUpLargeNumbers = function(amount)
        local left, num, right = string.match(amount,'^([^%d]*%d)(%d*)(.-)$')
        return left .. (num:reverse():gsub('(%d%d%d)','%1 '):reverse()) .. right
    end
end

local function GetAbsoluteMoneyString(amount, showSilverAndCopper)
    amount = amount or 0

    local gold   = math.floor(amount / COPPER_PER_GOLD)
    local silver = math.floor(amount / SILVER_PER_GOLD) % SILVER_PER_GOLD
    local copper = amount % COPPER_PER_SILVER

    local tbl, fmt = {}, ''
    if gold > 0 then
        tbl[#tbl + 1] = BreakUpLargeNumbers(gold) .. GOLD_ICON_STRING
    end
    if showSilverAndCopper or (gold == 0) then
        if silver > 0 then
            fmt = (gold == 0) and '%d%s' or '%02d%s'
            tbl[#tbl + 1] = fmt:format(silver, SILVER_ICON_STRING)
        end
        fmt = (gold + silver == 0) and '%d%s' or '%02d%s'
        tbl[#tbl + 1] = fmt:format(copper, COPPER_ICON_STRING)
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
function addon:OptionsPanel_DoDeleteCharacters(info, value)

    local sv = self.sv
    for key in pairs(selectedToons) do
        sv.char[key] = nil
        sv.profileKeys[key] = nil

        -- Supprime aussi le perso de la table des options
        local name, realm = SplitCharKey(key)

        tDeleteItem(sortedChars[realm], name)
        if #sortedChars[realm] == 0 then
            sortedChars[realm] = nil

            tDeleteItem(sortedRealms, realm)
            options_panel.args.database.args[realm] = nil
        else
            options_panel.args.database.args[realm].values[name] = nil
        end
    end

    -- Déselectionne tous les personnages
    numSelectedToons = #wipe(selectedToons)

    -- Recalcule la richesse des royaumes
    self:AuditRealms()
end

-- Réinitialise les statistiques des personnages sélectionnés
function addon:OptionsPanel_DoResetCharacters(info, value)

    -- Traitement spécial pour le personnage courant
    if selectedToons[currentCharKey] then
        selectedToons[currentCharKey] = nil

        self.db.char.money   = GetMoney()
        self.db.char.session = 0
        self.db.char.day     = 0
        self.db.char.week    = 0
        self.db.char.month   = 0
        self.db.char.year    = 0
        self.db.char.ever    = 0
    end

    -- Tous les autres...
    local chars = self.sv.char
    for key in pairs(selectedToons) do
        chars[key].money   = nil
        chars[key].session = nil
        chars[key].day     = nil
        chars[key].week    = nil
        chars[key].month   = nil
        chars[key].year    = nil
        chars[key].ever    = nil
    end

    -- Déselectionne tous les personnages
    numSelectedToons = #wipe(selectedToons)

    -- Recalcule la richesse des royaumes
    self:AuditRealms()
end

-- Affiche une demande de confirmation avant réinitialisation/suppression
function addon:OptionsPanel_ConfirmAction(info)

    -- str = RESET_TOON(S) ou DELETE_TOON(S)
    local str = info[#info]:upper() .. '_TOON' .. (numSelectedToons > 1 and 'S' or '')
    str = L[str]:format(numSelectedToons)

    -- Construit la demande de confirmation
    local tbl = {}
    for k in pairs(selectedToons) do
        tbl[#tbl + 1] = k
    end
    table.sort(tbl, function(t1, t2)
        return InvertCharKey(t1) < InvertCharKey(t2)
    end)
    return str .. '\n\n' .. table.concat(tbl, '\n') .. '\n\n' .. L['Are you sure?']
end

-- Vérifie si les boutons Supprimer et Réinitialiser doivent être désactivés
function addon:OptionsPanel_IsActionDisabled(info)
    -- True si (aucune sélection) OU (le bouton est 'Supprimer' ET le personnage courant fait partie des sélectionnés)
    return numSelectedToons == 0 or (info[#info] == 'delete' and selectedToons[currentCharKey])
end

-- Sélectionne / désélectionne un personnage
function addon:OptionsPanel_IsToonSelected(info, opt)
    return selectedToons[MakeCharKey(opt, info[#info])]
end

function addon:OptionsPanel_SetToonSelected(info, opt, value)
    local key = MakeCharKey(opt, info[#info])
    if value then
        selectedToons[key] = true
        numSelectedToons   = numSelectedToons + 1
    else
        selectedToons[key] = nil
        numSelectedToons   = numSelectedToons - 1
    end
end

-- Met à jour le nombre de personnages sélectionnés dans le dialogue
function addon:OptionsPanel_GetNumSelected(info)
    local fmt = 'NUMSELECTED_' .. (numSelectedToons > 1 and 'X' or numSelectedToons)
    return L[fmt]:format(numSelectedToons)
end

-- Gestion des checkboxes
function addon:OptionsPanel_GetOpt(info)
    return self.opts[info[#info-1]][info[#info]]
end

function addon:OptionsPanel_SetOpt(info, value)
    -- info[#info - 1] = 'menu' ou 'ldb', info[#info] = l'option cliquée
    self.opts[info[#info-1]][info[#info]] = value

    -- Met à jour le texte du LDB le cas échéant
    if info[#info-1] == 'ldb' then
        self.dataObject.text = GetAbsoluteMoneyString(self.db.char.money, self.opts.ldb.showSilverAndCopper)
    end
end

-- Affiche/masque le dialogue des options
--   BuildOptionsPanel() est appelée par ShowOptionsPanel() et par la fenêtre des options standard
--    ShowOptionsPanel() est appelée par ToggleOptionsPanel() et par les commandes slash
--  ToggleOptionsPanel() est appelée quand on clique sur l'icône LDB
function addon:BuildOptionsPanel()

    -- Construit le dialogue si ce n'est pas déjà fait
    if not options_panel.args.database.args[currentRealm] then

        -- Retrie les royaumes, mais cette fois par ordre alphabétique
        local orderedRealms = CopyTable(sortedRealms)
        table.sort(orderedRealms)

        -- Insère les royaumes et leurs personnages dans le panneau d'options
        for i,realm in ipairs(orderedRealms) do
            options_panel.args.database.args[realm] = {
                name   = realm,
                type   = 'multiselect',
                descStyle = 'inline',   -- Pas de tooltip svp :)
                get    = 'OptionsPanel_IsToonSelected',
                set    = 'OptionsPanel_SetToonSelected',
                values = {},
                order  = 10 + i
            }

            for _,name in ipairs(sortedChars[realm]) do
                options_panel.args.database.args[realm].values[name] = name
            end
        end
    end
end

function addon:ShowOptionsPanel(msg)

    -- Sauf si en combat ou si le menu ou les options standard sont affichés
    if InCombatLockdown() or GameMenuFrame:IsShown() or InterfaceOptionsFrame:IsShown() then return end

    self:BuildOptionsPanel()
    LibStub('AceConfigDialog-3.0'):Open(addonName)
end

function addon:ToggleOptionsPanel()

    -- Masque le tooltip
    self:HideMainTooltip()

    -- Masque le dialogue s'il est affiché, l'affiche sinon
    local acd = LibStub('AceConfigDialog-3.0')
    if acd.OpenFrames[addonName] then
        acd:Close(addonName)
    else
        self:ShowOptionsPanel()
    end
end

-------------------------------------------------------------------------------
-- Gestion du tooltip secondaire
-------------------------------------------------------------------------------
function addon:PrepareSubTooltip(mainTooltipLine)
    if not self.opts.menu.showSubTooltips then return end

    -- Affiche (ou déplace) le sous-tooltip
    if not subTooltip then
        subTooltip = libQTip:Acquire(addonName .. '_SubTooltip', 2, 'LEFT', 'RIGHT')
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
function addon:ShowRealmTooltip(realmLineFrame, selectedRealm)
    local stt = self:PrepareSubTooltip(realmLineFrame)
    if not stt then return end

    -- Calcule et affiche les données du royaume
    local realmDay, realmWeek, realmMonth, realmYear, realmEver = 0, 0, 0, 0, 0
    for key,char in pairs(self.sv.char) do
        local _, realm = SplitCharKey(key)
        if realm == selectedRealm then
            realmDay   = realmDay   + (char.day   or 0)
            realmWeek  = realmWeek  + (char.week  or 0)
            realmMonth = realmMonth + (char.month or 0)
            realmYear  = realmYear  + (char.year  or 0)
            realmEver  = realmEver  + (char.ever  or 0)
        end
    end

    local showSilverAndCopper = self.opts.menu.showSilverAndCopper
    stt:AddLine(L['Today'],      GetRelativeMoneyString(realmDay,   showSilverAndCopper))
    stt:AddLine(L['This week'],  GetRelativeMoneyString(realmWeek,  showSilverAndCopper))
    stt:AddLine(L['This month'], GetRelativeMoneyString(realmMonth, showSilverAndCopper))
    stt:AddLine(L['This year'],  GetRelativeMoneyString(realmYear,  showSilverAndCopper))
    stt:AddLine(L['Ever'],       GetRelativeMoneyString(realmEver,  showSilverAndCopper))
    stt:Show()
end

-------------------------------------------------------------------------------
function addon:ShowCharTooltip(charLineFrame, selectedCharKey)
    local stt = self:PrepareSubTooltip(charLineFrame)
    if not stt then return end

    -- Affiche les données du personnage
    local char = self.sv.char[selectedCharKey]
    stt:AddLine(); stt:SetCell(1, 1, selectedCharKey, 2)
    stt:AddLine(); stt:SetCell(2, 1, L['RECORDED_SINCE']:format(date(L['DATE_FORMAT'],      char.since)),     2)
    stt:AddLine(); stt:SetCell(3, 1,     L['LAST_SAVED']:format(date(L['DATE_TIME_FORMAT'], char.lastSaved)), 2)
    stt:AddLine(''); stt:AddSeparator(); stt:AddLine('')

    local showSilverAndCopper = self.opts.menu.showSilverAndCopper
    if selectedCharKey == currentCharKey then
        stt:AddLine(L['Current Session'], GetRelativeMoneyString(self.db.char.session, showSilverAndCopper))
    end
    stt:AddLine(L['Today'],      GetRelativeMoneyString(char.day   or 0, showSilverAndCopper))
    stt:AddLine(L['This week'],  GetRelativeMoneyString(char.week  or 0, showSilverAndCopper))
    stt:AddLine(L['This month'], GetRelativeMoneyString(char.month or 0, showSilverAndCopper))
    stt:AddLine(L['This year'],  GetRelativeMoneyString(char.year  or 0, showSilverAndCopper))
    stt:AddLine(L['Ever'],       GetRelativeMoneyString(char.ever  or 0, showSilverAndCopper))
    stt:Show()
end

-------------------------------------------------------------------------------
function addon:HideSubTooltip()
    if subTooltip then
        subTooltip:Release()
        subTooltip = nil
    end
end

-------------------------------------------------------------------------------
-- Gestion du tooltip principal
-------------------------------------------------------------------------------

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

-- Remplit le tooltip principal
function addon:UpdateMainTooltip()
    local mtt = mainTooltip
    if not mtt then return end

    -- Construit le tooltip
    local showSilverAndCopper = self.opts.menu.showSilverAndCopper
    local ln, rln

    mtt:Hide()
    mtt:Clear()
    mtt:SetCellMarginV(2)

    ---------------------------------------------------------------------------
    -- 1/ Le header
    ---------------------------------------------------------------------------
    mtt:AddHeader(L['Name'], L['Cash'])
    mtt:AddSeparator(); mtt:AddLine('')

    ---------------------------------------------------------------------------
    -- 2/ Le personnage courant
    ---------------------------------------------------------------------------
    mtt:AddLine(currentCharKey, GetAbsoluteMoneyString(self.db.char.money, showSilverAndCopper))
    ln = mtt:AddLine(); mtt:SetCell(ln, 1, L['Current Session'], GameTooltipTextSmall, 1, 20); mtt:SetCell(ln, 2, GetRelativeMoneyString(self.db.char.session, showSilverAndCopper), GameTooltipTextSmall)
    ln = mtt:AddLine(); mtt:SetCell(ln, 1, L['Today'],           GameTooltipTextSmall, 1, 20); mtt:SetCell(ln, 2, GetRelativeMoneyString(self.db.char.day,     showSilverAndCopper), GameTooltipTextSmall)
    ln = mtt:AddLine(); mtt:SetCell(ln, 1, L['This week'],       GameTooltipTextSmall, 1, 20); mtt:SetCell(ln, 2, GetRelativeMoneyString(self.db.char.week,    showSilverAndCopper), GameTooltipTextSmall)
    ln = mtt:AddLine(); mtt:SetCell(ln, 1, L['This month'],      GameTooltipTextSmall, 1, 20); mtt:SetCell(ln, 2, GetRelativeMoneyString(self.db.char.month,   showSilverAndCopper), GameTooltipTextSmall)
    ln = mtt:AddLine(); mtt:SetCell(ln, 1, L['This year'],       GameTooltipTextSmall, 1, 20); mtt:SetCell(ln, 2, GetRelativeMoneyString(self.db.char.year,    showSilverAndCopper), GameTooltipTextSmall)
    ln = mtt:AddLine(); mtt:SetCell(ln, 1, L['Ever'],            GameTooltipTextSmall, 1, 20); mtt:SetCell(ln, 2, GetRelativeMoneyString(self.db.char.ever,    showSilverAndCopper), GameTooltipTextSmall)
    mtt:AddLine(''); mtt:AddSeparator(); mtt:AddLine('')

    ---------------------------------------------------------------------------
    -- 3/ Tous les personnages, groupés par royaume
    ---------------------------------------------------------------------------

    -- Trie les royaumes par ordre décroissant de richesse
    -- (fait ici car l'ordre peut changer à tout moment selon le perso courant)
    table.sort(sortedRealms, function(r1, r2)
        return realmsWealths[r1] > realmsWealths[r2]
    end)

    -- Ajoute tous les personnages, royaume par royaume
    local totalMoney = 0
    for _,realm in ipairs(sortedRealms) do
        local unfolded, realmMoney = unfoldedRealms[realm], realmsWealths[realm]

        -- Comptabilise la richesse totale
        totalMoney = totalMoney + realmMoney

        -- 1/ Nom du royaume + nombre de personnages + richesse du royaume
        rln = mtt:AddLine()
        mtt:SetCell(rln, 1, ('%s %s (%d)'):format(unfolded and MINUS_BUTTON_STRING or PLUS_BUTTON_STRING, realm, #sortedChars[realm]))
        mtt:SetCell(rln, 2, GetAbsoluteMoneyString(realmMoney, showSilverAndCopper))
        mtt:SetLineTextColor(rln, COLOR_YELLOW:GetRGBA())
        mtt:SetLineScript(rln, 'OnEnter',     MainTooltip_OnEnterRealm, realm)
        mtt:SetLineScript(rln, 'OnLeave',     MainTooltip_OnLeaveRealm)
        mtt:SetLineScript(rln, 'OnMouseDown', MainTooltip_OnClickRealm, realm)

        -- 2/ Tous les personnages de ce royaume
        if unfolded then
            local chars = self.sv.char

            -- Trie les personnages du royaume par ordre décroissant de richesse
            -- (fait ici car l'ordre peut changer à tout moment selon le perso courant)
            table.sort(sortedChars[realm], function(n1, n2)
                n1, n2 = MakeCharKey(n1, realm), MakeCharKey(n2, realm)
                return ((chars[n1].money) or 0) > ((chars[n2].money) or 0)
            end)

            for _,name in ipairs(sortedChars[realm]) do
                local key = MakeCharKey(name, realm)

                -- Ajoute le personnage
                ln = mtt:AddLine()
                mtt:SetCell(ln, 1, name, 1, 20)
                mtt:SetCell(ln, 2, GetAbsoluteMoneyString(chars[key].money or 0, showSilverAndCopper))
                mtt:SetLineScript(ln, 'OnEnter', MainTooltip_OnEnterChar, key)
                mtt:SetLineScript(ln, 'OnLeave', MainTooltip_OnLeaveChar)
            end
            mtt:AddLine('')
        end
    end

    ---------------------------------------------------------------------------
    -- 4/ Ajoute le grand total
    ---------------------------------------------------------------------------
    mtt:AddLine(''); mtt:AddSeparator(); mtt:AddLine('')
    mtt:AddLine(L['Total'], GetAbsoluteMoneyString(totalMoney, showSilverAndCopper))

    -- Fini
    mtt:Show()
end

-------------------------------------------------------------------------------
function addon:ShowMainTooltip(LDBFrame)

    -- N'affiche pas le tooltip en plein combat
    if self.opts.menu.disableInCombat and InCombatLockdown() then return end

    if not mainTooltip then
        mainTooltip = libQTip:Acquire(addonName .. '_MainTooltip', 2, 'LEFT', 'RIGHT')
        mainTooltip:SmartAnchorTo(LDBFrame)
        mainTooltip:SetAutoHideDelay(0.1, LDBFrame, function() addon:HideMainTooltip() end)

        -- Surligne l'icône LDB, sauf si le display est Bazooka (il le fait déjà)
        if not (LDBFrame:GetName() or ''):find('Bazooka', 1) then
            highlightTexture:SetParent(LDBFrame)
            highlightTexture:SetAllPoints(LDBFrame)
            highlightTexture:Show()
        end
    end
    self:UpdateMainTooltip()
end

-------------------------------------------------------------------------------
function addon:HideMainTooltip()
    self:HideSubTooltip()

    if mainTooltip then
        mainTooltip:Release()
        mainTooltip = nil
    end

    -- Cache le surlignage
    highlightTexture:SetParent(UIParent)
    highlightTexture:Hide()
end

-------------------------------------------------------------------------------
-- Gestion des statistiques globales
-------------------------------------------------------------------------------
function addon:AuditRealms()

    ---------------------------------------------------------------------------
    -- Recense tous les personnages de tous les royaumes et compte la richesse globale de chaque royaume.
    -- NB: les tables ne sont pas triées ici mais au moment de l'affichage du tooltip
    ---------------------------------------------------------------------------
    table.wipe(sortedRealms)
    table.wipe(sortedChars)
    table.wipe(realmsWealths)

    for key,char in pairs(self.sv.char) do
        local name, realm = SplitCharKey(key)

        if not sortedChars[realm] then
            sortedChars[realm] = {}
            realmsWealths[realm] = 0
            table.insert(sortedRealms, realm)
        end
        table.insert(sortedChars[realm], name)
        realmsWealths[realm] = realmsWealths[realm] + (char.money or 0)
    end
end

-------------------------------------------------------------------------------
function addon:CheckStatsResets()

    local now = date('*t')

    ---------------------------------------------------------------------------
    -- 1/ Calcule les dates de réinitialisation des statistiques
    ---------------------------------------------------------------------------
    local startOfDay, startOfMonth, startOfYear, startOfWeek
    local reset = {
        hour = 0,   -- Toutes les limites sont fixées à 00:00:00
        min  = 0,   -- TODO: Gérer l'heure d'été/hiver ? Si oui, comment ?
        sec  = 0
    }

    -- Début du jour courant
    reset.day   = now.day
    reset.month = now.month
    reset.year  = now.year
    startOfDay = time(reset)

    -- Début du mois courant
    reset.day    = 1
    startOfMonth = time(reset)

    -- Début de l'année courante
    reset.month = 1
    startOfYear = time(reset)

    -- Début de la semaine courante
    local numDaysBack = now.wday - FIRST_DAY_OF_WEEK
    if numDaysBack < 0 then
        numDaysBack = 7 - now.wday
    end
    reset.day   = now.day - numDaysBack
    reset.month = now.month
    reset.year  = now.year
    if reset.day < 1 then
        reset.month = reset.month - 1
        if reset.month < 1 then
            reset.month = 12
            reset.year = reset.year - 1
        end
        -- Nb jours dans ce mois (cf. http://lua-users.org/wiki/DayOfWeekAndDaysInMonthExample)
        reset.day = date('*t', time( { day = 0, month = reset.month + 1, year = reset.year } ))['day']
    end
    startOfWeek = time(reset)

    ---------------------------------------------------------------------------
    -- 2/ Réinitialise les stats périmées
    ---------------------------------------------------------------------------
    for key,char in pairs(self.sv.char) do
        local lastSaved, resetValue = char.lastSaved or 0, key == currentCharKey and 0 or nil

        if lastSaved < startOfDay   then char.day   = resetValue end
        if lastSaved < startOfWeek  then char.week  = resetValue end
        if lastSaved < startOfMonth then char.month = resetValue end
        if lastSaved < startOfYear  then char.year  = resetValue end
    end

    ---------------------------------------------------------------------------
    -- 3/ Recalcule la richesse de tous les royaumes
    ---------------------------------------------------------------------------
    self:AuditRealms()

    -- Rafraîchit le tooltip s'il est affiché
    if mainTooltip and mainTooltip:IsShown() then
        self:UpdateMainTooltip()
    end

    ---------------------------------------------------------------------------
    -- 4/ Relance le chronomètre jusqu'à demain minuit pour la prochaine vérification
    ---------------------------------------------------------------------------
    now.day  = now.day + 1	-- Demain
    now.hour = 0			-- à 0 heure
    now.min  = 0			-- 0 minute
    now.sec  = 1			-- et 1 seconde (marge de sécurité)
    self:ScheduleTimer('CheckStatsResets', difftime(time(now), time()))
end

-------------------------------------------------------------------------------
-- Gestion des stats du personnage courant
-------------------------------------------------------------------------------
function addon:PLAYER_MONEY(evt)

    -- Calcule le gain/la perte d'or
    local diff = GetMoney() - self.db.char.money

    -- Met les stats à jour
    for _,stat in ipairs( { 'money', 'session', 'day', 'week', 'month', 'year', 'ever' } ) do
        self.db.char[stat] = self.db.char[stat] + diff
    end
    self.db.char.lastSaved = time()

    -- Met à jour la richesse du royaume
    realmsWealths[currentRealm] = (realmsWealths[currentRealm] or 0) + diff

    -- Met à jour le texte du LDB
    self.dataObject.text = GetAbsoluteMoneyString(self.db.char.money, self.opts.ldb.showSilverAndCopper)
end

-------------------------------------------------------------------------------
-- Initialisation
-------------------------------------------------------------------------------
function addon:DeferredStart()

    -- Est-ce la première connexion avec ce perso ?
    if self.db.char.since == 0 then
        self.db.char.since = time()
        self.db.char.money = GetMoney()

        -- Rend aussi l'info dispo pour :AuditRealms()
        self.sv.char[currentCharKey].since = self.db.char.since
        self.sv.char[currentCharKey].money = self.db.char.money
    end

    -- Vérifie si les stats doivent être réinitialisées et lance le timer jusqu'à minuit
    self:CheckStatsResets()

    -- Sauve le montant d'or actuel
    self:PLAYER_MONEY()

    -- Ecoute les événements
    self:RegisterEvent('PLAYER_MONEY')
end

-------------------------------------------------------------------------------
function addon:PLAYER_ENTERING_WORLD(evt, isLogin, isReload)

    -- Plus besoin de ça
    self:UnregisterEvent(evt)

    -- Initialise la stat de session si ce n'est pas un reload
    if isLogin == true and isReload == false then
        if (time() - self.db.char.lastLogout) > self.db.global.general.sessionThreshold then
            self.db.char.session = 0
        end
    end

    -- Minimise les imprécisions dues aux millisecondes
    -- en attendant (le début de) la prochaine seconde
    -- pour vérifier les stats et lancer le vrai timer
    local now = date('*t')
    now.sec = now.sec + 1
    self:ScheduleTimer('DeferredStart', difftime(time(now), time()))
end

-------------------------------------------------------------------------------
function addon:PLAYER_LOGOUT()
    self.db.char.lastLogout = time()
end

-------------------------------------------------------------------------------
function addon:OnInitialize()

    -- Initialise AceDB et garde une référence directe sur les données sauvegardées
    self.db   = LibStub('AceDB-3.0'):New('Broker_CashDB', sv_defaults, true)
    self.sv   = _G.Broker_CashDB    -- ou rawget(self.db, 'sv')
    self.opts = self.db.global

    -- Conversion des options v1.3.3 => v1.4.0
    if self.opts.ldb.showSilver == false or self.opts.ldb.showCopper == false then
        self.opts.ldb.showSilverAndCopper = false
        self.opts.ldb.showSilver = nil
        self.opts.ldb.showCopper = nil
    end
    if self.opts.menu.showSilver == false or self.opts.menu.showCopper == false then
        self.opts.menu.showSilverAndCopper = false
        self.opts.menu.showSilver = nil
        self.opts.menu.showCopper = nil
    end

    -- v1.4.0: Ajoute le champ 'ever' si le personnage de l'a pas
    if self.db.char.ever == 0 then
        self.db.char.ever = self.db.char.year
    end

    -- Crée l'objet LDB
    self.dataObject = libLDB:NewDataObject(addonName, {
        type    = 'data source',
        icon    = 'Interface\\MINIMAP\\TRACKING\\Banker',
        text    = GetAbsoluteMoneyString(addon.db.char.money, addon.opts.ldb.showSilverAndCopper),
        OnEnter = function(f) addon:ShowMainTooltip(f) end,
        OnClick = function(f, b) addon:ToggleOptionsPanel() end
    })

    -- Initialise le panneau des options
    LibStub('AceConfig-3.0'):RegisterOptionsTable(addonName, options_panel)
    local optionsFrame = LibStub('AceConfigDialog-3.0'):AddToBlizOptions(addonName)
    optionsFrame.refresh = function() addon:BuildOptionsPanel() end

    -- Active les commandes slash
    for _,cmd in ipairs({ 'brokercash', 'bcash' }) do
        self:RegisterChatCommand(cmd, 'ShowOptionsPanel')
    end

    -- Diffère la fin de l'initialisation à PLAYER_ENTERING_WORLD
    self:RegisterEvent('PLAYER_ENTERING_WORLD')
    self:RegisterEvent('PLAYER_LOGOUT')
end
