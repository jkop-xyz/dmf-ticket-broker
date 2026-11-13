-- Exports a row's Breakdown as an Auctionator shopping list.

local addonName, ns = ...

local Shopping = {}

local PREFIX = "|cffffd100DMF Ticket Broker|r: "

local function itemName(entry)
    return (C_Item and C_Item.GetItemNameByID and C_Item.GetItemNameByID(entry.itemID)) or entry.name
end

local function searchString(api, entry)
    local name = itemName(entry)
    if api.ConvertToSearchString then
        local ok, result = pcall(api.ConvertToSearchString, addonName, {
            searchString = name,
            isExact = true,
            quantity = entry.quantity,
        })
        if ok and type(result) == "string" then
            return result
        end
    end
    -- Auctionator's exact-match syntax, without a quantity.
    return "\"" .. name .. "\""
end

function Shopping.ListName(row)
    return "DMF: " .. row.source.name
end

function Shopping.HasItems(row)
    return #ns.Engine.ShoppingList(row) > 0
end

function Shopping.Create(row)
    local api = Auctionator and Auctionator.API and Auctionator.API.v1
    if not (api and api.CreateShoppingList) then
        print(PREFIX .. "Auctionator's shopping list API is not available.")
        return
    end
    local items = ns.Engine.ShoppingList(row)
    if #items == 0 then
        print(PREFIX .. "nothing to buy on the Auction House for " .. row.source.name .. ".")
        return
    end
    local terms = {}
    for i, entry in ipairs(items) do
        terms[i] = searchString(api, entry)
    end
    local listName = Shopping.ListName(row)
    local ok, err = pcall(api.CreateShoppingList, addonName, listName, terms)
    if ok then
        print(PREFIX .. "created Auctionator shopping list \"" .. listName .. "\" with " .. #items .. (#items == 1 and " item." or " items."))
    else
        print(PREFIX .. "could not create the shopping list (" .. tostring(err) .. ").")
    end
end

ns.Shopping = Shopping
