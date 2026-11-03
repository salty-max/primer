-- A small game for Primer's tests (the kit's game, wowmock.lua: frames, events
-- and timers, the character, the minimap). FOREVER=1 plays Forever's client.
-- Primer reads nothing else of the game, so this adds nothing to it.
local G = dofile("addon/test/wowmock.lua")

-- ── the events the addon asks for
-- (G.registered[event]: Primer reads nothing in combat, so a test can say so)
G.registered = {}
local register = G.methods.RegisterEvent
G.methods.RegisterEvent = function(self, event, ...)
  G.registered[event] = true
  return register(self, event, ...)
end

-- ── the addon ────────────────────────────────────────────────────────────────
G.load("Primer")
return G
