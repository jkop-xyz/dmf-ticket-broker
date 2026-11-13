local Engine = LoadAddon("Engine.lua").Engine

local function fixture()
  return {
    tiers = {
      [1] = { tickets = 1 },
      [2] = { tickets = 4 },
    },
    sources = {
      { questID = 1, name = "Paws",  tier = 1, items = { { itemID = 10, quantity = 5 } } },
      { questID = 2, name = "Pelts", tier = 2, items = { { itemID = 20, quantity = 5 } } },
      { questID = 3, name = "Mixed", tier = 2, items = {
        { itemID = 10, quantity = 2 },
        { itemID = 30, quantity = 1 },
      } },
      { questID = 4, name = "Voucher", free = true, tickets = 5, items = { { itemID = 99, quantity = 1 } } },
    },
  }
end

local function names(rows)
  local out = {}
  for i, row in ipairs(rows) do out[i] = row.source.name end
  return out
end

describe("Engine.Rank", function()
  it("computes Buy Cost per Ticket from Scan Prices, quantities and tickets rewarded", function()
    local rows = Engine.Rank(fixture(), {
      [10] = { price = 100 },
      [20] = { price = 400 },
      [30] = { price = 1000 },
    }, {})
    local byName = {}
    for _, row in ipairs(rows) do byName[row.source.name] = row end

    assert.are.equal(500, byName.Paws.buyCost)
    assert.are.equal(500, byName.Paws.buyCostPerTicket)
    assert.are.equal(2000, byName.Pelts.buyCost)
    assert.are.equal(500, byName.Pelts.buyCostPerTicket)
    assert.are.equal(1200, byName.Mixed.buyCost)
    assert.are.equal(300, byName.Mixed.buyCostPerTicket)
  end)

  it("orders rows cheapest Cost per Ticket first", function()
    local rows = Engine.Rank(fixture(), {
      [10] = { price = 100 },  -- Paws 500/ticket, Mixed 300/ticket
      [20] = { price = 80 },   -- Pelts 100/ticket
      [30] = { price = 1000 },
    }, {})
    assert.are.same({ "Pelts", "Mixed", "Paws" }, names(rows))
  end)

  it("ranks by rankCost, which equals Buy Cost per Ticket", function()
    local rows = Engine.Rank(fixture(), { [10] = { price = 100 }, [20] = { price = 80 }, [30] = { price = 1 } }, {})
    for _, row in ipairs(rows) do
      assert.are.equal(row.buyCostPerTicket, row.rankCost)
    end
  end)

  it("flags a source as no data when any Turn-in Item lacks a Scan Price, and sorts it last", function()
    local rows = Engine.Rank(fixture(), {
      [10] = { price = 100000 },  -- Paws very expensive, but priced
      [20] = { price = 80 },
      -- 30 missing: Mixed can't be priced
    }, {})
    assert.are.same({ "Pelts", "Paws", "Mixed" }, names(rows))
    local last = rows[#rows]
    assert.is_true(last.noData)
    assert.is_nil(last.buyCost)
    assert.is_nil(last.rankCost)
    assert.is_false(rows[1].noData)
  end)

  it("treats every source as no data when there are no prices at all", function()
    local rows = Engine.Rank(fixture(), {}, {})
    assert.are.equal(3, #rows)
    for _, row in ipairs(rows) do
      assert.is_true(row.noData)
    end
  end)

  it("never ranks Free Ticket Sources", function()
    local rows = Engine.Rank(fixture(), { [99] = { price = 1 } }, {})
    for _, row in ipairs(rows) do
      assert.is_not_true(row.source.free)
    end
    assert.are.equal(3, #rows)
  end)

  it("orders deterministically when costs tie", function()
    local rows = Engine.Rank(fixture(), { [10] = { price = 100 }, [20] = { price = 400 }, [30] = { price = 1800 } }, {})
    -- Paws 500 (T1), Pelts 500 (T2), Mixed 500 (T2): tier, then name
    assert.are.same({ "Paws", "Mixed", "Pelts" }, names(rows))
  end)
end)

describe("Engine.Rank sorting by Cost per Turn-in", function()
  local prices = {
    [10] = { price = 100 },  -- Paws 500/turn-in (500/ticket), Mixed 1200/turn-in (300/ticket)
    [20] = { price = 80 },   -- Pelts 400/turn-in (100/ticket)
    [30] = { price = 1000 },
  }

  it("reports the cheapest total for one turn-in", function()
    local byName = Fixtures.byName(Engine.Rank(fixture(), prices, {}))
    assert.are.equal(500, byName.Paws.turnInCost)
    assert.are.equal(400, byName.Pelts.turnInCost)
    assert.are.equal(1200, byName.Mixed.turnInCost)
  end)

  it("sorts by Cost per Ticket by default", function()
    assert.are.same({ "Pelts", "Mixed", "Paws" }, names(Engine.Rank(fixture(), prices, {})))
  end)

  it("sorts cheapest turn-in first when asked", function()
    local rows = Engine.Rank(fixture(), prices, {}, { sortBy = Engine.SORT.PER_TURN_IN })
    assert.are.same({ "Pelts", "Paws", "Mixed" }, names(rows))
  end)

  it("still puts no-data rows last", function()
    local rows = Engine.Rank(fixture(), { [10] = { price = 100 } }, {}, { sortBy = Engine.SORT.PER_TURN_IN })
    assert.are.same({ "Paws", "Mixed", "Pelts" }, names(rows))
    assert.is_nil(rows[3].turnInCost)
  end)
end)
