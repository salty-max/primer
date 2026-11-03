-- What the guide reads of the game, all of it in one place and all of it out of
-- combat: the character's class and level, the season, the spells in its book,
-- the talents it has taken and a spell's name and picture. Called when the
-- window draws (Window.lua), never from an event of a fight: in combat
-- snapshot() answers nil and the window waits.
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

function R.season()
  if C_Seasons and C_Seasons.GetActiveSeason then return C_Seasons.GetActiveSeason() end
end

-- Whether a spell is in the character's book: rank 1's id is the family's.
function R.known(spell)
  if not C_SpellBook then return false end
  if C_SpellBook.IsSpellInSpellBook and C_SpellBook.IsSpellInSpellBook(spell) then return true end
  return C_SpellBook.IsSpellKnown and C_SpellBook.IsSpellKnown(spell) or false
end

-- A spell's name and picture, the game's, by id (nothing typed here).
function R.spell(id)
  if C_Spell and C_Spell.GetSpellInfo then
    local info = C_Spell.GetSpellInfo(id)
    if info then return info.name, info.iconID end
  end
  if GetSpellTexture then return nil, GetSpellTexture(id) end
end

-- The talent groups: Era has one in practice, Forever two (dual specialisation).
-- Asked of the game, never assumed: a client without the call has one.
function R.groups()
  -- (a global in both clients' own code, the count of groups: false, not inspecting)
  local n = GetNumSpecGroups and GetNumSpecGroups(false)
  return type(n) == "number" and n >= 1 and n or 1
end
function R.activeGroup()
  local g = C_SpecializationInfo
    and C_SpecializationInfo.GetActiveSpecGroup
    and C_SpecializationInfo.GetActiveSpecGroup()
  return type(g) == "number" and g >= 1 and g or 1
end

-- The talents a group has (the one in use unless told): by the talent's id,
-- { name, icon, rank, max, tab (the tree's place in the window: 1 to 3) }, the
-- points in each tree and in all. The call is the probe's own (no group named)
-- for the group in use.
function R.talents(group, active)
  local t = { byId = {}, points = {}, total = 0 }
  if not (C_SpecializationInfo and C_SpecializationInfo.GetTalentInfo) then return t end
  local tabs = GetNumTalentTabs and GetNumTalentTabs() or 0
  t.names = {}
  for tab = 1, tabs do
    local sum = 0
    -- (the tree's own name, the game's: its talent window asks the same call)
    if C_SpecializationInfo.GetSpecializationInfo then
      t.names[tab] = select(2, C_SpecializationInfo.GetSpecializationInfo(tab))
    end
    -- (the tree's size when the game says it, else to the first empty cell)
    local cells = GetNumTalents and GetNumTalents(tab) or MOST_TALENTS
    for index = 1, math.min(cells, MOST_TALENTS) do
      local info = C_SpecializationInfo.GetTalentInfo({
        specializationIndex = tab,
        talentIndex = index,
        groupIndex = group and group ~= active and group or nil,
      })
      if not (info and info.talentID) then break end
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
  local name, token = UnitClass("player")
  local active = R.activeGroup()
  local groups = R.groups()
  if not group or group > groups then group = active end
  local snap = {
    level = UnitLevel("player"),
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
