# 04: Turn-in Eligibility

**What to build:** Each row in the ranking shows the current character's Turn-in Eligibility as a badge: Eligible, Level Too Low (with the required level), Reputation Too High (the Tier's quest has disappeared at this Darkmoon Faire standing), or Already Done (one-time sources). Ineligible rows stay in the single ranked list, greyed out. Tier 5 repeatable "More …" sources never become Reputation Too High.

**Blocked by:** 01

**Status:** ready-for-agent

- [x] The character adapter supplies player level, Darkmoon Faire reputation standing and completed quest IDs.
- [x] `Rank` gives each row a Turn-in Eligibility based on the Tier's minimum level, the Tier's reputation cap, repeatability and quest completion.
- [x] The window shows the badge on each row, with the required level for Level Too Low, and greys ineligible rows without moving them out of rank order.
- [x] busted tests cover each state, the boundary values for level and reputation cap, and Tier 5 repeatables staying Eligible past the cap.

## Comments

- 2026-11-10: Implemented and covered by busted tests. Reputation comes from C_Reputation.GetFactionDataByID(909).currentStanding, falling back to GetFactionInfoByID. Check the absolute standing values in game. Waiting for the end-to-end in-game test (see ../in-game-checklist.md).
