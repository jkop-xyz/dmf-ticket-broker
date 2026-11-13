local Engine = LoadAddon("Engine.lua").Engine
local C, R = Engine.CRAFTABILITY, Engine.ROUTE

-- Widget (100) is crafted by Engineering 100 from 2x Gear (200) + 1x Cloth (300).
-- Gear (200) is itself crafted by Engineering 50 from 1x Bar (400), yield 2.
-- Gadget (500), made by Blacksmithing, is used by nothing here.
local function data(opts)
  opts = opts or {}
  return {
    tiers = { [1] = { tickets = opts.tickets or 1, minLevel = 1, repCap = 500 } },
    sources = {
      { questID = 1, name = "Widgets", tier = 1, items = { { itemID = 100, name = "Widget", quantity = opts.quantity or 1 } } },
    },
    recipes = {
      [100] = { name = "Widget", profession = "Engineering", skill = 100, yield = opts.yield or 1, reagents = {
        { itemID = 200, name = "Gear", quantity = 2 }, { itemID = 300, name = "Cloth", quantity = 1 } } },
      [200] = { name = "Gear", profession = opts.gearProfession or "Engineering", skill = 50, yield = 2, reagents = {
        { itemID = 400, name = "Bar", quantity = 1 } } },
    },
    vendor = opts.vendor or {},
  }
end

local function rank(d, prices, character)
  return Engine.Rank(d, prices, character)[1]
end

local allKnown = { [100] = true, [200] = true }

describe("Craftability", function()
  local prices = { [100] = { price = 1000 }, [200] = { price = 10 }, [300] = { price = 10 } }

  it("is Missing Profession without the profession", function()
    local row = rank(data(), prices, { skills = {} })
    assert.are.equal(C.MISSING_PROFESSION, row.craftability)
    assert.is_nil(row.craftCost)
  end)

  it("is Missing Profession for an empty character snapshot", function()
    assert.are.equal(C.MISSING_PROFESSION, rank(data(), prices, {}).craftability)
  end)

  it("is Needs Skill-up under the recipe's skill level", function()
    local row = rank(data(), prices, Fixtures.engineer(99, allKnown))
    assert.are.equal(C.NEEDS_SKILL_UP, row.craftability)
    assert.are.equal(100, row.breakdown[1].requiredSkill)
    assert.is_nil(row.craftCost)
  end)

  it("is Not Scanned when the profession's recipes have never been seen", function()
    local row = rank(data(), prices, { skills = { Engineering = 300 } })
    assert.are.equal(C.NOT_SCANNED, row.craftability)
    assert.are.equal("Engineering", row.profession)
    assert.is_nil(row.craftCost)
  end)

  it("is Recipe Unknown when the scanned recipes do not include it", function()
    local row = rank(data(), prices, Fixtures.engineer(300, { [200] = true }))
    assert.are.equal(C.RECIPE_UNKNOWN, row.craftability)
    assert.is_nil(row.craftCost)
  end)

  it("is Craftable with the profession, skill and recipe", function()
    local row = rank(data(), prices, Fixtures.engineer(100, allKnown))
    assert.are.equal(C.CRAFTABLE, row.craftability)
    assert.is_number(row.craftCost)
  end)

  it("is absent for items without a recipe", function()
    local d = data()
    d.recipes = {}
    assert.is_nil(rank(d, prices, Fixtures.engineer(300, allKnown)).craftability)
  end)
end)

describe("the Craft route", function()
  local engineer = Fixtures.engineer(300, allKnown)

  it("ranks by Craft when Craftable and cheaper than Buy", function()
    -- Craft: 2 Gear (bought 10 each) + 1 Cloth 10 = 30 < Buy 1000
    local row = rank(data(), { [100] = { price = 1000 }, [200] = { price = 10 }, [300] = { price = 10 } }, engineer)
    assert.are.equal(1000, row.buyCostPerTicket)
    assert.are.equal(30, row.craftCostPerTicket)
    assert.are.equal(30, row.rankCost)
    assert.are.equal(R.CRAFT, row.breakdown[1].route)
  end)

  it("ranks by Buy when Buy is cheaper, but still reports the Craft cost", function()
    local row = rank(data(), { [100] = { price = 20 }, [200] = { price = 10 }, [300] = { price = 10 } }, engineer)
    assert.are.equal(20, row.rankCost)
    assert.are.equal(30, row.craftCostPerTicket)
    assert.are.equal(R.AH, row.breakdown[1].route)
  end)

  it("ranks by Buy when not Craftable, however cheap Craft would be", function()
    local row = rank(data(), { [100] = { price = 1000 }, [200] = { price = 1 }, [300] = { price = 1 } }, {})
    assert.are.equal(1000, row.rankCost)
  end)

  it("divides by the recipe's yield, rounding crafts up", function()
    -- 36 Widgets at yield 3 = 12 crafts; each craft 2 Gear + 1 Cloth
    local row = rank(data({ quantity = 36, yield = 3 }), { [200] = { price = 10 }, [300] = { price = 10 } }, engineer)
    local node = row.breakdown[1]
    assert.are.equal(12, node.crafts)
    assert.are.equal(24, node.children[1].quantity)
    assert.are.equal(12, node.children[2].quantity)
    assert.are.equal(360, row.rankCost)

    local partial = rank(data({ quantity = 4, yield = 3 }), { [200] = { price = 10 }, [300] = { price = 10 } }, engineer)
    assert.are.equal(2, partial.breakdown[1].crafts)
  end)

  it("makes Craft no data when a reagent has no price, without hiding Buy", function()
    local row = rank(data(), { [100] = { price = 500 }, [200] = { price = 10 } }, engineer)
    assert.is_nil(row.craftCost)
    assert.are.equal(500, row.rankCost)
    assert.is_false(row.noData)
  end)

  it("is no data when neither Buy nor Craft can be priced", function()
    local row = rank(data(), { [200] = { price = 10 } }, engineer)
    assert.is_true(row.noData)
  end)

  it("prices reagents from Vendor Items", function()
    local d = data({ vendor = { [300] = { name = "Cloth", price = 1, where = "Trade Supplies" } } })
    local row = rank(d, { [200] = { price = 10 } }, engineer)
    assert.are.equal(21, row.rankCost)
    assert.are.equal(R.VENDOR, row.breakdown[1].children[2].route)
  end)
end)

describe("Intermediate Reagents", function()
  local engineer = Fixtures.engineer(300, allKnown)

  it("crafts the intermediate when that is cheaper", function()
    -- Gear: buy 10 each, or craft from Bar 2 per craft (yield 2) = 2 Gear for 2
    local row = rank(data(), { [200] = { price = 10 }, [300] = { price = 10 }, [400] = { price = 2 } }, engineer)
    local gear = row.breakdown[1].children[1]
    assert.are.equal(R.CRAFT, gear.route)
    assert.are.equal(1, gear.crafts)
    assert.are.equal(1, gear.children[1].quantity)
    assert.are.equal(12, row.rankCost) -- 2 (one Bar) + 10 Cloth
  end)

  it("buys the intermediate when that is cheaper", function()
    local row = rank(data(), { [200] = { price = 1 }, [300] = { price = 10 }, [400] = { price = 100 } }, engineer)
    assert.are.equal(R.AH, row.breakdown[1].children[1].route)
    assert.are.equal(12, row.rankCost)
  end)

  it("only crafts an intermediate the character can craft", function()
    -- Gear made by Blacksmithing, which the engineer lacks
    local row = rank(data({ gearProfession = "Blacksmithing" }),
      { [200] = { price = 10 }, [300] = { price = 10 }, [400] = { price = 1 } }, engineer)
    local gear = row.breakdown[1].children[1]
    assert.are.equal(C.MISSING_PROFESSION, gear.craftability)
    assert.are.equal(R.AH, gear.route)
    assert.are.equal(30, row.rankCost)
  end)

  it("propagates no data from a leaf when there is no other route", function()
    local row = rank(data(), { [300] = { price = 10 } }, engineer) -- no Gear, no Bar, no Widget price
    local gear = row.breakdown[1].children[1]
    assert.is_true(gear.noData)
    assert.is_true(row.noData)
  end)

  it("marks the row Stale when a chosen price deep in the tree is Stale", function()
    local row = rank(data(), { [200] = { price = 10 }, [300] = { price = 10 }, [400] = { price = 2, age = 9 } },
      { skills = engineer.skills, knownRecipes = engineer.knownRecipes, staleDays = 3 })
    assert.is_true(row.stale)
    assert.is_true(row.breakdown[1].anyStale)
  end)

  it("survives a recipe cycle by buying", function()
    local d = data()
    d.recipes[400] = { name = "Bar", profession = "Engineering", skill = 1, yield = 1, reagents = {
      { itemID = 200, name = "Gear", quantity = 1 } } }
    local known = Fixtures.engineer(300, { [100] = true, [200] = true, [400] = true })
    local row = rank(d, { [200] = { price = 10 }, [300] = { price = 10 }, [400] = { price = 2 } }, known)
    assert.is_number(row.rankCost)
  end)
end)

describe("full craft cost (display only)", function()
  local Engine = LoadAddon("Engine.lua").Engine

  local function data()
    return Fixtures.single({
      quantity = 2, tickets = 2,
      recipes = {
        [100] = { name = "Widget", profession = "Engineering", skill = 100, yield = 1, reagents = {
          { itemID = 200, name = "Gear", quantity = 3 },
          { itemID = 300, name = "Bolt", quantity = 1 } } },
        [300] = { name = "Bolt", profession = "Engineering", skill = 10, yield = 1, reagents = {
          { itemID = 400, name = "Bar", quantity = 1 } } },
      },
    })
  end
  local prices = { [100] = { price = 500 }, [200] = { price = 10 }, [300] = { price = 100 }, [400] = { price = 5 } }

  it("is shown for characters who can't craft, using the cheapest reagents", function()
    local row = Engine.Rank(data(), prices, {})[1]
    -- 2 crafts x (3 gears x 10 + 1 bolt crafted from a 5c bar)
    assert.are.equal(70, row.fullCraftCost)
    assert.are.equal(35, row.fullCraftCostPerTicket)
    assert.is_nil(row.craftCost)
  end)

  it("never changes the ranking", function()
    local row = Engine.Rank(data(), prices, {})[1]
    assert.are.equal(1000, row.turnInCost)
    assert.are.equal(Engine.ROUTE.AH, row.breakdown[1].route)
  end)

  it("is nil when a reagent has no price", function()
    local row = Engine.Rank(data(), { [100] = { price = 500 }, [200] = { price = 10 } }, {})[1]
    assert.is_nil(row.fullCraftCost)
  end)

  it("is absent for items nobody crafts", function()
    local row = Engine.Rank(Fixtures.single(), { [100] = { price = 5 } }, {})[1]
    assert.is_nil(row.fullCraftCost)
  end)
end)
