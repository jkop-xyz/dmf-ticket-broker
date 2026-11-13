# 01: Tracer bullet: Buy-only ranking in a window

**What to build:** On WoW: Forever, the player types `/dmft` (or `/dmftickets`) and a basic window opens. It lists every Ticket Source ranked by Buy Cost per Ticket, using Auctionator's latest Scan Prices. Free Ticket Sources are left out, and any source with a missing price shows "no data" and sorts last. This builds the thinnest version of the whole addon: TOC for interface 16001 with Auctionator as a required dependency, the seeded Data module, the pure Engine `Rank(data, prices, character)`, the price adapter, a minimal window and the slash commands. It also sets up the busted / Lua 5.1 test harness. See the spec, Implementation Decisions.

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

- [ ] The addon loads without errors on the Forever client (interface 16001), and Auctionator is declared as a required dependency.
- [x] The Data module holds every non-free Ticket Source (all five Tiers, including the Tier 5 repeatables), the Tier table, and the Free Ticket Source, each marked as unverified vanilla data. The known conflicts listed in the spec are noted next to their entries.
- [x] The Engine is pure Lua with no WoW globals. `Rank` returns rows ordered by Buy Cost per Ticket (the sum of Turn-in Item Scan Prices × quantities, divided by tickets rewarded).
- [x] Rows with any missing Scan Price are flagged "no data" and sort after every priced row.
- [x] Free Ticket Sources never appear in the ranked rows.
- [x] The price adapter uses only `Auctionator.API.v1` (`GetAuctionPriceByItemID`, with numeric item IDs and the addon name as callerID). No Auctionator internals are read.
- [ ] `/dmft` and `/dmftickets` toggle a window showing each row's name, Tier, tickets rewarded, Turn-in Items and Buy Cost per Ticket (formatted as gold, silver and copper).
- [x] busted tests under Lua 5.1 exercise `Rank` with small fixtures: ordering, cost math, "no data" sorting last, and Free Ticket Sources excluded. A smoke test runs the real Data table through `Rank` without errors.

## Comments

- 2026-11-10: Implementation done. The busted suite passes under Lua 5.1 (10 tests), via `scripts/test`. The two unchecked criteria (the addon loads on the Forever client, and the window opens through the slash commands) need a manual in-game check, because the client isn't available here. Auctionator is declared with `## RequiredDeps`. The Free Ticket Voucher item ID (19338) was confirmed from Wowhead Classic.
