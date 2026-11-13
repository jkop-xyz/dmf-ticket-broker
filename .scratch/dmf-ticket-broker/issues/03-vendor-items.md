# 03: Vendor Items

**What to build:** Items that NPC vendors sell in unlimited stock are priced from a static Vendor Item table bundled with the addon. Each entry has the price and an example vendor and zone. When an item is both a Vendor Item and has a Scan Price, the cheaper one is used, and the chosen source is labelled ("AH" or the vendor name and zone). A Vendor Item with no AH data still ranks normally. This includes Copper Modulator, which is itself a Turn-in Item.

**Blocked by:** 01

**Status:** ready-for-agent

- [ ] The Data module has a Vendor Item table covering at least Coarse Thread, Fine Thread, Heavy Silken Thread, Green Dye, Salt and Copper Modulator, with a price, vendor name and zone for each. Unverified prices are marked.
- [x] `Rank` prices each item at the minimum of its Scan Price and its Vendor Item price, and records which source won.
- [x] A Vendor Item with no Scan Price is priced, not "no data".
- [x] An item missing from the Vendor Item table that has no Scan Price is still "no data". Limited-stock items are never added to the table.
- [x] The window shows the chosen source for vendor-priced items, including where to buy them.
- [x] busted tests cover: vendor-only pricing, vendor cheaper than AH, AH cheaper than vendor, and non-vendor items without a Scan Price.

## Comments

- 2026-11-10: Implemented. Deviation: Copper Modulator is NOT a Vendor Item. Verification on Wowhead Classic showed Engineering Supplies vendors only carry limited stock, so under the Vendor Item definition (unlimited stock) it stays AH or Craft. Heavy Silken Thread is 20s. Vendor locations are shown as vendor types (e.g. "Trade Supplies") rather than specific NPCs, to avoid naming NPCs that may not exist on Forever. The price adapter prefers the vendor price Auctionator has recorded at a merchant, and falls back to the table. Waiting for the end-to-end in-game test (see ../in-game-checklist.md).
