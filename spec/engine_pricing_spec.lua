local Engine = LoadAddon("Engine.lua").Engine
local R = Engine.ROUTE

describe("Price Age and Stale Prices", function()
  local function rank(age, staleDays)
    local rows = Engine.Rank(Fixtures.single(), { [100] = { price = 10, age = age } }, { staleDays = staleDays })
    return rows[1]
  end

  it("carries the Price Age onto the Breakdown node", function()
    assert.are.equal(2, rank(2, 3).breakdown[1].age)
  end)

  it("is not Stale below the threshold", function()
    local row = rank(2, 3)
    assert.is_false(row.breakdown[1].stale)
    assert.is_false(row.stale)
  end)

  it("is not Stale exactly at the threshold", function()
    assert.is_false(rank(3, 3).stale)
  end)

  it("is Stale above the threshold", function()
    local row = rank(4, 3)
    assert.is_true(row.breakdown[1].stale)
    assert.is_true(row.stale)
  end)

  it("defaults the threshold to 3 days", function()
    assert.is_false(rank(3, nil).stale)
    assert.is_true(rank(4, nil).stale)
  end)

  it("is never Stale without a Price Age", function()
    assert.is_false(rank(nil, 3).stale)
  end)

  it("ignores the age of an AH price that was not chosen", function()
    local data = Fixtures.single({ vendor = { [100] = { name = "Widget", price = 5, where = "Somewhere" } } })
    local rows = Engine.Rank(data, { [100] = { price = 10, age = 30 } }, { staleDays = 3 })
    assert.are.equal(R.VENDOR, rows[1].breakdown[1].route)
    assert.is_false(rows[1].stale)
  end)
end)

describe("Vendor Items", function()
  local vendor = { [100] = { name = "Widget", price = 50, where = "Trade Supplies" } }

  it("prices a Vendor Item with no Scan Price from the vendor table", function()
    local rows = Engine.Rank(Fixtures.single({ quantity = 4, vendor = vendor }), {}, {})
    local row, node = rows[1], rows[1].breakdown[1]
    assert.is_false(row.noData)
    assert.are.equal(200, row.rankCost)
    assert.are.equal(R.VENDOR, node.route)
    assert.are.equal("Trade Supplies", node.vendor.where)
  end)

  it("uses the vendor when it is cheaper than the AH", function()
    local rows = Engine.Rank(Fixtures.single({ vendor = vendor }), { [100] = { price = 80 } }, {})
    assert.are.equal(R.VENDOR, rows[1].breakdown[1].route)
    assert.are.equal(50, rows[1].rankCost)
  end)

  it("uses the AH when it is cheaper than the vendor", function()
    local rows = Engine.Rank(Fixtures.single({ vendor = vendor }), { [100] = { price = 30 } }, {})
    assert.are.equal(R.AH, rows[1].breakdown[1].route)
    assert.are.equal(30, rows[1].rankCost)
  end)

  it("prefers a vendor price the player has seen over the table's fallback", function()
    local rows = Engine.Rank(Fixtures.single({ vendor = vendor }), { [100] = { vendorPrice = 45 } }, {})
    assert.are.equal(45, rows[1].rankCost)
  end)

  it("ignores a seen vendor price for items that are not Vendor Items", function()
    local rows = Engine.Rank(Fixtures.single(), { [100] = { vendorPrice = 45 } }, {})
    assert.is_true(rows[1].noData)
  end)

  it("leaves a non-vendor item without a Scan Price as no data", function()
    local rows = Engine.Rank(Fixtures.single(), {}, {})
    assert.is_true(rows[1].noData)
    assert.is_true(rows[1].breakdown[1].noData)
    assert.is_nil(rows[1].breakdown[1].route)
  end)
end)

describe("hasAnyPrice", function()
  it("is false with no Scan Prices, even when Vendor Items are priced", function()
    local data = Fixtures.single({ vendor = { [100] = { name = "Widget", price = 1, where = "x" } } })
    local _, info = Engine.Rank(data, { [100] = { vendorPrice = 1 } }, {})
    assert.is_false(info.hasAnyPrice)
  end)

  it("is true once any Scan Price exists", function()
    local _, info = Engine.Rank(Fixtures.single(), { [100] = { price = 1 } }, {})
    assert.is_true(info.hasAnyPrice)
  end)
end)
