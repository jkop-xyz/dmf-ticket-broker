-- Main window: the ranked Ticket Sources with expandable Breakdowns.
--
-- Layout, top to bottom: title bar with portrait, a dark inset panel holding
-- a section header (ticket count, settings), sort buttons, notices, column
-- headers and the scrolling list, then a footer legend under the panel.

local addonName, ns = ...

local UI = {}

local FRAME_NAME = "DMFTicketBrokerFrame"
local WIDTH, HEIGHT = 920, 640
local INELIGIBLE_ALPHA = 0.45
local ICON_FALLBACK = "Interface\\Icons\\INV_Misc_QuestionMark"

-- Line heights per kind; rows are two-line cards.
local HEIGHT_OF = { row = 44, reward = 44, summary = 22, craftSummary = 22, bheader = 18, node = 22, shop = 28, spacer = 6 }
local ROW_GAP = 2
local INDENT = 16

-- Columns, shared by rows and Breakdown lines so values line up: a node's
-- Total sits under the row's Per turn-in.
-- Rows start with an expand/collapse icon, then the item icon, then the name.
local X_TOGGLE, TOGGLE_SIZE = 6, 14
local X_ROW_ICON = 24
local X_NAME = 64
-- One cost column; the sort tabs pick whether it shows per ticket or per
-- turn-in. In Breakdowns, TOTAL sits under it and EACH to its left.
local X_TICKETS, W_TICKETS = 420, 50
local X_COST, W_COST = 480, 110
local X_HOW, W_HOW = 610, 140
local X_AGE, W_AGE = 770, 60
local X_EACH, W_EACH = 360, 110
local CONTENT_WIDTH = WIDTH - 60
-- The panel sits under the title bar and above the footer.
local PANEL_TOP, PANEL_BOTTOM = 28, 30
local PANEL_HEIGHT = HEIGHT - PANEL_TOP - PANEL_BOTTOM

local PALETTE = {
    panel = { 0.03, 0.03, 0.04, 0.92 },
    panelBorder = { 0.45, 0.36, 0.16, 0.9 },
    rowA = { 0.08, 0.08, 0.10, 0.95 },
    rowB = { 0.13, 0.13, 0.15, 0.95 },
    inset = { 0.06, 0.06, 0.07, 0.98 },
    accent = { 1.0, 0.82, 0.0, 0.9 },
    hover = { 1, 1, 1, 0.06 },
    noticeWarn = { 0.35, 0.25, 0.0, 0.55 },
    noticeBad = { 0.4, 0.05, 0.05, 0.55 },
    noticeGood = { 0.05, 0.3, 0.05, 0.55 },
    tab = { 0.09, 0.09, 0.10, 0.95 },
    tabActive = { 0.32, 0.25, 0.05, 0.95 },
}

local COLOR = {
    white = "|cffffffff",
    good = "|cff40ff40",
    warn = "|cffffd100",
    bad = "|cffff5050",
    stale = "|cffff8000",
    dim = "|cff8c8c8c",
    gold = "|cffffd700",
    silver = "|cffc7c7cf",
    copper = "|cffb87333",
}
local function color(key, text)
    return COLOR[key] .. text .. "|r"
end

local SEP = color("dim", "  ·  ")
local GREY = { 0.5, 0.5, 0.5 }

local function stripColors(text)
    return (text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""))
end

local frame, content, scroll
local linePool = {}
local expanded = {}
local lastRows, lastInfo, lastCharacter = {}, {}, {}

-- The two views, switched by the tabs under the window.
local VIEW = { SOURCES = "sources", REWARDS = "rewards" }

-- Formatting -------------------------------------------------------------------

-- "12g 4s 5c" with tinted unit letters, leaving out leading zero units.
local function money(copper)
    copper = math.floor(copper + 0.5)
    local g, s, c = math.floor(copper / 10000), math.floor(copper / 100) % 100, copper % 100
    -- Leading and trailing zero units are left out: "5s", "1g 0s 3c", "0c".
    local parts = {}
    if g > 0 then
        parts[#parts + 1] = g .. color("gold", "g")
    end
    if s > 0 or (g > 0 and c > 0) then
        parts[#parts + 1] = s .. color("silver", "s")
    end
    if c > 0 or (g == 0 and s == 0) then
        parts[#parts + 1] = c .. color("copper", "c")
    end
    return table.concat(parts, " ")
end

local function ageText(age)
    if age == nil then
        return ""
    elseif age < 1 then
        return "today"
    end
    return string.format("%dd", age)
end

-- An age for display; stale ones are orange and marked with "!".
local function ageLabel(age, stale)
    if age == nil then
        return ""
    end
    return stale and color("stale", ageText(age) .. " !") or color("dim", ageText(age))
end

local function plural(n, word)
    return string.format("%d %s%s", n, word, n == 1 and "" or "s")
end

local function itemName(itemID, fallback)
    local name = C_Item and C_Item.GetItemNameByID and C_Item.GetItemNameByID(itemID)
    if name then
        return name
    end
    if C_Item and C_Item.RequestLoadItemDataByID then
        C_Item.RequestLoadItemDataByID(itemID)
    end
    return fallback or ("item " .. itemID)
end

local function itemIcon(itemID)
    local icon = C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(itemID)
    return icon or ICON_FALLBACK
end

-- Prize Tickets are a currency on this client, so its icon is the reliable one.
local function ticketIcon()
    local info = C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo
        and C_CurrencyInfo.GetCurrencyInfo(ns.Data.ticketCurrencyID)
    if info and info.iconFileID then
        return info.iconFileID
    end
    return (ns.Minimap and ns.Minimap.ICON) or itemIcon(ns.Data.ticketItemID)
end

local E, C, R, SORT = ns.Engine.ELIGIBILITY, ns.Engine.CRAFTABILITY, ns.Engine.ROUTE, ns.Engine.SORT

-- The window's one-line version of the reminder.
local function reminderShort(source)
    return string.format("Free Ticket Voucher: hand in \"%s\" to %s for %d Prize Tickets.",
        source.name, source.npc, source.tickets)
end

-- The full reminder, printed to chat.
function UI.ReminderText(source)
    return string.format("You have a Free Ticket Voucher. Accept and hand in \"%s\" to %s at the Darkmoon Faire "
        .. "for %d free Prize Tickets.", source.name, source.npc, source.tickets)
end

local function eligibilityBadge(eligibility)
    local state = eligibility.state
    if state == E.ELIGIBLE then
        return color("good", "Can turn in")
    elseif state == E.LEVEL_TOO_LOW then
        return color("bad", "Needs level " .. eligibility.requiredLevel)
    elseif state == E.PROFESSION_REQUIRED then
        return color("bad", "Needs " .. ns.Character.ProfessionName(eligibility.profession) .. " "
            .. (eligibility.requiredSkill or "") .. " to turn in")
    elseif state == E.REPUTATION_TOO_HIGH then
        return color("bad", "Reputation too high")
    elseif state == E.ALREADY_DONE then
        return color("dim", "Already done")
    end
    return ""
end

local function eligibilityExplanation(row)
    local state = row.eligibility.state
    local tier = ns.Data.tiers[row.source.tier]
    if state == E.LEVEL_TOO_LOW then
        return "Tier " .. row.source.tier .. " quests need level " .. row.eligibility.requiredLevel .. "."
    elseif state == E.PROFESSION_REQUIRED then
        return "Only characters with " .. ns.Character.ProfessionName(row.eligibility.profession)
            .. (row.eligibility.requiredSkill and (" " .. row.eligibility.requiredSkill) or "")
            .. " can hand this quest in."
    elseif state == E.REPUTATION_TOO_HIGH and tier and tier.repCap then
        return "Your Darkmoon Faire reputation is past this tier's limit (" .. tier.repCap
            .. "). Only the repeatable quests stay available."
    end
end

local function craftabilityBadge(state, profession, requiredSkill)
    if not state then
        return ""
    end
    -- Prefixed with "Craft:" so they don't read as turn-in requirements.
    local name = ns.Character.ProfessionName(profession)
    if state == C.CRAFTABLE then
        return color("good", "Can craft")
    elseif state == C.NEEDS_SKILL_UP then
        return color("warn", "Craft: needs " .. name .. " " .. (requiredSkill or "?"))
    elseif state == C.RECIPE_UNKNOWN then
        return color("warn", "Craft: recipe unknown")
    elseif state == C.NOT_SCANNED then
        return color("warn", "Craft: open " .. name .. " to check")
    elseif state == C.MISSING_PROFESSION then
        return color("dim", "Craft: no " .. name)
    end
    return ""
end

-- Why this character can't craft an item, as a sentence fragment.
local function craftReason(state, profession, requiredSkill)
    local name = ns.Character.ProfessionName(profession)
    if state == C.NEEDS_SKILL_UP then
        return "you need " .. name .. " " .. (requiredSkill or "?")
    elseif state == C.RECIPE_UNKNOWN then
        return "you haven't learned the recipe"
    elseif state == C.NOT_SCANNED then
        return "open your " .. name .. " window once so the addon can read your recipes"
    elseif state == C.MISSING_PROFESSION then
        return "you don't have " .. name
    end
end

local function craftabilityExplanation(state, profession)
    local name = ns.Character.ProfessionName(profession)
    if state == C.NOT_SCANNED then
        return "Open your " .. name .. " window once so the addon can read which recipes you know."
    elseif state == C.RECIPE_UNKNOWN then
        return "You have " .. name .. " but haven't learned this recipe."
    end
end

local function yieldOf(itemID)
    local recipe = ns.Data.recipes and ns.Data.recipes[itemID]
    return recipe and recipe.yield or 1
end

local function routeText(node)
    if node.route == R.AH then
        return "Auction House"
    elseif node.route == R.VENDOR then
        return "Vendor"
    elseif node.route == R.CRAFT then
        local text = "Craft " .. plural(node.crafts, "time")
        local yield = yieldOf(node.itemID)
        if yield > 1 then
            text = text .. color("dim", " (" .. yield .. " each)")
        end
        return text
    elseif node.children then
        return color("dim", "Craft: reagent unpriced")
    end
    return color("dim", "no data")
end

local ROW_ROUTE = { [R.AH] = "Auction House", [R.VENDOR] = "Vendor", [R.CRAFT] = "Craft" }

-- How the cheapest price for a whole Ticket Source is reached.
local function rowRouteText(row)
    local route
    for _, node in ipairs(row.breakdown) do
        if not node.route then
            return ""
        elseif route and route ~= node.route then
            return "Mixed"
        end
        route = node.route
    end
    return ROW_ROUTE[route] or ""
end

-- The oldest Scan Price the row's cheapest route depends on.
local function oldestAge(nodes)
    local oldest
    for _, node in ipairs(nodes) do
        if node.route == R.AH and node.age and (not oldest or node.age > oldest) then
            oldest = node.age
        elseif node.route == R.CRAFT and node.children then
            local child = oldestAge(node.children)
            if child and (not oldest or child > oldest) then
                oldest = child
            end
        end
    end
    return oldest
end

-- Widgets ----------------------------------------------------------------------------

local function colorTexture(parent, layer, rgba)
    local tex = parent:CreateTexture(nil, layer)
    tex:SetColorTexture(rgba[1], rgba[2], rgba[3], rgba[4])
    return tex
end

-- A 1px border around `target`, drawn on `target`.
local function border(target, rgba)
    local edges = {
        { "TOPLEFT", "TOPRIGHT", nil, 1 },
        { "BOTTOMLEFT", "BOTTOMRIGHT", nil, 1 },
        { "TOPLEFT", "BOTTOMLEFT", 1, nil },
        { "TOPRIGHT", "BOTTOMRIGHT", 1, nil },
    }
    for _, e in ipairs(edges) do
        local tex = colorTexture(target, "BORDER", rgba)
        tex:SetPoint(e[1])
        tex:SetPoint(e[2])
        if e[3] then tex:SetWidth(e[3]) end
        if e[4] then tex:SetHeight(e[4]) end
    end
end

-- A font string; `y` is an offset from the parent's vertical centre.
local function fontString(parent, x, width, template, justify, y)
    local fs = parent:CreateFontString(nil, "OVERLAY", template or "GameFontHighlightSmall")
    fs:SetPoint("LEFT", x, y or 0)
    if width then
        fs:SetWidth(width)
    end
    fs:SetJustifyH(justify or "LEFT")
    fs:SetWordWrap(false)
    return fs
end

local function addWrapped(tt, text)
    if text then
        tt:AddLine(text, 1, 1, 1, true)
    end
end

-- Tooltips ---------------------------------------------------------------------------

-- How an item comes into the game: crafted, mob drop and/or vendor.
local function obtainLines(itemID)
    local lines = {}
    local recipe = ns.Data.recipes and ns.Data.recipes[itemID]
    if recipe then
        lines[#lines + 1] = "Crafted with " .. ns.Character.ProfessionName(recipe.profession) .. " (" .. recipe.skill .. ")"
    end
    local obtain = ns.Data.obtain and ns.Data.obtain[itemID] or {}
    if obtain.drop then
        lines[#lines + 1] = "Mob drop"
    end
    local vendor = obtain.vendor or (ns.Data.vendor[itemID] and ns.Data.vendor[itemID].where)
    if vendor then
        lines[#lines + 1] = "Sold by " .. vendor
    end
    return lines
end

local function rowTooltip(tt, row)
    local src = row.source
    tt:AddLine(src.name)
    tt:AddLine(string.format("%s, Tier %d, %s", src.npc, src.tier, plural(row.tickets, "Prize Ticket")), 1, 1, 1)
    if src.repeatable then
        tt:AddLine("Repeatable", 1, 1, 1)
    end
    if src.doubtful then
        addWrapped(tt, color("warn", src.doubtful))
    end
    tt:AddLine(" ")
    tt:AddLine("Hand in:")
    for _, entry in ipairs(src.items) do
        tt:AddLine(string.format("  %dx %s", entry.quantity, itemName(entry.itemID, entry.name)), 1, 1, 1)
        for _, text in ipairs(obtainLines(entry.itemID)) do
            tt:AddLine("    " .. text, 0.6, 0.8, 1, true)
        end
    end
    tt:AddLine(" ")
    local function costLine(label, perTicket, perTurnIn, dimmed)
        local shade = dimmed and 0.7 or 1
        if perTicket then
            tt:AddLine(label .. ": " .. money(perTicket) .. " per ticket (" .. money(perTurnIn) .. " per turn-in)",
                shade, shade, shade)
        else
            tt:AddLine(label .. ": no data", 0.6, 0.6, 0.6)
        end
    end
    costLine("Buy", row.buyCostPerTicket, row.buyCost)
    if row.craftCostPerTicket then
        costLine("Craft", row.craftCostPerTicket, row.craftCost)
        if row.craftCost and row.buyCost then
            addWrapped(tt, color("dim", row.craftCost < row.buyCost and "Crafting is cheaper than buying."
                or "Buying is cheaper than crafting."))
        end
    elseif row.craftability then
        -- The character can't craft it yet: show the price anyway and say why,
        -- once, instead of repeating the craft badge below.
        costLine("Craft (not ranked)", row.fullCraftCostPerTicket, row.fullCraftCost, true)
        local reason = craftReason(row.craftability, row.profession, row.breakdown[1].requiredSkill)
        local text = "You can't craft this yet: " .. (reason or "unknown") .. "."
        if row.fullCraftCost and row.buyCost and row.fullCraftCost < row.buyCost then
            text = text .. " Crafting would be cheaper than buying."
        end
        addWrapped(tt, color("dim", text))
    end
    tt:AddLine(" ")
    tt:AddLine(eligibilityBadge(row.eligibility))
    addWrapped(tt, eligibilityExplanation(row))
    local tier = ns.Data.tiers[src.tier]
    if row.unlimited then
        addWrapped(tt, color("dim", "No limit: this quest repeats forever and gives no reputation."))
    elseif row.turnInsLeft and tier then
        if row.turnInsLeft > 0 then
            tt:AddLine(plural(row.turnInsLeft, "turn-in") .. " left (" .. plural(row.ticketsLeft or 0, "ticket") .. ")",
                1, 1, 1)
        end
        addWrapped(tt, color("dim", string.format("Reputation %d of %d (+%d per turn-in). Reputation is shared: "
            .. "turn-ins at any tier count toward this limit.", lastCharacter.reputation or 0, tier.repCap,
            row.repPerTurnIn or 0)))
    elseif tier and tier.repCap then
        addWrapped(tt, color("dim", "Disappears at " .. tier.repCap .. " Darkmoon Faire reputation."))
    end
    if row.craftability == C.CRAFTABLE then
        tt:AddLine(craftabilityBadge(row.craftability, row.profession, row.breakdown[1].requiredSkill))
    end
    if row.stale then
        addWrapped(tt, color("stale", "Some prices are older than " .. plural(ns.Settings.Get("staleDays"), "day")
            .. ". Rescan the Auction House."))
    end
    tt:AddLine(" ")
    tt:AddLine(color("dim", expanded[src.questID] and "Click to hide the Breakdown." or "Click to show the Breakdown."))
end

local function nodeTooltip(tt, node)
    tt:SetItemByID(node.itemID)
    local vendor = ns.Data.vendor[node.itemID]
    if vendor then
        tt:AddLine(" ")
        addWrapped(tt, "Sold by " .. vendor.where)
        local example = vendor.example and (vendor.example[lastCharacter.faction] or vendor.example.Alliance)
        if example then
            addWrapped(tt, "For example " .. example .. ".")
        end
    end
    if node.craftability then
        tt:AddLine(" ")
        tt:AddLine(craftabilityBadge(node.craftability, node.profession, node.requiredSkill))
        addWrapped(tt, craftabilityExplanation(node.craftability, node.profession))
    end
end

local function rewardTooltip(tt, entry)
    local reward = entry.reward
    tt:SetItemByID(reward.itemID)
    tt:AddLine(" ")
    addWrapped(tt, "Gelvas Grimegate sells this for " .. plural(reward.tickets, "Prize Ticket") .. ". You have "
        .. entry.owned .. ".")
    if not entry.usable then
        addWrapped(tt, color("warn", "You can buy it now, but can only use it from level " .. reward.useLevel .. "."))
    end
    local plan = entry.plan
    if not plan then
        return
    end
    tt:AddLine(" ")
    tt:AddLine("Cheapest way to the " .. plural(entry.missing, "missing ticket") .. ":")
    for _, step in ipairs(plan.turnIns) do
        tt:AddDoubleLine(string.format("  %dx %s (%s)", step.count, step.row.source.name,
            plural(step.count * step.row.tickets, "ticket")), money(step.count * step.row.turnInCost),
            1, 1, 1, 1, 1, 1)
    end
    if #plan.turnIns > 0 then
        tt:AddDoubleLine("Total", "about " .. money(plan.cost), 1, 0.82, 0, 1, 0.82, 0)
    end
    if not plan.complete then
        addWrapped(tt, color("warn", "Only " .. plural(plan.tickets, "ticket") .. " can be earned this way right "
            .. "now. The other quests are past their reputation limit, need a higher level, or have no prices."))
    end
    addWrapped(tt, color("dim", "Estimated from current prices, taking each tier's reputation limit into account."))
end

local function onLineEnter(line)
    if line.kind ~= "row" and line.kind ~= "node" and line.kind ~= "reward" then
        return
    end
    local tt = GameTooltip
    tt:SetOwner(line, "ANCHOR_RIGHT")
    if line.kind == "row" then
        rowTooltip(tt, line.data)
    elseif line.kind == "reward" then
        rewardTooltip(tt, line.data)
    else
        nodeTooltip(tt, line.data)
    end
    tt:Show()
end

local function onLineClick(line)
    if line.kind == "row" then
        local key = line.data.source.questID
        expanded[key] = not expanded[key] or nil
        UI.Render()
    end
end

local function onShoppingEnter(self)
    local row = self.row
    if not row then
        return
    end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    if self:IsEnabled() then
        GameTooltip:AddLine("Create Auctionator shopping list")
        addWrapped(GameTooltip, "Saves the Auction House items in this Breakdown as \"" .. ns.Shopping.ListName(row)
            .. "\". An existing list with that name is replaced.")
    elseif row.noData then
        GameTooltip:AddLine("No prices yet")
        addWrapped(GameTooltip, "Some items here have no Auction House price. Scan the Auction House with "
            .. "Auctionator first.")
    else
        GameTooltip:AddLine("Nothing to buy on the Auction House")
        addWrapped(GameTooltip, "Every item here comes from a vendor or is crafted from vendor items.")
    end
    GameTooltip:Show()
end

-- Lines -------------------------------------------------------------------------------

local function acquireLine(index)
    local line = linePool[index]
    if line then
        return line
    end
    line = CreateFrame("Button", nil, content)
    line.bg = line:CreateTexture(nil, "BACKGROUND")
    line.bg:SetAllPoints()
    line.hover = colorTexture(line, "HIGHLIGHT", PALETTE.hover)
    line.hover:SetAllPoints()
    line.toggle = line:CreateTexture(nil, "ARTWORK")
    line.toggle:SetSize(TOGGLE_SIZE, TOGGLE_SIZE)
    line.toggle:SetPoint("LEFT", X_TOGGLE, 0)
    line.accent = colorTexture(line, "ARTWORK", PALETTE.accent)
    line.accent:SetPoint("TOPLEFT")
    line.accent:SetPoint("BOTTOMLEFT")
    line.accent:SetWidth(2)
    line.icon = line:CreateTexture(nil, "ARTWORK")
    line.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    line:SetScript("OnEnter", onLineEnter)
    line:SetScript("OnLeave", GameTooltip_Hide or function() GameTooltip:Hide() end)
    line:SetScript("OnClick", onLineClick)
    line.cols = {}
    line.button = CreateFrame("Button", nil, line, "UIPanelButtonTemplate")
    line.button:SetSize(130, 20)
    line.button:SetText("Shopping list")
    line.button:SetPoint("LEFT", X_NAME, 0)
    line.button:SetMotionScriptsWhileDisabled(true)
    line.button:SetScript("OnEnter", onShoppingEnter)
    line.button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    linePool[index] = line
    return line
end

-- Columns marked `solid` ignore the line's fade, so the reason a row is faded
-- stays readable.
-- Each font string's template colour, restored after it was drawn grey.
local baseColors = setmetatable({}, { __mode = "k" })

local function setCols(line, layout, alpha, grey)
    for _, fs in pairs(line.cols) do
        fs:Hide()
    end
    for i, col in ipairs(layout) do
        local key = layout.kind .. i
        local fs = line.cols[key]
        if not fs then
            fs = fontString(line, col.x, col.width, col.template, col.justify, col.y)
            line.cols[key] = fs
        end
        if not baseColors[fs] then
            baseColors[fs] = { fs:GetTextColor() }
        end
        if grey then
            fs:SetText(stripColors(col.text or ""))
            fs:SetTextColor(GREY[1], GREY[2], GREY[3])
        else
            fs:SetText(col.text or "")
            fs:SetTextColor(unpack(baseColors[fs]))
        end
        fs:SetAlpha(col.solid and 1 or alpha)
        fs:Show()
    end
end

local function rowLayout(row)
    local src = row.source
    local perTicket, perTurnIn, age = color("dim", "no data"), "", ""
    if not row.noData then
        perTicket, perTurnIn = money(row.rankCost), money(row.turnInCost)
        local oldest = oldestAge(row.breakdown)
        age = ageLabel(oldest, row.stale)
    end
    local item = src.items[1]
    -- The status line stays at full alpha so the reason a row is faded stays
    -- readable; its item text is dimmed by colour instead.
    local faded = row.eligibility.state ~= E.ELIGIBLE and row.eligibility.state ~= E.PROFESSION_REQUIRED
    local status = {}
    for _, entry in ipairs(src.items) do
        status[#status + 1] = color(faded and "dim" or "white", entry.quantity .. "x " .. itemName(entry.itemID, entry.name))
    end
    status[#status + 1] = color("dim", "Tier " .. src.tier)
    if src.doubtful then
        status[#status + 1] = color("warn", "Tickets unconfirmed")
    end
    if row.unlimited then
        status[#status + 1] = color("dim", "No limit")
    elseif row.turnInsLeft and row.turnInsLeft > 0 then
        status[#status + 1] = color(faded and "dim" or "white", plural(row.turnInsLeft, "turn-in") .. " left")
    end
    status[#status + 1] = eligibilityBadge(row.eligibility)
    local craft = craftabilityBadge(row.craftability, row.profession, row.breakdown[1].requiredSkill)
    if craft ~= "" then
        status[#status + 1] = craft
    end
    return {
        kind = "row",
        icon = item and itemIcon(item.itemID),
        iconX = X_ROW_ICON,
        { x = X_NAME, width = X_TICKETS - X_NAME - 10, text = src.name, template = "GameFontHighlight", y = 8 },
        { x = X_NAME, width = CONTENT_WIDTH - X_NAME - 10, text = table.concat(status, SEP),
          template = "GameFontNormalSmall", y = -9, solid = true },
        { x = X_TICKETS, width = W_TICKETS, text = tostring(row.tickets), template = "GameFontHighlight",
          justify = "RIGHT", y = 8 },
        { x = X_COST, width = W_COST, template = "GameFontHighlight", justify = "RIGHT", y = 8,
          text = (ns.Settings.Get("sortBy") == SORT.PER_TURN_IN and not row.noData) and perTurnIn or perTicket },
        { x = X_HOW, width = W_HOW, text = rowRouteText(row), y = 8 },
        { x = X_AGE, width = W_AGE, text = age, justify = "RIGHT", y = 8 },
    }
end

local function costSummary(label, perTicket, perTurnIn, cheapest, note)
    if not perTicket then
        return color("dim", label .. ": no data" .. (note and ("   " .. note) or ""))
    end
    local text = color("warn", label .. "  ") .. money(perTicket) .. color("dim", " per ticket") .. SEP
        .. money(perTurnIn) .. color("dim", " per turn-in")
    if cheapest then
        text = text .. "   " .. color("good", "cheapest")
    end
    if note then
        text = text .. "   " .. color("dim", note)
    end
    return text
end

local function craftIsCheapest(row)
    for _, node in ipairs(row.breakdown) do
        if node.route == R.CRAFT then
            return true
        end
    end
    return false
end

local function shopLayout(row)
    local count = #ns.Engine.ShoppingList(row)
    local text
    if count > 0 then
        text = color("dim", "Adds the " .. plural(count, "Auction House item") .. " for the cheapest way to an "
            .. "Auctionator shopping list.")
    else
        text = ""
    end
    return {
        kind = "shop",
        { x = X_NAME + 140, width = X_HOW - X_NAME - 140, text = text },
    }
end

local function summaryLayout(kind, text)
    return {
        kind = kind,
        { x = X_NAME, width = WIDTH - X_NAME - 220, text = text },
    }
end

local function breakdownHeaderLayout()
    local function h(text) return text end
    return {
        kind = "bheader",
        { x = X_NAME, width = 200, text = h("ITEM"), template = "GameFontNormalSmall" },
        { x = X_EACH, width = W_EACH, text = h("EACH"), justify = "RIGHT", template = "GameFontNormalSmall" },
        { x = X_COST, width = W_COST, text = h("TOTAL"), justify = "RIGHT", template = "GameFontNormalSmall" },
        { x = X_HOW, width = W_HOW, text = h("CHEAPEST WAY"), template = "GameFontNormalSmall" },
        { x = X_AGE, width = W_AGE, text = h("AGE"), justify = "RIGHT", template = "GameFontNormalSmall" },
    }
end

local function nodeLayout(node, depth)
    local unit, total, age = "", "", ""
    if node.total then
        total = money(node.total)
        unit = color("dim", money(node.unitCost or node.total / node.quantity))
    end
    if node.route == R.AH then
        age = ageLabel(node.age, node.stale)
    end
    local x = X_NAME + 20 + depth * INDENT
    return {
        kind = "node",
        icon = itemIcon(node.itemID),
        iconX = x - 20,
        { x = x, width = X_EACH - x, text = node.quantity .. "x " .. itemName(node.itemID, node.name) },
        { x = X_EACH, width = W_EACH, text = unit, justify = "RIGHT" },
        { x = X_COST, width = W_COST, text = total, justify = "RIGHT" },
        -- Crafted nodes have no age, so their route text may run into that column.
        { x = X_HOW, width = node.route == R.AH and W_HOW or W_HOW + W_AGE, text = routeText(node) },
        { x = X_AGE, width = W_AGE, text = age, justify = "RIGHT" },
    }
end

-- Flatten rows and expanded Breakdowns into display lines.
local function buildLines(rows)
    local lines = {}
    local grey = false
    local function add(kind, data, layout, alpha, extra)
        local spec = { kind = kind, data = data, layout = layout, alpha = alpha, grey = grey }
        for k, v in pairs(extra or {}) do spec[k] = v end
        lines[#lines + 1] = spec
    end
    local function addNode(node, depth, alpha)
        add("node", node, nodeLayout(node, depth), alpha)
        if node.children then
            for _, child in ipairs(node.children) do
                addNode(child, depth + 1, alpha)
            end
        end
    end
    local onlyEligible = ns.Settings.Get("eligibleOnly") == true
    local shown = 0
    for _, row in ipairs(rows) do
        if not onlyEligible or row.eligibility.state == E.ELIGIBLE then
            shown = shown + 1
            local i = shown
            -- A quest that needs a profession this character lacks is greyed as a
            -- whole entry; other ineligible rows fade but keep their coloured status.
            grey = row.eligibility.state == E.PROFESSION_REQUIRED
            local alpha = (row.eligibility.state == E.ELIGIBLE or grey) and 1 or INELIGIBLE_ALPHA
            local open = expanded[row.source.questID] == true
            add("row", row, rowLayout(row), alpha, { stripe = i % 2 == 0, expanded = open })
            if open then
                local crafted = craftIsCheapest(row)
                local hasCraft = row.craftCostPerTicket ~= nil
                add("summary", row, summaryLayout("summary",
                    costSummary("Buy", row.buyCostPerTicket, row.buyCost, hasCraft and not crafted and not row.noData)), alpha)
                if hasCraft then
                    add("craftSummary", row, summaryLayout("craftSummary",
                        costSummary("Craft", row.craftCostPerTicket, row.craftCost, crafted)), alpha)
                elseif row.craftability then
                    add("craftSummary", row, summaryLayout("craftSummary",
                        costSummary("Craft", row.fullCraftCostPerTicket, row.fullCraftCost, false,
                            "not ranked: " .. (craftReason(row.craftability, row.profession,
                                row.breakdown[1].requiredSkill) or "can't craft"))), alpha)
                end
                add("bheader", row, breakdownHeaderLayout(), alpha)
                for _, node in ipairs(row.breakdown) do
                    addNode(node, 0, alpha)
                end
                add("shop", row, shopLayout(row), alpha)
                add("spacer", row, { kind = "spacer" }, alpha)
            end
        end
    end
    return lines, shown
end

local function rewardLayout(entry)
    local reward = entry.reward
    local status = {}
    if not entry.usable then
        status[#status + 1] = color("warn", "Usable from level " .. reward.useLevel)
    end
    if entry.affordable then
        status[#status + 1] = color("good", "You have enough tickets")
    else
        status[#status + 1] = color("warn", plural(entry.missing, "more ticket") .. " needed")
    end
    local gold = ""
    if entry.plan and entry.plan.complete then
        gold = "about " .. money(entry.plan.cost)
    elseif entry.plan then
        gold = color("dim", "not reachable yet")
    end
    return {
        kind = "reward",
        icon = itemIcon(reward.itemID),
        iconX = X_ROW_ICON,
        { x = X_NAME, width = X_TICKETS - X_NAME - 10, text = reward.name, template = "GameFontHighlight", y = 8 },
        { x = X_NAME, width = CONTENT_WIDTH - X_NAME - 10, text = table.concat(status, SEP),
          template = "GameFontNormalSmall", y = -9, solid = true },
        { x = X_TICKETS, width = W_TICKETS, text = tostring(reward.tickets), template = "GameFontHighlight",
          justify = "RIGHT", y = 8 },
        { x = X_COST, width = W_COST, text = entry.affordable and color("dim", "-") or tostring(entry.missing),
          template = "GameFontHighlight", justify = "RIGHT", y = 8 },
        { x = X_HOW, width = W_HOW, text = gold, template = "GameFontHighlight", justify = "RIGHT", y = 8 },
    }
end

local function buildRewardLines(rewards)
    local lines = {}
    for i, entry in ipairs(rewards) do
        lines[i] = { kind = "reward", data = entry, layout = rewardLayout(entry), stripe = i % 2 == 0,
            alpha = 1 }
    end
    return lines
end

-- Header area ----------------------------------------------------------------------

local function currentSort()
    return ns.Settings.Get("sortBy") or SORT.PER_TICKET
end

local function updateSortControls()
    local active = currentSort()
    for sortBy, tab in pairs(frame.sortTabs) do
        local on = sortBy == active
        local c = on and PALETTE.tabActive or PALETTE.tab
        tab.bg:SetColorTexture(c[1], c[2], c[3], c[4])
        tab.text:SetText(on and color("white", tab.label) or color("dim", tab.label))
    end
    frame.costHeader:SetText(active == SORT.PER_TURN_IN and "COST PER TURN-IN" or "COST PER TICKET")
end

-- Notices sit in coloured strips between the sort buttons and the list.
local function layoutNotices(notices)
    local y = frame.noticeTop
    for i, strip in ipairs(frame.notices) do
        local notice = notices[i]
        strip:SetShown(notice ~= nil)
        if notice then
            local c = PALETTE[notice.style]
            strip.bg:SetColorTexture(c[1], c[2], c[3], c[4])
            strip.text:SetText(notice.text)
            strip:SetPoint("TOPLEFT", frame.panel, "TOPLEFT", 10, y)
            strip:SetPoint("RIGHT", frame.panel, "RIGHT", -10, 0)
            y = y - 24
        end
    end
    frame.headers:SetPoint("TOPLEFT", frame.panel, "TOPLEFT", 0, y - 4)
    frame.rewardHeaders:SetPoint("TOPLEFT", frame.panel, "TOPLEFT", 0, y - 4)
    scroll:SetPoint("TOPLEFT", frame.panel, "TOPLEFT", 0, y - 24)
    -- Size the list to whole collapsed rows so none is cut off mid-card.
    local available = PANEL_HEIGHT + (y - 24) - 6
    local pitch = HEIGHT_OF.row + ROW_GAP
    local rows = math.max(1, math.floor((available + ROW_GAP) / pitch))
    scroll:SetSize(WIDTH - 24 - 26, rows * pitch - ROW_GAP)
end

local function currentView()
    return ns.Settings.Get("view") == VIEW.REWARDS and VIEW.REWARDS or VIEW.SOURCES
end

local function updateView()
    local rewards = currentView() == VIEW.REWARDS
    for _, tab in pairs(frame.sortTabs) do
        tab:SetShown(not rewards)
    end
    if frame.eligibleOnly then
        frame.eligibleOnly:SetShown(not rewards)
        frame.eligibleLabel:SetShown(not rewards)
    end
    frame.headers:SetShown(not rewards)
    frame.rewardHeaders:SetShown(rewards)
    frame.section:SetText(rewards and "Prize Rewards" or "Prize Ticket Sources")
    for view, tab in pairs(frame.viewTabs) do
        local on = view == currentView()
        local c = on and PALETTE.tabActive or PALETTE.tab
        tab.bg:SetColorTexture(c[1], c[2], c[3], c[4])
        tab.text:SetText(on and color("white", tab.label) or color("dim", tab.label))
    end
    if rewards then
        frame.footer:SetText("Hover a prize for the cheapest way to the missing tickets" .. SEP
            .. "Gold amounts are estimates from current prices")
    else
        frame.footer:SetText("Click a row for its Breakdown" .. SEP .. "Hover for details" .. SEP
            .. color("stale", "!") .. " = price older than " .. plural(ns.Settings.Get("staleDays"), "day")
            .. SEP .. "Faded = can't turn in")
    end
end

local function updateHeader()
    updateSortControls()
    updateView()
    frame.tickets:SetText(color("dim", "Prize Tickets  ") .. ns.Character.TicketCount())

    local notices = {}
    if not ns.Prices.IsAvailable() then
        notices[#notices + 1] = { style = "noticeBad", text = "Auctionator is not loaded. Enable it to see prices." }
    elseif not lastInfo.hasAnyPrice then
        notices[#notices + 1] = { style = "noticeWarn",
            text = "No prices yet. Scan the Auction House with Auctionator to see prices." }
    end
    if lastInfo.reminder then
        notices[#notices + 1] = { style = "noticeGood", text = reminderShort(lastInfo.reminder) }
    end
    layoutNotices(notices)
end

local function savePosition()
    local point, _, relativePoint, x, y = frame:GetPoint(1)
    ns.Settings.DB().window = { point = point, relativePoint = relativePoint, x = x, y = y }
end

local function restorePosition()
    local pos = ns.Settings.DB().window
    frame:ClearAllPoints()
    if type(pos) == "table" and pos.point then
        frame:SetPoint(pos.point, UIParent, pos.relativePoint or pos.point, pos.x or 0, pos.y or 0)
    else
        frame:SetPoint("CENTER")
    end
end

-- The portrait frame is the modern look; fall back to the plain template if
-- this client doesn't have it.
local function createWindow()
    local ok, f = pcall(CreateFrame, "Frame", FRAME_NAME, UIParent, "PortraitFrameTemplate")
    if ok and f then
        return f, true
    end
    return CreateFrame("Frame", FRAME_NAME, UIParent, "BasicFrameTemplateWithInset"), false
end

local function setTitleAndPortrait(hasPortrait)
    local title = "DMF Ticket Broker"
    if type(frame.SetTitle) == "function" then
        frame:SetTitle(title)
    elseif type(frame.TitleText) == "table" then
        frame.TitleText:SetText(title)
    else
        local fs = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        fs:SetPoint("TOP", 0, -5)
        fs:SetText(title)
    end
    if hasPortrait then
        local icon = ticketIcon()
        if type(frame.SetPortraitToAsset) == "function" then
            pcall(frame.SetPortraitToAsset, frame, icon)
        elseif type(frame.portrait) == "table" then
            frame.portrait:SetTexture(icon)
        end
    end
end

-- Tabs drawn like the panel: 1px gold border, filled when active.
local function createSortTab(parent, label, sortBy, anchor)
    local tab = CreateFrame("Button", nil, parent)
    tab:SetSize(140, 24)
    tab.bg = tab:CreateTexture(nil, "BACKGROUND")
    tab.bg:SetAllPoints()
    border(tab, PALETTE.panelBorder)
    local hover = colorTexture(tab, "HIGHLIGHT", PALETTE.hover)
    hover:SetAllPoints()
    tab.label = label
    tab.text = tab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    tab.text:SetPoint("CENTER")
    tab.text:SetText(label)
    tab:SetPoint("LEFT", anchor, "RIGHT", anchor == frame.section and 20 or 6, 0)
    tab:SetScript("OnClick", function() UI.SetSort(sortBy) end)
    frame.sortTabs[sortBy] = tab
    return tab
end

local function createColumnHeaders(panel)
    frame.headers = CreateFrame("Frame", nil, panel)
    frame.headers:SetSize(CONTENT_WIDTH, 16)
    local function header(text, x, width, justify)
        local fs = fontString(frame.headers, x, width, "GameFontNormalSmall", justify)
        fs:SetText(text)
        return fs
    end
    frame.sourceHeader = header("TICKET SOURCE", X_NAME, 300)
    header("TICKETS", X_TICKETS, W_TICKETS, "RIGHT")
    frame.costHeader = fontString(frame.headers, X_COST, W_COST, "GameFontNormalSmall", "RIGHT")
    header("CHEAPEST WAY", X_HOW, W_HOW)
    header("AGE", X_AGE, W_AGE, "RIGHT")

    frame.rewardHeaders = CreateFrame("Frame", nil, panel)
    frame.rewardHeaders:SetSize(CONTENT_WIDTH, 16)
    local function rewardHeader(text, x, width, justify)
        local fs = fontString(frame.rewardHeaders, x, width, "GameFontNormalSmall", justify)
        fs:SetText(text)
        return fs
    end
    frame.prizeHeader = rewardHeader("PRIZE", X_NAME, 300)
    rewardHeader("TICKETS", X_TICKETS, W_TICKETS, "RIGHT")
    rewardHeader("STILL NEEDED", X_COST, W_COST, "RIGHT")
    rewardHeader("GOLD FOR THE REST", X_HOW, W_HOW, "RIGHT")
    frame.rewardHeaders:Hide()
end

-- Tabs hanging under the window switch between the views.
local function createViewTab(label, view, anchor)
    local tab = CreateFrame("Button", nil, frame)
    tab:SetSize(140, 26)
    tab.bg = tab:CreateTexture(nil, "BACKGROUND")
    tab.bg:SetAllPoints()
    border(tab, PALETTE.panelBorder)
    local hover = colorTexture(tab, "HIGHLIGHT", PALETTE.hover)
    hover:SetAllPoints()
    tab.label = label
    tab.text = tab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    tab.text:SetPoint("CENTER")
    tab.text:SetText(label)
    if anchor then
        tab:SetPoint("LEFT", anchor, "RIGHT", 6, 0)
    else
        tab:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 20, 2)
    end
    tab:SetScript("OnClick", function() UI.SetView(view) end)
    frame.viewTabs[view] = tab
    return tab
end

local function build()
    local hasPortrait
    frame, hasPortrait = createWindow()
    frame:SetSize(WIDTH, HEIGHT)
    frame:SetFrameStrata("HIGH")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        savePosition()
    end)
    restorePosition()
    frame:Hide()
    table.insert(UISpecialFrames, FRAME_NAME)
    setTitleAndPortrait(hasPortrait)

    -- The dark inset panel everything else lives in.
    local panel = CreateFrame("Frame", nil, frame)
    panel:SetPoint("TOPLEFT", 12, -PANEL_TOP)
    panel:SetPoint("BOTTOMRIGHT", -12, PANEL_BOTTOM)
    local panelBg = colorTexture(panel, "BACKGROUND", PALETTE.panel)
    panelBg:SetAllPoints()
    border(panel, PALETTE.panelBorder)
    frame.panel = panel

    local sectionIcon = panel:CreateTexture(nil, "ARTWORK")
    sectionIcon:SetSize(18, 18)
    -- Leave room for the round portrait, which overlaps the panel's corner.
    sectionIcon:SetPoint("TOPLEFT", hasPortrait and 54 or 12, -11)
    sectionIcon:SetTexture(ticketIcon())
    sectionIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    local section = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    section:SetPoint("LEFT", sectionIcon, "RIGHT", 6, 0)
    section:SetText("Prize Ticket Sources")
    frame.section = section

    local gear = CreateFrame("Button", nil, panel)
    gear:SetSize(20, 20)
    gear:SetPoint("TOPRIGHT", -10, -9)
    gear:SetNormalTexture("Interface\\Buttons\\UI-OptionsButton")
    gear:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    gear:SetScript("OnClick", function() ns.Settings.Open() end)
    gear:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("Settings")
        GameTooltip:AddLine("Stale price threshold and the minimap button.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    gear:SetScript("OnLeave", function() GameTooltip:Hide() end)
    frame.tickets = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.tickets:SetPoint("RIGHT", gear, "LEFT", -10, 0)

    frame.sortTabs = {}
    local first = createSortTab(panel, "Cost per ticket", SORT.PER_TICKET, section)
    local second = createSortTab(panel, "Cost per turn-in", SORT.PER_TURN_IN, first)

    -- Off by default: the full list stays the normal view.
    local okBox, box = pcall(CreateFrame, "CheckButton", nil, panel, "UICheckButtonTemplate")
    if okBox and box then
        box:SetSize(22, 22)
        box:SetPoint("LEFT", second, "RIGHT", 14, 0)
        local label = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        label:SetPoint("LEFT", box, "RIGHT", 2, 0)
        label:SetText("Can turn in only")
        frame.eligibleLabel = label
        box:SetChecked(ns.Settings.Get("eligibleOnly") == true)
        box:SetScript("OnClick", function(self)
            ns.Settings.DB().eligibleOnly = self:GetChecked() and true or false
            UI.Render()
        end)
        frame.eligibleOnly = box
    end

    frame.noticeTop = -40
    frame.notices = {}
    for i = 1, 2 do
        local strip = CreateFrame("Frame", nil, panel)
        strip:SetHeight(22)
        strip.bg = strip:CreateTexture(nil, "BACKGROUND")
        strip.bg:SetAllPoints()
        strip.text = fontString(strip, 10, CONTENT_WIDTH, "GameFontHighlightSmall")
        strip:Hide()
        frame.notices[i] = strip
    end

    createColumnHeaders(panel)

    local okScroll, s = pcall(CreateFrame, "ScrollFrame", nil, panel, "ScrollFrameTemplate")
    scroll = okScroll and s or CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    content = CreateFrame("Frame", nil, scroll)
    content:SetSize(CONTENT_WIDTH, 1)
    scroll:SetScrollChild(content)

    -- Light grey: readable on the dark frame, still quieter than the list.
    frame.footer = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.footer:SetTextColor(0.8, 0.8, 0.8)
    frame.footer:SetPoint("BOTTOMLEFT", 16, 10)
    frame.footer:SetPoint("BOTTOMRIGHT", -16, 10)
    frame.footer:SetJustifyH("LEFT")
    frame.footer:SetWordWrap(false)

    frame.viewTabs = {}
    local sourcesTab = createViewTab("Ticket Sources", VIEW.SOURCES)
    createViewTab("Prize Rewards", VIEW.REWARDS, sourcesTab)

    frame:SetScript("OnShow", function() UI.Refresh() end)
end

-- Rendering ------------------------------------------------------------------------

local function backgroundFor(spec)
    if spec.kind == "row" or spec.kind == "reward" then
        return spec.stripe and PALETTE.rowB or PALETTE.rowA
    end
    return PALETTE.inset
end

function UI.Render()
    if not frame then
        return
    end
    updateHeader()
    local lines
    if currentView() == VIEW.REWARDS then
        local rewards = lastInfo.rewards or {}
        lines = buildRewardLines(rewards)
        frame.prizeHeader:SetText("PRIZE (" .. #rewards .. ")")
    else
        local shown
        lines, shown = buildLines(lastRows)
        frame.sourceHeader:SetText(shown == #lastRows and ("TICKET SOURCE (" .. shown .. ")")
            or ("TICKET SOURCE (" .. shown .. " of " .. #lastRows .. ")"))
    end
    local y = 0
    for index, spec in ipairs(lines) do
        local line = acquireLine(index)
        local height = HEIGHT_OF[spec.kind]
        if (spec.kind == "row" or spec.kind == "reward") and index > 1 then
            y = y + ROW_GAP
        end
        line.kind, line.data, line.expanded = spec.kind, spec.data, spec.expanded
        line:ClearAllPoints()
        line:SetHeight(height)
        line:SetPoint("TOPLEFT", 0, -y)
        line:SetPoint("RIGHT", content, "RIGHT")
        y = y + height

        local bg = backgroundFor(spec)
        line.bg:SetColorTexture(bg[1], bg[2], bg[3], bg[4])
        line.bg:SetShown(spec.kind ~= "spacer")
        line.accent:SetShown(spec.kind ~= "row" and spec.kind ~= "spacer" or spec.expanded == true)
        line.hover:SetShown(spec.kind == "row" or spec.kind == "node" or spec.kind == "reward")
        if spec.kind == "reward" then
            line.accent:Hide()
        end
        line.toggle:SetShown(spec.kind == "row")
        if spec.kind == "row" then
            line.toggle:SetTexture(spec.expanded and "Interface\\Buttons\\UI-MinusButton-Up"
                or "Interface\\Buttons\\UI-PlusButton-Up")
            line.toggle:SetAlpha(spec.alpha or 1)
        end

        local layout = spec.layout
        line.icon:SetShown(layout.icon ~= nil)
        if layout.icon then
            local size = (spec.kind == "row" or spec.kind == "reward") and 32 or 16
            line.icon:SetSize(size, size)
            line.icon:ClearAllPoints()
            line.icon:SetPoint("LEFT", layout.iconX or 8, 0)
            line.icon:SetTexture(layout.icon)
            line.icon:SetAlpha(spec.alpha or 1)
            line.icon:SetDesaturated(spec.grey == true)
        end
        setCols(line, layout, spec.alpha or 1, spec.grey)

        if spec.kind == "shop" then
            local row = spec.data
            line.button:Show()
            line.button.row = row
            line.button:SetEnabled(ns.Shopping.HasItems(row))
            line.button:SetScript("OnClick", function() ns.Shopping.Create(row) end)
        else
            line.button:Hide()
        end
        line:Show()
    end
    for index = #lines + 1, #linePool do
        linePool[index]:Hide()
    end
    content:SetHeight(math.max(1, y))
end

-- Recomputes the ranking and redraws. Expanded Breakdowns stay expanded.
function UI.Refresh()
    if not frame or not frame:IsShown() then
        return
    end
    lastCharacter = ns.Character.Snapshot()
    lastRows, lastInfo = ns.Engine.Rank(ns.Data, ns.Prices.Snapshot(ns.Data), lastCharacter,
        { sortBy = currentSort() })
    UI.Render()
end

-- Switches between the Ticket Sources and Prize Rewards views and remembers it.
function UI.SetView(view)
    local db = ns.Settings.DB()
    if db then
        db.view = view
    end
    if scroll and scroll.SetVerticalScroll then
        scroll:SetVerticalScroll(0)
    end
    UI.Render()
end

-- Picks the sort order (Engine.SORT.*), remembers it and re-ranks.
function UI.SetSort(sortBy)
    local db = ns.Settings.DB()
    if db then
        db.sortBy = sortBy
    end
    UI.Refresh()
end

local refreshQueued = false
function UI.RequestRefresh()
    if refreshQueued or not frame or not frame:IsShown() then
        return
    end
    refreshQueued = true
    C_Timer.After(0.25, function()
        refreshQueued = false
        UI.Refresh()
    end)
end

function UI.IsShown()
    return frame ~= nil and frame:IsShown()
end

function UI.Toggle()
    if not frame then
        build()
    end
    frame:SetShown(not frame:IsShown())
end

ns.UI = UI
