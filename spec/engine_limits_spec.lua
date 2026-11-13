local Engine = LoadAddon("Engine.lua").Engine

-- Two capped tiers sharing one reputation, plus a repeatable quest.
local function fixture()
  return {
    tiers = {
      [1] = { tickets = 1, minLevel = 1,  repCap = 500,  rep = 100 },
      [2] = { tickets = 4, minLevel = 10, repCap = 1100, rep = 100 },
      [5] = { tickets = 20, minLevel = 40, repCap = 9000, rep = 100 },
    },
    sources = {
      { questID = 1, name = "Paws",  tier = 1, items = { { itemID = 10, quantity = 1 } } },
      { questID = 2, name = "Pelts", tier = 2, items = { { itemID = 20, quantity = 1 } } },
      { questID = 3, name = "More",  tier = 5, repeatable = true, items = { { itemID = 30, quantity = 1 } } },
    },
    recipes = {},
    vendor = {},
    rewards = {
      { questID = 100, itemID = 900, name = "Flower", tickets = 5 },
      { questID = 101, itemID = 901, name = "Orb", tickets = 1200, useLevel = 60 },
    },
  }
end

describe("turn-ins left before the reputation limit", function()
  it("counts turn-ins until the tier's limit, including the one that crosses it", function()
    local byName = Fixtures.byName(Engine.Rank(fixture(), {}, { level = 60, reputation = 250 }))
    -- 250 -> 350 -> 450 -> 550: three turn-ins (the last starts below 500)
    assert.are.equal(3, byName.Paws.turnInsLeft)
    assert.are.equal(3, byName.Paws.ticketsLeft)
    assert.are.equal(9, byName.Pelts.turnInsLeft)
    assert.are.equal(36, byName.Pelts.ticketsLeft)
  end)

  it("is zero once the limit is reached", function()
    local byName = Fixtures.byName(Engine.Rank(fixture(), {}, { level = 60, reputation = 500 }))
    assert.are.equal(0, byName.Paws.turnInsLeft)
  end)

  it("marks repeatable quests as unlimited", function()
    local byName = Fixtures.byName(Engine.Rank(fixture(), {}, { level = 60, reputation = 250 }))
    assert.is_true(byName.More.unlimited)
    assert.is_nil(byName.More.turnInsLeft)
    assert.are.equal(0, byName.More.repPerTurnIn)
  end)

  it("is unknown when the reputation can't be read", function()
    local byName = Fixtures.byName(Engine.Rank(fixture(), {}, { level = 60 }))
    assert.is_nil(byName.Paws.turnInsLeft)
    assert.is_nil(byName.Paws.unlimited)
  end)
end)

describe("Engine.TicketPlan", function()
  local prices = {
    [10] = { price = 10 },   -- Paws: 10 per ticket
    [20] = { price = 80 },   -- Pelts: 20 per ticket
    [30] = { price = 1000 }, -- More: 50 per ticket
  }

  local function plan(character, need)
    local data = fixture()
    local rows = Engine.Rank(data, prices, character)
    return Engine.TicketPlan(data, rows, character, need)
  end

  local function counts(p)
    local out = {}
    for _, entry in ipairs(p.turnIns) do out[entry.row.source.name] = entry.count end
    return out
  end

  it("takes the cheapest turn-ins first and stops at the reputation limit", function()
    -- Paws until 500 (5 turn-ins, 5 tickets), then Pelts (4 per turn-in).
    local p = plan({ level = 60, reputation = 0 }, 13)
    assert.is_true(p.complete)
    assert.are.same({ Paws = 5, Pelts = 2 }, counts(p))
    assert.are.equal(13, p.tickets)
    assert.are.equal(5 * 10 + 2 * 80, p.cost)
  end)

  it("lets every turn-in use up the shared reputation", function()
    -- Starting at 1000: one Pelts turn-in (1000 < 1100) pushes reputation
    -- past both limits, so the rest must come from the repeatable quest.
    local p = plan({ level = 60, reputation = 1000 }, 30)
    assert.are.same({ Pelts = 1, More = 2 }, counts(p))
    assert.are.equal(44, p.tickets)
  end)

  it("skips quests the character's level can't hand in", function()
    local p = plan({ level = 5, reputation = 0 }, 7)
    assert.are.same({ Paws = 5 }, counts(p))
    assert.is_false(p.complete)
    assert.are.equal(5, p.tickets)
  end)

  it("skips quests without prices", function()
    local data = fixture()
    local character = { level = 60, reputation = 0 }
    local rows = Engine.Rank(data, { [30] = { price = 1000 } }, character)
    local p = Engine.TicketPlan(data, rows, character, 40)
    assert.are.same({ More = 2 }, counts(p))
  end)
end)

describe("Prize Rewards", function()
  it("says what the character can afford and plans the missing tickets", function()
    local _, info = Engine.Rank(fixture(), { [10] = { price = 10 }, [30] = { price = 1000 } },
      { level = 60, reputation = 0, tickets = 7 })
    local flower, orb = info.rewards[1], info.rewards[2]
    assert.is_true(flower.affordable)
    assert.are.equal(0, flower.missing)
    assert.is_nil(flower.plan)
    assert.is_false(orb.affordable)
    assert.are.equal(1193, orb.missing)
    assert.is_true(orb.plan.complete)
    assert.is_true(orb.plan.tickets >= 1193)
  end)

  it("checks the item's own level requirement", function()
    local _, info = Engine.Rank(fixture(), {}, { level = 30, tickets = 0 })
    assert.is_true(info.rewards[1].usable)
    assert.is_false(info.rewards[2].usable)
  end)
end)
