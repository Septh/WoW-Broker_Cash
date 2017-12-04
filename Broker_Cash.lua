-- Broker: Cash v1.4.1
-- By Septh, BSD licenced
--

-- Upvalues
local GetAddOnMetadata, UnitName, GetRealmName, InCombatLockdown = GetAddOnMetadata, UnitName, GetRealmName, InCombatLockdown
local GetMoney, BreakUpLargeNumbers = GetMoney, BreakUpLargeNumbers
local CreateColor, tDeleteItem = CreateColor, tDeleteItem
local UIParent, GameTooltipText, GameTooltipTextSmall = UIParent, GameTooltipText, GameTooltipTextSmall

-- Environnement
-- GLOBALS: LibStub
local addonName, addonTable = ...
local addon   = LibStub('AceAddon-3.0'):NewAddon(addonTable, addonName, 'AceConsole-3.0', 'AceEvent-3.0')
local L       = LibStub('AceLocale-3.0'):GetLocale(addonName)
local libLDB  = LibStub('LibDataBroker-1.1')
local libQTip = LibStub('LibQTip-1.0')

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
local dayOfYear = 0
local startOfDay, startOfWeek, startOfMonth, startOfYear

-- Données des personnages
local currentChar    = UnitName('player')
local currentRealm   = GetRealmName()
local currentCharKey = currentChar .. ' - ' .. currentRealm
local sessionMoney   = 0
local allRealms, allChars, realmsWealth = {}, {}, {}

-- Données sauvegardées
local sv_defaults = {
    global = {
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
        since     = 0,
        lastSaved = 0,
        money     = 0,
        day       = 0,
        week      = 0,
        month     = 0,
        year      = 0,
        ever      = 0
    }
}

-- Panneau des options
local options_panel = {
    name    = addonName .. ' v' .. GetAddOnMetadata(addonName, 'Version'),
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
                            order = 2,
                        },
                    },
                },
                menu = {
                    name   = L['Options_Menu'],
                    type   = 'group',
                    inline = true,
                    order  = 20,
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
        local fmt
        if silver > 0 then
            fmt = (gold == 0) and '%d%s' or '%02d%s'
            table.insert(tbl, fmt:format(silver, SILVER_ICON_STRING))
        end
        fmt = (gold + silver == 0) and '%d%s' or '%02d%s'
        table.insert(tbl, fmt:format(copper, COPPER_ICON_STRING))
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
    self:AuditRealms()

    -- Déselectionne tous les personnages et redessine le panneau des options
    numSelectedToons = #wipe(selectedToons)
    LibStub('AceConfigRegistry-3.0'):NotifyChange(addonName)
end

-- Réinitialise les statistiques des personnages sélectionnés
function addon:ConfigPanel_DoResetCharacters(info, value)
    local sv = self.sv

    for key in pairs(selectedToons) do
        -- sv.char[key].lastSaved = time()
        if key == currentCharKey then
            sv.char[key].money = GetMoney()
            sv.char[key].day   = 0
            sv.char[key].week  = 0
            sv.char[key].month = 0
            sv.char[key].year  = 0
            sv.char[key].ever  = 0
            sessionMoney       = 0
        else
            sv.char[key].money = 0
            sv.char[key].day   = nil
            sv.char[key].week  = nil
            sv.char[key].month = nil
            sv.char[key].year  = nil
            sv.char[key].ever  = nil
        end
    end

    -- Recalcule la richesse des royaumes
    self:AuditRealms()

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
function addon:ShowOptionsPanel(msg)

    -- Masque le tooltip
    self:HideMainTooltip()

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
        LibStub('AceConfig-3.0'):RegisterOptionsTable(addonName, options_panel)
    end

    -- Affiche le dialogue, sans aucun personnage sélectionné à l'ouverture
    numSelectedToons = #wipe(selectedToons)
    LibStub('AceConfigDialog-3.0'):Open(addonName)
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

    -- Prépare le second tooltip
    local stt = self:PrepareSubTooltip(realmLineFrame)
    if not stt then return end

    -- Calcule et affiche les données du royaume
    local realmDay, realmWeek, realmMonth, realmYear, realmEver = 0, 0, 0, 0, 0
    for key,data in pairs(self.sv.char) do
        local _, realm = SplitCharKey(key)
        if realm == selectedRealm then
            self:CheckStatResets(data, key == currentCharKey)

            realmDay   = realmDay   + (data.day   or 0)
            realmWeek  = realmWeek  + (data.week  or 0)
            realmMonth = realmMonth + (data.month or 0)
            realmYear  = realmYear  + (data.year  or 0)
            realmEver  = realmEver  + (data.ever  or 0)
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
-- Affiche le sous-tooltip pour un personnage
function addon:ShowCharTooltip(charLineFrame, selectedCharKey)

    -- Prépare le second sous-tooltip
    local stt = self:PrepareSubTooltip(charLineFrame)
    if not stt then return end

    -- Affiche les données du personnage
    local data = self.sv.char[selectedCharKey]

    self:CheckStatResets(data, selectedCharKey == currentCharKey)

    local ln
    ln = stt:AddLine(); stt:SetCell(ln, 1, selectedCharKey, 2)
    ln = stt:AddLine(); stt:SetCell(ln, 1, L['RECORDED_SINCE']:format(date(L['DATE_FORMAT'],      data.since)),     2)
    ln = stt:AddLine(); stt:SetCell(ln, 1,     L['LAST_SAVED']:format(date(L['DATE_TIME_FORMAT'], data.lastSaved)), 2)

    stt:AddLine(''); stt:AddSeparator(); stt:AddLine('')

    local showSilverAndCopper = self.opts.menu.showSilverAndCopper
    if selectedCharKey == currentCharKey then
        stt:AddLine(L['Current Session'], GetRelativeMoneyString(sessionMoney, showSilverAndCopper))
    end
    stt:AddLine(L['Today'],      GetRelativeMoneyString(data.day,   showSilverAndCopper))
    stt:AddLine(L['This week'],  GetRelativeMoneyString(data.week,  showSilverAndCopper))
    stt:AddLine(L['This month'], GetRelativeMoneyString(data.month, showSilverAndCopper))
    stt:AddLine(L['This year'],  GetRelativeMoneyString(data.year,  showSilverAndCopper))
    stt:AddLine(L['Ever'],       GetRelativeMoneyString(data.ever,  showSilverAndCopper))
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
        highlightTexture:Hide()
        highlightTexture:SetParent(UIParent)
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

-- Remplit le tooltip principal
function addon:UpdateMainTooltip()
    local showSilverAndCopper = self.opts.menu.showSilverAndCopper
    local mtt = mainTooltip
    local ln, rln

    -- Construit le tooltip
    mtt:Hide()
    mtt:Clear()
    mtt:SetCellMarginV(2)

    -- Header
    mtt:AddHeader(L['Name'], L['Cash'])
    mtt:AddSeparator(); mtt:AddLine('')

    -- Personnage courant en premier
    self:CheckStatResets(self.db.char, true)

    mtt:AddLine(currentCharKey, GetAbsoluteMoneyString(self.db.char.money, showSilverAndCopper))
    ln = mtt:AddLine(); mtt:SetCell(ln, 1, L['Current Session'], GameTooltipTextSmall, 1, 20); mtt:SetCell(ln, 2, GetRelativeMoneyString(sessionMoney,       showSilverAndCopper), GameTooltipTextSmall)
    ln = mtt:AddLine(); mtt:SetCell(ln, 1, L['Today'],           GameTooltipTextSmall, 1, 20); mtt:SetCell(ln, 2, GetRelativeMoneyString(self.db.char.day,   showSilverAndCopper), GameTooltipTextSmall)
    ln = mtt:AddLine(); mtt:SetCell(ln, 1, L['This week'],       GameTooltipTextSmall, 1, 20); mtt:SetCell(ln, 2, GetRelativeMoneyString(self.db.char.week,  showSilverAndCopper), GameTooltipTextSmall)
    ln = mtt:AddLine(); mtt:SetCell(ln, 1, L['This month'],      GameTooltipTextSmall, 1, 20); mtt:SetCell(ln, 2, GetRelativeMoneyString(self.db.char.month, showSilverAndCopper), GameTooltipTextSmall)
    ln = mtt:AddLine(); mtt:SetCell(ln, 1, L['This year'],       GameTooltipTextSmall, 1, 20); mtt:SetCell(ln, 2, GetRelativeMoneyString(self.db.char.year,  showSilverAndCopper), GameTooltipTextSmall)
    ln = mtt:AddLine(); mtt:SetCell(ln, 1, L['Ever'],            GameTooltipTextSmall, 1, 20); mtt:SetCell(ln, 2, GetRelativeMoneyString(self.db.char.ever,  showSilverAndCopper), GameTooltipTextSmall)
    mtt:AddLine(''); mtt:AddSeparator(); mtt:AddLine('')

    -- Trie les royaumes par ordre décroissant de richesse
    -- (fait ici car l'ordre peut changer à tout moment)
    table.sort(allRealms, function(r1, r2)
        return realmsWealth[r1] > realmsWealth[r2]
    end)

    -- Ajoute tous les personnages, royaume par royaume
    local sv, totalMoney = self.sv, 0
    for _,realm in ipairs(allRealms) do
        local unfolded = unfoldedRealms[realm]
        local realmMoney = realmsWealth[realm]

        -- Comptabilise la richesse par totale
        totalMoney = totalMoney + realmMoney

        -- 1/ Nom du royaume + nombre de personnages + richesse du royaume
        rln = mtt:AddLine()
        mtt:SetCell(rln, 1, ('%s %s (%d)'):format(unfolded and MINUS_BUTTON_STRING or PLUS_BUTTON_STRING, realm, #allChars[realm]))
        mtt:SetCell(rln, 2, GetAbsoluteMoneyString(realmMoney, showSilverAndCopper))
        mtt:SetLineTextColor(rln, COLOR_YELLOW:GetRGBA())
        mtt:SetLineScript(rln, 'OnEnter',     MainTooltip_OnEnterRealm, realm)
        mtt:SetLineScript(rln, 'OnLeave',     MainTooltip_OnLeaveRealm)
        mtt:SetLineScript(rln, 'OnMouseDown', MainTooltip_OnClickRealm, realm)

        -- 2/ Tous les personnages de ce royaume
        if unfolded then
            -- Trie les personnages du royaume par ordre décroissant de richesse
            -- (fait ici car l'ordre peut changer à tout instant)
            table.sort(allChars[realm], function(n1, n2)
                n1 = MakeCharKey(n1, realm)
                n2 = MakeCharKey(n2, realm)
                return ((sv.char[n1].money) or 0) > ((sv.char[n2].money) or 0)
            end)

            for _,name in ipairs(allChars[realm]) do
                local key  = MakeCharKey(name, realm)
                local data = sv.char[key]
                local money = data.money or 0

                -- Vérifie s'il faut réinitialiser les statistiques de ce personnage
                self:CheckStatResets(data, key == currentCharKey)

                -- Ajoute le personnage (avec une marge à gauche)
                ln = mtt:AddLine()
                mtt:SetCell(ln, 1, name, 1, 20)
                mtt:SetCell(ln, 2, GetAbsoluteMoneyString(money, showSilverAndCopper))
                mtt:SetLineScript(ln, 'OnEnter', MainTooltip_OnEnterChar, key)
                mtt:SetLineScript(ln, 'OnLeave', MainTooltip_OnLeaveChar)
            end
            mtt:AddLine('')
        end
    end

    -- Ajoute le grand total
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
        mainTooltip = libQTip:Acquire('BrokerCash_MainTooltip', 2, 'LEFT', 'RIGHT')
        mainTooltip:SmartAnchorTo(LDBFrame)
        mainTooltip:SetAutoHideDelay(0.1, LDBFrame, function() addon:HideMainTooltip() end)

        -- Surligne l'icône LDB, sauf si le display est Bazooka (il le fait déjà)
        local LDBFrameName = LDBFrame:GetName() or ''
        if not LDBFrameName:find('Bazooka', 1) then
            highlightTexture:SetParent(LDBFrame)
            highlightTexture:SetAllPoints()
            highlightTexture:Show()
        end
    end
    self:UpdateMainTooltip()
end

-------------------------------------------------------------------------------
-- Gestion des statistiques des personnages
-------------------------------------------------------------------------------

-- Calcule les dates de réinitialisation des statistiques
local function days_in_month(m, y)
	-- http://lua-users.org/wiki/DayOfWeekAndDaysInMonthExample
	return date('*t', time( { year = y, month = m + 1, day = 0 } ))['day']
end

function addon:CalcResetDates()

    -- Seulement si on a changé de jour depuis le dernier calcul
    local today = date('*t')
    if dayOfYear == today.yday then return false end
    dayOfYear = today.yday

    -- Toutes les limites sont fixées à 00:00:00
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
    local numDaysBack
    if today.wday == FIRST_DAY_OF_WEEK then
        numDaysBack = 0 -- Une nouvelle semaine commence aujourd'hui
    elseif today.wday > FIRST_DAY_OF_WEEK then
        numDaysBack = today.wday - FIRST_DAY_OF_WEEK
    else
        numDaysBack = 7 - today.wday
    end
    limit.day   = today.day - numDaysBack
    limit.month = today.month
    limit.year  = today.year
    if limit.day < 1 then
        limit.month = limit.month - 1
        if limit.month < 1 then
            limit.month = 12
            limit.year = limit.year - 1
        end
        limit.day = days_in_month(limit.month, limit.year) + limit.day
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

    -- Les dates ont changé
    return true
end

-------------------------------------------------------------------------------
-- Réinitialise les stats qui ont dépassé leur date limite
function addon:CheckStatResets(charData, isCurrentChar)

    -- On a changé de jour depuis la dernière vérification ?
    if self:CalcResetDates() then
        -- Réinitilise à 0 pour le personnage courant, à nil pour les autres afin de rester consistant avec AceDB
        local charLastSaved, resetValue = charData.lastSaved or 0, isCurrentChar and 0 or nil

        if charLastSaved < startOfDay   then charData.day   = resetValue end -- Quotidienne
        if charLastSaved < startOfWeek  then charData.week  = resetValue end -- Hebdomadaire
        if charLastSaved < startOfMonth then charData.month = resetValue end -- Mensuelle
        if charLastSaved < startOfYear  then charData.year  = resetValue end -- Annuelle

        -- Ajoute le champ 'ever' aux personnages qui ne l'ont pas
        if not charData.ever then
            charData.ever = charData.year or charData.month or charData.week or charData.day or resetValue
        end
    end
end

-------------------------------------------------------------------------------
-- Calcule la richesse globale de chaque royaume
function addon:AuditRealms()

    -- Recense les personnages connus
    table.wipe(allRealms)       -- { 'royaume1', 'royaume2', ..., 'royaumeN' }
    table.wipe(allChars)        -- { ['royaume1'] = { 'perso1', ..., 'persoN' }, ..., ['royaumeN] = {...} }
    table.wipe(realmsWealth)    -- { ['royaume1'] = XXX, ..., ['royaumeN] = ZZZ }

    for charKey,charData in pairs(self.sv.char) do

        -- Vérifie s'il faut réinitialier les stats de ce personnage
        self:CheckStatResets(charData, charKey == currentCharKey)

        -- Recense ce personnage
        local name, realm = SplitCharKey(charKey)
        if allChars[realm] then
            table.insert(allChars[realm], name)
        else
            table.insert(allRealms, realm)
            allChars[realm] = { name }
        end

        -- Comptabilise la richesse de chaque royaume
        realmsWealth[realm] = (realmsWealth[realm] or 0) + (charData.money or 0)
    end
end

-------------------------------------------------------------------------------
-- Mise à jour des données du personnage courant à chaque gain ou perte d'argent
-------------------------------------------------------------------------------
function addon:PLAYER_MONEY(evt)

    -- Vérifie s'il faut réinitialiser les stats du personnage
    -- A faire avant chaque dépense / rentrée d'argent
    self:CheckStatResets(self.db.char, true)

    -- Enregistre la dépense / recette
    local money = GetMoney()
    local diff  = money - self.db.char.money

    -- Met à jour la stat de session...
    sessionMoney = sessionMoney + diff

    -- Et les stats quotidienne/hebdomadaire/mensuelle/annuelle...
    self.db.char.lastSaved = time()
    self.db.char.money     = money
    self.db.char.day       = self.db.char.day   + diff
    self.db.char.week      = self.db.char.week  + diff
    self.db.char.month     = self.db.char.month + diff
    self.db.char.year      = self.db.char.year  + diff
    self.db.char.ever      = self.db.char.ever  + diff

    -- Et la richesse du royaume actuel.
    realmsWealth[currentRealm] = (realmsWealth[currentRealm] or 0) + diff

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

    -- Sauve la richesse du personnage courant
    -- (fait ici GetMoney() ne fonctionne pas avant PLAYER_ENTERING_WORLD)
    if self.db.char.since == 0 then
        self.db.char.since = time()     -- Première connexion avec ce personnage
        self.db.char.money = GetMoney()
    end
    self:PLAYER_MONEY()

    -- Pré-calcule la richesse de tous les royaumes connus
    -- (fait ici car l'addon peut être désactivé / réactivé à tout moment)
    self:AuditRealms()

    -- Surveille les événements
    self:RegisterEvent('PLAYER_MONEY')
end

-------------------------------------------------------------------------------
-- Initialisation
-------------------------------------------------------------------------------
function addon:OnInitialize()

    -- Garde une référence directe sur les données sauvegardées brutes
    self.sv = _G.Broker_CashDB

    -- Initialise AceDB
    self.db = LibStub('AceDB-3.0'):New(self.sv, sv_defaults, true)

    -- Conversion des options v1.3.3 => v1.4.0
    self.opts = self.db.global
    for _,section in ipairs { 'ldb', 'menu' } do
        if self.opts[section].showSilver == false or self.opts[section].showCopper == false then
            self.opts[section].showSilverAndCopper = false
            self.opts[section].showSilver = nil
            self.opts[section].showCopper = nil
        end
    end

    -- Crée l'objet LDB
    self.dataObject = libLDB:NewDataObject(addonName, {
        type    = 'data source',
        icon    = 'Interface\\MINIMAP\\TRACKING\\Banker',
        text    = GetAbsoluteMoneyString(self.db.char.money, self.opts.ldb.showSilverAndCopper),   -- Ok même si première connexion
        OnEnter = function(f) addon:ShowMainTooltip(f) end,
        OnClick = function(f, b) addon:ShowOptionsPanel() end
    })

    -- Commandes slash
    for _,cmd in ipairs({ 'brokercash', 'bcash'--[[ , 'cash', 'bc' ]] }) do
        self:RegisterChatCommand(cmd, 'ShowOptionsPanel')
    end
end

-----------------------------------------------------------------------------
-- GLOBALS: IsAddOnLoaded, LoadAddOn, DevTools_Dump
--[[ function addon:Dump(x)
    if not IsAddOnLoaded('Blizzard_DebugTools') then LoadAddOn('Blizzard_DebugTools') end
    DevTools_Dump(x)
end ]]
--
