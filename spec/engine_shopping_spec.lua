local Engine = LoadAddon("Engine.lua").Engine

describe("Engine.ShoppingList", function()
  local d = {
    tiers = { [1] = { tickets = 1 } },
    sources = {
      { questID = 1, name = "Kit", tier = 1, items = {
        { itemID = 100, name = "Widget", quantity = 2 },
        { itemID = 600, name = "Thread", quantity = 3 },
      } },
    },
    recipes = {
      [100] = { name = "Widget", profession = "Engineering", skill = 1, yield = 1, reagents = {
        { itemID = 300, name = "Cloth", quantity = 2 },
        { itemID = 200, name = "Gear", quantity = 1 } } },
      [200] = { name = "Gear", profession = "Engineering", skill = 1, yield = 1, reagents = {
        { itemID = 300, name = "Cloth", quantity = 1 } } },
    },
    vendor = { [600] = { name = "Thread", price = 1, where = "Trade Supplies" } },
  }
  local engineer = Fixtures.engineer(300, { [100] = true, [200] = true })

  it("lists AH-routed leaves through the craft tree, summing quantities per item", function()
    local row = Engine.Rank(d, { [100] = { price = 1000 }, [200] = { price = 1000 }, [300] = { price = 1 } }, engineer)[1]
    -- 2 Widgets crafted: 4 Cloth + 2 Gear crafted (2 more Cloth) = 6 Cloth
    assert.are.same({ { itemID = 300, name = "Cloth", quantity = 6 } }, Engine.ShoppingList(row))
  end)

  it("leaves out Vendor Items and no-data items", function()
    local row = Engine.Rank(d, { [100] = { price = 5 } }, {})[1]
    assert.are.same({ { itemID = 100, name = "Widget", quantity = 2 } }, Engine.ShoppingList(row))
  end)

  it("is empty when nothing comes from the AH", function()
    local row = Engine.Rank(d, {}, {})[1]
    assert.are.same({}, Engine.ShoppingList(row))
  end)
end)
