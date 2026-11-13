# In-game checklist: DMF Ticket Broker

Run this once on the WoW: Forever client. Everything here was built without a client: the Engine is unit-tested, and the rest only ran against a stubbed WoW API.

## Install

1. Copy or symlink `DMFTicketBroker/` into `World of Warcraft/_forever_/Interface/AddOns/`.
2. Make sure Auctionator (Forever build) is installed and enabled.
3. Start the client, or restart it if it was running, so the new folder is detected. Open the AddOns list at character select and check that DMF Ticket Broker is listed and not marked out of date. If it is, compare `/dump select(4, GetBuildInfo())` with `## Interface: 16001`.

## Loading (ticket 01)

- [ ] No Lua error on login. Turn on `/console scriptErrors 1` first, or use BugSack.
- [ ] `/dmft` and `/dmftickets` each toggle the window. Escape closes it.

## Prices (01, 02, 03, 11)

- [ ] Before any Auctionator scan, the window shows the "No prices yet" banner.
- [ ] After a full Auctionator scan, the banner disappears and rows show gold/silver/copper costs per ticket, cheapest first.
- [ ] The "Cost per ticket" / "Cost per turn-in" tabs sit on the same line as "Prize Ticket Sources" and switch the sort order. The active tab is filled gold with white text, the other dark with grey text. There is a single cost column whose header and values follow the active tab. The choice survives `/reload`.
- [ ] With the window open at the AH, prices update within about 5 s after a scan finishes.
- [ ] The window has the round portrait showing the Prize Ticket icon (not a question mark) at the top left, overlapping the panel's corner without covering the section icon or title. If it opens as the old plain frame instead, the portrait template is missing on Forever (not an error).
- [ ] Rows are two-line cards: a grey +/− icon at the far left, the item icon, the source name on top, and underneath "5x <item>  ·  Tier N  ·  <turn-in status>  ·  <craft status>". Craft statuses start with "Craft:" (e.g. "Craft: needs Leatherworking 120"). The list shows whole rows only (the last visible row isn't cut in half), and TICKET SOURCE shows the count, e.g. "(26)".
- [ ] Money shows as e.g. "1g 64s 3c" or "5s" (no trailing "0c") with tinted g/s/c letters; the copper "c" is brown, clearly different from the orange stale "!". CHEAPEST WAY says Auction House, Vendor or Craft. AGE shows the oldest price the row depends on. Alternate rows are visibly different shades.
- [ ] The "No prices yet" banner and the short voucher reminder ("Free Ticket Voucher: hand in … for 5 Prize Tickets.") appear as coloured strips above the column headers, fully visible. Chat still gets the long version.
- [ ] Faded (ineligible) rows: the name, costs and item text fade, but the red reason stays fully readable.
- [ ] Ticking "Can turn in only" (next to the tabs) hides rows you can't turn in and the header shows "(N of 26)". Unticking brings them back. It is unticked by default and survives `/reload`.
- [ ] An expanded row gets a gold bar on its left and a darker panel underneath: the Buy line (and Craft line), with a green "cheapest" tag on the one in use, then ITEM / EACH / TOTAL / CHEAPEST WAY / AGE headers, the items with small icons, and finally the Shopping list button with a note on how many Auction House items it adds. Only rows and items highlight on hover.
- [ ] Price Age shows "today" or "Nd" in the AGE columns. Set the stale threshold to 1 in settings and check that older ages turn orange and get a "!".
- [ ] Thread, Green Dye and Salt show "Vendor" in Breakdowns (hover: the tooltip names Edna Mullby in Stormwind City for Alliance, Shimra in Orgrimmar for Horde) even with no AH listing.

## Eligibility (04)

- [ ] Capped rows show "N turn-ins left" on their status line; repeatable "More …" rows show "No limit". The row tooltip shows your Darkmoon Faire reputation against the tier's limit (e.g. "Reputation 250 of 500 (+100 per turn-in)"). Hand one in and check the count drops by one and the reputation by 100. If a turn-in gives a different amount, fix `rep` in Data.tiers.

- [ ] Hovering a row lists under "Hand in" how the item is obtained: e.g. Torn Bear Pelt "Mob drop", Copper Modulator "Crafted with Engineering (65)", "Mob drop" and "Sold by Engineering Supplies vendors (limited stock)", Green Firework also "Sold by Holiday Fireworks Vendors".
- [ ] Confirm on Forever that no turn-in quest needs a profession (try handing in a crafted item on a character without that profession). If one does, add `requiresProfession` to it in Data.lua: its whole row then turns grey with "Needs <Profession> N to turn in".

- [ ] Rows show "Can turn in", "Needs level N" or "Reputation too high" correctly for your level and Darkmoon Faire standing. Ineligible rows are greyed but stay in rank order.
- [ ] Tier 5 "More …" quests stay "Can turn in".

## Professions (05, 06)

- [ ] For a profession you have but haven't opened yet, the status line says "Craft: open <Profession> to check".
- [ ] Open the profession window once. Rows switch to "Can craft", "Craft: recipe unknown" or "Craft: needs <Profession> N". Check after `/reload` that this is remembered.
- [ ] A Craftable row shows a Craft cost in its tooltip and a second Breakdown summary line, and the tooltip says whether crafting or buying is cheaper, and ranks by the cheaper of Buy and Craft.
- [ ] A crafted item you can't craft yet (e.g. Carnival Jerkins, "Craft: needs Leatherworking 120") still shows "Craft (not ranked): … per ticket (… per turn-in)" in its tooltip, followed once by why you can't craft it and whether crafting would be cheaper. The Breakdown's Craft line says "not ranked: you need Leatherworking 120". The tooltip's Buy line reads "Buy: 6s per ticket (24s per turn-in)".
- [ ] Column headers (TICKET SOURCE, TICKETS, COST PER …, CHEAPEST WAY, AGE, and the Breakdown's ITEM / EACH / TOTAL …) are gold and easy to read.
- [ ] Intermediate Reagents (e.g. Handful of Copper Bolts, Heavy Blasting Powder) show their own craft tree in the Breakdown when crafting them is cheaper.
- [ ] Learning a new recipe updates the row without a `/reload`.

## Breakdown and shopping list (07, 08)

- [ ] Clicking a row expands or collapses its Breakdown. Hovering an item shows its game tooltip.
- [ ] "Shopping list" creates an Auctionator list named "DMF: <source>" with the AH items and quantities. Clicking it again replaces the list rather than duplicating it.
- [ ] The button is disabled when nothing needs to be bought on the AH.

## Access and polish (09, 02)

- [ ] The minimap button shows the ticket icon (not a green square) and can be dragged. Left-click opens the window, right-click opens settings.
- [ ] The Addon Compartment (the minimap dropdown) lists DMF Ticket Broker and opens the window.
- [ ] Options → AddOns → DMF Ticket Broker has the stale threshold slider and the "Hide minimap button" checkbox. Both work and persist after `/reload`.
- [ ] The gear button at the top right of the panel opens the settings.
- [ ] The window can be dragged and keeps its position after `/reload`.
- [ ] The Prize Ticket count at the top right of the panel matches your currency tab. The footer legend under the panel fits on one line.

## Free Ticket Source (10)

- [ ] With a Free Ticket Voucher in your bags (and the quest not done), the window shows the reminder line and chat shows one message per session.
- [ ] After handing it in, both reminders stop.

## Data to confirm while you're there

Wowhead's Forever data (saved in `.scratch/wowhead/`, checked 2026-11-13) already confirms the turn-in items, tickets, reputation and levels of every tier quest, the prize costs, the vendor items and the recipes. Only these remain:

- **"More …" quests (most important):** hand one in (e.g. More Bat Eyes) and check whether you get 20 Prize Tickets. Wowhead's Forever data suggests they may give none. If they do give 20, remove `doubtful` from them in Data.lua. If not, they should be dropped from the ranking.
- Reputation limits: tier 2 is confirmed at 1,100 (2026-11-13). Are tier 1 quests still offered between 500 and 600 reputation (500 or 600)? At what standing do the non-repeatable tier 5 quests disappear (5,999 into Friendly?), and do they still give reputation near it?
- Coarse Weightstone: Wowhead lists only 1 Coarse Stone as its reagent (no Wool Cloth). Check the recipe in your Blacksmithing window.

Fix any wrong values in `DMFTicketBroker/Data.lua`. Nothing else hardcodes game data.

## Prize Rewards

- [ ] Two tabs hang under the window, "Ticket Sources" and "Prize Rewards". The active one is filled gold. The choice survives `/reload`.
- [ ] Prize Rewards lists ten prizes with their icons and ticket costs (5 Flower, 5 Minor Prize, 10 Last Month's Mutton, 12 Lesser Prize, 40 Greater Prize, 40 Steam Tonk schematic, 50 Storage Box, 50 Last Year's Mutton, 1200 Orb, 1200 Amulet). Compare them with Gelvas Grimegate's vendor window in game.
- [ ] STILL NEEDED is your ticket count subtracted from the cost; prizes you can afford say "You have enough tickets". Prizes whose item you can't use yet say "Usable from level N" in yellow (e.g. Orb of the Darkmoon: 60) but aren't faded, since buying them has no level requirement.
- [ ] GOLD FOR THE REST shows "about …"; the tooltip lists the turn-ins that make it up and their total. With few quests available it says "not reachable yet" and explains why.

