# 09: Minimap button, Addon Compartment and window polish

**What to build:** The window can also be opened from a LibDBIcon minimap button, which can be dragged around the minimap and hidden, or from an entry in the Addon Compartment. The window is movable and remembers its position, and it shows the character's current Prize Ticket count.

**Blocked by:** 01

**Status:** ready-for-agent

- [x] LibStub, CallbackHandler-1.0, LibDataBroker-1.1 and LibDBIcon-1.0 are embedded. The minimap button toggles the window, and its position and visibility persist.
- [x] If ticket 02 has landed, the settings panel has a "show minimap button" toggle. Otherwise the toggle is added when 02 lands.
- [x] An Addon Compartment entry (global callback function, icon in the TOC) toggles the window.
- [x] The window can be dragged, and its position persists across reloads.
- [x] The window shows the Prize Ticket count from currency 515, falling back to the item count if the currency isn't available.

## Comments

- 2026-11-10: Implemented. LibStub, CallbackHandler-1.0 (8), LibDataBroker-1.1 (4) and LibDBIcon-1.0 (55) are embedded, copied from an addon confirmed working on Forever. Right-clicking the button opens settings. The icon texture path INV_Misc_Ticket_Darkmoon_01 isn't verified, so check it in game. Waiting for the end-to-end in-game test (see ../in-game-checklist.md).
