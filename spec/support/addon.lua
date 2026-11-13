-- Loads the addon's pure-Lua files the way the WoW client does:
-- each file is called with (addonName, ns) as its varargs.
local ADDON_DIR = "DMFTicketBroker/"

function LoadAddon(...)
  local ns = {}
  for _, file in ipairs({ ... }) do
    local chunk = assert(loadfile(ADDON_DIR .. file))
    chunk("DMFTicketBroker", ns)
  end
  return ns
end
