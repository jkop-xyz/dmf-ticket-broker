-- The ranking engine: pure Lua with no WoW API access. This is the addon's
-- single automated test seam.
--
--   rows, info = Engine.Rank(data, prices, character)
--
-- data      : the static tables from Data.lua (or a test fixture shaped the same)
-- prices    : itemID -> { price = copper|nil, age = days|nil, vendorPrice = copper|nil }
--             `price`/`age` are Auctionator's latest Scan Price and Price Age.
--             `vendorPrice` overrides data.vendor's fallback price for Vendor Items.
-- character : snapshot of the current character, every field optional:
--               level, faction ("Alliance"/"Horde"), reputation (absolute barValue),
--               completedQuests = { [questID] = true },
--               hasVoucher      = bool,
--               skills          = { [profession] = rank }        absent => Missing Profession
--               knownRecipes    = { [profession] = { [itemID] = true } }
--                                 absent profession => Not Scanned
--               staleDays       = number (default 3)
--
-- rows: one per ranked Ticket Source, cheapest rankCost first, noData rows last.
--   source, tickets
--   buyCost, buyCostPerTicket        Buy route for every Turn-in Item (AH or vendor)
--   craftCost, craftCostPerTicket    only when a Turn-in Item is Craftable and priceable
--   fullCraftCost, fullCraftCostPerTicket
--                                    Craft cost as if the character could craft
--                                    everything; display only, never ranked
--   turnInCost                       cheapest available total for one turn-in
--   rankCost                         turnInCost / tickets (Cost per Ticket)
--   noData                           true when no route prices every Turn-in Item
--   eligibility = { state = Engine.ELIGIBILITY.*, requiredLevel = n,
--                   profession = key, requiredSkill = n }   (the last two for PROFESSION_REQUIRED)
--   craftability                     Engine.CRAFTABILITY.* of the (first) crafted Turn-in Item
--   profession                       that item's profession
--   stale                            any chosen price in the Breakdown is Stale
--   repPerTurnIn                     reputation one turn-in gives (0 for repeatables)
--   unlimited                        true for repeatable quests with no limit
--   turnInsLeft, ticketsLeft         turn-ins (and tickets) left before the tier's
--                                    reputation limit; nil when unlimited or unknown
--   breakdown                        list of item nodes (see resolve below)
--
-- options: { sortBy = Engine.SORT.* } (default PER_TICKET); optional.
--
-- info: { reminder = Free Ticket Source to remind about, or nil,
--         hasAnyPrice = whether any Scan Price exists at all,
--         rewards = one entry per Prize Reward (see rewardsFor below) }

local _, ns = ...

local Engine = {}

Engine.ELIGIBILITY = {
    ELIGIBLE = "eligible",
    LEVEL_TOO_LOW = "levelTooLow",
    PROFESSION_REQUIRED = "professionRequired",
    REPUTATION_TOO_HIGH = "reputationTooHigh",
    ALREADY_DONE = "alreadyDone",
}

Engine.CRAFTABILITY = {
    CRAFTABLE = "craftable",
    NEEDS_SKILL_UP = "needsSkillUp",
    RECIPE_UNKNOWN = "recipeUnknown",
    NOT_SCANNED = "notScanned",
    MISSING_PROFESSION = "missingProfession",
}

Engine.ROUTE = { AH = "ah", VENDOR = "vendor", CRAFT = "craft" }

-- Ranking orders for Engine.Rank options.sortBy.
Engine.SORT = { PER_TICKET = "perTicket", PER_TURN_IN = "perTurnIn" }

local E, C, R = Engine.ELIGIBILITY, Engine.CRAFTABILITY, Engine.ROUTE
local DEFAULT_STALE_DAYS = 3

-- Craftability ---------------------------------------------------------------

function Engine.Craftability(data, character, itemID)
    local recipe = data.recipes and data.recipes[itemID]
    if not recipe then
        return nil
    end
    local rank = character.skills and character.skills[recipe.profession]
    if not rank then
        return C.MISSING_PROFESSION, recipe
    end
    if rank < recipe.skill then
        return C.NEEDS_SKILL_UP, recipe
    end
    local known = character.knownRecipes and character.knownRecipes[recipe.profession]
    if not known then
        return C.NOT_SCANNED, recipe
    end
    if not known[itemID] then
        return C.RECIPE_UNKNOWN, recipe
    end
    return C.CRAFTABLE, recipe
end

-- Turn-in Eligibility ----------------------------------------------------------

local function eligibility(data, character, source)
    if source.free and character.completedQuests and character.completedQuests[source.questID] then
        return { state = E.ALREADY_DONE }
    end
    local tier = source.tier and data.tiers[source.tier]
    if tier then
        if character.level and tier.minLevel and character.level < tier.minLevel then
            return { state = E.LEVEL_TOO_LOW, requiredLevel = tier.minLevel }
        end
    end
    -- Only quests flagged in Data need a profession to be turned in.
    local need = source.requiresProfession
    if need then
        local rank = character.skills and character.skills[need.profession]
        if not rank or rank < (need.skill or 1) then
            return { state = E.PROFESSION_REQUIRED, profession = need.profession, requiredSkill = need.skill }
        end
    end
    if tier then
        if not source.repeatable and character.reputation and tier.repCap
            and character.reputation >= tier.repCap then
            return { state = E.REPUTATION_TOO_HIGH }
        end
    end
    return { state = E.ELIGIBLE }
end

-- Item resolution ------------------------------------------------------------
--
-- A node prices `quantity` of one item by the cheapest available route:
--   itemID, name, quantity
--   route            Engine.ROUTE.* that was chosen, or nil (noData)
--   total, unitCost  copper for the whole quantity / per item, or nil
--   buyTotal         cheapest of AH and vendor for the whole quantity, or nil
--   craftTotal       total via Craft when Craftable and priceable, or nil
--   fullCraftTotal   total via Craft as if the character could craft every
--                    recipe in the tree (for display only; never ranked), or nil
--   ahTotal, vendorTotal
--   age              Price Age of the Scan Price (when one exists)
--   stale            the chosen route is AH and its Scan Price is Stale
--   anyStale         stale here or anywhere below in the chosen tree
--   vendor           the data.vendor entry, when the item is a Vendor Item
--   craftability     Engine.CRAFTABILITY.*, for items that have a recipe
--   requiredSkill, profession   from the recipe
--   crafts           number of crafts needed (when route is Craft)
--   children         reagent nodes (when route is Craft, or when a Craftable
--                    item is noData, to show which reagent lacks a price)
--   noData           true when no route is available

local resolve

-- Cheapest of AH and vendor for `quantity` of an item, or nil.
local function buyPrice(ctx, itemID, quantity)
    local quote = ctx.prices[itemID]
    local best = quote and quote.price and quote.price * quantity
    local vendorEntry = ctx.data.vendor and ctx.data.vendor[itemID]
    if vendorEntry then
        local unit = (quote and quote.vendorPrice) or vendorEntry.price
        if unit and (not best or unit * quantity < best) then
            best = unit * quantity
        end
    end
    return best
end

-- Craft cost ignoring Craftability: every reagent is bought or crafted,
-- whichever is cheaper. Nil when a reagent has no price at all.
local function fullCraftCost(ctx, recipe, quantity, visiting)
    local crafts = math.ceil(quantity / (recipe.yield or 1))
    local total = 0
    for _, r in ipairs(recipe.reagents) do
        local needed = r.quantity * crafts
        local best = buyPrice(ctx, r.itemID, needed)
        local sub = ctx.data.recipes and ctx.data.recipes[r.itemID]
        if sub and not visiting[r.itemID] then
            visiting[r.itemID] = true
            local crafted = fullCraftCost(ctx, sub, needed, visiting)
            visiting[r.itemID] = nil
            if crafted and (not best or crafted < best) then
                best = crafted
            end
        end
        if not best then
            return nil
        end
        total = total + best
    end
    return total
end

local function craftOption(ctx, recipe, quantity, visiting)
    local crafts = math.ceil(quantity / (recipe.yield or 1))
    local children, total = {}, 0
    for i, r in ipairs(recipe.reagents) do
        local child = resolve(ctx, r.itemID, r.name, r.quantity * crafts, visiting)
        children[i] = child
        if total and child.total then
            total = total + child.total
        else
            total = nil
        end
    end
    return total, children, crafts
end

function resolve(ctx, itemID, name, quantity, visiting)
    local data, prices, character = ctx.data, ctx.prices, ctx.character
    local node = { itemID = itemID, name = name, quantity = quantity }

    local quote = prices[itemID]
    if quote and quote.price then
        node.ahTotal = quote.price * quantity
        node.age = quote.age
    end

    local vendorEntry = data.vendor and data.vendor[itemID]
    if vendorEntry then
        node.vendor = vendorEntry
        local vendorPrice = (quote and quote.vendorPrice) or vendorEntry.price
        if vendorPrice then
            node.vendorTotal = vendorPrice * quantity
        end
    end

    local craftability, recipe = Engine.Craftability(data, character, itemID)
    node.craftability = craftability
    if recipe then
        node.profession = recipe.profession
        node.requiredSkill = recipe.skill
        local wasVisiting = visiting[itemID]
        visiting[itemID] = true
        node.fullCraftTotal = fullCraftCost(ctx, recipe, quantity, visiting)
        visiting[itemID] = wasVisiting
    end

    local craftChildren, crafts
    if craftability == C.CRAFTABLE and not visiting[itemID] then
        visiting[itemID] = true
        node.craftTotal, craftChildren, crafts = craftOption(ctx, recipe, quantity, visiting)
        visiting[itemID] = nil
    end

    -- Buy: the cheaper of AH and vendor. Ties go to the vendor (always in stock).
    local buyRoute
    if node.vendorTotal and (not node.ahTotal or node.vendorTotal <= node.ahTotal) then
        node.buyTotal, buyRoute = node.vendorTotal, R.VENDOR
    elseif node.ahTotal then
        node.buyTotal, buyRoute = node.ahTotal, R.AH
    end

    -- Cheapest overall. Ties prefer buying over crafting.
    if node.craftTotal and (not node.buyTotal or node.craftTotal < node.buyTotal) then
        node.route, node.total = R.CRAFT, node.craftTotal
        node.children, node.crafts = craftChildren, crafts
    elseif node.buyTotal then
        node.route, node.total = buyRoute, node.buyTotal
    elseif craftChildren then
        -- No route works, but keep the attempted craft tree so the Breakdown
        -- can show which reagent is missing a price.
        node.children, node.crafts = craftChildren, crafts
    end

    node.noData = node.total == nil
    if node.total then
        node.unitCost = node.total / quantity
    end
    node.stale = node.route == R.AH and node.age ~= nil and node.age > ctx.staleDays
    node.anyStale = node.stale
    if node.children then
        for _, child in ipairs(node.children) do
            if child.anyStale then
                node.anyStale = true
            end
        end
    end
    return node
end

-- Rows -------------------------------------------------------------------------

local function ticketsFor(data, source)
    if source.tickets then
        return source.tickets
    end
    local tier = data.tiers[source.tier]
    return tier and tier.tickets
end

local function sum(nodes, field)
    local total = 0
    for _, node in ipairs(nodes) do
        if not node[field] then
            return nil
        end
        total = total + node[field]
    end
    return total
end

local function perTicket(total, tickets)
    if total and tickets then
        return total / tickets
    end
    return nil
end

local function buildRow(ctx, source)
    local nodes = {}
    for i, entry in ipairs(source.items) do
        nodes[i] = resolve(ctx, entry.itemID, entry.name, entry.quantity, {})
    end

    local row = {
        source = source,
        tickets = ticketsFor(ctx.data, source),
        breakdown = nodes,
        eligibility = eligibility(ctx.data, ctx.character, source),
    }

    row.buyCost = sum(nodes, "buyTotal")
    local anyCraft = false
    for _, node in ipairs(nodes) do
        if node.craftability and row.craftability == nil then
            row.craftability, row.profession = node.craftability, node.profession
        end
        if node.craftTotal then
            anyCraft = true
        end
        if node.anyStale then
            row.stale = true
        end
    end
    if anyCraft then
        local craftCost = 0
        for _, node in ipairs(nodes) do
            local cost = node.craftTotal or node.buyTotal
            craftCost = craftCost and cost and craftCost + cost or nil
        end
        row.craftCost = craftCost
    end

    -- What crafting would cost if this character could craft everything, for
    -- display next to rows the character can't craft yet. Never ranked.
    local anyRecipe = false
    local fullCraft = 0
    for _, node in ipairs(nodes) do
        if node.fullCraftTotal then
            anyRecipe = true
        end
        local cost = node.fullCraftTotal or node.buyTotal
        fullCraft = fullCraft and cost and fullCraft + cost or nil
    end
    if anyRecipe then
        row.fullCraftCost = fullCraft
        row.fullCraftCostPerTicket = perTicket(fullCraft, row.tickets)
    end

    row.buyCostPerTicket = perTicket(row.buyCost, row.tickets)
    row.craftCostPerTicket = perTicket(row.craftCost, row.tickets)
    row.turnInCost = sum(nodes, "total")
    row.rankCost = perTicket(row.turnInCost, row.tickets)
    row.noData = row.rankCost == nil

    local tier = source.tier and ctx.data.tiers[source.tier]
    if source.repeatable then
        row.unlimited, row.repPerTurnIn = true, 0
    elseif tier then
        row.repPerTurnIn = tier.rep or 0
        local reputation = ctx.character.reputation
        if reputation and tier.repCap and row.repPerTurnIn > 0 then
            -- Available while reputation is below the limit, so the turn-in that
            -- crosses it still counts.
            row.turnInsLeft = reputation >= tier.repCap and 0
                or math.ceil((tier.repCap - reputation) / row.repPerTurnIn)
            row.ticketsLeft = row.tickets and row.turnInsLeft * row.tickets
        end
    end
    row.stale = row.stale or false
    return row
end

local SORT_FIELD = {
    perTicket = "rankCost",
    perTurnIn = "turnInCost",
}

local function compareRows(field, a, b)
    if a.noData ~= b.noData then
        return not a.noData
    end
    if not a.noData and a[field] ~= b[field] then
        return a[field] < b[field]
    end
    if not a.noData and a.rankCost ~= b.rankCost then
        return a.rankCost < b.rankCost
    end
    local tierA, tierB = a.source.tier or 0, b.source.tier or 0
    if tierA ~= tierB then
        return tierA < tierB
    end
    if a.source.name ~= b.source.name then
        return a.source.name < b.source.name
    end
    return (a.source.questID or 0) < (b.source.questID or 0)
end

local function reminderFor(data, character)
    if not character.hasVoucher then
        return nil
    end
    for _, source in ipairs(data.sources) do
        local levelOk = not (source.minLevel and character.level and character.level < source.minLevel)
        if source.free and levelOk
            and (not source.faction or not character.faction or source.faction == character.faction) then
            if not (character.completedQuests and character.completedQuests[source.questID]) then
                return source
            end
        end
    end
    return nil
end

-- Ticket plan ----------------------------------------------------------------------
--
-- The cheapest way to earn `need` more tickets from the ranked rows: repeatedly
-- take the cheapest-per-ticket turn-in still available. Reputation is shared, so
-- every turn-in moves all tiers closer to their limits. Rows the character can't
-- hand in (level, profession) and rows without prices are skipped.
-- Returns { cost, tickets, complete, turnIns = { { row = row, count = n }, ... } }.
local PLAN_MAX_STEPS = 5000

function Engine.TicketPlan(data, rows, character, need)
    local reputation = character.reputation
    local candidates = {}
    for _, row in ipairs(rows) do
        local state = row.eligibility.state
        if not row.noData and state ~= E.LEVEL_TOO_LOW and state ~= E.PROFESSION_REQUIRED
            and state ~= E.ALREADY_DONE then
            candidates[#candidates + 1] = row
        end
    end
    local function available(row)
        if row.unlimited or reputation == nil then
            return true
        end
        local tier = data.tiers[row.source.tier]
        return not (tier and tier.repCap) or reputation < tier.repCap
    end

    local plan = { cost = 0, tickets = 0, turnIns = {} }
    local byQuest = {}
    for _ = 1, PLAN_MAX_STEPS do
        if plan.tickets >= need then
            break
        end
        local best
        for _, row in ipairs(candidates) do
            if available(row) and (not best or row.rankCost < best.rankCost) then
                best = row
            end
        end
        if not best then
            break
        end
        plan.cost = plan.cost + best.turnInCost
        plan.tickets = plan.tickets + best.tickets
        if reputation then
            reputation = reputation + (best.repPerTurnIn or 0)
        end
        local entry = byQuest[best.source.questID]
        if not entry then
            entry = { row = best, count = 0 }
            byQuest[best.source.questID] = entry
            plan.turnIns[#plan.turnIns + 1] = entry
        end
        entry.count = entry.count + 1
    end
    plan.complete = plan.tickets >= need
    return plan
end

-- Prize Rewards -------------------------------------------------------------------
--
-- One entry per Prize Reward: { reward, owned, missing, affordable, usable,
-- plan } (`usable`: the character meets the item's own level requirement;
-- buying it has none) where `plan` (a TicketPlan for the missing tickets) is nil when the
-- character already has enough.
local function rewardsFor(data, rows, character)
    local owned = character.tickets or 0
    local out = {}
    for i, reward in ipairs(data.rewards or {}) do
        local missing = math.max(0, reward.tickets - owned)
        out[i] = {
            reward = reward,
            owned = owned,
            missing = missing,
            affordable = missing == 0,
            usable = not (character.level and reward.useLevel and character.level < reward.useLevel),
            plan = missing > 0 and Engine.TicketPlan(data, rows, character, missing) or nil,
        }
    end
    return out
end

local function hasAnyPrice(prices)
    for _, quote in pairs(prices) do
        if quote.price then
            return true
        end
    end
    return false
end

function Engine.Rank(data, prices, character, options)
    prices = prices or {}
    character = character or {}
    local ctx = {
        data = data,
        prices = prices,
        character = character,
        staleDays = character.staleDays or DEFAULT_STALE_DAYS,
    }
    local rows = {}
    for _, source in ipairs(data.sources) do
        if not source.free then
            rows[#rows + 1] = buildRow(ctx, source)
        end
    end
    local field = SORT_FIELD[options and options.sortBy] or SORT_FIELD.perTicket
    table.sort(rows, function(a, b) return compareRows(field, a, b) end)
    return rows, {
        reminder = reminderFor(data, character),
        hasAnyPrice = hasAnyPrice(prices),
        rewards = rewardsFor(data, rows, character),
    }
end

-- Shopping list ------------------------------------------------------------------

-- The items a row's Breakdown says to buy on the AH: AH-routed nodes, descending
-- through crafted nodes. Vendor Items and noData items are left out. Quantities
-- are summed per item. Returns a list of { itemID, name, quantity }, sorted by name.
function Engine.ShoppingList(row)
    local byItem, order = {}, {}
    local function walk(node)
        if node.route == R.AH then
            local entry = byItem[node.itemID]
            if not entry then
                entry = { itemID = node.itemID, name = node.name, quantity = 0 }
                byItem[node.itemID] = entry
                order[#order + 1] = entry
            end
            entry.quantity = entry.quantity + node.quantity
        elseif node.route == R.CRAFT then
            for _, child in ipairs(node.children) do
                walk(child)
            end
        end
    end
    for _, node in ipairs(row.breakdown) do
        walk(node)
    end
    table.sort(order, function(a, b) return a.name < b.name end)
    return order
end

ns.Engine = Engine
