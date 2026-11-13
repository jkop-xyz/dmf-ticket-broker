Status: ready-for-agent

# Spec: DMF Ticket Broker

## Problem Statement

On World of Warcraft: Forever I want to earn Darkmoon Faire Prize Tickets as cheaply as possible. There are around twenty Ticket Sources across five Tiers. Each one needs a different bundle of Turn-in Items, and many of those can be bought on the auction house, crafted from reagents, or bought partly from vendors. Auctionator already has the auction-house prices, but working out the Cost per Ticket for every source means a lot of manual arithmetic. On top of that I have to keep track of which quests my character can still hand in at its level and Darkmoon Faire reputation, and which items it can craft. Existing tools work outside the game on exported SavedVariables, so they're always out of date and need me to leave the game.

## Solution

DMF Ticket Broker is an in-game addon. It reads Auctionator's latest Scan Prices and ranks every Ticket Source by Cost per Ticket in one window, opened by slash command, minimap button or Addon Compartment. For each Turn-in Item and Intermediate Reagent it takes the cheapest of AH, Vendor Item and Craft, where Craft is only considered when the current character can craft the item right now. Every row shows the character's Turn-in Eligibility and Craftability as separate badges, shows the Price Age of every price, and highlights Stale Prices. A row expands into a Breakdown, which I can export as an Auctionator shopping list. Free Ticket Sources aren't ranked. Instead the addon reminds me to accept and hand them in.

## User Stories

1. As a player, I want to open a window with `/dmft` or `/dmftickets`, so that I can check ticket costs at any time.
2. As a player, I want a minimap button for the window, so that I can open it with one click the way I open other addons.
3. As a player, I want the window listed in the Addon Compartment, so that I can open it even when I've hidden the minimap button.
4. As a player, I want to drag the minimap button around the minimap and hide it, so that it fits my UI layout.
5. As a player, I want every Ticket Source in one list ranked by Cost per Ticket, cheapest first, so that I can see the best deal at a glance.
6. As a player, I want each row to show the Ticket Source name, its Tier, the tickets rewarded and the Turn-in Items needed, so that I know what the quest involves.
7. As a player, I want each row to show the Buy cost per ticket, so that I know what buying the finished items costs.
8. As a player with the right profession, I want each row to also show the Craft cost per ticket when the item is Craftable, so that I can compare crafting with buying.
9. As a player, I want the rank to use the cheaper of Buy and Craft when the item is Craftable, and Buy otherwise, so that the order matches what I can actually do.
10. As a player, I want Craft costs to include Intermediate Reagents priced at the cheaper of buying and crafting them, so that the craft price is realistic (e.g. Handful of Copper Bolts, Blasting Powder, Iron Buckle).
11. As a player, I want recipes that make more than one item (e.g. Green Firework makes 3) to be costed per item produced, so that I don't overpay in the calculation.
12. As a player, I want Vendor Items (unlimited-stock vendor goods) priced at their vendor price even when Auctionator has no data, so that sources that use thread or dye still get ranked.
13. As a player, I want an item that is both a Vendor Item and on the AH to use whichever is cheaper, with the chosen source labelled, so that I always see the true cheapest route.
14. As a player, I want to see where a Vendor Item can be bought (an example vendor and zone), so that I know where to go.
15. As a player, I want a finished Turn-in Item that's a Vendor Item (e.g. Copper Modulator) treated the same way, so that vendor-buyable turn-ins rank correctly.
16. As a player, I want items with no Scan Price that aren't Vendor Items shown as "no data", so that the addon never guesses a price.
17. As a player, I want any Ticket Source whose cheapest available route has missing data to sort to the bottom, so that incomplete rows don't push out reliable ones.
18. As a player, I want every price to show its Price Age, so that I can judge how far to trust it.
19. As a player, I want Stale Prices visibly highlighted, so that I know to rescan before acting on them.
20. As a player, I want to set the Stale Price threshold (3 days by default), so that it matches how often I scan.
21. As a player, I want a Turn-in Eligibility badge on each row (Eligible, Level Too Low with the required level, Reputation Too High, Already Done), so that I know whether I can hand the source in at all.
22. As a player, I want sources I'm not eligible for to stay in the same list but greyed out, so that I still see their prices without mistaking them for options.
23. As a player whose reputation has passed a Tier's cap, I want the Tier 5 repeatable "More …" sources to still show as Eligible, so that I always have a working option.
24. As a player, I want a Craftability badge on each crafted Turn-in Item (Craftable, Needs Skill-up, Recipe Unknown, Not Scanned, Missing Profession), shown separately from Turn-in Eligibility, so that I know whether I could make it myself and why not.
25. As a player, I want the addon to remember my known recipes from the last time I opened each profession window, so that Craftability works without reopening the window every session.
26. As a player who hasn't opened a profession window yet, I want Craftability to say Not Scanned and tell me to open that profession, so that I know how to fix it.
27. As a player, I want Craftability to update right after I learn a recipe or gain skill, so that the ranking stays current.
28. As a player, I want everything judged for my current character only, so that the list reflects what this character can do.
29. As a player, I want to expand a row into a Breakdown that lists every item to obtain, with quantity, unit price, chosen route (AH, vendor and where, or craft) and Price Age, so that I have a complete shopping plan.
30. As a player, I want the Breakdown to show the craft tree down through Intermediate Reagents when Craft is chosen, so that I know what to buy for each step.
31. As a player, I want a button on each Breakdown that creates an Auctionator shopping list with the AH items and quantities for that source, so that I can buy everything in a few clicks.
32. As a player, I want the shopping list to leave out Vendor Items and items routed to Craft, so that it contains only what I should buy on the AH.
33. As a player, I want Free Ticket Sources (the Free Ticket Voucher quest) left out of the ranking, so that a zero-cost one-time quest doesn't distort the list.
34. As a player with a Free Ticket Voucher in my bags who hasn't done the quest, I want a reminder line at the top of the window, so that I don't forget the free tickets.
35. As a player with a Free Ticket Voucher, I want one chat reminder per session, so that I notice it even when the window is closed.
36. As a player who has done the Free Ticket Source, I want the reminders to stop, so that I'm not nagged.
37. As a player with no Auctionator scan data for this realm, I want the window to still open with a banner telling me to scan the AH, so that I know why the prices are missing.
38. As a player, I want the ranking to refresh after an Auctionator scan without a reload, so that I see new prices right away.
39. As a player, I want the window to show my current Prize Ticket count, so that I know how many I already have.
40. As a player, I want the settings (Stale Price threshold, minimap button visibility) in the game's Options → AddOns panel, so that I find them in the usual place.
41. As a player, I want a gear button in the window that opens those settings, so that I can reach them quickly.
42. As a player, I want hovering an item in a row or Breakdown to show its normal item tooltip, so that I can inspect it.
43. As a player, I want the window to be movable and remember its position, so that it doesn't get in my way.
44. As a player, I want item names shown in my client's language, so that the addon works on non-English clients without translation.
45. As a maintainer, I want quest, Tier, recipe and Vendor Item data kept in one static data table, so that I can fix it when Forever turns out to differ from vanilla.

## Implementation Decisions

- **Target client.** WoW: Forever, interface 16001, which uses the modern Mainline API family. Classic Era flavors are not supported. Use `C_Item`, `C_CurrencyInfo`, `C_SkillInfo` and `C_TradeSkillUI`, not removed globals such as `GetItemInfo` and `GetNumSkillLines`. Item data may arrive asynchronously (`ITEM_DATA_LOAD_RESULT`), and the UI must cope with names that haven't loaded yet.
- **Dependencies.** Auctionator is a required dependency. LibStub, CallbackHandler-1.0, LibDataBroker-1.1 and LibDBIcon-1.0 are embedded for the minimap button.
- **Modules:**
  - **Data**: static, editable tables:
    - Ticket Sources: ID, name, Tier, tickets rewarded, Turn-in Items and quantities, repeatable or one-time, Free flag.
    - Tiers: tickets, minimum level, reputation cap.
    - Recipes for every Turn-in Item and Intermediate Reagent: profession, required skill, reagents and quantities, yield, recipe ID.
    - Vendor Items: item, price, example vendor and zone.
    - Seeded from vanilla data and marked as unverified for Forever. Known conflicts to check in game: Copper Modulator ×5 or ×3, Big Black Mace ×1 or ×3, Coarse Weightstone reagents, and the ID of the repeatable "More Dense Grinding Stones" quest.
  - **Engine**: pure Lua with no WoW API access, and the single test seam. Its interface is `Rank(data, prices, character)`:
    - `prices`: a lookup from item ID to Scan Price (copper) and Price Age (days), or nil.
    - `character`: level, Darkmoon Faire reputation, completed quest IDs, Free Ticket Voucher held, skill rank per profession, cached known recipe IDs per profession (absent means Not Scanned), and the Stale Price threshold.
    - Returns ordered rows, each with:
      - Ticket Source, Turn-in Eligibility, Buy cost per ticket, Craft cost per ticket (if any), ranking cost, and a "no data" flag.
      - A Breakdown tree in which each node has item, quantity, unit cost, chosen route (AH / Vendor with location / Craft) with Craftability, Price Age and a Stale flag.
      - Separately, the Free Ticket Source reminder state.
  - **Pricing rules in the Engine:**
    - An item's cost is the minimum over the available routes: AH Scan Price, Vendor Item price, and Craft (only when Craftable), resolved recursively through Intermediate Reagents.
    - Craft cost is the sum of reagent costs divided by the recipe's yield.
    - When no route is available, the result is "no data".
    - The ranking cost is the cheaper of Buy and Craft when Craftable, and Buy otherwise.
    - Rows with "no data" sort last.
  - **Price adapter**: builds `prices` from `Auctionator.API.v1.GetAuctionPriceByItemID` and `GetAuctionAgeByItemID` with the addon's name as `callerID`. It uses no Auctionator internals and no price history (ADR 0002).
  - **Character adapter**: builds `character` from:
    - player level and Darkmoon Faire faction standing
    - completed quests (`C_QuestLog.IsQuestFlaggedCompleted`)
    - bag contents for the Free Ticket Voucher
    - `C_SkillInfo` skill lines, with `GetProfessions` / `GetProfessionInfo` as a fallback
    - known recipes, captured from `C_TradeSkillUI` while a profession window is open (`TRADE_SKILL_SHOW` / `TRADE_SKILL_LIST_UPDATE`) and cached per character in SavedVariables.
    - It reads the Prize Ticket count from `C_CurrencyInfo` (currency 515), falling back to the item count.
  - **UI**:
    - A movable main window whose position is saved, with a ranked list, expandable Breakdown rows, Turn-in Eligibility and Craftability badges, greyed ineligible rows, Price Age display, Stale highlighting, the no-scan banner, the Free Ticket Source reminder line, the ticket count, and a gear button.
    - A LibDBIcon minimap button and an Addon Compartment entry (`AddonCompartmentFunc` must be a global function).
    - Slash commands `/dmft` and `/dmftickets`.
    - A settings panel in Options → AddOns through the Settings API.
  - **Shopping list export**: turns a Breakdown's AH-routed leaf items and quantities into an Auctionator shopping list through `Auctionator.API.v1.CreateShoppingList`. The list is named after the Ticket Source and replaces any earlier list with the same name.
  - **Reminder**: one chat message per session while the Free Ticket Source reminder state is active.
- **Refresh.** Recompute the ranking when the window opens, after an Auctionator scan finishes (watch for price changes on window open or with a cheap poll while the AH is open, because the API has no update callback), and on `SKILL_LINES_CHANGED`, recipe learning, level-up, reputation change and quest turn-in.
- **SavedVariables.** Use account-wide settings (Stale Price threshold, minimap button state, window position) plus a per-character known-recipe cache. Initialize them on `ADDON_LOADED`.
- **No external tools.** Everything is computed in game, and the addon has no export to websites (ADR 0001).

## Testing Decisions

- A good test drives the Engine only through `Rank(data, prices, character)` and asserts on the returned rows: order, costs, chosen routes, badges and flags. Tests must not reach into helper functions or internal tables, so the internals can be restructured freely.
- The Engine is tested with busted under plain Lua 5.1, outside the game. Tests use small hand-built `data`, `prices` and `character` fixtures rather than the real data table, so that corrections to the data never break tests. One additional smoke test runs the real data table through `Rank` to catch malformed entries such as missing recipes or non-numeric quantities.
- Cases to cover:
  - ordering by Cost per Ticket
  - min of Buy and Craft only when Craftable
  - each Craftability state blocking Craft
  - recursive Intermediate Reagent pricing
  - yield division
  - Vendor Item fallback when there's no Scan Price
  - choosing the cheaper of vendor and AH, with the source labelled
  - "no data" propagation and sorting last
  - Stale flag at, below and above the threshold
  - each Turn-in Eligibility state, including Tier 5 repeatables staying Eligible
  - Free Ticket Sources left out of the ranking, with the reminder state on or off depending on whether the voucher is held and the quest is done.
- The adapters, UI, shopping-list export and chat reminder aren't unit-tested. They get a manual in-game checklist: every way to open the window, a scan refreshing the prices, the Not Scanned → Craftable transition after opening a profession window, shopping-list creation, the reminder, and the settings panel.
- There is no prior art: the repo is empty, so this spec establishes the test layout.

## Out of Scope

- Any external tool, website or SavedVariables export (ADR 0001).
- Auctionator price history or averaging. Only the latest Scan Price is used (ADR 0002).
- Alts and account-wide profession data. Only the current character counts.
- Farming as an Acquisition Route, and time or opportunity-cost estimates.
- Planning toward a target ticket count or a specific prize.
- AH depth or quantity awareness. The minimum buyout is assumed to be available in any quantity.
- Limited-stock vendor items. They aren't Vendor Items and show as "no data" unless the AH has them.
- Classic Era, Season of Discovery, Anniversary and retail clients.
- Automatically buying from the AH or vendors.

## Further Notes

- The quest, Tier and recipe data is assumed to match vanilla until it's checked in game. The Data module should make corrections trivial.
- On Forever, Prize Tickets are a currency (515), not item 19182.
- Auctionator keeps separate auction houses for PvE, PvP, Hardcore and RP rulesets on Forever. Its public API already returns prices for the current one.
- `Auctionator.API.v1` item-ID functions throw on non-number arguments, so the price adapter must always pass numbers.
- A similar external web tool, `TheoSchramm/wow-dmf-calculator`, is useful for cross-checking quest and recipe data.
