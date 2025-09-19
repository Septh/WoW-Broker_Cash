--
-- GLOBALS: LibStub, Broker_CashDB
local _G = _G
local string, table, math, date, time = string, table, math, date, time
local pairs, ipairs = pairs, ipairs
local time, difftime = time, difftime
local wipe = wipe

-- API
local GetAddOnMetadata, InCombatLockdown = C_AddOns.GetAddOnMetadata, InCombatLockdown
local UnitName, UnitGUID, GetRealmName, GetRealmID = UnitName, UnitGUID, GetRealmName, GetRealmID
local GetMoney, BreakUpLargeNumbers = GetMoney, BreakUpLargeNumbers
local CreateColor, CopyTable, tDeleteItem, SecondsToTime = CreateColor, CopyTable, tDeleteItem, SecondsToTime
local UIParent, GameTooltipText, GameTooltipTextSmall = UIParent, GameTooltipText, GameTooltipTextSmall
local GameMenuFrame, InterfaceOptionsFrame = GameMenuFrame, InterfaceOptionsFrame
local SILVER_PER_GOLD, COPPER_PER_GOLD, COPPER_PER_SILVER = SILVER_PER_GOLD, COPPER_PER_GOLD, COPPER_PER_SILVER

-- Environment
local addonName, addonSpace = ...
local addon = LibStub('AceAddon-3.0'):NewAddon(addonSpace, addonName, 'AceConsole-3.0', 'AceEvent-3.0', 'AceTimer-3.0')
local L = LibStub('AceLocale-3.0'):GetLocale(addonName)
local VERSION = GetAddOnMetadata(addonName, 'Version')

-- Libraries
local libLDB = LibStub('LibDataBroker-1.1')
local libQTip = LibStub('LibQTip-1.0')
local LibDBIcon = LibStub("LibDBIcon-1.0")

-- Textures
local tth = select(2, GameTooltipText:GetFontObject():GetFont())
local GOLD_ICON_STRING = ('|TInterface\\MoneyFrame\\UI-GoldIcon:%d:%d:2:0|t'):format(tth, tth)
local SILVER_ICON_STRING = ('|TInterface\\MoneyFrame\\UI-SilverIcon:%d:%d:2:0|t'):format(tth, tth)
local COPPER_ICON_STRING = ('|TInterface\\MoneyFrame\\UI-CopperIcon:%d:%d:2:0|t'):format(tth, tth)
local PLUS_BUTTON_STRING = ('|TInterface\\Buttons\\UI-PlusButton-Up:%d:%d:2:0|t'):format(tth, tth)
local MINUS_BUTTON_STRING = ('|TInterface\\Buttons\\UI-MinusButton-Up:%d:%d:2:0|t'):format(tth, tth)

local HORDE_ICON_STRING = ('|TInterface\\FriendsFrame\\PlusManz-Horde:13:13|t'):format(tth, tth)
local ALLIANCE_ICON_STRING = ('|TInterface\\FriendsFrame\\PlusManz-Alliance:13:13|t'):format(tth, tth)
local NEUTRAL_ICON_STRING = ('|TInterface\\FriendsFrame\\StatusIcon-Offline:13:13|t'):format(tth, tth)

-- Colors
local COLOR_RED = CreateColor(0.8, 0.1, 0.1, 1)
local COLOR_GREEN = CreateColor(0.1, 0.8, 0.1, 1)
local COLOR_YELLOW = CreateColor(0.8, 0.8, 0.1, 1)

-- Statistics management
local FIRST_DAY_OF_WEEK = 2 -- Monday
local MIN_SESSION_THRESHOLD, MAX_SESSION_THRESHOLD, DEFAULT_SESSION_THRESHOLD = 0, 300, 60 -- In seconds

-- Characters data
local currentChar = UnitName('player')
local currentRealm = GetRealmName()
local currentCharKey = currentChar .. ' - ' .. currentRealm
local currentCharGUID = UnitGUID('player')
local serverID = select(2, strsplit('-', currentCharGUID))
local realmID = GetRealmID()
serverID = tonumber(serverID)
local sortedRealms, sortedChars, realmsWealths = {}, {}, {}

-- Saved data
local sv_defaults = {
  global = {
    general = {
      sessionThreshold = DEFAULT_SESSION_THRESHOLD
    },
    ldb = {
      showSilverAndCopper = true,
      highlight = false, -- v2.1.6
      displayedText = 'CASH' -- v2.2.5
    },
    menu = {
      disableInCombat = true,
      showSilverAndCopper = true,
      showSubTooltips = true
    },
    minimap = {
      hide = false
    },
    account = { -- v2.2.7
      token = 0,
      lastSaved = 0,
      money = 0,
      day = 0,
      week = 0,
      month = 0,
      year = 0,
      ever = 0
    },
    serverID = {}
  },
  char = {
    since = 0,
    lastSaved = 0,
    money = 0,
    session = 0, -- v2.0.0
    lastLogout = 0, -- v2.1.0
    day = 0,
    week = 0,
    month = 0,
    year = 0,
    ever = 0 -- v1.4.0
  }
}

-- Options panel
local options_panel = {
  name = ('%s v%s'):format(addonName, VERSION),
  handler = addon,
  type = 'group',
  childGroups = 'tab',
  args = {
    options = {
      name = L['Options'],
      type = 'group',
      order = 1,
      get = 'OptionsPanel_GetOpt',
      set = 'OptionsPanel_SetOpt',
      args = {
        general = {
          name = L['OPTIONS_GENERAL'],
          type = 'group',
          inline = true,
          order = 10,
          args = {
            sessionThreshold = {
              name = L['OPTS_SESSION_THRESHOLD'],
              order = 1,
              width = 'full',
              type = 'range',
              min = MIN_SESSION_THRESHOLD,
              max = MAX_SESSION_THRESHOLD,
              step = 1,
              bigStep = 10
            },
            sessionThresholdDesc = {
              name = '\n' .. L['OPTS_SESSION_THRESHOLD_DESC'],
              order = 2,
              type = 'description',
              fontSize = 'small'
            }
          }
        },
        ldb = {
          name = L['OPTIONS_LDB'],
          type = 'group',
          inline = true,
          order = 20,
          args = {
            highlight = {
              name = L['OPTS_HIGHLIGHT_LDB'],
              desc = L['OPTS_HIGHLIGHT_LDB_DESC'],
              descStyle = 'inline',
              type = 'toggle',
              width = 'full',
              order = 1
            },
            showSilverAndCopper = {
              name = L['OPTS_SMALL_PARTS'],
              desc = L['OPTS_SMALL_PARTS_DESC'],
              descStyle = 'inline',
              type = 'toggle',
              width = 'full',
              order = 2
            },
            hideMinimapButton = {
              name = L['OPTS_HIDE_MINIMAP_BUTTON'],
              descStyle = 'inline',
              type = 'toggle',
              width = 'full',
              order = 3,
              get = function()
                return addon.db.global.minimap.hide
              end,
              set = function(info, value)
                addon.db.global.minimap.hide = value
                if value then
                  LibDBIcon:Hide(addonName)
                else
                  LibDBIcon:Show(addonName)
                end
              end
            },
            displayedText = {
              type = "select",
              name = L["OPTS_TEXT_LDB"],
              values = {
                ["CASH"] = L['Character: Cash'],
                ["ACCOUNT"] = L['Account: Cash'],
                ["CHARACTER_TODAY"] = L['Character: Today'],
                ["ACCOUNT_TODAY"] = L['Account: Today'],
              },
              order = 4,
              set = function(info, value)
                addon.db.global.ldb.displayedText = value
                addon:SetLDBText()
              end
            }
          }
        },
        menu = {
          name = L['OPTIONS_MENU'],
          type = 'group',
          inline = true,
          order = 30,
          args = {
            disableInCombat = {
              name = L['OPTS_DISABLE_IN_COMBAT'],
              desc = L['OPTS_DISABLE_IN_COMBAT_DESC'],
              descStyle = 'inline',
              type = 'toggle',
              width = 'full',
              order = 1
            },
            showSilverAndCopper = {
              name = L['OPTS_SMALL_PARTS'],
              desc = L['OPTS_SMALL_PARTS_DESC'],
              descStyle = 'inline',
              type = 'toggle',
              width = 'full',
              order = 2
            },
            showSubTooltips = {
              name = L['Show Details'],
              desc = L['OPTS_SHOW_DETAILS_DESC'],
              descStyle = 'inline',
              type = 'toggle',
              width = 'full',
              order = 3
            }
          }
        }
      }
    },
    database = {
      name = L['Characters'],
      type = 'group',
      order = 2,
      args = {
        infos = {
          type = 'group',
          name = L['Notice'],
          inline = true,
          order = 1,
          args = {
            line1 = {
              type = 'description',
              name = L['OPTS_CHARACTERS_INFO_1'],
              fontSize = 'medium',
              order = 1
            },
            line2 = {
              type = 'description',
              name = string.format('> ' .. YELLOW_FONT_COLOR_CODE .. '%s' .. FONT_COLOR_CODE_CLOSE .. ' %s', L['Reset'], L['OPTS_CHARACTERS_INFO_2']),
              fontSize = 'medium',
              order = 2
            },
            line3 = {
              type = 'description',
              name = string.format('> ' .. YELLOW_FONT_COLOR_CODE .. '%s' .. FONT_COLOR_CODE_CLOSE .. ' %s', L['Delete'], L['OPTS_CHARACTERS_INFO_3']),
              fontSize = 'medium',
              order = 3
            },
            line4 = {
              type = 'description',
              name = string.format('\n' .. ORANGE_FONT_COLOR_CODE .. '%s' .. FONT_COLOR_CODE_CLOSE, L['OPTS_CHARACTERS_INFO_4']),
              fontSize = 'medium',
              order = 4
            }
          }
        },
        actions = {
          type = 'group',
          name = function()
            return false
          end, -- Allow a group to have no title or frame
          inline = true,
          order = 100,
          args = {
            count = {
              type = 'description',
              name = function()
                return addon:OptionsPanel_GetNumSelected()
              end,
              width = 'fill', -- Magic number in AceConfigDialog-3.0
              order = 1,
              fontSize = 'medium'
            },
            reset = {
              type = 'execute',
              name = L['Reset'],
              order = 2,
              disabled = 'OptionsPanel_IsActionDisabled',
              confirm = 'OptionsPanel_ConfirmAction',
              func = 'OptionsPanel_DoResetCharacters'
            },
            delete = {
              type = 'execute',
              name = L['Delete'],
              order = 3,
              disabled = 'OptionsPanel_IsActionDisabled',
              confirm = 'OptionsPanel_ConfirmAction',
              func = 'OptionsPanel_DoDeleteCharacters'
            }
          }
        }
      }
    }
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
-- Helpers
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

local function ClassColorise(class, targetstring)
  if class then
    local c = "|c" .. RAID_CLASS_COLORS[class].colorStr
    return c .. targetstring .. FONT_COLOR_CODE_CLOSE
  else
    return targetstring
  end
end

local function GetFactionIcon(faction)
  if faction == "Horde" then
    return HORDE_ICON_STRING
  elseif faction == "Alliance" then
    return ALLIANCE_ICON_STRING
  else
    return NEUTRAL_ICON_STRING
  end
end

local function SkinFrame(frame)
  if C_AddOns.IsAddOnLoaded("ElvUI") or C_AddOns.IsAddOnLoaded("Tukui") then
    if frame.StripTextures then
      frame:StripTextures()
    end
    if frame.CreateBackdrop then
      frame:CreateBackdrop("Transparent")
    end
  end
end

-------------------------------------------------------------------------------
if GetLocale() == 'frFR' then
  -- Fix a bug in French GlobalStrings.lua
  BreakUpLargeNumbers = function(amount)
    local left, num, right = string.match(amount, '^([^%d]*%d)(%d*)(.-)$')
    return left .. (num:reverse():gsub('(%d%d%d)', '%1 '):reverse()) .. right
  end
end

local function GetAbsoluteMoneyString(amount, showSilverAndCopper)
  amount = amount or 0

  local gold = math.floor(amount / COPPER_PER_GOLD)
  local silver = math.floor(amount / SILVER_PER_GOLD) % SILVER_PER_GOLD
  local copper = amount % COPPER_PER_SILVER

  local tbl, fmt = {}, ''
  if gold > 0 then
    tbl[#tbl + 1] = BreakUpLargeNumbers(gold) .. GOLD_ICON_STRING
  end
  local noGold = gold == 0
  if showSilverAndCopper or noGold then
    if silver > 0 or not noGold then
      fmt = noGold and '%d%s' or '%02d%s'
      tbl[#tbl + 1] = fmt:format(silver, SILVER_ICON_STRING)
    end
    fmt = (gold + silver == 0) and '%d%s' or '%02d%s'
    tbl[#tbl + 1] = fmt:format(copper, COPPER_ICON_STRING)
  end
  return table.concat(tbl, ' ')
end

local function GetRelativeMoneyString(amount, showSilverAndCopper)
  if (amount or 0) == 0 then
    return COLOR_YELLOW:WrapTextInColorCode('0' .. COPPER_ICON_STRING)
  elseif amount < 0 then
    return COLOR_RED:WrapTextInColorCode('-' .. GetAbsoluteMoneyString(-amount, showSilverAndCopper))
  else
    return COLOR_GREEN:WrapTextInColorCode('+' .. GetAbsoluteMoneyString(amount, showSilverAndCopper))
  end
end

-------------------------------------------------------------------------------
-- Control panel management
-------------------------------------------------------------------------------

-- Remove selected characters from saved data
function addon:OptionsPanel_DoDeleteCharacters(info, value)

  local sv = self.sv
  for key in pairs(selectedToons) do
    sv.char[key] = nil
    sv.profileKeys[key] = nil

    -- Also remove the character from the options table
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

  -- Reset Warband bank
  addon:DoResetWarbandBank()

  -- Deselect all characters
  numSelectedToons = #wipe(selectedToons)

  -- Recalculating the wealth of realms
  self:AuditRealms()
end

-- Reset the statistics of selected characters
function addon:OptionsPanel_DoResetCharacters(info, value)

  -- Special processing for the current character
  if selectedToons[currentCharKey] then
    selectedToons[currentCharKey] = nil

    self.db.char.money = GetMoney()
    self.db.char.session = 0
    self.db.char.day = 0
    self.db.char.week = 0
    self.db.char.month = 0
    self.db.char.year = 0
    self.db.char.ever = 0
  end

  -- All the others...
  local chars = self.sv.char
  for key in pairs(selectedToons) do
    chars[key].money = nil
    chars[key].session = nil
    chars[key].day = nil
    chars[key].week = nil
    chars[key].month = nil
    chars[key].year = nil
    chars[key].ever = nil
  end

  -- Reset Warband bank
  addon:DoResetWarbandBank()

  -- Deselect all characters
  numSelectedToons = #wipe(selectedToons)

  -- Recalculating the wealth of realms
  self:AuditRealms()
end

-- Reset Warband bank
function addon:DoResetWarbandBank()
  local account = self.db.global.account
  account.money = C_Bank.FetchDepositedMoney(Enum.BankType.Account)
  account.day = 0
  account.week = 0
  account.month = 0
  account.year = 0
  account.ever = 0
end

-- Display a confirmation request before resetting/deleting
function addon:OptionsPanel_ConfirmAction(info)

  -- str = RESET_TOON(S) or DELETE_TOON(S)
  local str = info[#info]:upper() .. '_TOON' .. (numSelectedToons > 1 and 'S' or '')
  str = L[str]:format(numSelectedToons)

  -- Build the confirmation request
  local tbl = {}
  for k in pairs(selectedToons) do
    tbl[#tbl + 1] = k
  end
  table.sort(tbl, function(t1, t2)
    return InvertCharKey(t1) < InvertCharKey(t2)
  end)
  return str .. '\n\n' .. table.concat(tbl, '\n') .. '\n\n' .. L['Are you sure?']
end

-- Check whether the Delete and Reset buttons should be disabled
function addon:OptionsPanel_IsActionDisabled(info)
  -- True if (no selection) OR (the button is ‘Delete’ AND the current character is one of the selected characters)
  return numSelectedToons == 0 or (info[#info] == 'delete' and selectedToons[currentCharKey])
end

-- Select / deselect a character
function addon:OptionsPanel_IsToonSelected(info, opt)
  return selectedToons[MakeCharKey(opt, info[#info])]
end

function addon:OptionsPanel_SetToonSelected(info, opt, value)
  local key = MakeCharKey(opt, info[#info])
  if value then
    selectedToons[key] = true
    numSelectedToons = numSelectedToons + 1
  else
    selectedToons[key] = nil
    numSelectedToons = numSelectedToons - 1
  end
end

-- Update the number of characters selected in the dialog
function addon:OptionsPanel_GetNumSelected(info)
  local fmt = 'NUMSELECTED_' .. (numSelectedToons > 1 and 'X' or numSelectedToons)
  return L[fmt]:format(numSelectedToons)
end

-- Checkbox management
function addon:OptionsPanel_GetOpt(info)
  return self.opts[info[#info - 1]][info[#info]]
end

function addon:OptionsPanel_SetOpt(info, value)
  -- info[#info-1] = 'menu' or 'ldb', info[#info] = option clicked
  self.opts[info[#info - 1]][info[#info]] = value

  -- Update the LDB text where necessary
  if info[#info - 1] == 'ldb' then
    self:SetLDBText()
  end
end

-- Show/hide the options dialog
--   BuildOptionsPanel() is called by ShowOptionsPanel() and the standard options window
--   ShowOptionsPanel() is called by ToggleOptionsPanel() and slash commands
--   ToggleOptionsPanel() is called when the LDB icon is clicked
function addon:BuildOptionsPanel()

  -- Build dialog if it hasn't already been done
  if not options_panel.args.database.args[currentRealm] then

    -- Sort the realms, but this time in alphabetical order
    local orderedRealms = CopyTable(sortedRealms)
    table.sort(orderedRealms)

    -- Insert realms and their characters in the options panel
    for i, realm in ipairs(orderedRealms) do
      options_panel.args.database.args[realm] = {
        name = realm,
        type = 'multiselect',
        descStyle = 'inline', -- No tooltip please :)
        get = 'OptionsPanel_IsToonSelected',
        set = 'OptionsPanel_SetToonSelected',
        values = {},
        order = 10 + i
      }

      for _, name in ipairs(sortedChars[realm]) do
        options_panel.args.database.args[realm].values[name] = name
      end
    end
  end
end

function addon:ShowOptionsPanel(msg)

  -- Unless in combat or if the menu or standard options are displayed
  if InCombatLockdown() or GameMenuFrame:IsShown() or InterfaceOptionsFrame then
    return
  end

  self:BuildOptionsPanel()
  LibStub('AceConfigDialog-3.0'):Open(addonName)
end

function addon:ToggleOptionsPanel()

  -- Hide the tooltip
  self:HideMainTooltip()

  -- Hide the dialog if it is displayed, displays it otherwise
  local acd = LibStub('AceConfigDialog-3.0')
  if acd.OpenFrames[addonName] then
    acd:Close(addonName)
  else
    self:ShowOptionsPanel()
  end
end

-------------------------------------------------------------------------------
-- Secondary tooltip management
-------------------------------------------------------------------------------
function addon:PrepareSubTooltip(mainTooltipLine)
  if not self.opts.menu.showSubTooltips then
    return
  end

  -- Display (or moves) the sub-tooltip
  if not subTooltip then
    subTooltip = libQTip:Acquire(addonName .. '_SubTooltip', 2, 'LEFT', 'RIGHT')
    subTooltip:SetFrameLevel(mainTooltipLine:GetFrameLevel() + 1)
    SkinFrame(subTooltip)
  end

  -- Define the position of the tooltip (to the left of the parent line if there isn't enough space on the right)
  local x, y, w, h = mainTooltipLine:GetRect()
  local sw, sh = UIParent:GetSize()

  if (x + w + 200) < sw then
    subTooltip:SetPoint('TOPLEFT', mainTooltipLine, 'TOPRIGHT', 0, 10)
  else
    subTooltip:SetPoint('TOPRIGHT', mainTooltipLine, 'TOPLEFT', 0, 10)
  end
  subTooltip:SetClampedToScreen(true)

  -- Delete content
  subTooltip:Clear()
  subTooltip:SetFont(GameTooltipTextSmall)
  subTooltip:SetCellMarginV(2)

  return subTooltip
end

-------------------------------------------------------------------------------
function addon:ShowRealmTooltip(realmLineFrame, selectedRealm)
  local stt = self:PrepareSubTooltip(realmLineFrame)
  if not stt then
    return
  end

  -- Calculate and display realm data
  local realmDay, realmWeek, realmMonth, realmYear, realmEver = 0, 0, 0, 0, 0
  for key, char in pairs(self.sv.char) do
    local _, realm = SplitCharKey(key)
    if realm == selectedRealm then
      realmDay = realmDay + (char.day or 0)
      realmWeek = realmWeek + (char.week or 0)
      realmMonth = realmMonth + (char.month or 0)
      realmYear = realmYear + (char.year or 0)
      realmEver = realmEver + (char.ever or 0)
    end
  end

  local showSilverAndCopper = self.opts.menu.showSilverAndCopper
  stt:AddLine(L['Today'], GetRelativeMoneyString(realmDay, showSilverAndCopper))
  stt:AddLine(L['This week'], GetRelativeMoneyString(realmWeek, showSilverAndCopper))
  stt:AddLine(L['This month'], GetRelativeMoneyString(realmMonth, showSilverAndCopper))
  stt:AddLine(L['This year'], GetRelativeMoneyString(realmYear, showSilverAndCopper))
  stt:AddLine(L['Ever'], GetRelativeMoneyString(realmEver, showSilverAndCopper))
  stt:Show()
end

-------------------------------------------------------------------------------
function addon:ShowCharTooltip(charLineFrame, selectedCharKey)
  local stt = self:PrepareSubTooltip(charLineFrame)
  if not stt then
    return
  end

  -- Display character data
  local char = self.sv.char[selectedCharKey]
  stt:AddLine()
  stt:SetCell(1, 1, GetFactionIcon(char.faction) .. ClassColorise(char.class, selectedCharKey), 2)
  stt:AddLine()
  stt:SetCell(2, 1, L['RECORDED_SINCE']:format(date(L['DATE_FORMAT'], char.since)), 2)
  stt:AddLine()
  stt:SetCell(3, 1, L['LAST_SAVED']:format(date(L['DATE_TIME_FORMAT'], char.lastSaved)), 2)
  stt:AddLine('')
  stt:AddSeparator()
  stt:AddLine('')

  local showSilverAndCopper = self.opts.menu.showSilverAndCopper
  if selectedCharKey == currentCharKey then
    stt:AddLine(L['Current Session'], GetRelativeMoneyString(self.db.char.session, showSilverAndCopper))
  end
  stt:AddLine(L['Today'], GetRelativeMoneyString(char.day or 0, showSilverAndCopper))
  stt:AddLine(L['This week'], GetRelativeMoneyString(char.week or 0, showSilverAndCopper))
  stt:AddLine(L['This month'], GetRelativeMoneyString(char.month or 0, showSilverAndCopper))
  stt:AddLine(L['This year'], GetRelativeMoneyString(char.year or 0, showSilverAndCopper))
  stt:AddLine(L['Ever'], GetRelativeMoneyString(char.ever or 0, showSilverAndCopper))
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
-- Main tooltip management
-------------------------------------------------------------------------------

-- Unfold/fold a realm in the tooltip
local function MainTooltip_OnClickRealm(realmLineFrame, realm, button)
  unfoldedRealms[realm] = not unfoldedRealms[realm]
  addon:UpdateMainTooltip()
end

-- Display the secondary tooltip for a realm
local function MainTooltip_OnEnterRealm(realmLineFrame, realm)
  addon:ShowRealmTooltip(realmLineFrame, realm)
end

local function MainTooltip_OnLeaveRealm(realmLineFrame)
  addon:HideSubTooltip()
end

-- Display the secondary tooltip for a character
local function MainTooltip_OnEnterChar(charLineFrame, charKey)
  addon:ShowCharTooltip(charLineFrame, charKey)
end

local function MainTooltip_OnLeaveChar(charLineFrame)
  addon:HideSubTooltip()
end

-- Fill the main tooltip
function addon:UpdateMainTooltip()
  local mtt = mainTooltip
  if not mtt then
    return
  end

  -- Build the tooltip
  local showSilverAndCopper = self.opts.menu.showSilverAndCopper
  local ln, rln

  mtt:Hide()
  mtt:Clear()
  mtt:SetCellMarginV(2)

  ---------------------------------------------------------------------------
  -- 1/ Header
  ---------------------------------------------------------------------------
  mtt:AddHeader(L['Name'], L['Cash'])
  mtt:AddSeparator()
  mtt:AddLine('')

  ---------------------------------------------------------------------------
  -- 2/ Current character
  ---------------------------------------------------------------------------
  mtt:AddLine(GetFactionIcon(self.db.char.faction) .. ClassColorise(self.db.char.class, currentCharKey), GetAbsoluteMoneyString(self.db.char.money, showSilverAndCopper))
  ln = mtt:AddLine()
  mtt:SetCell(ln, 1, L['Current Session'], GameTooltipTextSmall, 1, 20)
  mtt:SetCell(ln, 2, GetRelativeMoneyString(self.db.char.session, showSilverAndCopper), GameTooltipTextSmall)
  ln = mtt:AddLine()
  mtt:SetCell(ln, 1, L['Today'], GameTooltipTextSmall, 1, 20)
  mtt:SetCell(ln, 2, GetRelativeMoneyString(self.db.char.day, showSilverAndCopper), GameTooltipTextSmall)
  ln = mtt:AddLine()
  mtt:SetCell(ln, 1, L['This week'], GameTooltipTextSmall, 1, 20)
  mtt:SetCell(ln, 2, GetRelativeMoneyString(self.db.char.week, showSilverAndCopper), GameTooltipTextSmall)
  ln = mtt:AddLine()
  mtt:SetCell(ln, 1, L['This month'], GameTooltipTextSmall, 1, 20)
  mtt:SetCell(ln, 2, GetRelativeMoneyString(self.db.char.month, showSilverAndCopper), GameTooltipTextSmall)
  ln = mtt:AddLine()
  mtt:SetCell(ln, 1, L['This year'], GameTooltipTextSmall, 1, 20)
  mtt:SetCell(ln, 2, GetRelativeMoneyString(self.db.char.year, showSilverAndCopper), GameTooltipTextSmall)
  ln = mtt:AddLine()
  mtt:SetCell(ln, 1, L['Ever'], GameTooltipTextSmall, 1, 20)
  mtt:SetCell(ln, 2, GetRelativeMoneyString(self.db.char.ever, showSilverAndCopper), GameTooltipTextSmall)
  mtt:AddLine('')
  mtt:AddSeparator()
  mtt:AddLine('')

  ---------------------------------------------------------------------------
  -- 3/ All the characters, grouped by realm
  ---------------------------------------------------------------------------

  -- Sort realms in descending order of wealth
  -- (done here because the order can change at any time depending on the current character)
  table.sort(sortedRealms, function(r1, r2)
    if realmsWealths[r1] == realmsWealths[r2] then
      return r1 < r2
    else
      return realmsWealths[r1] > realmsWealths[r2]
    end
  end)

  -- Add all the characters, realm by realm
  local chars = self.sv.char
  local totalMoney = 0

  for _, realm in ipairs(sortedRealms) do
    local unfolded, realmMoney = unfoldedRealms[realm], realmsWealths[realm]

    -- Display realm if wealthy
    if realmMoney > 0 then

      -- Calculates total wealth
      totalMoney = totalMoney + realmMoney

      local wealthyCharsCount = 0
      for _, name in ipairs(sortedChars[realm]) do
        local key = MakeCharKey(name, realm)
        if (chars[key].money or 0) > 0 then
          wealthyCharsCount = wealthyCharsCount + 1
        end
      end

      -- 1/ Realm name + number of characters + wealth of realm
      mtt:AddLine('')
      rln = mtt:AddLine()
      mtt:SetCell(rln, 1, ('%s %s (%d)'):format(unfolded and MINUS_BUTTON_STRING or PLUS_BUTTON_STRING, realm, wealthyCharsCount))
      mtt:SetCell(rln, 2, GetAbsoluteMoneyString(realmMoney, showSilverAndCopper))
      mtt:SetLineTextColor(rln, COLOR_YELLOW:GetRGBA())
      mtt:SetLineScript(rln, 'OnEnter', MainTooltip_OnEnterRealm, realm)
      mtt:SetLineScript(rln, 'OnLeave', MainTooltip_OnLeaveRealm)
      mtt:SetLineScript(rln, 'OnMouseDown', MainTooltip_OnClickRealm, realm)

      -- 2/ All the characters in this realm
      if unfolded then

        -- Sorts the realm's characters in descending order of wealth
        -- (done here because the order can change at any time depending on the current character)
        table.sort(sortedChars[realm], function(n1, n2)
          n1, n2 = MakeCharKey(n1, realm), MakeCharKey(n2, realm)
          return ((chars[n1].money) or 0) > ((chars[n2].money) or 0)
        end)

        for _, name in ipairs(sortedChars[realm]) do
          local key = MakeCharKey(name, realm)

          -- Add the character if wealthy
          if (chars[key].money or 0) > 0 then
            ln = mtt:AddLine()
            mtt:SetCell(ln, 1, GetFactionIcon(chars[key].faction) .. ClassColorise(chars[key].class, name), 1, 20)
            mtt:SetCell(ln, 2, GetAbsoluteMoneyString(chars[key].money or 0, showSilverAndCopper))
            mtt:SetLineScript(ln, 'OnEnter', MainTooltip_OnEnterChar, key)
            mtt:SetLineScript(ln, 'OnLeave', MainTooltip_OnLeaveChar)
          end
        end
      end
    end
  end
  -- Add Warband bank money
  totalMoney = totalMoney + self.db.global.account.money

  ---------------------------------------------------------------------------
  -- 4/ Add Warband Bank
  ---------------------------------------------------------------------------
  if self.db.global.account.money > 0 then
    mtt:AddLine('')
    mtt:AddSeparator()
    mtt:AddLine('')
    mtt:AddLine(L['Warband Bank'], GetAbsoluteMoneyString(self.db.global.account.money, showSilverAndCopper))
  end

  ---------------------------------------------------------------------------
  -- 5/ Add the grand total
  ---------------------------------------------------------------------------

  -- Calculating the total balance
  local totalBalance = {
    day = 0,
    week = 0,
    month = 0,
    year = 0,
    ever = 0
  }

  -- Each character
  for _, char in pairs(self.sv.char) do
    totalBalance.day = totalBalance.day + (char.day or 0)
    totalBalance.week = totalBalance.week + (char.week or 0)
    totalBalance.month = totalBalance.month + (char.month or 0)
    totalBalance.year = totalBalance.year + (char.year or 0)
    totalBalance.ever = totalBalance.ever + (char.ever or 0)
  end

  -- Warband
  local account = self.db.global.account
  totalBalance.day = totalBalance.day + (account.day or 0)
  totalBalance.week = totalBalance.week + (account.week or 0)
  totalBalance.month = totalBalance.month + (account.month or 0)
  totalBalance.year = totalBalance.year + (account.year or 0)
  totalBalance.ever = totalBalance.ever + (account.ever or 0)

  -- Rendering the total
  mtt:AddLine('')
  mtt:AddSeparator()
  mtt:AddLine('')
  mtt:AddLine(L['Total'], GetAbsoluteMoneyString(totalMoney, showSilverAndCopper))
  ln = mtt:AddLine()
  mtt:SetCell(ln, 1, L['Today'], GameTooltipTextSmall, 1, 20)
  mtt:SetCell(ln, 2, GetRelativeMoneyString(totalBalance.day, showSilverAndCopper), GameTooltipTextSmall)
  ln = mtt:AddLine()
  mtt:SetCell(ln, 1, L['This week'], GameTooltipTextSmall, 1, 20)
  mtt:SetCell(ln, 2, GetRelativeMoneyString(totalBalance.week, showSilverAndCopper), GameTooltipTextSmall)
  ln = mtt:AddLine()
  mtt:SetCell(ln, 1, L['This month'], GameTooltipTextSmall, 1, 20)
  mtt:SetCell(ln, 2, GetRelativeMoneyString(totalBalance.month, showSilverAndCopper), GameTooltipTextSmall)
  ln = mtt:AddLine()
  mtt:SetCell(ln, 1, L['This year'], GameTooltipTextSmall, 1, 20)
  mtt:SetCell(ln, 2, GetRelativeMoneyString(totalBalance.year, showSilverAndCopper), GameTooltipTextSmall)
  ln = mtt:AddLine()
  mtt:SetCell(ln, 1, L['Ever'], GameTooltipTextSmall, 1, 20)
  mtt:SetCell(ln, 2, GetRelativeMoneyString(totalBalance.ever, showSilverAndCopper), GameTooltipTextSmall)
  mtt:AddLine('')
  mtt:AddSeparator()
  mtt:AddLine('')
  mtt:AddLine(L['WoW Token'], GetAbsoluteMoneyString(self.db.global.account.token, false))

  -- Done
  mtt:Show()
end

-------------------------------------------------------------------------------
function addon:ShowMainTooltip(LDBFrame)

  -- Don't display the tooltip in the middle of a fight
  if self.opts.menu.disableInCombat and InCombatLockdown() then
    return
  end

  if not mainTooltip then
    mainTooltip = libQTip:Acquire(addonName .. '_MainTooltip', 2, 'LEFT', 'RIGHT')
    mainTooltip:SmartAnchorTo(LDBFrame)
    mainTooltip:SetAutoHideDelay(0.1, LDBFrame, function()
      addon:HideMainTooltip()
    end)

    SkinFrame(mainTooltip)

    -- Highlight the LDB icon
    if self.opts.ldb.highlight then
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

  -- Hide highlighting
  highlightTexture:SetParent(UIParent)
  highlightTexture:Hide()
end

-------------------------------------------------------------------------------
-- Global statistics management
-------------------------------------------------------------------------------
function addon:AuditRealms()

  ---------------------------------------------------------------------------
  -- Lists all the characters in all the realms and counts the overall wealth of each realm.
  -- NB: tables are not sorted here, but when the tooltip is displayed.
  ---------------------------------------------------------------------------
  table.wipe(sortedRealms)
  table.wipe(sortedChars)
  table.wipe(realmsWealths)

  for key, char in pairs(self.sv.char) do
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
  -- 1/ Calculate statistics reset dates
  ---------------------------------------------------------------------------
  local startOfDay, startOfMonth, startOfYear, startOfWeek
  local reset = {
    hour = 0, -- All limits are set at 00:00:00
    min = 0, -- TODO: Manage daylight saving time? If so, how?
    sec = 0
  }

  -- Beginning of current day
  reset.day = now.day
  reset.month = now.month
  reset.year = now.year
  startOfDay = time(reset)

  -- Beginning of current month
  reset.day = 1
  startOfMonth = time(reset)

  -- Beginning of current year
  reset.month = 1
  startOfYear = time(reset)

  -- Beginning of current week
  local numDaysBack = now.wday - FIRST_DAY_OF_WEEK
  if numDaysBack < 0 then
    numDaysBack = 7 - now.wday
  end
  reset.day = now.day - numDaysBack
  reset.month = now.month
  reset.year = now.year
  if reset.day < 1 then
    reset.month = reset.month - 1
    if reset.month < 1 then
      reset.month = 12
      reset.year = reset.year - 1
    end
    -- Number of days in this month (cf. http://lua-users.org/wiki/DayOfWeekAndDaysInMonthExample)
    reset.day = date('*t', time({
      day = 0,
      month = reset.month + 1,
      year = reset.year
    }))['day']
  end
  startOfWeek = time(reset)

  ---------------------------------------------------------------------------
  -- 2/ Reset outdated stats
  ---------------------------------------------------------------------------

  -- For each character
  for key, char in pairs(self.sv.char) do
    local lastSaved, resetValue = char.lastSaved or 0, key == currentCharKey and 0 or nil

    if lastSaved < startOfDay then
      char.day = resetValue
    end
    if lastSaved < startOfWeek then
      char.week = resetValue
    end
    if lastSaved < startOfMonth then
      char.month = resetValue
    end
    if lastSaved < startOfYear then
      char.year = resetValue
    end
    if char.token then
      char.token = nil
    end
  end

  -- For Warband
  do
    local account = self.db.global.account
    local lastSaved = account.lastSaved or 0

    if lastSaved < startOfDay then
      account.day = 0
    end
    if lastSaved < startOfWeek then
      account.week = 0
    end
    if lastSaved < startOfMonth then
      account.month = 0
    end
    if lastSaved < startOfYear then
      account.year = 0
    end
  end

  ---------------------------------------------------------------------------
  -- 3/ Recalculate the wealth of all realms
  ---------------------------------------------------------------------------
  self:AuditRealms()

  -- Refresh the tooltip if it is displayed
  if mainTooltip and mainTooltip:IsShown() then
    self:UpdateMainTooltip()
  end

  ---------------------------------------------------------------------------
  -- 4/ Restart the timer until midnight tomorrow for the next check.
  ---------------------------------------------------------------------------
  now.day = now.day + 1 -- Tomorrow
  now.hour = 0 -- at 0 hour
  now.min = 0 -- 0 minute
  now.sec = 1 -- and 1 second (safety margin)
  self:ScheduleTimer('CheckStatsResets', difftime(time(now), time()))
end

-------------------------------------------------------------------------------
-- Current character stats management
-------------------------------------------------------------------------------
function addon:PLAYER_MONEY(evt)

  -- Calculate gold gain/loss
  local diff = GetMoney() - self.db.char.money

  -- Update stats
  for _, stat in ipairs({'money', 'session', 'day', 'week', 'month', 'year', 'ever'}) do
    self.db.char[stat] = self.db.char[stat] + diff
  end
  self.db.char.lastSaved = time()
  _, self.db.char.class = UnitClass("player")
  self.db.char.faction = UnitFactionGroup("player")

  -- Update the realm's wealth
  realmsWealths[currentRealm] = (realmsWealths[currentRealm] or 0) + diff

  -- Update the LDB text
  self:SetLDBText()
end

-------------------------------------------------------------------------------
-- Warband stats management
-------------------------------------------------------------------------------
function addon:ACCOUNT_MONEY(evt)

  -- Calculate gold gain/loss
  local diff = C_Bank.FetchDepositedMoney(Enum.BankType.Account) - self.db.global.account.money

  -- Update stats
  for _, stat in ipairs({'money', 'day', 'week', 'month', 'year', 'ever'}) do
    self.db.global.account[stat] = self.db.global.account[stat] + diff
  end
  self.db.global.account.lastSaved = time()
end

-------------------------------------------------------------------------------
-- Management 
-------------------------------------------------------------------------------
function addon:SetLDBText()
  if self.opts.ldb.displayedText == 'CHARACTER_TODAY' then
    self.dataObject.text = GetRelativeMoneyString(self.db.char.day, self.opts.ldb.showSilverAndCopper)
  elseif self.opts.ldb.displayedText == 'ACCOUNT_TODAY' then
    local balance = 0
    for _, char in pairs(self.sv.char) do
      balance = balance + (char.day or 0)
    end
    balance = balance + (self.db.global.account.day or 0)
    self.dataObject.text = GetRelativeMoneyString(balance, self.opts.ldb.showSilverAndCopper)
  elseif self.opts.ldb.displayedText == 'ACCOUNT' then
    local money = 0
    for _, char in pairs(self.sv.char) do
      money = money + (char.money or 0)
    end
    money = money + (self.db.global.account.money or 0)
    self.dataObject.text = GetAbsoluteMoneyString(money, self.opts.ldb.showSilverAndCopper)
  else
    self.dataObject.text = GetAbsoluteMoneyString(self.db.char.money, self.opts.ldb.showSilverAndCopper)
  end
end

-------------------------------------------------------------------------------
-- Initialization
-------------------------------------------------------------------------------
function addon:DeferredStart()

  -- Is this the first connection with this character?
  if self.db.char.since == 0 then
    self.db.char.since = time()
    self.db.char.money = GetMoney()

    -- Also makes info available for :AuditRealms()
    self.sv.char[currentCharKey].since = self.db.char.since
    self.sv.char[currentCharKey].money = self.db.char.money
  end

  -- Check whether the stats need to be reset and start the timer until midnight
  self:CheckStatsResets()

  -- Save the current gold amount
  self:PLAYER_MONEY()
  self:ACCOUNT_MONEY()

  -- Listen to events
  self:RegisterEvent('PLAYER_MONEY')
  self:RegisterEvent('ACCOUNT_MONEY')
end

-------------------------------------------------------------------------------
function addon:PLAYER_ENTERING_WORLD(evt, isLogin, isReload)

  -- No more need for that
  self:UnregisterEvent(evt)

  -- Initialise the session stat if this is not a reload
  if isLogin == true and isReload == false then
    if (time() - self.db.char.lastLogout) > self.db.global.general.sessionThreshold then
      self.db.char.session = 0
    end
  end

  -- Minimises inaccuracies due to milliseconds
  -- waiting for (the start of) the next second
  -- to check the stats and start the real timer
  local now = date('*t')
  now.sec = now.sec + 1
  self:ScheduleTimer('DeferredStart', difftime(time(now), time()))
end

-------------------------------------------------------------------------------
function addon:TOKEN_MARKET_PRICE_UPDATED()
  local price = C_WowTokenPublic.GetCurrentMarketPrice()

  if (price) then
    self.db.global.account.token = price
  end
end

-------------------------------------------------------------------------------
function addon:PLAYER_LOGOUT()
  self.db.char.lastLogout = time()
end

-------------------------------------------------------------------------------
function addon:OnInitialize()

  -- Initialise AceDB and keep a direct reference to saved data
  self.db = LibStub('AceDB-3.0'):New('Broker_CashDB', sv_defaults, true)
  self.sv = _G.Broker_CashDB -- or rawget(self.db, 'sv')
  self.opts = self.db.global

  -- update Token Price
  C_WowTokenPublic.UpdateMarketPrice()

  -- Options conversion v1.3.3 => v1.4.0
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

  -- v1.4.0: Add the ‘ever’ field if the character doesn't have it
  if self.db.char.ever == 0 then
    self.db.char.ever = self.db.char.year
  end

  -- Create LDB object
  self.dataObject = libLDB:NewDataObject(addonName, {
    type = 'data source',
    icon = 'Interface\\MINIMAP\\TRACKING\\Banker',
    text = GetAbsoluteMoneyString(self.db.char.money, self.opts.ldb.showSilverAndCopper),
    OnEnter = function(f)
      addon:ShowMainTooltip(f)
    end,
    OnClick = function(f, b)
      addon:ToggleOptionsPanel()
    end
  })

  -- Initialize the minimap icon
  LibDBIcon:Register(addonName, self.dataObject, self.db.global.minimap)

  -- Initialize the options panel
  LibStub('AceConfig-3.0'):RegisterOptionsTable(addonName, options_panel)
  local optionsFrame = LibStub('AceConfigDialog-3.0'):AddToBlizOptions(addonName)
  optionsFrame.refresh = function()
    addon:BuildOptionsPanel()
  end

  -- Activate slash commands
  for _, cmd in ipairs({'brokercash', 'bcash'}) do
    self:RegisterChatCommand(cmd, 'ShowOptionsPanel')
  end

  -- Build connected realms table
  self.opts.serverID[serverID] = self.opts.serverID[serverID] or {}
  self.opts.serverID[serverID][currentRealm] = realmID

  -- Defers end of initialisation to PLAYER_ENTERING_WORLD
  self:RegisterEvent('PLAYER_ENTERING_WORLD')
  self:RegisterEvent('TOKEN_MARKET_PRICE_UPDATED')
  self:RegisterEvent('PLAYER_LOGOUT')
end
