# 11: Live refresh and no-scan banner

**What to build:** The ranking stays current without a reload. It recomputes when the window opens, after an Auctionator scan (Auctionator's API has no update callback, so this is detected on window open and with a cheap poll while the auction house is open), and when skills, recipes, level, reputation or completed quests change. When Auctionator has no Scan Prices for this realm, the window still opens and shows a banner: "Scan the AH with Auctionator to see prices".

**Blocked by:** 01

**Status:** ready-for-agent

- [x] The ranking recomputes on window open and while the auction house is open, at a modest poll interval that only runs while the AH frame is shown.
- [x] The ranking recomputes on `SKILL_LINES_CHANGED`, recipe learning, level-up, Darkmoon Faire reputation change and quest turn-in, for whichever of those the landed tickets use.
- [x] Recomputing is cheap enough not to cause visible hitches, and an open window updates in place while keeping expanded Breakdowns expanded.
- [x] When no Ticket Source has any Scan Price, the window shows the no-scan banner, which disappears once prices exist.

## Comments

- 2026-11-10: Implemented. The window refreshes on open, on a 5 s poll while the AH is open (AUCTION_HOUSE_SHOW/CLOSED), and on the refresh events. Unknown events are registered through pcall so they can't break loading. Refreshes are throttled to 0.25 s, and expanded rows are kept. Waiting for the end-to-end in-game test (see ../in-game-checklist.md).
