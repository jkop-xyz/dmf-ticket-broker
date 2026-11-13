# DMF Ticket Broker

DMF Ticket Broker is an in-game-only addon for World of Warcraft: Forever (no external tools or exports) that uses Auctionator's auction-house prices to rank the cheapest ways to earn Darkmoon Faire Prize Tickets.

## Language

**Prize Ticket**:
The Darkmoon Prize Ticket, the currency the user wants to earn. On Forever it is a currency, not a bag item as in vanilla.
_Avoid_: Ticket token, DMF currency

**Ticket Source**:
One Darkmoon Faire quest that rewards Prize Tickets in exchange for handing in a fixed bundle of items.
_Avoid_: Turn-in (when meaning the quest), ticket quest

**Free Ticket Source**:
A one-time Ticket Source that costs no gold (the Free Ticket Voucher quest). It is never ranked. Instead the player gets a reminder to accept and hand it in until it is Already Done.
_Avoid_: Voucher quest

**Turn-in Item**:
An item that a Ticket Source requires to be handed in.
_Avoid_: Quest item, reagent (reagents are crafting inputs)

**Cost per Ticket**:
The gold cost of the cheapest way to obtain a Ticket Source's Turn-in Items, divided by the number of Prize Tickets it rewards.
_Avoid_: Ticket price

**Cost per Turn-in**:
The gold cost of the cheapest way to obtain all of a Ticket Source's Turn-in Items for one hand-in, before dividing by Prize Tickets.
_Avoid_: Quest cost, total cost

### Acquisition

**Acquisition Route**:
A way of obtaining a Turn-in Item with gold: either **Buy** or **Craft**. Farming is not an Acquisition Route.

**Buy**:
Purchasing the finished Turn-in Item, from the auction house or, for a Vendor Item, from a vendor (whichever is cheaper).

**Craft**:
Purchasing a Turn-in Item's reagents from the auction house or vendors and crafting it. Only available to a character that has the required profession.

### Character fit

Character fit is always judged for the logged-in character only, never alts.

**Turn-in Eligibility**:
Whether the current character may hand in a Ticket Source: **Eligible**, **Level Too Low**, **Reputation Too High** (the tier's quest has disappeared at the character's Darkmoon Faire standing), **Profession Required** (the quest only accepts characters with a given profession and skill), or **Already Done** (one-time sources). In vanilla no Ticket Source requires a profession, so Profession Required only applies if the game data says so.

**Tier**:
The level band of a Ticket Source (1–5). It sets the tickets rewarded, the minimum level, and the reputation at which the quest disappears. Tier 5 sources include repeatable "More …" variants that never disappear.
_Avoid_: Eligibility (unqualified), can craft

**Craftability**:
Whether the current character can craft a Turn-in Item right now: **Craftable**, **Needs Skill-up** (has the profession but is under the recipe's skill level), **Recipe Unknown** (has the profession but not the recipe), **Not Scanned** (has the profession, but the addon hasn't seen its recipe list yet), or **Missing Profession**. This is separate from Turn-in Eligibility.
_Avoid_: Eligibility, can turn in

**Intermediate Reagent**:
A crafted reagent consumed by another recipe on the way to a Turn-in Item (e.g. Handful of Copper Bolts). It is priced by the cheaper of Buy and Craft, the same way as a Turn-in Item.

### Pricing

**Scan Price**:
The minimum buyout Auctionator recorded for an item in its most recent auction-house scan. It is the only auction-house price used.
_Avoid_: Market price, average price

**Breakdown**:
The expanded view of one Ticket Source. It lists every item to obtain, with quantity, unit price, chosen route and Price Age. It can be exported as an Auctionator shopping list.
_Avoid_: Recipe tree, details

**Stale Price**:
A Scan Price whose Price Age exceeds the user's configured threshold (3 days by default).

**Price Age**:
How many days ago the Scan Price was recorded. It is always shown next to the price.

**Item Origin**:
How a Turn-in Item comes into the game: **crafted**, a **mob drop**, or **sold by a vendor** (including limited-stock and holiday vendors). An item can have several. It is shown to the player for information and does not change any price; only Vendor Items are priced from vendors.

**Vendor Item**:
An item that an NPC vendor sells in unlimited stock at a fixed price. It counts as priced even when Auctionator has no data for it, and the UI says where to buy it.
_Avoid_: Limited-supply item (a vendor item with restocking limited stock is not a Vendor Item)

### Limits and prizes

**Reputation Limit**:
The Darkmoon Faire reputation at which a Tier's non-repeatable quests disappear. Reputation is shared, so a turn-in at any Tier moves the character toward every Tier's limit. Repeatable "More …" quests have no limit and give no reputation.

**Turn-ins Left**:
How many more times the character can hand in a Ticket Source before reaching its Tier's Reputation Limit, counting only that source.

**Prize Reward**:
An item Gelvas Grimegate gives in exchange for Prize Tickets, with its ticket cost.
_Avoid_: Ticket vendor item, prize item

**Ticket Plan**:
The estimated cheapest set of turn-ins that earns a given number of Prize Tickets at current prices, respecting Turn-in Eligibility and Reputation Limits as the plan's own turn-ins use up reputation.

