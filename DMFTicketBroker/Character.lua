-- Character adapter: builds the Engine's `character` snapshot from the game,
-- and caches known recipes per character while a profession window is open.

local _, ns = ...

local Character = {}

-- Localized profession names seen in the skill list, by Data profession key.
local localizedNames = {}

local function isSecret(value)
    return issecretvalue and issecretvalue(value)
end

local function safeNumber(value)
    if type(value) == "number" and not isSecret(value) then
        return value
    end
    return nil
end

local function professionBySkillLine(skillLine)
    for key, profession in pairs(ns.Data.professions) do
        if profession.skillLine == skillLine then
            return key
        end
    end
    return nil
end

-- Skills ---------------------------------------------------------------------

local function readSkills()
    local skills = {}

    -- 1. Enumerate the skill list.
    if C_SkillInfo and C_SkillInfo.GetNumSkillLines and C_SkillInfo.GetSkillLineInfo then
        local ok, count = pcall(C_SkillInfo.GetNumSkillLines)
        if ok and type(count) == "number" then
            for i = 1, count do
                local okInfo, info = pcall(C_SkillInfo.GetSkillLineInfo, i)
                if okInfo and type(info) == "table" and not info.isHeader then
                    local key = professionBySkillLine(info.skillID)
                    local rank = safeNumber(info.rank)
                    if key and rank then
                        skills[key] = rank
                        localizedNames[key] = info.name
                    end
                end
            end
        end
    end

    -- 2. Fall back to the profession slots.
    if next(skills) == nil and GetProfessions and GetProfessionInfo then
        local slots = { GetProfessions() }
        for _, index in pairs(slots) do
            if index then
                local name, _, rank, _, _, _, skillLine = GetProfessionInfo(index)
                local key = professionBySkillLine(skillLine)
                rank = safeNumber(rank)
                if key and rank then
                    skills[key] = rank
                    localizedNames[key] = name
                end
            end
        end
    end

    -- 3. Ask for each profession directly.
    if next(skills) == nil and C_SkillInfo and C_SkillInfo.GetSkillLineInfoByID then
        for key, profession in pairs(ns.Data.professions) do
            local ok, info = pcall(C_SkillInfo.GetSkillLineInfoByID, profession.skillLine)
            local rank = ok and type(info) == "table" and safeNumber(info.rank)
            if rank and rank > 0 then
                skills[key] = rank
                localizedNames[key] = info.name
            end
        end
    end

    return skills
end

function Character.ProfessionName(key)
    return localizedNames[key] or key
end

-- Reputation, quests, bags -------------------------------------------------------

local function readReputation()
    local factionID = ns.Data.factionID
    if C_Reputation and C_Reputation.GetFactionDataByID then
        local ok, info = pcall(C_Reputation.GetFactionDataByID, factionID)
        if ok and type(info) == "table" then
            return safeNumber(info.currentStanding) or 0
        end
    end
    if GetFactionInfoByID then
        local barValue = select(6, GetFactionInfoByID(factionID))
        return safeNumber(barValue) or 0
    end
    -- Never met the faction: no reputation yet.
    return 0
end

local function isQuestCompleted(questID)
    if C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted then
        return C_QuestLog.IsQuestFlaggedCompleted(questID) == true
    end
    return false
end

local function itemCount(itemID)
    if C_Item and C_Item.GetItemCount then
        return safeNumber(C_Item.GetItemCount(itemID)) or 0
    end
    return 0
end

function Character.TicketCount()
    local data = ns.Data
    if C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo then
        local ok, info = pcall(C_CurrencyInfo.GetCurrencyInfo, data.ticketCurrencyID)
        if ok and type(info) == "table" and info.name and info.name ~= "" then
            return safeNumber(info.quantity) or 0
        end
    end
    return itemCount(data.ticketItemID)
end

-- Known recipe cache --------------------------------------------------------------

local function charDB()
    DMFTicketBrokerCharDB = DMFTicketBrokerCharDB or {}
    DMFTicketBrokerCharDB.knownRecipes = DMFTicketBrokerCharDB.knownRecipes or {}
    return DMFTicketBrokerCharDB
end

-- Which Data profession the open profession window shows, or nil.
local function openProfession()
    local T = C_TradeSkillUI
    if not T then
        return nil
    end
    for _, viewingOther in ipairs({ "IsTradeSkillLinked", "IsTradeSkillGuild", "IsNPCCrafting" }) do
        if T[viewingOther] then
            local ok, result = pcall(T[viewingOther])
            if ok and result then
                return nil
            end
        end
    end
    local candidates = {}
    for _, getter in ipairs({ "GetBaseProfessionInfo", "GetChildProfessionInfo" }) do
        if T[getter] then
            local ok, info = pcall(T[getter])
            if ok and type(info) == "table" then
                candidates[#candidates + 1] = info
            end
        end
    end
    for _, info in ipairs(candidates) do
        local key = professionBySkillLine(info.professionID) or professionBySkillLine(info.parentProfessionID)
        if key then
            return key
        end
    end
    -- Fall back to matching the window's profession name.
    local names = {}
    for _, info in ipairs(candidates) do
        names[#names + 1] = info.professionName
        names[#names + 1] = info.parentProfessionName
    end
    if GetTradeSkillLine then
        names[#names + 1] = (GetTradeSkillLine())
    end
    for _, name in ipairs(names) do
        if name then
            for key in pairs(ns.Data.professions) do
                if name == key or name == localizedNames[key] then
                    return key
                end
            end
        end
    end
    return nil
end

local function recipeOutputItemID(recipeID)
    local T = C_TradeSkillUI
    if T.GetRecipeSchematic then
        local ok, schematic = pcall(T.GetRecipeSchematic, recipeID, false)
        if ok and type(schematic) == "table" and schematic.outputItemID then
            return schematic.outputItemID
        end
    end
    if T.GetRecipeItemLink then
        local ok, link = pcall(T.GetRecipeItemLink, recipeID)
        if ok and type(link) == "string" then
            local id = link:match("item:(%d+)")
            return id and tonumber(id)
        end
    end
    return nil
end

local function isLearned(recipeID)
    local ok, info = pcall(C_TradeSkillUI.GetRecipeInfo, recipeID)
    return ok and type(info) == "table" and info.learned
end

-- Scans the open profession window. Returns true when the cache changed.
function Character.ScanOpenProfession()
    local key = openProfession()
    if not key then
        return false
    end
    local T = C_TradeSkillUI
    local getIDs = T.GetAllRecipeIDs or T.GetFilteredRecipeIDs
    if not getIDs then
        return false
    end
    local ok, recipeIDs = pcall(getIDs)
    if not ok or type(recipeIDs) ~= "table" or #recipeIDs == 0 then
        -- The list hasn't loaded yet; TRADE_SKILL_LIST_UPDATE will call again.
        return false
    end
    local known = {}
    for _, recipeID in ipairs(recipeIDs) do
        if isLearned(recipeID) then
            local itemID = recipeOutputItemID(recipeID)
            local recipe = itemID and ns.Data.recipes[itemID]
            if recipe and recipe.profession == key then
                known[itemID] = true
            end
        end
    end
    charDB().knownRecipes[key] = known
    return true
end

-- Adds a single newly learned recipe to the cache.
function Character.LearnRecipe(recipeID)
    if not (C_TradeSkillUI and recipeID) then
        return false
    end
    local itemID = recipeOutputItemID(recipeID)
    local recipe = itemID and ns.Data.recipes[itemID]
    if not recipe then
        return false
    end
    local cache = charDB().knownRecipes
    cache[recipe.profession] = cache[recipe.profession] or {}
    cache[recipe.profession][itemID] = true
    return true
end

-- Snapshot ---------------------------------------------------------------------

function Character.Snapshot()
    local data = ns.Data
    local completed = {}
    for _, source in ipairs(data.sources) do
        if source.free and isQuestCompleted(source.questID) then
            completed[source.questID] = true
        end
    end
    return {
        level = safeNumber(UnitLevel("player")),
        faction = (UnitFactionGroup("player")),
        reputation = readReputation(),
        completedQuests = completed,
        hasVoucher = itemCount(data.voucherItemID) > 0,
        skills = readSkills(),
        knownRecipes = charDB().knownRecipes,
        staleDays = ns.Settings.Get("staleDays"),
        tickets = Character.TicketCount(),
    }
end

ns.Character = Character
