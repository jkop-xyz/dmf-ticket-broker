-- Smoke test: load the whole addon against a stubbed WoW API and drive it.
-- This checks wiring only; real behaviour still needs the in-game checklist.
insulate("the addon in a stubbed client", function()
  dofile("spec/support/wow_stub.lua")

  local state = {
    level = 60, faction = "Horde", reputation = 0, tickets = 42,
    bags = { [19338] = 1 },
    skillLines = {
      { skillID = 202, name = "Engineering", rank = 300, isHeader = false },
    },
    prices = {
      [5134] = { price = 50, age = 0 },
      [9313] = { price = 5000, age = 6 },
      [4377] = { price = 10, age = 1 },
      [4234] = { price = 20, age = 1 },
    },
  }

  local ns

  setup(function()
    WowStub.Install(state)
    ns = WowStub.LoadTOC("DMFTicketBroker/", "DMFTicketBroker")
    WowStub.Fire("ADDON_LOADED", "DMFTicketBroker")
    WowStub.Fire("PLAYER_ENTERING_WORLD")
    WowStub.FlushTimers()
  end)

  it("initializes SavedVariables with defaults", function()
    assert.are.equal(3, DMFTicketBrokerDB.staleDays)
    assert.is_false(DMFTicketBrokerDB.minimap.hide)
  end)

  it("registers the slash commands", function()
    assert.are.equal("/dmft", SLASH_DMFTICKETBROKER1)
    assert.are.equal("/dmftickets", SLASH_DMFTICKETBROKER2)
    assert.is_function(SlashCmdList.DMFTICKETBROKER)
  end)

  it("defines the Addon Compartment callbacks as globals", function()
    assert.is_function(DMFTicketBroker_OnAddonCompartmentClick)
    assert.is_function(DMFTicketBroker_OnAddonCompartmentEnter)
    assert.is_function(DMFTicketBroker_OnAddonCompartmentLeave)
  end)

  it("prints the Free Ticket Source reminder once per session", function()
    local function count()
      local n = 0
      for _, line in ipairs(WowStub.printed) do
        if line:find("Free Ticket Voucher", 1, true) then n = n + 1 end
      end
      return n
    end
    assert.are.equal(1, count())
    WowStub.Fire("BAG_UPDATE_DELAYED")
    WowStub.FlushTimers()
    assert.are.equal(1, count())
  end)

  it("opens the window from the slash command and shows the ranking", function()
    SlashCmdList.DMFTICKETBROKER("")
    assert.is_true(DMFTicketBrokerFrame:IsShown())
    assert.is_true(ns.UI.IsShown())
  end)

  it("caches known recipes from the open profession window", function()
    state.openProfession = { professionID = 202, professionName = "Engineering" }
    state.recipeIDs = { 1001, 1002 }
    state.learned = { [1001] = true, [1002] = true }
    state.recipeOutputs = { [1001] = 9313, [1002] = 4377 }
    WowStub.Fire("TRADE_SKILL_SHOW")
    WowStub.FlushTimers()
    assert.is_true(DMFTicketBrokerCharDB.knownRecipes.Engineering[9313])
    assert.is_true(DMFTicketBrokerCharDB.knownRecipes.Engineering[4377])
  end)

  it("ranks Green Fireworks by Craft once the recipe is known", function()
    local rows = ns.Engine.Rank(ns.Data, ns.Prices.Snapshot(ns.Data), ns.Character.Snapshot())
    local fireworks
    for _, row in ipairs(rows) do
      if row.source.questID == 7896 then fireworks = row end
    end
    assert.are.equal(ns.Engine.CRAFTABILITY.CRAFTABLE, fireworks.craftability)
    assert.are.equal(ns.Engine.ROUTE.CRAFT, fireworks.breakdown[1].route)
    -- 12 crafts x (10 + 20)
    assert.are.equal(360 / 8, fireworks.rankCost)
  end)

  it("renders expanded Breakdowns and exports a shopping list", function()
    ns.UI.Refresh()
    -- Expand every row through the same click path the player uses.
    local function collapsedRow()
      for _, w in ipairs(WowStub.created) do
        if w.kind == "row" and w:IsShown() and not w.expanded then return w end
      end
    end
    local clicked = 0
    for _ = 1, 100 do
      local w = collapsedRow()
      if not w then break end
      w:Click()
      clicked = clicked + 1
    end
    assert.is_true(clicked >= 20)
    local summaries, shoppingButtons = 0, 0
    for _, w in ipairs(WowStub.created) do
      if w.kind == "shop" and w:IsShown() then
        summaries = summaries + 1
        if w.button:IsShown() then shoppingButtons = shoppingButtons + 1 end
      end
      if (w.kind == "node" or w.kind == "row" or w.kind == "summary") and w:IsShown() and w._scripts.OnEnter then
        w._scripts.OnEnter(w)
      end
      if w.kind == "shop" and w:IsShown() then
        w.button._scripts.OnEnter(w.button)
      end
    end
    assert.are.equal(clicked, summaries)
    assert.are.equal(summaries, shoppingButtons)
    local rows = ns.Engine.Rank(ns.Data, ns.Prices.Snapshot(ns.Data), ns.Character.Snapshot())
    assert.is_true(#rows > 0)
    local fireworks
    for _, row in ipairs(rows) do
      if row.source.questID == 7896 then fireworks = row end
    end
    ns.Shopping.Create(fireworks)
    local terms = WowStub.shoppingLists["DMF: Green Fireworks"]
    assert.is_table(terms)
    table.sort(terms)
    assert.are.same({ "Heavy Blasting Powder;12", "Heavy Leather;12" }, terms)
  end)

  it("sorts by Cost per Turn-in from the column header and remembers it", function()
    local function header(sortBy)
      return DMFTicketBrokerFrame.sortTabs[sortBy]
    end
    assert.are.equal("perTicket", DMFTicketBrokerDB.sortBy)
    header("perTurnIn"):Click()
    assert.are.equal("perTurnIn", DMFTicketBrokerDB.sortBy)
    local shownCosts = {}
    for _, w in ipairs(WowStub.created) do
      if w.kind == "row" and w:IsShown() and w.data and not w.data.noData then
        shownCosts[#shownCosts + 1] = w.data.turnInCost
      end
    end
    assert.is_true(#shownCosts > 1)
    for i = 2, #shownCosts do
      assert.is_true(shownCosts[i - 1] <= shownCosts[i])
    end
    header("perTicket"):Click()
    assert.are.equal("perTicket", DMFTicketBrokerDB.sortBy)
  end)

  it("greys out a quest that needs a profession the character lacks", function()
    local source = ns.Data.sources[1]
    source.requiresProfession = { profession = "Blacksmithing", skill = 50 }
    ns.UI.Refresh()
    local greyRows = 0
    for _, w in ipairs(WowStub.created) do
      if w.kind == "row" and w:IsShown() and w.data.source == source then
        assert.are.equal(ns.Engine.ELIGIBILITY.PROFESSION_REQUIRED, w.data.eligibility.state)
        w._scripts.OnEnter(w)
        greyRows = greyRows + 1
      end
    end
    assert.are.equal(1, greyRows)
    source.requiresProfession = nil
    ns.UI.Refresh()
  end)

  it("hides sources the character can't turn in when 'Can turn in only' is ticked", function()
    local function shownRows()
      local n = 0
      for _, w in ipairs(WowStub.created) do
        if w.kind == "row" and w:IsShown() then n = n + 1 end
      end
      return n
    end
    state.level = 5  -- only tier 1 (level 1) quests are eligible
    ns.UI.Refresh()
    local all = shownRows()
    DMFTicketBrokerDB.eligibleOnly = true
    ns.UI.Render()
    local tier1 = 0
    for _, source in ipairs(ns.Data.sources) do
      if source.tier == 1 then tier1 = tier1 + 1 end
    end
    assert.are.equal(tier1, shownRows())
    assert.is_true(all > tier1)
    DMFTicketBrokerFrame.eligibleOnly:Click()  -- the stub reports it unticked
    assert.is_false(DMFTicketBrokerDB.eligibleOnly)
    assert.are.equal(all, shownRows())
    state.level = 60
    ns.UI.Refresh()
  end)

  it("shows the Prize Rewards view from its tab and back", function()
    ns.UI.Refresh()
    DMFTicketBrokerFrame.viewTabs.rewards:Click()
    assert.are.equal("rewards", DMFTicketBrokerDB.view)
    local rewards = {}
    for _, w in ipairs(WowStub.created) do
      if w.kind == "reward" and w:IsShown() then
        rewards[#rewards + 1] = w
        w._scripts.OnEnter(w)
      end
    end
    assert.are.equal(#ns.Data.rewards, #rewards)
    -- 42 tickets: the 5-ticket Darkmoon Flower is affordable, the 1200-ticket Orb isn't.
    local byName = {}
    for _, w in ipairs(rewards) do byName[w.data.reward.name] = w.data end
    assert.is_true(byName["Darkmoon Flower"].affordable)
    assert.are.equal(1158, byName["Orb of the Darkmoon"].missing)
    DMFTicketBrokerFrame.viewTabs.sources:Click()
    assert.are.equal("sources", DMFTicketBrokerDB.view)
  end)

  it("survives the refresh events", function()
    for _, event in ipairs({ "SKILL_LINES_CHANGED", "PLAYER_LEVEL_UP", "UPDATE_FACTION", "QUEST_TURNED_IN",
      "CURRENCY_DISPLAY_UPDATE", "MERCHANT_CLOSED", "AUCTION_HOUSE_SHOW", "AUCTION_HOUSE_CLOSED",
      "ITEM_DATA_LOAD_RESULT", "NEW_RECIPE_LEARNED" }) do
      WowStub.Fire(event, 1001)
    end
    WowStub.FlushTimers()
  end)

  it("opens settings from the compartment's right-click", function()
    WowStub.settingsOpened = false
    DMFTicketBroker_OnAddonCompartmentClick(nil, "RightButton")
    assert.is_true(WowStub.settingsOpened)
  end)

  it("closes the window on a second toggle", function()
    SlashCmdList.DMFTICKETBROKER("")
    assert.is_false(DMFTicketBrokerFrame:IsShown())
  end)
end)
