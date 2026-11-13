# 10: Free Ticket Source reminder

**What to build:** While the player has a Free Ticket Voucher in their bags and the Free Ticket Source isn't Already Done, a reminder line at the top of the window tells them to accept and hand it in. They also get one chat message per session. Both reminders stop once the quest is done. Free Ticket Sources stay out of the ranking.

**Blocked by:** 04

**Status:** ready-for-agent

- [x] The character adapter reports whether a Free Ticket Voucher is in the bags.
- [x] `Rank` returns a reminder state that is on only when a voucher is held and the matching (faction) Free Ticket Source isn't completed.
- [x] The window shows the reminder line while the state is on.
- [x] One chat message is printed per session while the state is on (on login, or when the voucher is picked up), and never more than once.
- [x] busted tests cover the reminder state for voucher held or not, and quest done or not.

## Comments

- 2026-11-10: Implemented. The reminder state is covered by busted tests. The once-per-session chat message is covered by the stubbed-client smoke test. Waiting for the end-to-end in-game test (see ../in-game-checklist.md).
