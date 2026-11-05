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

-- (the walk /primer fit makes: a frame's texts and children, a text that does not wrap and is wider than its
-- frame cut short, as the client's IsTruncated tells, a texture's picture: the kit's battery.lua)
local B = dofile("addon/test/battery.lua")
B.track(G)

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
  GetSpellTexture = function(id)
    read()
    return id and 100000 + id or nil
  end,
  GetSpellName = function(id)
    read()
    return id and "Spell " .. id or nil
  end,
}
C_Seasons = {
  GetActiveSeason = function()
    read()
    return state.season
  end,
}
-- (the talent trees as the game lists them: three tabs, a tree's cells in the game's order, row then
-- column; the data's own cells stand in for the window: those of the trees state.treeNames names)
local function tabs()
  local seen, out = {}, {}
  for _, t in ipairs(G.ns.data.cells) do
    if state.treeNames[t.tab] and not seen[t.tab] then
      seen[t.tab] = true
      table.insert(out, t.tab)
    end
  end
  table.sort(out)
  return out
end
local function cellsOf(tab)
  local cells = {}
  for _, t in ipairs(G.ns.data.cells) do
    if t.tab == tab then table.insert(cells, t) end
  end
  table.sort(cells, function(a, b)
    if a.row ~= b.row then return a.row < b.row end
    return a.col < b.col
  end)
  return cells
end
-- (the trees as the game names them, by their id; a test that plays another class sets
-- state.treeNames to that class's trees)
state.treeNames = { [161] = "Arms", [163] = "Protection", [164] = "Fury" }
function GetNumTalents(tab)
  read()
  return #cellsOf(tabs()[tab])
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
    local cells = cellsOf(tabs()[q.specializationIndex])
    local t = cells[q.talentIndex]
    if not t then return nil end
    -- (the talents of group 1 are state.ranks, of group 2 state.otherRanks, the group in use when none is named)
    local ranks = (q.groupIndex or state.group) == 1 and state.ranks or state.otherRanks
    local rank = ranks[t.id] or 0
    return { name = "Talent " .. t.id, icon = 200000 + t.id, talentID = t.id, rank = rank, maxRank = t.max, spellID = 0 }
  end,
}

-- ── Forever's talents: a trait tree (C_Traits), the way the client's own frame reads it. Every cell of the
-- data is a node (id 10000 + the cell's id) with one entry (20000 +) and a definition (30000 +) whose spell
-- is the cell's; one node more is a class spell no cell has. state.ranks (by the cell's id) are the ranks,
-- state.traits the rest of what the client answers.
if G.FOREVER then
  state.traits = { config = 7, tree = 700, points = 0, secret = {}, raise = {}, free = {} }
  state.secrets = {}
  dofile("addon/test/secrets.lua").install(G, state.secrets)
  local EXTRA = 99999
  C_ClassTalents = {
    GetActiveConfigID = function()
      read()
      return state.traits.config
    end,
  }
  C_Traits = {
    GetConfigInfo = function(id)
      read()
      if id ~= state.traits.config then return nil end
      return { ID = id, treeIDs = { state.traits.tree } }
    end,
    GetTreeNodes = function(tree)
      read()
      local out = {}
      -- (the class the test plays: the Warrior unless UnitClass says another)
      local _, token = UnitClass("player")
      local class = 1
      for id, c in pairs(G.ns.data.classes) do
        if c.token == token then class = id end
      end
      for _, c in ipairs(G.ns.data.cells) do
        if c.class == class then out[#out + 1] = 10000 + c.id end
      end
      out[#out + 1] = EXTRA
      table.sort(out)
      return out
    end,
    GetTreeCurrencyInfo = function()
      read()
      return state.traits.points and { { traitCurrencyID = 1, quantity = state.traits.points, spent = 0 } } or nil
    end,
    GetNodeInfo = function(config, node)
      read()
      if state.traits.raise[node] then error("secret") end
      local id = node - 10000
      local rank = state.ranks[id] or 0
      local info = {
        ID = node,
        currentRank = rank,
        activeRank = rank - (state.traits.staged and state.traits.staged[id] or 0),
        ranksPurchased = state.traits.free[id] and 0 or rank,
        maxRanks = 5,
        entryIDs = { 20000 + id },
        activeEntry = rank > 0 and { entryID = 20000 + id, rank = rank } or nil,
      }
      if state.traits.secret[node] then state.secrets[info] = true end
      return info
    end,
    GetEntryInfo = function(config, entry)
      read()
      return { definitionID = entry + 10000, maxRanks = 5 }
    end,
    GetDefinitionInfo = function(def)
      read()
      local id = def - 30000
      if id == EXTRA - 10000 then return { spellID = 1 } end
      for _, c in ipairs(G.ns.data.cells) do
        if c.id == id then return { spellID = c.spell } end
      end
    end,
  }
end

-- ── the strict game: what Blizzard's documentation says the client refuses, refused here too
-- (STRICT=0 plays the lenient game, to compare)
if os.getenv("STRICT") ~= "0" then
  G.strict = dofile("addon/test/strict.lua")
  G.strict.install(G, G.FOREVER and "forever" or "classic")
end

-- ── the addon ────────────────────────────────────────────────────────────────
-- (a test that needs the game changed before the addon loads, and so before the addon keeps a copy of a
-- global: matrix.lua secrets replaces `type` so a secret value reports the type it stands for)
if PRIMER_BEFORE_LOAD then PRIMER_BEFORE_LOAD(G) end
G.load("Primer")
return G
