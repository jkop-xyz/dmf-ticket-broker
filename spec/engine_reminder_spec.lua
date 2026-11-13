local Engine = LoadAddon("Engine.lua").Engine

describe("the Free Ticket Source reminder", function()
  local d = {
    tiers = {},
    sources = {
      { questID = 7905, name = "The Darkmoon Faire", faction = "Alliance", free = true, tickets = 5, items = { { itemID = 9, quantity = 1 } } },
      { questID = 7926, name = "The Darkmoon Faire", faction = "Horde", free = true, tickets = 5, items = { { itemID = 9, quantity = 1 } } },
    },
  }

  local function reminder(character)
    local _, info = Engine.Rank(d, {}, character)
    return info.reminder
  end

  it("is on with a voucher and the faction's quest not done", function()
    assert.are.equal(7905, reminder({ hasVoucher = true, faction = "Alliance" }).questID)
    assert.are.equal(7926, reminder({ hasVoucher = true, faction = "Horde" }).questID)
  end)

  it("is off without a voucher", function()
    assert.is_nil(reminder({ hasVoucher = false, faction = "Alliance" }))
  end)

  it("is off once the faction's quest is done", function()
    assert.is_nil(reminder({ hasVoucher = true, faction = "Horde", completedQuests = { [7926] = true } }))
  end)

  it("ignores the other faction's quest", function()
    assert.is_not_nil(reminder({ hasVoucher = true, faction = "Alliance", completedQuests = { [7926] = true } }))
  end)

  it("never puts Free Ticket Sources in the ranking", function()
    local rows = Engine.Rank(d, {}, { hasVoucher = true, faction = "Alliance" })
    assert.are.equal(0, #rows)
  end)
end)

describe("Free Ticket Source level requirement", function()
  local Engine = LoadAddon("Engine.lua").Engine

  it("waits until the character reaches the voucher quest's level", function()
    local data = {
      tiers = {},
      sources = { { questID = 7926, name = "The Darkmoon Faire", npc = "Gelvas Grimegate", free = true,
        tickets = 5, minLevel = 6, items = { { itemID = 19338, quantity = 1 } } } },
    }
    local _, low = Engine.Rank(data, {}, { level = 5, hasVoucher = true })
    local _, ok = Engine.Rank(data, {}, { level = 6, hasVoucher = true })
    assert.is_nil(low.reminder)
    assert.are.equal(7926, ok.reminder.questID)
  end)
end)
