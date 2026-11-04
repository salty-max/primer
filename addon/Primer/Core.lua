-- Primer: a class guide to read out of combat. The window (Window.lua) shows,
-- for the character's class and build, the talents to pick, what to press and
-- what the build is for; the rules are generated (Guide_<game>.lua, its words
-- GuideText.lua) and the character keeps only its choices. /primer.
--
-- It reads nothing in combat: no combat event is listened to, the game is read
-- only by Reader.lua (when the window draws, and after a burst of events to
-- know whether the level-10 question waits, for the minimap glow) and never in
-- combat, and no frame of the game is touched, the window is our own and opens
-- on a command or a click.
--
--   PrimerChar (SavedVariablesPerCharacter), whose guide: guid
--     groups[n]  what the character chose for talent group n (Era has one,
--                Forever two), each none: the default. role (damage, tank,
--                heal), pickedBuild (an id of D.builds), freestyle (their own
--                way), notYet (the level the question was put off at),
--                driftSeen (the drift the player dismissed)
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

local function newBook(guid) return { guid = guid, groups = {} } end

-- A call or a page that failed, the first time of each this session, kept for
-- `/primer debug` (ns.faults[what] = the error): the next failure is a note,
-- not a red box. Not saved: a week-old error would mislead.
ns.faults = {}
function ns.fault(what, err)
  if ns.faults[what] == nil then ns.faults[what] = tostring(err) end
end

-- The choices for a talent group, made when first asked.
function ns.choice(group)
  char.groups = char.groups or {}
  char.groups[group] = char.groups[group] or {}
  return char.groups[group]
end

function ns.login()
  local guid = UnitGUID("player")
  if type(PrimerChar) ~= "table" or PrimerChar.guid ~= guid then PrimerChar = newBook(guid) end
  char = PrimerChar
  ns.loadProfile()
  if ns.createMinimapButton then ns.createMinimapButton() end
  ns.loggedIn = true
end

-- What changes while the window is open shows a moment later, bursts as one
-- (ns.changed): a level, a spell learned (a trainer, a quest, the level), a
-- talent point or a change of talent group. Whether each fires on the live
-- client is for the game to say: an event a client lacks is skipped, never
-- raised (K.events), and Forever's trait engine has its own. The window reads
-- the game only when it draws, and never in combat (Reader.lua).
for _, event in ipairs({
  "PLAYER_ENTERING_WORLD",
  "PLAYER_LEVEL_UP",
  "SPELLS_CHANGED",
  "LEARNED_SPELL_IN_SKILL_LINE",
  "TRAINER_UPDATE",
  "CHARACTER_POINTS_CHANGED",
  "PLAYER_TALENT_UPDATE",
  "TRAIT_CONFIG_UPDATED",
}) do
  events.on(event, function()
    if ns.changed then ns.changed() end
  end)
end
-- (the other group is now the one in use: the window follows it)
events.on("ACTIVE_TALENT_GROUP_CHANGED", function()
  if ns.groupChanged then ns.groupChanged() end
end)

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
  usage = L["/primer opens the guide. /primer minimap shows or hides its button on the minimap. /primer debug says what went wrong, if anything did."],
  commands = {
    debug = function()
      local any = false
      for what, err in pairs(ns.faults) do
        any = true
        print(ns.PREFIX .. what .. ": " .. err)
      end
      if not any then print(ns.PREFIX .. L["Nothing has gone wrong."]) end
    end,
  },
  -- (looked up when used: Settings.lua makes them, after this file)
  minimap = {
    get = function(k) return ns.option(k) end,
    set = function(k, v) ns.setOption(k, v) end,
  },
})
