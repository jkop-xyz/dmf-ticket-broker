-- Static game data for DMF Ticket Broker.
--
-- Everything here is seeded from vanilla (Classic) data and has NOT been
-- verified on WoW: Forever yet. Fix entries here when the game disagrees;
-- nothing else in the addon hardcodes quest or item facts.
--
-- Pure Lua: no WoW API calls, so the test suite can load this file directly.

local _, ns = ...

local Data = {}

-- Tier: tickets rewarded, minimum character level, the Darkmoon Faire
-- reputation (absolute barValue, Neutral starts at 0) at which the tier's
-- non-repeatable quests disappear, and the reputation each turn-in gives.
-- Reputation is shared, so a turn-in at any tier counts toward every cap.
-- Checked 2026-11-13 against Wowhead's Forever data for every ticket quest
-- (saved pages in .scratch/wowhead): 100 reputation, 1/4/8/12/20 tickets of
-- currency 515, and levels 1/10/20/30/40.
-- Wowhead has no reputation caps; they come from wowforever.be: 500, 1,100,
-- 1,700, 2,500 into Neutral and 5,999 into Friendly (Friendly starts at 3,000).
-- Confirmed in game 2026-11-13: tier 2 stops at exactly 1,100 (Torn Bear Pelts
-- gone at 1,100 after a turn-in from 1,000), and C_Reputation's currentStanding
-- uses this scale (1,200 = 1,200 into Neutral).
-- UNVERIFIED: ClassicDB gives tier 1's cap as "lower than Neutral+600"; players
-- report tier 5 may stop giving reputation around 2,000 into Friendly.
Data.tiers = {
    [1] = { tickets = 1,  minLevel = 1,  repCap = 500,  rep = 100 },
    [2] = { tickets = 4,  minLevel = 10, repCap = 1100, rep = 100 },
    [3] = { tickets = 8,  minLevel = 20, repCap = 1700, rep = 100 },
    [4] = { tickets = 12, minLevel = 30, repCap = 2500, rep = 100 },
    [5] = { tickets = 20, minLevel = 40, repCap = 9000, rep = 100 },
}

local function item(itemID, name, quantity)
    return { itemID = itemID, name = name, quantity = quantity }
end

-- Ticket Sources. Every quest's turn-in items and counts were checked against
-- Wowhead's Forever quest data on 2026-11-13.
-- `repeatable` marks tier 5 "More ..." quests that never
-- disappear and give no reputation (Wowhead lists none for them).
-- `doubtful` explains a reward Wowhead's Forever data puts in question; the UI
-- shows it. UNVERIFIED: for the "More ..." quests Wowhead's Forever data says
-- "no longer Darkmoon Faire Prize Ticket x20" without adding the ticket
-- currency, unlike every tier quest, so they may give no tickets on Forever. `free` marks Free Ticket Sources, which are never ranked.
-- `requiresProfession = { profession = "Engineering", skill = 40 }` marks a
-- quest that only characters with that profession can turn in. No quest has
-- it: in vanilla none of these checks professions (ClassicDB, Warcraft Wiki
-- list only a level and a reputation cap). Add it here if Forever differs.
local MORE_DOUBT = "Wowhead's Forever data says this quest no longer rewards the old ticket item and lists no "
    .. "ticket currency in its place. It may give no tickets on Forever: check before relying on it."

Data.sources = {
    -- Yebb Neblegear (beast drops)
    { questID = 7899, name = "Small Furry Paws",       npc = "Yebb Neblegear", tier = 1, items = { item(5134,  "Small Furry Paw",       5) } },
    { questID = 7900, name = "Torn Bear Pelts",        npc = "Yebb Neblegear", tier = 2, items = { item(11407, "Torn Bear Pelt",        5) } },
    { questID = 7901, name = "Soft Bushy Tails",       npc = "Yebb Neblegear", tier = 3, items = { item(4582,  "Soft Bushy Tail",       5) } },
    { questID = 7902, name = "Vibrant Plumes",         npc = "Yebb Neblegear", tier = 4, items = { item(5117,  "Vibrant Plume",         5) } },
    { questID = 7903, name = "Evil Bat Eyes",          npc = "Yebb Neblegear", tier = 5, items = { item(11404, "Evil Bat Eye",          10) } },
    { questID = 8222, name = "Glowing Scorpid Blood",  npc = "Yebb Neblegear", tier = 5, items = { item(19933, "Glowing Scorpid Blood", 10) } },
    { questID = 7943, doubtful = MORE_DOUBT, name = "More Bat Eyes",          npc = "Yebb Neblegear", tier = 5, repeatable = true, items = { item(11404, "Evil Bat Eye",          10) } },
    { questID = 8223, doubtful = MORE_DOUBT, name = "More Glowing Scorpid Blood", npc = "Yebb Neblegear", tier = 5, repeatable = true, items = { item(19933, "Glowing Scorpid Blood", 10) } },

    -- Rinling (engineering)
    { questID = 7894, name = "Copper Modulator",       npc = "Rinling", tier = 1, items = { item(4363,  "Copper Modulator",       5) } },
    { questID = 7895, name = "Whirring Bronze Gizmo",  npc = "Rinling", tier = 2, items = { item(4375,  "Whirring Bronze Gizmo",  7) } },
    { questID = 7896, name = "Green Fireworks",        npc = "Rinling", tier = 3, items = { item(9313,  "Green Firework",         36) } },
    { questID = 7897, name = "Mechanical Repair Kits", npc = "Rinling", tier = 4, items = { item(11590, "Mechanical Repair Kit",  6) } },
    { questID = 7898, name = "Thorium Widget",         npc = "Rinling", tier = 5, items = { item(15994, "Thorium Widget",         6) } },
    { questID = 7942, doubtful = MORE_DOUBT, name = "More Thorium Widgets",   npc = "Rinling", tier = 5, repeatable = true, items = { item(15994, "Thorium Widget", 6) } },

    -- Kerri Hicks (blacksmithing)
    { questID = 7889, name = "Coarse Weightstone",     npc = "Kerri Hicks", tier = 1, items = { item(3240,  "Coarse Weightstone",   10) } },
    { questID = 7890, name = "Heavy Grinding Stone",   npc = "Kerri Hicks", tier = 2, items = { item(3486,  "Heavy Grinding Stone", 7) } },
    { questID = 7891, name = "Green Iron Bracers",     npc = "Kerri Hicks", tier = 3, items = { item(3835,  "Green Iron Bracers",   3) } },
    { questID = 7892, name = "Big Black Mace",         npc = "Kerri Hicks", tier = 4, items = { item(7945,  "Big Black Mace",       1) } },
    { questID = 7893, name = "Rituals of Strength",    npc = "Kerri Hicks", tier = 5, items = { item(12644, "Dense Grinding Stone", 8) } },
    { questID = 7939, doubtful = MORE_DOUBT, name = "More Dense Grinding Stones", npc = "Kerri Hicks", tier = 5, repeatable = true, items = { item(12644, "Dense Grinding Stone", 8) } },

    -- Chronos (leatherworking)
    { questID = 7881, name = "Carnival Boots",         npc = "Chronos", tier = 1, items = { item(2309,  "Embossed Leather Boots",  3) } },
    { questID = 7882, name = "Carnival Jerkins",       npc = "Chronos", tier = 2, items = { item(2314,  "Toughened Leather Armor", 3) } },
    { questID = 7883, name = "The World's Largest Gnome!", npc = "Chronos", tier = 3, items = { item(5739, "Barbaric Harness", 3) } },
    { questID = 7884, name = "Crocolisk Boy and the Bearded Murloc", npc = "Chronos", tier = 4, items = { item(8185, "Turtle Scale Leggings", 1) } },
    { questID = 7885, name = "Armor Kits",             npc = "Chronos", tier = 5, items = { item(15564, "Rugged Armor Kit", 8) } },
    { questID = 7941, doubtful = MORE_DOUBT, name = "More Armor Kits",        npc = "Chronos", tier = 5, repeatable = true, items = { item(15564, "Rugged Armor Kit", 8) } },

    -- Free Ticket Sources (one-time, never ranked)
    -- Level 6, 50 reputation (Wowhead Forever).
    { questID = 7905, name = "The Darkmoon Faire", npc = "Gelvas Grimegate", faction = "Alliance", free = true, tickets = 5, minLevel = 6, items = { item(19338, "Free Ticket Voucher", 1) } },
    { questID = 7926, name = "The Darkmoon Faire", npc = "Gelvas Grimegate", faction = "Horde",    free = true, tickets = 5, minLevel = 6, items = { item(19338, "Free Ticket Voucher", 1) } },
}

-- Professions that craft Turn-in Items or Intermediate Reagents.
-- `skillLine` is the skill-line ID (Wowhead Forever: 164, 165, 202).
Data.professions = {
    Blacksmithing  = { skillLine = 164 },
    Leatherworking = { skillLine = 165 },
    Engineering    = { skillLine = 202 },
}

-- Recipes keyed by the item they produce. Covers every crafted Turn-in Item and
-- every crafted Intermediate Reagent. Smelted bars and leather are not recipes
-- here; they are bought.
-- Checked 2026-11-13 against Wowhead's Forever profession pages (all marked
-- unchanged from vanilla). `skill` is the level the recipe requires (where it
-- turns orange), not the later yellow level.
local function reagent(itemID, name, quantity)
    return { itemID = itemID, name = name, quantity = quantity }
end

Data.recipes = {
    -- Engineering
    [4363]  = { name = "Copper Modulator", profession = "Engineering", skill = 65, yield = 1, reagents = {
        reagent(4359, "Handful of Copper Bolts", 2), reagent(2840, "Copper Bar", 1), reagent(2589, "Linen Cloth", 2) } },
    [4359]  = { name = "Handful of Copper Bolts", profession = "Engineering", skill = 30, yield = 1, reagents = {
        reagent(2840, "Copper Bar", 1) } },
    [4375]  = { name = "Whirring Bronze Gizmo", profession = "Engineering", skill = 125, yield = 1, reagents = {
        reagent(2841, "Bronze Bar", 2), reagent(2592, "Wool Cloth", 1) } },
    [9313]  = { name = "Green Firework", profession = "Engineering", skill = 150, yield = 3, reagents = {
        reagent(4377, "Heavy Blasting Powder", 1), reagent(4234, "Heavy Leather", 1) } },
    [4377]  = { name = "Heavy Blasting Powder", profession = "Engineering", skill = 125, yield = 1, reagents = {
        reagent(2838, "Heavy Stone", 1) } },
    [11590] = { name = "Mechanical Repair Kit", profession = "Engineering", skill = 200, yield = 1, reagents = {
        reagent(3860, "Mithril Bar", 1), reagent(4338, "Mageweave Cloth", 1), reagent(10505, "Solid Blasting Powder", 1) } },
    [10505] = { name = "Solid Blasting Powder", profession = "Engineering", skill = 175, yield = 1, reagents = {
        reagent(7912, "Solid Stone", 2) } },
    [15994] = { name = "Thorium Widget", profession = "Engineering", skill = 260, yield = 1, reagents = {
        reagent(12359, "Thorium Bar", 3), reagent(14047, "Runecloth", 1) } },

    -- Blacksmithing
    [3240]  = { name = "Coarse Weightstone", profession = "Blacksmithing", skill = 40, yield = 1, reagents = {
        reagent(2836, "Coarse Stone", 1) } },  -- Wowhead Forever: no Wool Cloth
    [3486]  = { name = "Heavy Grinding Stone", profession = "Blacksmithing", skill = 100, yield = 1, reagents = {
        reagent(2838, "Heavy Stone", 3) } },
    [3835]  = { name = "Green Iron Bracers", profession = "Blacksmithing", skill = 140, yield = 1, reagents = {
        reagent(3575, "Iron Bar", 6), reagent(2605, "Green Dye", 1) } },
    [7945]  = { name = "Big Black Mace", profession = "Blacksmithing", skill = 205, yield = 1, reagents = {
        reagent(3860, "Mithril Bar", 16), reagent(7971, "Black Pearl", 1), reagent(1210, "Shadowgem", 4),
        reagent(7966, "Solid Grinding Stone", 1), reagent(4304, "Thick Leather", 2) } },
    [7966]  = { name = "Solid Grinding Stone", profession = "Blacksmithing", skill = 175, yield = 1, reagents = {
        reagent(7912, "Solid Stone", 4) } },
    [12644] = { name = "Dense Grinding Stone", profession = "Blacksmithing", skill = 225, yield = 1, reagents = {
        reagent(12365, "Dense Stone", 4) } },
    [7071]  = { name = "Iron Buckle", profession = "Blacksmithing", skill = 125, yield = 2, reagents = {
        reagent(3575, "Iron Bar", 1) } },

    -- Leatherworking
    [2309]  = { name = "Embossed Leather Boots", profession = "Leatherworking", skill = 50, yield = 1, reagents = {
        reagent(2318, "Light Leather", 8), reagent(2320, "Coarse Thread", 5) } },
    [2314]  = { name = "Toughened Leather Armor", profession = "Leatherworking", skill = 95, yield = 1, reagents = {
        reagent(2319, "Medium Leather", 10), reagent(4231, "Cured Light Hide", 2), reagent(2321, "Fine Thread", 2) } },
    [4231]  = { name = "Cured Light Hide", profession = "Leatherworking", skill = 30, yield = 1, reagents = {
        reagent(783, "Light Hide", 1), reagent(4289, "Salt", 1) } },
    [5739]  = { name = "Barbaric Harness", profession = "Leatherworking", skill = 165, yield = 1, reagents = {
        reagent(4234, "Heavy Leather", 14), reagent(2321, "Fine Thread", 2), reagent(7071, "Iron Buckle", 1) } },
    [8185]  = { name = "Turtle Scale Leggings", profession = "Leatherworking", skill = 210, yield = 1, reagents = {
        reagent(4304, "Thick Leather", 14), reagent(8167, "Turtle Scale", 28), reagent(8343, "Heavy Silken Thread", 1) } },
    [15564] = { name = "Rugged Armor Kit", profession = "Leatherworking", skill = 225, yield = 1, reagents = {
        reagent(8170, "Rugged Leather", 5) } },
}

-- Vendor Items: sold by NPC vendors in unlimited stock. `price` is a fallback
-- in copper; the price adapter prefers the price Auctionator recorded at a
-- merchant. Limited-stock items must never be listed here.
-- Prices are vanilla base prices (checked on Wowhead Classic); reputation
-- discounts shift them slightly.
-- Deliberately NOT listed:
--   Copper Modulator: Engineering Supplies vendors only have limited stock.
--   Green Firework: Holiday Fireworks Vendors only appear during holidays.
--   Leathers: the Darkmoon Faire Exotic Goods vendor only has limited stock.
-- All five checked 2026-11-13 on Wowhead Forever: unlimited stock at these
-- prices. Edna Mullby (Stormwind City) and Shimra (Orgrimmar) sell all of them.
local TRADE_VENDORS = { Alliance = "Edna Mullby in Stormwind City", Horde = "Shimra in Orgrimmar" }

Data.vendor = {
    [2320]  = { name = "Coarse Thread",       price = 10,  where = "Trade Supplies and Leatherworking/Tailoring Supplies vendors", example = TRADE_VENDORS },
    [2321]  = { name = "Fine Thread",         price = 100, where = "Trade Supplies and Leatherworking/Tailoring Supplies vendors", example = TRADE_VENDORS },
    [8343]  = { name = "Heavy Silken Thread", price = 2000, where = "Trade Supplies and Leatherworking/Tailoring Supplies vendors", example = TRADE_VENDORS },
    [2605]  = { name = "Green Dye",           price = 100, where = "Trade Supplies and Tailoring Supplies vendors", example = TRADE_VENDORS },
    [4289]  = { name = "Salt",                price = 50,  where = "Trade Supplies and Cooking/Leatherworking Supplies vendors", example = TRADE_VENDORS },
}

-- How Turn-in Items come into the game, shown in the row tooltip. Crafting
-- needs no entry: every item in Data.recipes is shown as crafted.
--   drop   = true                 dropped by mobs
--   vendor = "where"              sold by NPCs, including limited-stock and
--                                 holiday vendors (unlike Data.vendor, which
--                                 the price ranking relies on)
Data.obtain = {
    [5134]  = { drop = true },  -- Small Furry Paw
    [11407] = { drop = true },  -- Torn Bear Pelt
    [4582]  = { drop = true },  -- Soft Bushy Tail
    [5117]  = { drop = true },  -- Vibrant Plume
    [11404] = { drop = true },  -- Evil Bat Eye
    [19933] = { drop = true },  -- Glowing Scorpid Blood
    [4363]  = { drop = true, vendor = "Engineering Supplies vendors (limited stock)" },  -- Copper Modulator
    [9313]  = { vendor = "Holiday Fireworks Vendors (during holidays only)" },          -- Green Firework
}

-- Prize Rewards: on Forever, Gelvas Grimegate sells these for the ticket
-- currency (vanilla's "<N> Tickets - <item>" quests are still listed too).
-- Checked 2026-11-13 on Wowhead Forever: ticket costs from his sell list;
-- `useLevel` is the item's own level requirement there (nil = none; Forever
-- removed it from the Flower, the Storage Box and the schematic). Buying has
-- no level requirement.
local function reward(questID, itemID, name, tickets, useLevel)
    return { questID = questID, itemID = itemID, name = name, tickets = tickets, useLevel = useLevel }
end

Data.rewards = {
    reward(7930, 19295, "Darkmoon Flower",                  5,    nil),
    reward(7931, 19298, "Minor Darkmoon Prize",             5,    15),
    reward(7935, 19292, "Last Month's Mutton",              10,   29),
    reward(7932, 19297, "Lesser Darkmoon Prize",            12,   30),
    reward(7933, 19296, "Greater Darkmoon Prize",           40,   45),
    reward(9249, 22729, "Schematic: Steam Tonk Controller", 40,   nil),
    reward(7934, 19291, "Darkmoon Storage Box",             50,   nil),
    reward(7936, 19293, "Last Year's Mutton",               50,   50),
    reward(7940, 19426, "Orb of the Darkmoon",              1200, 60),
    reward(7981, 19491, "Amulet of the Darkmoon",           1200, 60),
}

-- The item handed in for Free Ticket Sources.
Data.voucherItemID = 19338

-- The Prize Ticket: a currency on Forever, an item in vanilla.
Data.ticketCurrencyID = 515
Data.ticketItemID = 19182

-- The Darkmoon Faire reputation faction.
Data.factionID = 909

ns.Data = Data
