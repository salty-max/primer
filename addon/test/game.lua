-- A small game for Primer's tests (the kit's game, wowmock.lua: frames, events
-- and timers, the character, the minimap). FOREVER=1 plays Forever's client.
-- What the guide reads of the game, as the pinned Era client answers it (the
-- probe of 3 November 2026): the spell book, the talent call (a talent's name,
-- icon, rank and id; the rank 0 spell is 0), the season, a spell's name and
-- picture. state.spells: the spells in the book (by id), state.ranks: the
-- talents taken (by talent id), state.season, state.combat.
local G = dofile("addon/test/wowmock.lua")
local state = G.state

-- ── the events the addon asks for
-- (G.registered[event]: Primer reads nothing in combat, so a test can say so)
G.registered = {}
local register = G.methods.RegisterEvent
G.methods.RegisterEvent = function(self, event, ...)
  -- (Era's client has no TRAIT_CONFIG_UPDATED: it raises, as the game does)
  if event == "TRAIT_CONFIG_UPDATED" and not G.FOREVER then error("unknown event " .. event) end
  G.registered[event] = true
  return register(self, event, ...)
end

-- (a texture remembers its picture, so a test can say which)
G.methods.SetTexture = function(self, path) self.texture = path end

-- ── what the guide reads
state.spells, state.ranks, state.season = {}, {}, 0
-- (talent groups: Era has one; state.groups and state.group (the one in use)
-- say otherwise, state.otherRanks the other group's talents)
state.groups, state.group, state.otherRanks = 1, 1, {}
state.reads = 0 -- (every call the guide makes of the game: none in combat)
local function read() state.reads = state.reads + 1 end
C_SpellBook = {
  IsSpellInSpellBook = function(id)
    read()
    return state.spells[id] == true
  end,
  IsSpellKnown = function(id)
    read()
    return state.spells[id] == true
  end,
}
C_Spell = {
  GetSpellInfo = function(id)
    read()
    return { name = "Spell " .. id, iconID = 100000 + id }
  end,
}
C_Seasons = {
  GetActiveSeason = function()
    read()
    return state.season
  end,
}
-- (the talent trees as the game lists them: three tabs, the cells in talent id
-- order; the data's own talents stand in for the whole window)
local function tabs()
  local seen, out = {}, {}
  for _, t in pairs(G.ns.data.talents) do
    if state.treeNames[t.tab] and not seen[t.tab] then
      seen[t.tab] = true
      table.insert(out, t.tab)
    end
  end
  table.sort(out)
  return out
end
-- (the trees as the game names them, by their place in the window; the three
-- tabs of the data's own talents, 161 Arms, 163 Protection, 164 Fury)
state.treeNames = { [161] = "Arms", [163] = "Protection", [164] = "Fury" }
function GetNumTalents(tab)
  read()
  local n, id = 0, tabs()[tab]
  for _, t in pairs(G.ns.data.talents) do
    if t.tab == id then n = n + 1 end
  end
  return n
end
function GetNumTalentTabs()
  read()
  return 3
end
function GetNumSpecGroups()
  read()
  return state.groups
end
C_SpecializationInfo = {
  GetSpecializationInfo = function(tab)
    read()
    local id = tabs()[tab]
    return id, state.treeNames[id]
  end,
  GetActiveSpecGroup = function()
    read()
    return state.group
  end,
  GetTalentInfo = function(q)
    read()
    local tab = tabs()[q.specializationIndex]
    local cells = {}
    for _, t in pairs(G.ns.data.talents) do
      if t.tab == tab then table.insert(cells, t) end
    end
    table.sort(cells, function(a, b) return a.id < b.id end)
    local t = cells[q.talentIndex]
    if not t then return nil end
    -- (the talents of group 1 are state.ranks, of group 2 state.otherRanks, the group in use when none is named)
    local ranks = (q.groupIndex or state.group) == 1 and state.ranks or state.otherRanks
    local rank = ranks[t.id] or 0
    return { name = "Talent " .. t.id, icon = 200000 + t.id, talentID = t.id, rank = rank, maxRank = t.max, spellID = 0 }
  end,
}

-- ── the addon ────────────────────────────────────────────────────────────────
G.load("Primer")
return G
