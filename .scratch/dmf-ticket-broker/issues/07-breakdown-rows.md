# 07: Breakdown rows

**What to build:** Clicking a row in the ranking expands it into a Breakdown. The Breakdown lists every item to obtain for that Ticket Source, with its quantity, unit price, chosen route and Price Age. Hovering an item shows its normal game tooltip. The Breakdown renders whatever routes exist when this ticket lands. If tickets 03, 05 or 06 are already done, it must also show vendor locations and the craft tree down through Intermediate Reagents. If they land later, each of those tickets extends the Breakdown for its route.

**Blocked by:** 01

**Status:** ready-for-agent

- [x] `Rank` returns a Breakdown tree for each row: one node per item, with quantity, unit cost, chosen route, Price Age, a Stale flag (if ticket 02 has landed) and a "no data" flag.
- [x] Clicking a row expands or collapses its Breakdown. Several rows can be expanded at once.
- [x] Each Breakdown line shows the item name (handling item data that hasn't loaded yet), quantity, unit price, route and Price Age.
- [x] Hovering a Breakdown item shows its game tooltip.
- [x] busted tests assert on the Breakdown tree's structure and quantities for a simple Buy row and, if ticket 05 has landed, a Craft row.

## Comments

- 2026-11-10: Implemented. The Breakdown shows vendor locations and the craft tree. A stubbed-client smoke test expands every row and hovers every node. The visual layout needs checking in game. Waiting for the end-to-end in-game test (see ../in-game-checklist.md).
