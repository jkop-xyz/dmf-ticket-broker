local ns = LoadAddon("Data.lua", "Engine.lua")
local Data, Engine = ns.Data, ns.Engine

describe("the real Data table", function()
  it("has well-formed Ticket Sources", function()
    for _, source in ipairs(Data.sources) do
      local label = tostring(source.name)
      assert.is_number(source.questID, label)
      assert.is_string(source.name, label)
      if source.free then
        assert.is_number(source.tickets, label)
      else
        assert.is_table(Data.tiers[source.tier], label .. " has a known tier")
      end
      assert.is_true(#source.items > 0, label .. " has Turn-in Items")
      for _, entry in ipairs(source.items) do
        assert.is_number(entry.itemID, label)
        assert.is_string(entry.name, label)
        assert.is_number(entry.quantity, label)
        assert.is_true(entry.quantity > 0, label)
      end
    end
  end)

  it("has a complete Tier table", function()
    for tier = 1, 5 do
      local t = Data.tiers[tier]
      assert.is_number(t.tickets)
      assert.is_number(t.minLevel)
      assert.is_number(t.repCap)
    end
  end)

  it("ranks through the Engine without errors", function()
    local prices = {}
    for _, source in ipairs(Data.sources) do
      for _, entry in ipairs(source.items) do
        prices[entry.itemID] = { price = 100 }
      end
    end
    local rows = Engine.Rank(Data, prices, {})
    local nonFree = 0
    for _, source in ipairs(Data.sources) do
      if not source.free then nonFree = nonFree + 1 end
    end
    assert.are.equal(nonFree, #rows)
    for _, row in ipairs(rows) do
      assert.is_false(row.noData)
    end
  end)
end)

describe("the real recipe and Vendor Item tables", function()
  it("has a recipe for every Turn-in Item of a profession quest", function()
    local crafted = { Rinling = true, ["Kerri Hicks"] = true, Chronos = true }
    for _, source in ipairs(Data.sources) do
      if crafted[source.npc] then
        for _, entry in ipairs(source.items) do
          assert.is_table(Data.recipes[entry.itemID], entry.name .. " has a recipe")
        end
      end
    end
  end)

  it("has well-formed recipes in known professions", function()
    for itemID, recipe in pairs(Data.recipes) do
      local label = tostring(recipe.name)
      assert.is_number(itemID, label)
      assert.is_table(Data.professions[recipe.profession], label .. " has a known profession")
      assert.is_number(recipe.skill, label)
      assert.is_true(recipe.yield >= 1, label)
      assert.is_true(#recipe.reagents > 0, label)
      for _, r in ipairs(recipe.reagents) do
        assert.is_number(r.itemID, label)
        assert.is_string(r.name, label)
        assert.is_true(r.quantity > 0, label)
      end
    end
  end)

  it("has well-formed Vendor Items", function()
    for itemID, entry in pairs(Data.vendor) do
      assert.is_number(itemID)
      assert.is_string(entry.name)
      assert.is_number(entry.price)
      assert.is_string(entry.where)
    end
  end)

  it("prices every source through Craft for a character with every recipe", function()
    local prices, skills, known = {}, {}, {}
    for profession in pairs(Data.professions) do
      skills[profession] = 300
      known[profession] = {}
    end
    for itemID, recipe in pairs(Data.recipes) do
      known[recipe.profession][itemID] = true
      for _, r in ipairs(recipe.reagents) do
        if not Data.recipes[r.itemID] then prices[r.itemID] = { price = 1 } end
      end
    end
    local rows = Engine.Rank(Data, prices, { level = 60, reputation = 0, skills = skills, knownRecipes = known })
    for _, row in ipairs(rows) do
      if row.craftability then
        assert.are.equal(Engine.CRAFTABILITY.CRAFTABLE, row.craftability, row.source.name)
        assert.is_false(row.noData, row.source.name)
      end
    end
  end)
end)

describe("Data.obtain", function()
  local Data = LoadAddon("Data.lua").Data

  it("says how every Turn-in Item is obtained", function()
    for _, source in ipairs(Data.sources) do
      if not source.free then
        for _, entry in ipairs(source.items) do
          local known = Data.recipes[entry.itemID] or Data.obtain[entry.itemID]
          assert.is_truthy(known, source.name .. ": no origin for " .. entry.name)
        end
      end
    end
  end)

  it("flags no quest as needing a profession (none does in vanilla)", function()
    for _, source in ipairs(Data.sources) do
      assert.is_nil(source.requiresProfession, source.name)
    end
  end)
end)

describe("Data.rewards", function()
  local Data = LoadAddon("Data.lua").Data

  it("lists the ten Prize Rewards with ticket costs", function()
    assert.are.equal(10, #Data.rewards)
    for _, reward in ipairs(Data.rewards) do
      assert.is_number(reward.questID)
      assert.is_number(reward.itemID)
      assert.is_true(reward.tickets > 0, reward.name)
    end
  end)

  it("gives every tier its reputation per turn-in", function()
    for tier = 1, 5 do
      assert.are.equal(100, Data.tiers[tier].rep)
    end
  end)
end)
