# DMF Ticket Broker

A World of Warcraft: Forever addon that works out the cheapest way to earn Darkmoon Faire Prize Tickets, using your [Auctionator](https://www.curseforge.com/wow/addons/auctionator) prices. Everything happens in game: no external tools or exports.

## Features

- **Cheapest turn-ins:** ranks every Prize Ticket quest by cost per ticket or per turn-in, from the latest Auctionator scan, with the age of each price.
- **Buy or craft:** if your character can craft a turn-in item (or a reagent in it), the cheaper of buying and crafting is used. Vendor-bought reagents are priced from the vendor.
- **Can you turn it in?** Each quest shows whether your character's level and Darkmoon Faire reputation allow it, and how many turn-ins are left before the tier's reputation limit.
- **Breakdown:** click a quest to see every item and reagent, where to get it and what it costs, and create an Auctionator shopping list from it.
- **Prize Rewards:** everything Gelvas Grimegate sells for tickets, how many tickets you're missing, and roughly what they would cost in gold.
- **Free Ticket Voucher reminder:** a reminder in the window and in chat while you carry an unused voucher.

## Install

1. Install Auctionator for WoW: Forever.
2. Download `DMFTicketBroker-<version>.zip` from the [latest release](../../releases/latest).
3. Unzip it into `World of Warcraft/_forever_/Interface/AddOns/`, so that you end up with `Interface/AddOns/DMFTicketBroker/DMFTicketBroker.toc`.
4. Restart the game and make sure DMF Ticket Broker is enabled in the AddOns list at character select.

## Use

- Open the window with `/dmft` (or `/dmftickets`), the minimap button, or the addon menu on the minimap.
- Scan the Auction House with Auctionator to get prices. With the window open at the Auction House, prices refresh as the scan finishes.
- Open each of your professions once so the addon knows which recipes you have.
- Settings (stale price threshold, minimap button): `/dmft settings` or Options → AddOns → DMF Ticket Broker.

## Game data

All quest, recipe, vendor and prize data lives in [`DMFTicketBroker/Data.lua`](DMFTicketBroker/Data.lua). Most of it was checked against Wowhead's WoW: Forever database. A few values are still unconfirmed and are marked `UNVERIFIED` there, notably whether the repeatable "More …" quests give tickets on Forever (shown as "Tickets unconfirmed" in game). Corrections are welcome.

## Development

Tests run with [busted](https://lunarmodules.github.io/busted/) under Lua 5.1:

```sh
scripts/test
```

The ranking logic (`Engine.lua`) and the game data (`Data.lua`) use no WoW API, so they are tested directly. The rest of the addon is tested against a stubbed client. Domain terms are defined in [`GLOSSARY.md`](GLOSSARY.md), and design decisions are recorded in [`docs/adr/`](docs/adr/).
