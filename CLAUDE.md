## Agent skills

### Issue tracker

Issues and specs live as local markdown files under `.scratch/<feature>/`. See `docs/agents/issue-tracker.md`.

### Triage labels

Default vocabulary (`needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`), recorded as a `Status:` line in each issue file. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: one `GLOSSARY.md` and `docs/adr/` at the repo root. See `docs/agents/domain.md`.

## Development

- The addon lives in `DMFTicketBroker/` and targets WoW: Forever (`## Interface: 16001`, modern Mainline API).
- Run the tests with `scripts/test` (busted under Lua 5.1).
- `Engine.Rank(data, prices, character)` is the single test seam. Keep `Engine.lua` and `Data.lua` free of WoW API calls.
- All game facts (quests, tiers, recipes, Vendor Items) live in `DMFTicketBroker/Data.lua`.
