-- Small hand-built fixtures. Tests never depend on the real Data table.
Fixtures = {}

function Fixtures.byName(rows)
  local out = {}
  for _, row in ipairs(rows) do out[row.source.name] = row end
  return out
end

function Fixtures.names(rows)
  local out = {}
  for i, row in ipairs(rows) do out[i] = row.source.name end
  return out
end

-- One Ticket Source handing in `quantity` of item 100 for `tickets` tickets.
function Fixtures.single(opts)
  opts = opts or {}
  return {
    tiers = { [1] = { tickets = opts.tickets or 1, minLevel = 1, repCap = 500 } },
    sources = {
      { questID = 1, name = "Widgets", tier = 1, items = { { itemID = 100, name = "Widget", quantity = opts.quantity or 1 } } },
    },
    recipes = opts.recipes or {},
    vendor = opts.vendor or {},
  }
end

function Fixtures.engineer(rank, known)
  return {
    skills = { Engineering = rank },
    knownRecipes = { Engineering = known or {} },
  }
end
