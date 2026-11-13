# 08: Auctionator shopping list export

**What to build:** Each Breakdown has a button that creates an Auctionator shopping list containing exactly the items that Breakdown says to buy on the AH, at the right quantities. Vendor Items and items routed to Craft are left out, but the reagents of crafted items are included when they are routed to AH. The list is named after the Ticket Source and replaces any earlier list with the same name.

**Blocked by:** 07

**Status:** ready-for-agent

- [x] The button collects the AH-routed leaf nodes of the Breakdown tree and adds up the quantities for each item.
- [x] The shopping list is created through `Auctionator.API.v1` (search strings that include quantities), named after the Ticket Source, and replaces an existing list of the same name.
- [x] The player gets confirmation in the window or chat that the list was created.
- [x] A Breakdown with no AH-routed items disables the button.
- [x] The leaf-collection logic is pure and covered by busted tests (summing quantities across a craft tree, excluding vendor and craft-routed nodes).

## Comments

- 2026-11-10: Implemented. ShoppingList is a pure Engine function with busted coverage. The export uses ConvertToSearchString with isExact plus quantity, and falls back to a quoted exact name. Assumption: CreateShoppingList overwrites a list with the same name. Check that in game. Waiting for the end-to-end in-game test (see ../in-game-checklist.md).
