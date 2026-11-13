local Engine = LoadAddon("Engine.lua").Engine
local E = Engine.ELIGIBILITY

local data = {
  tiers = {
    [2] = { tickets = 4, minLevel = 10, repCap = 1100 },
    [5] = { tickets = 20, minLevel = 40, repCap = 9000 },
  },
  sources = {
    { questID = 1, name = "Pelts", tier = 2, items = { { itemID = 1, quantity = 1 } } },
    { questID = 2, name = "Eyes", tier = 5, items = { { itemID = 1, quantity = 1 } } },
    { questID = 3, name = "More Eyes", tier = 5, repeatable = true, items = { { itemID = 1, quantity = 1 } } },
    { questID = 4, name = "Voucher", free = true, tickets = 5, items = { { itemID = 9, quantity = 1 } } },
  },
}

local function states(character)
  local out = {}
  for name, row in pairs(Fixtures.byName(Engine.Rank(data, { [1] = { price = 1 } }, character))) do
    out[name] = row.eligibility
  end
  return out
end

describe("Turn-in Eligibility", function()
  it("is Eligible when level and reputation allow it", function()
    local s = states({ level = 40, reputation = 0 })
    assert.are.equal(E.ELIGIBLE, s.Pelts.state)
    assert.are.equal(E.ELIGIBLE, s.Eyes.state)
  end)

  it("is Level Too Low below the Tier's minimum level, with the required level", function()
    local s = states({ level = 9, reputation = 0 })
    assert.are.equal(E.LEVEL_TOO_LOW, s.Pelts.state)
    assert.are.equal(10, s.Pelts.requiredLevel)
  end)

  it("is Eligible exactly at the minimum level", function()
    assert.are.equal(E.ELIGIBLE, states({ level = 10, reputation = 0 }).Pelts.state)
  end)

  it("is Reputation Too High at or past the Tier's reputation cap", function()
    assert.are.equal(E.ELIGIBLE, states({ level = 60, reputation = 1099 }).Pelts.state)
    assert.are.equal(E.REPUTATION_TOO_HIGH, states({ level = 60, reputation = 1100 }).Pelts.state)
  end)

  it("keeps Tier 5 repeatables Eligible past the cap", function()
    local s = states({ level = 60, reputation = 20000 })
    assert.are.equal(E.REPUTATION_TOO_HIGH, s.Eyes.state)
    assert.are.equal(E.ELIGIBLE, s["More Eyes"].state)
  end)

  it("checks level before reputation", function()
    assert.are.equal(E.LEVEL_TOO_LOW, states({ level = 5, reputation = 5000 }).Pelts.state)
  end)

  it("is Eligible when the character snapshot is unknown", function()
    assert.are.equal(E.ELIGIBLE, states({}).Pelts.state)
  end)

  it("keeps ineligible rows in rank order", function()
    local cheap = {
      tiers = data.tiers,
      sources = {
        { questID = 1, name = "Cheap", tier = 2, items = { { itemID = 1, quantity = 1 } } },
        { questID = 2, name = "Dear", tier = 2, items = { { itemID = 2, quantity = 1 } } },
      },
    }
    local rows = Engine.Rank(cheap, { [1] = { price = 1 }, [2] = { price = 100 } }, { level = 1 })
    assert.are.same({ "Cheap", "Dear" }, Fixtures.names(rows))
    assert.are.equal(E.LEVEL_TOO_LOW, rows[1].eligibility.state)
  end)
end)

describe("Turn-in Eligibility for quests that need a profession", function()
  local Engine = LoadAddon("Engine.lua").Engine
  local E = Engine.ELIGIBILITY

  local function data()
    local d = Fixtures.single({ tickets = 1 })
    d.sources[1].requiresProfession = { profession = "Engineering", skill = 40 }
    return d
  end

  it("blocks characters without the profession", function()
    local row = Engine.Rank(data(), {}, { level = 60 })[1]
    assert.are.equal(E.PROFESSION_REQUIRED, row.eligibility.state)
    assert.are.equal("Engineering", row.eligibility.profession)
    assert.are.equal(40, row.eligibility.requiredSkill)
  end)

  it("blocks characters below the required skill", function()
    local row = Engine.Rank(data(), {}, { level = 60, skills = { Engineering = 39 } })[1]
    assert.are.equal(E.PROFESSION_REQUIRED, row.eligibility.state)
  end)

  it("lets characters with enough skill turn in", function()
    local row = Engine.Rank(data(), {}, { level = 60, skills = { Engineering = 40 } })[1]
    assert.are.equal(E.ELIGIBLE, row.eligibility.state)
  end)

  it("ignores professions for unflagged quests", function()
    local row = Engine.Rank(Fixtures.single(), {}, { level = 60 })[1]
    assert.are.equal(E.ELIGIBLE, row.eligibility.state)
  end)
end)
