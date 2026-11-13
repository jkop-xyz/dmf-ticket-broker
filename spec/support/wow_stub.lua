-- A minimal fake of the WoW client API, just enough to load the whole addon
-- (libraries included), fire its events and drive its UI outside the game.
-- It checks wiring (nil calls, typos, event handling), not real behaviour.

WowStub = {}

local function noop() end

-- Generic widget: tracks shown state, scripts, text, points and children.
-- Unknown methods are no-ops; Create* methods return new widgets.
local Widget = {}
Widget.__index = function(self, key)
  local method = rawget(Widget, key)
  if method then return method end
  if type(key) == "string" and key:match("^Create") then
    return function(parent) return WowStub.NewWidget(parent) end
  end
  return noop
end

function WowStub.NewWidget(parent, name)
  local w = setmetatable({ _shown = true, _scripts = {}, _parent = parent, _name = name, _events = {} }, Widget)
  return w
end

function Widget:Show()
  local was = self._shown
  self._shown = true
  if not was and self._scripts.OnShow then self._scripts.OnShow(self) end
end
function Widget:Hide() self._shown = false end
function Widget:SetShown(shown) if shown then self:Show() else self:Hide() end end
function Widget:IsShown() return self._shown end
function Widget:IsVisible() return self._shown end
function Widget:SetScript(name, fn) self._scripts[name] = fn end
function Widget:GetScript(name) return self._scripts[name] end
function Widget:HookScript(name, fn) self._scripts[name] = fn end
function Widget:SetText(text) self._text = text end
function Widget:GetText() return self._text end
function Widget:GetName() return self._name end
function Widget:GetParent() return self._parent end
function Widget:RegisterEvent(event)
  if not WowStub.knownEvents[event] then
    error("Attempt to register unknown event \"" .. event .. "\"")
  end
  self._events[event] = true
  WowStub.eventFrames[self] = true
end
function Widget:UnregisterEvent(event) self._events[event] = nil end
function Widget:GetPoint() return "CENTER", nil, "CENTER", 0, 0 end
function Widget:GetWidth() return 100 end
function Widget:GetHeight() return 20 end
function Widget:GetFrameLevel() return 1 end
function Widget:GetVertexColor() return 1, 1, 1, 1 end
function Widget:Click(button)
  if self._scripts.OnClick then self._scripts.OnClick(self, button or "LeftButton") end
end
function Widget:SetEnabled(enabled) self._enabled = enabled end
function Widget:IsEnabled() return self._enabled ~= false end

WowStub.knownEvents = {}
for _, e in ipairs({
  "ADDON_LOADED", "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "BAG_UPDATE_DELAYED", "ITEM_DATA_LOAD_RESULT",
  "TRADE_SKILL_SHOW", "TRADE_SKILL_LIST_UPDATE", "TRADE_SKILL_DATA_SOURCE_CHANGED", "NEW_RECIPE_LEARNED",
  "SKILL_LINES_CHANGED", "PLAYER_LEVEL_UP", "UPDATE_FACTION", "QUEST_TURNED_IN", "CURRENCY_DISPLAY_UPDATE",
  "MERCHANT_CLOSED", "AUCTION_HOUSE_SHOW", "AUCTION_HOUSE_CLOSED",
}) do WowStub.knownEvents[e] = true end

function WowStub.Fire(event, ...)
  for frame in pairs(WowStub.eventFrames) do
    if frame._events[event] and frame._scripts.OnEvent then
      frame._scripts.OnEvent(frame, event, ...)
    end
  end
end

-- Timers run when flushed.
function WowStub.FlushTimers()
  for _ = 1, 5 do
    local pending = WowStub.timers
    WowStub.timers = {}
    for _, fn in ipairs(pending) do fn() end
  end
end

-- Installs the fake API as globals. `state` controls what the character and
-- Auctionator report.
function WowStub.Install(state)
  WowStub.eventFrames = {}
  WowStub.timers = {}
  WowStub.printed = {}
  WowStub.shoppingLists = {}
  WowStub.created = {}

  -- Lua aliases the client defines.
  strmatch, strfind, strsub, strlower, strupper, format, strlen, strrep, gsub =
    string.match, string.find, string.sub, string.lower, string.upper, string.format, string.len, string.rep, string.gsub
  tinsert, tremove, tconcat = table.insert, table.remove, table.concat
  wipe = function(t) for k in pairs(t) do t[k] = nil end return t end
  geterrorhandler = function() return error end
  securecallfunction = function(fn, ...) return fn(...) end
  max, min, floor, abs = math.max, math.min, math.floor, math.abs

  UIParent = WowStub.NewWidget(nil, "UIParent")
  Minimap = WowStub.NewWidget(UIParent, "Minimap")
  GameTooltip = WowStub.NewWidget(UIParent, "GameTooltip")
  UISpecialFrames = {}
  SlashCmdList = {}
  CreateFrame = function(_, name, parent)
    local w = WowStub.NewWidget(parent, name)
    WowStub.created[#WowStub.created + 1] = w
    if name then _G[name] = w end
    return w
  end
  print = function(...)
    local parts = {}
    for i = 1, select("#", ...) do parts[i] = tostring((select(i, ...))) end
    WowStub.printed[#WowStub.printed + 1] = table.concat(parts, " ")
  end
  issecretvalue = function() return false end
  GetMoneyString = function(copper) return tostring(copper) .. "c" end
  GameTooltip_Hide = noop
  UnitLevel = function() return state.level end
  UnitFactionGroup = function() return state.faction end
  GetCursorPosition = function() return 0, 0 end

  C_Timer = {
    After = function(_, fn) WowStub.timers[#WowStub.timers + 1] = fn end,
    NewTicker = function(_, fn) return { Cancel = noop, fn = fn } end,
  }
  C_Item = {
    GetItemNameByID = function() return nil end,
    GetItemIconByID = function() return 134400 end,
    RequestLoadItemDataByID = noop,
    GetItemCount = function(itemID) return (state.bags or {})[itemID] or 0 end,
  }
  C_CurrencyInfo = {
    GetCurrencyInfo = function(id)
      if id == 515 then return { name = "Darkmoon Prize Ticket", quantity = state.tickets or 0 } end
    end,
  }
  C_SkillInfo = {
    GetNumSkillLines = function() return #(state.skillLines or {}) end,
    GetSkillLineInfo = function(i) return state.skillLines[i] end,
  }
  C_Reputation = {
    GetFactionDataByID = function() return { currentStanding = state.reputation or 0 } end,
  }
  C_QuestLog = {
    IsQuestFlaggedCompleted = function(questID) return (state.completed or {})[questID] == true end,
  }
  C_TradeSkillUI = {
    GetBaseProfessionInfo = function() return state.openProfession end,
    GetAllRecipeIDs = function() return state.recipeIDs or {} end,
    GetRecipeInfo = function(id) return { learned = (state.learned or {})[id] == true } end,
    GetRecipeSchematic = function(id) return { outputItemID = (state.recipeOutputs or {})[id] } end,
  }

  local settingsCategory = { GetID = function() return 1 end }
  local function settingObject() return { SetValueChangedCallback = noop } end
  Settings = {
    VarType = { Number = "number", Boolean = "boolean" },
    RegisterVerticalLayoutCategory = function() return settingsCategory end,
    RegisterAddOnSetting = function() return settingObject() end,
    CreateSliderOptions = function() return { SetLabelFormatter = noop } end,
    CreateSlider = noop,
    CreateCheckbox = noop,
    RegisterAddOnCategory = noop,
    OpenToCategory = function() WowStub.settingsOpened = true end,
  }

  Auctionator = { API = { v1 = {
    GetAuctionPriceByItemID = function(caller, itemID)
      assert(type(caller) == "string" and caller ~= "", "callerID")
      assert(type(itemID) == "number", "itemID must be a number")
      local q = (state.prices or {})[itemID]
      return q and q.price
    end,
    GetAuctionAgeByItemID = function(_, itemID)
      local q = (state.prices or {})[itemID]
      return q and q.age
    end,
    GetVendorPriceByItemID = function() return nil end,
    ConvertToSearchString = function(_, term) return term.searchString .. ";" .. tostring(term.quantity) end,
    CreateShoppingList = function(_, name, terms) WowStub.shoppingLists[name] = terms end,
  } } }
end

-- Loads every file the TOC lists, in order, the way the client does.
function WowStub.LoadTOC(dir, addonName)
  local ns = {}
  for line in io.lines(dir .. addonName .. ".toc") do
    line = line:gsub("\r", "")
    if line ~= "" and not line:match("^#") then
      local path = dir .. line:gsub("\\", "/")
      local chunk = assert(loadfile(path))
      chunk(addonName, ns)
    end
  end
  return ns
end
