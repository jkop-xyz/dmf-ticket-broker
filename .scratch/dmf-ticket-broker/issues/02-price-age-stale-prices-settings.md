# 02: Price Age, Stale Prices and settings

**What to build:** Every price in the window shows its Price Age in days. Any Stale Price, meaning one older than the configured threshold, is visibly highlighted. A panel in the game's Options → AddOns menu lets the player change the threshold (default 3 days), and a gear button in the window opens that panel. The threshold persists in account-wide SavedVariables.

**Blocked by:** 01

**Status:** ready-for-agent

- [x] The price adapter supplies Price Age from `GetAuctionAgeByItemID`.
- [x] `Rank` marks each priced item as Stale when its Price Age is above the threshold passed in through `character`. A Price Age equal to the threshold is not Stale.
- [x] The window shows Price Age for each priced item and highlights Stale Prices.
- [x] A settings panel in Options → AddOns has a Stale Price threshold control, defaulting to 3. Changes apply right away and persist across reloads.
- [x] A gear button in the window opens the settings panel.
- [x] busted tests cover Stale at, below and above the threshold.

## Comments

- 2026-11-10: Implemented. Price Age and Stale Prices are covered by busted tests. The settings panel (Settings API) and the gear button are only exercised against the stubbed client; check them in game. Waiting for the end-to-end in-game test (see ../in-game-checklist.md).
