-- Price adapter: builds the Engine's `prices` table from Auctionator.
--
-- Uses only the public Auctionator.API.v1 (ADR 0002): no internals, no history.

local addonName, ns = ...

local Prices = {}

local function auctionatorAPI()
    return Auctionator and Auctionator.API and Auctionator.API.v1
end

function Prices.IsAvailable()
    return auctionatorAPI() ~= nil
end

-- Every item ID the data references: Turn-in Items, recipe outputs and reagents.
local itemIDs
local function referencedItemIDs(data)
    if itemIDs then
        return itemIDs
    end
    local seen = {}
    itemIDs = {}
    local function add(id)
        if not seen[id] then
            seen[id] = true
            itemIDs[#itemIDs + 1] = id
        end
    end
    for _, source in ipairs(data.sources) do
        if not source.free then
            for _, entry in ipairs(source.items) do
                add(entry.itemID)
            end
        end
    end
    for itemID, recipe in pairs(data.recipes or {}) do
        add(itemID)
        for _, r in ipairs(recipe.reagents) do
            add(r.itemID)
        end
    end
    return itemIDs
end

local function call(fn, itemID)
    if not fn then
        return nil
    end
    local ok, value = pcall(fn, addonName, itemID)
    if ok and type(value) == "number" then
        return value
    end
    return nil
end

-- Returns itemID -> { price = copper, age = days, vendorPrice = copper } for
-- every referenced item Auctionator knows something about.
function Prices.Snapshot(data)
    local api = auctionatorAPI()
    local snapshot = {}
    if not api then
        return snapshot
    end
    for _, itemID in ipairs(referencedItemIDs(data)) do
        local quote = {}
        quote.price = call(api.GetAuctionPriceByItemID, itemID)
        if quote.price then
            quote.age = call(api.GetAuctionAgeByItemID, itemID)
        end
        if data.vendor and data.vendor[itemID] then
            quote.vendorPrice = call(api.GetVendorPriceByItemID, itemID)
        end
        if quote.price or quote.vendorPrice then
            snapshot[itemID] = quote
        end
    end
    return snapshot
end

ns.Prices = Prices
