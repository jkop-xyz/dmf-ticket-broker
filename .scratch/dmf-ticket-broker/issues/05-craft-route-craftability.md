# 05: Craft route and Craftability

**What to build:** For crafted Turn-in Items, the addon works out whether the current character can craft them right now and shows a Craftability badge next to the separate Turn-in Eligibility badge: Craftable, Needs Skill-up, Recipe Unknown, Not Scanned (with a hint to open that profession's window), or Missing Profession. When an item is Craftable, its row also shows a Craft Cost per Ticket, and the rank uses the cheaper of Buy and Craft. Craft cost is the sum of reagent costs divided by the recipe's yield (e.g. Green Firework makes 3). In this ticket every reagent is priced by Buy, or by Vendor Item price if ticket 03 has landed. Known recipes are cached per character the last time each profession window was opened.

**Blocked by:** 01

**Status:** ready-for-agent

- [x] The Data module holds a recipe for every crafted Turn-in Item: profession, required skill, recipe ID, reagents and quantities, and yield.
- [x] The character adapter reads profession skill ranks through `C_SkillInfo`, with `GetProfessions` / `GetProfessionInfo` as a fallback.
- [x] While a profession window is open, the known recipes are captured through `C_TradeSkillUI` and saved per character. A profession with no cached recipes reads as Not Scanned.
- [x] `Rank` gives each crafted Turn-in Item a Craftability state, and computes a Craft cost only when the state is Craftable.
- [x] The ranking cost is the cheaper of Buy and Craft when the item is Craftable, and Buy otherwise. A missing reagent price makes Craft "no data" without hiding a valid Buy.
- [x] The window shows the Craftability badge (with the open-window hint for Not Scanned) and the Craft Cost per Ticket.
- [x] Craftability updates after learning a recipe, gaining skill, or opening a profession window, without a reload.
- [x] busted tests cover each Craftability state blocking or allowing Craft, the min(Buy, Craft) ranking, yield division, and Craft with missing reagent prices.

## Comments

- 2026-11-10: Implemented together with ticket 06: reagents are already resolved recursively. Known recipes are captured by mapping each learned recipe to its output item (GetRecipeSchematic().outputItemID), so the data doesn't need recipe spell IDs. The open profession is identified by GetBaseProfessionInfo().professionID, falling back to its name. Not checked on Forever. Needs Skill-up is checked before Not Scanned/Recipe Unknown, and the glossary wording was adjusted to match. Corrections from Wowhead verification: Toughened Leather Armor needs 2 Cured Light Hide (not 6), and Iron Buckle yields 2. Waiting for the end-to-end in-game test (see ../in-game-checklist.md).
