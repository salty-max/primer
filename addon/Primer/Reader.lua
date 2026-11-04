-- What the guide reads of the game, all of it in one place and all of it out of
-- combat: the character's class and level, the season, the spells in its book,
-- the talents it has taken and a spell's name and picture. Called when the
-- window draws (Window.lua), never from an event of a fight: in combat
-- snapshot() answers nil and the window waits.
--
-- Every call goes through try(): a function the client documents can still
-- RAISE on this client ("API unsupported in this version", GetNumSpecGroups on
-- Classic Era, found by the first test in the game), and a function being
-- there says nothing about it working. An error is recorded once (ns.fault,
-- `/primer debug` prints it), the call is skipped from then on, and the answer
-- is the safe default (one talent group, no season, no talents, nothing in
-- the book): never an error out of the guide.
--
-- Era's own code calls these (the pinned client's source, ui.ts): the old
-- globals (GetTalentInfo, IsSpellKnown...) are only a fallback behind a CVar
-- and are never used here. Era's probe on 3 November 2026 (a Hardcore dwarf
-- warrior, level 4): C_SpecializationInfo.GetTalentInfo answers with the
-- talent's name, icon, rank and talentID but its spellID is 0 at rank 0, so a
-- talent is found by its id (Guide_<game>.lua's talents), never by its spell.
local _, ns = ...
local R = {}
ns.reader = R

-- (a tree holds 16 talents; the loop stops at the first cell the game has
-- not got)
local MOST_TALENTS = 40
-- (a class has three trees on both games)
local TREES = 3

-- The calls that raised or are not there: not made again until the window is
-- opened again (R.reset: a refusal of this client does not change, a one-off
-- might).
local dead = {}
function R.reset() dead = {} end

-- fn(...) behind a pcall: its answers, or nothing when it is missing, raised
-- before, or raises now (the first time recorded by what it was).
local function pass(what, ok, ...)
  if ok then return ... end
  dead[what] = true
  if ns.fault then ns.fault(what, (...)) end
end
local function try(what, fn, ...)
  if dead[what] then return end
  if type(fn) ~= "function" then
    dead[what] = true
    return
  end
  return pass(what, pcall(fn, ...))
end

-- Whether the game would not tell the guide what a page cannot do without
-- (the talents taken, the spells in the book): the page then says so, and
-- shows no advice drawn from defaults. Call after the page has read them.
function R.blind()
  return dead["C_SpecializationInfo.GetTalentInfo"]
    or (dead["C_SpellBook.IsSpellInSpellBook"] and dead["C_SpellBook.IsSpellKnown"])
    or false
end

function R.season() return try("C_Seasons.GetActiveSeason", C_Seasons and C_Seasons.GetActiveSeason) end

-- Whether a spell is in the character's book. The game gives each rank its own id and may report only the highest
-- rank learned, so a spell counts as known when any rank of its family (the data lists them) is.
local function knownOne(spell)
  if try("C_SpellBook.IsSpellInSpellBook", C_SpellBook and C_SpellBook.IsSpellInSpellBook, spell) then return true end
  return try("C_SpellBook.IsSpellKnown", C_SpellBook and C_SpellBook.IsSpellKnown, spell) and true or false
end
function R.known(spell, family)
  if knownOne(spell) then return true end
  for _, id in ipairs(family or {}) do
    if id ~= spell and knownOne(id) then return true end
  end
  return false
end

-- A spell's name and picture, the game's, by id (nothing typed here).
function R.spell(id)
  local info = try("C_Spell.GetSpellInfo", C_Spell and C_Spell.GetSpellInfo, id)
  if type(info) == "table" then return info.name, info.iconID end
  return nil, try("GetSpellTexture", GetSpellTexture, id)
end

-- The talent groups: Era has one in practice, Forever two (dual specialisation).
-- Asked of the game, never assumed: a client that has no answer has one.
function R.groups()
  -- (a global in both clients' own code, the count of groups: false, not inspecting)
  local n = try("GetNumSpecGroups", GetNumSpecGroups, false)
  return type(n) == "number" and n >= 1 and n or 1
end
function R.activeGroup()
  local g =
    try("C_SpecializationInfo.GetActiveSpecGroup", C_SpecializationInfo and C_SpecializationInfo.GetActiveSpecGroup)
  return type(g) == "number" and g >= 1 and g or 1
end

-- The talents a group has (the one in use unless told): by the talent's id,
-- { name, icon, rank, max, tab (the tree's place in the window: 1 to 3) }, the
-- points in each tree and in all, and the trees' names. The call is the
-- probe's own (no group named) for the group in use.
function R.talents(group, active)
  local t = { byId = {}, points = {}, total = 0, names = {} }
  local get = C_SpecializationInfo and C_SpecializationInfo.GetTalentInfo
  local tabs = try("GetNumTalentTabs", GetNumTalentTabs) or TREES
  for tab = 1, math.min(tabs, TREES) do
    local sum = 0
    -- (the tree's own name, the game's: its talent window asks the same call)
    t.names[tab] = select(
      2,
      try(
        "C_SpecializationInfo.GetSpecializationInfo",
        C_SpecializationInfo and C_SpecializationInfo.GetSpecializationInfo,
        tab
      )
    )
    -- (the tree's size when the game says it, else to the first empty cell)
    local cells = try("GetNumTalents", GetNumTalents, tab)
    for index = 1, math.min(type(cells) == "number" and cells or MOST_TALENTS, MOST_TALENTS) do
      local info = try("C_SpecializationInfo.GetTalentInfo", get, {
        specializationIndex = tab,
        talentIndex = index,
        groupIndex = group and group ~= active and group or nil,
      })
      if not (type(info) == "table" and info.talentID) then break end
      local rank = info.rank or 0
      t.byId[info.talentID] = { name = info.name, icon = info.icon, rank = rank, max = info.maxRank, tab = tab }
      sum = sum + rank
    end
    t.points[tab] = sum
    t.total = t.total + sum
  end
  return t
end

-- The character as the guide needs it, or nil in combat (the window waits):
-- its talents are the group asked for (the one in use: none), with how many
-- groups there are and which is in use.
function R.snapshot(group)
  if InCombatLockdown() then return nil end
  local name, token = try("UnitClass", UnitClass, "player")
  local active = R.activeGroup()
  local groups = R.groups()
  if not group or group > groups then group = active end
  local snap = {
    level = try("UnitLevel", UnitLevel, "player") or 1,
    token = token,
    className = name,
    season = R.season(),
    knows = R.known,
    group = group,
    active = active,
    groups = groups,
  }
  -- (the talents are read when a page asks for them: the pages that say there
  -- is no guide never do)
  return setmetatable(snap, {
    __index = function(t, k)
      if k == "talents" then
        local talents = R.talents(group, active)
        rawset(t, "talents", talents)
        return talents
      end
    end,
  })
end
