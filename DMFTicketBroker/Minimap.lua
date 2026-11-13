-- Minimap button (LibDBIcon) and the Addon Compartment entry.

local addonName, ns = ...

local Minimap_ = {}

Minimap_.ICON = "Interface\\Icons\\INV_Misc_Ticket_Darkmoon_01"

local LDB = LibStub and LibStub("LibDataBroker-1.1", true)
local DBIcon = LibStub and LibStub("LibDBIcon-1.0", true)

local function tooltip(tt)
    tt:AddLine("DMF Ticket Broker")
    tt:AddLine("Click to show or hide the cheapest Ticket Sources.", 1, 1, 1)
    tt:AddLine("Right-click for settings.", 1, 1, 1)
end

function Minimap_.Init()
    if not (LDB and DBIcon) then
        return
    end
    local launcher = LDB:NewDataObject(addonName, {
        type = "launcher",
        text = "DMF Ticket Broker",
        icon = Minimap_.ICON,
        OnClick = function(_, button)
            if button == "RightButton" then
                ns.Settings.Open()
            else
                ns.UI.Toggle()
            end
        end,
        OnTooltipShow = tooltip,
    })
    DBIcon:Register(addonName, launcher, ns.Settings.DB().minimap)
end

function Minimap_.ApplyVisibility()
    if not DBIcon then
        return
    end
    if ns.Settings.DB().minimap.hide then
        DBIcon:Hide(addonName)
    else
        DBIcon:Show(addonName)
    end
end

-- Addon Compartment callbacks are looked up by name, so they must be globals.
function DMFTicketBroker_OnAddonCompartmentClick(_, button)
    if button == "RightButton" then
        ns.Settings.Open()
    else
        ns.UI.Toggle()
    end
end

function DMFTicketBroker_OnAddonCompartmentEnter(_, menuButton)
    GameTooltip:SetOwner(menuButton, "ANCHOR_LEFT")
    tooltip(GameTooltip)
    GameTooltip:Show()
end

function DMFTicketBroker_OnAddonCompartmentLeave()
    GameTooltip:Hide()
end

ns.Minimap = Minimap_
