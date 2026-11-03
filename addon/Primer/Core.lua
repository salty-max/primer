-- Primer: a class guide to read out of combat. The window (Window.lua) shows,
-- for the character's class and build, the talents to pick, what to press and
-- what the build is for; the rules are generated (Guide_<game>.lua, its words
-- GuideText.lua) and the character keeps only its choices. /primer.
--
-- It reads nothing in combat: no combat event is listened to, no unit is asked
-- (the player's GUID at login aside) and no frame of the game is touched, the window is our own and opens on a
-- command or a click.
--
--   PrimerChar (SavedVariablesPerCharacter), whose guide: guid
--     build   the build's id the character chose (D.builds): none yet (M3)
--     role    the role switch the player set: none yet (M3)
--   PrimerSettings (SavedVariables): each character's settings, the kit's
--     profiles (Settings.lua: the minimap button), and the window's place
--
-- Every record by id: a build by its id (content/<class>.json, saved-ids.json).
local _, ns = ...
local K, L = ns.kit, ns.kit.L
-- The kit's look (Kit.lua), in Primer's theme: the ink of a first reader, a
-- cool blue-grey on the dark panels.
K.theme({
  accent = { 0.62, 0.78, 0.90 },
  ring = { 0.35, 0.50, 0.62 },
  bar = { 0.40, 0.62, 0.78 },
  tint = { 0.95, 0.98, 1.00 },
  shade = { 0.01, 0.02, 0.03, 0.55 },
  highlight = { 0.82, 0.92, 1.00 },
})

ns.PREFIX = K.prefix("Primer")
-- (the game's own book, until the user has seen a logo of ours)
ns.ICON = "Interface\\Icons\\INV_Misc_Book_09"

local char
function ns.book() return char end

-- ── events ───────────────────────────────────────────────────────────────────
local events = K.events({
  login = function() ns.login() end,
  ready = function() return char ~= nil end,
})
ns.on = events.on

local function newBook(guid) return { guid = guid } end

function ns.login()
  local guid = UnitGUID("player")
  if type(PrimerChar) ~= "table" or PrimerChar.guid ~= guid then PrimerChar = newBook(guid) end
  char = PrimerChar
  ns.loadProfile()
  if ns.createMinimapButton then ns.createMinimapButton() end
  ns.loggedIn = true
end

-- ── /primer ──────────────────────────────────────────────────────────────────
-- The kit's command (K.commands): alone it opens the window, an unknown word
-- prints the usage.
K.commands({
  names = { "/primer" },
  key = "PRIMER",
  name = "Primer",
  prefix = ns.PREFIX,
  profiles = function() return ns.profiles end, -- (Settings.lua makes them, after this file)
  open = function()
    if ns.toggle then ns.toggle() end
  end,
  usage = L["/primer opens the guide. /primer minimap shows or hides its button on the minimap."],
  -- (looked up when used: Settings.lua makes them, after this file)
  minimap = {
    get = function(k) return ns.option(k) end,
    set = function(k, v) ns.setOption(k, v) end,
  },
})
