-- Account-wide settings and the Options -> AddOns panel.

local addonName, ns = ...

local Settings_ = {}

local DEFAULTS = {
    staleDays = 3,
    minimap = { hide = false },
    sortBy = "perTicket",
    eligibleOnly = false,
    view = "sources",
    window = nil,
}

local category

function Settings_.Init()
    DMFTicketBrokerDB = DMFTicketBrokerDB or {}
    local db = DMFTicketBrokerDB
    if type(db.staleDays) ~= "number" then
        db.staleDays = DEFAULTS.staleDays
    end
    if db.sortBy ~= "perTicket" and db.sortBy ~= "perTurnIn" then
        db.sortBy = DEFAULTS.sortBy
    end
    if db.view ~= "sources" and db.view ~= "rewards" then
        db.view = DEFAULTS.view
    end
    if type(db.eligibleOnly) ~= "boolean" then
        db.eligibleOnly = DEFAULTS.eligibleOnly
    end
    if type(db.minimap) ~= "table" then
        db.minimap = { hide = DEFAULTS.minimap.hide }
    end
end

function Settings_.Get(key)
    local db = DMFTicketBrokerDB
    if db and db[key] ~= nil then
        return db[key]
    end
    return DEFAULTS[key]
end

function Settings_.DB()
    return DMFTicketBrokerDB
end

-- Builds the panel. Every call is guarded: the Settings API has changed shape
-- between client versions and this one is not verified on Forever yet.
function Settings_.RegisterPanel()
    if not (Settings and Settings.RegisterVerticalLayoutCategory and Settings.RegisterAddOnSetting) then
        return
    end
    local ok, err = pcall(function()
        category = Settings.RegisterVerticalLayoutCategory("DMF Ticket Broker")

        local stale = Settings.RegisterAddOnSetting(category, "DMFTicketBroker_StaleDays", "staleDays",
            DMFTicketBrokerDB, Settings.VarType.Number, "Stale price threshold (days)", DEFAULTS.staleDays)
        local options = Settings.CreateSliderOptions(1, 21, 1)
        if MinimalSliderWithSteppersMixin and options.SetLabelFormatter then
            options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)
        end
        Settings.CreateSlider(category, stale, options,
            "Auction prices older than this many days are highlighted as stale.")
        stale:SetValueChangedCallback(function()
            ns.UI.RequestRefresh()
        end)

        local hide = Settings.RegisterAddOnSetting(category, "DMFTicketBroker_HideMinimap", "hide",
            DMFTicketBrokerDB.minimap, Settings.VarType.Boolean, "Hide minimap button", DEFAULTS.minimap.hide)
        Settings.CreateCheckbox(category, hide, "Hide the minimap button. The window stays available from the Addon Compartment and /dmft.")
        hide:SetValueChangedCallback(function()
            ns.Minimap.ApplyVisibility()
        end)

        Settings.RegisterAddOnCategory(category)
    end)
    if not ok then
        category = nil
        print("|cffffd100DMF Ticket Broker|r: could not create the settings panel (" .. tostring(err) .. ").")
    end
end

function Settings_.Open()
    if category and Settings and Settings.OpenToCategory then
        Settings.OpenToCategory(category:GetID())
    else
        print("|cffffd100DMF Ticket Broker|r: the settings panel is unavailable. Stale threshold: "
            .. Settings_.Get("staleDays") .. " days.")
    end
end

ns.Settings = Settings_
