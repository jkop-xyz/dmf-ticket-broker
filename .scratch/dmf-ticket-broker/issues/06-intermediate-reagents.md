# 06: Intermediate Reagents

**What to build:** Crafted reagents inside a recipe (e.g. Handful of Copper Bolts, Heavy and Solid Blasting Powder, Iron Buckle, Cured Light Hide, Solid Grinding Stone) are priced the same way as Turn-in Items: at the cheaper of Buy and Craft (and Vendor Item price when available). Craft is only considered when that sub-recipe is Craftable for the current character. Resolution recurses as deep as the recipes go.

**Blocked by:** 05

**Status:** ready-for-agent

- [x] The Data module holds recipes for every Intermediate Reagent used by a Turn-in Item recipe.
- [x] `Rank` resolves reagent cost recursively, choosing the cheapest available route at every level and respecting each sub-recipe's Craftability and yield.
- [x] A cycle or a missing recipe in the data is handled without infinite recursion. The item falls back to Buy.
- [x] busted tests cover a two-level craft tree where crafting the intermediate is cheaper, one where buying it is cheaper, a non-Craftable intermediate, and "no data" propagating from a leaf.

## Comments

- 2026-11-10: Implemented in the Engine together with ticket 05, with busted coverage including a cycle guard. An item with no route still keeps its attempted craft tree, so the Breakdown can show which reagent lacks a price. Waiting for the end-to-end in-game test (see ../in-game-checklist.md).
