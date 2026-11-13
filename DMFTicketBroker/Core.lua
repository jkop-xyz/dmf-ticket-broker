-- Entry point: SavedVariables, events, live refresh, reminder, slash commands.

local addonName, ns = ...

local events = CreateFrame("Frame")
local handlers = {}

local AH_POLL_SECONDS = 5
local ahTicker
local reminded = false

-- Free Ticket Source reminder: one chat message per session ------------------------

local function checkReminder()
    if reminded then
        return
    end
    local _, info = ns.Engine.Rank(ns.Data, {}, ns.Character.Snapshot())
    if info.reminder then
        reminded = true
        print("|cffffd100DMF Ticket Broker|r: " .. ns.UI.ReminderText(info.reminder))
    end
end

-- Events ---------------------------------------------------------------------------

function handlers.ADDON_LOADED(name)
    if name ~= addonName then
        return
    end
    ns.Settings.Init()
    ns.Settings.RegisterPanel()
    ns.Minimap.Init()
end

function handlers.PLAYER_ENTERING_WORLD()
    C_Timer.After(5, checkReminder)
end

function handlers.BAG_UPDATE_DELAYED()
    checkReminder()
    ns.UI.RequestRefresh()
end

-- Item names load asynchronously; redraw once a batch of them has arrived.
local redrawQueued = false
function handlers.ITEM_DATA_LOAD_RESULT()
    if redrawQueued or not ns.UI.IsShown() then
        return
    end
    redrawQueued = true
    C_Timer.After(0.2, function()
        redrawQueued = false
        ns.UI.Render()
    end)
end

local function scanProfession()
    if ns.Character.ScanOpenProfession() then
        ns.UI.RequestRefresh()
    end
end
handlers.TRADE_SKILL_SHOW = scanProfession
handlers.TRADE_SKILL_LIST_UPDATE = scanProfession
handlers.TRADE_SKILL_DATA_SOURCE_CHANGED = scanProfession

function handlers.NEW_RECIPE_LEARNED(recipeID)
    ns.Character.LearnRecipe(recipeID)
    ns.UI.RequestRefresh()
end

-- Anything else that changes the snapshot just triggers a refresh.
for _, event in ipairs({
    "SKILL_LINES_CHANGED", "PLAYER_LEVEL_UP", "UPDATE_FACTION", "QUEST_TURNED_IN",
    "CURRENCY_DISPLAY_UPDATE", "MERCHANT_CLOSED",
}) do
    handlers[event] = function()
        ns.UI.RequestRefresh()
    end
end

-- Auctionator has no update callback, so poll while the auction house is open.
function handlers.AUCTION_HOUSE_SHOW()
    if ahTicker then
        return
    end
    ahTicker = C_Timer.NewTicker(AH_POLL_SECONDS, function()
        ns.UI.RequestRefresh()
    end)
end

function handlers.AUCTION_HOUSE_CLOSED()
    if ahTicker then
        ahTicker:Cancel()
        ahTicker = nil
    end
    ns.UI.RequestRefresh()
end

events:SetScript("OnEvent", function(_, event, ...)
    handlers[event](...)
end)
for event in pairs(handlers) do
    -- Registering an event the client doesn't know raises an error on the
    -- modern client; skip those rather than failing to load.
    pcall(events.RegisterEvent, events, event)
end

-- Slash commands --------------------------------------------------------------------

SLASH_DMFTICKETBROKER1 = "/dmft"
SLASH_DMFTICKETBROKER2 = "/dmftickets"
SlashCmdList.DMFTICKETBROKER = function(msg)
    msg = (msg or ""):lower():match("^%s*(.-)%s*$")
    if msg == "settings" or msg == "options" or msg == "config" then
        ns.Settings.Open()
    else
        ns.UI.Toggle()
    end
end
