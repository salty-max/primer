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

-- A value the game may hide from addons (a secret value keeps its type and
-- raises on a compare, a concatenation or an index) is used only after this
-- says it is not hidden: the page shows nothing of it rather than raise.
local secret = issecretvalue or function() return false end
local function num(v) return type(v) == "number" and not secret(v) and v or nil end
local function tbl(v) return type(v) == "table" and not secret(v) and v or nil end

-- Whether the game would not tell the guide what a page cannot do without
-- (the talents taken, the spells in the book): the page then says so, and
-- shows no advice drawn from defaults. Call after the page has read them.
function R.blind()
  return dead["C_SpecializationInfo.GetTalentInfo"]
    or (R.probe and R.probe.blind)
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
  if tbl(info) then
    local name, icon = info.name, info.iconID
    return not secret(name) and name or nil, not secret(icon) and icon or nil
  end
  return nil, try("GetSpellTexture", GetSpellTexture, id)
end

-- The talent groups: Era has one in practice, Forever two (dual specialisation).
-- Asked of the game, never assumed: a client that has no answer has one.
function R.groups()
  -- (a global in both clients' own code, the count of groups: false, not inspecting)
  local n = try("GetNumSpecGroups", GetNumSpecGroups, false)
  return num(n) and n >= 1 and n or 1
end
function R.activeGroup()
  local g =
    try("C_SpecializationInfo.GetActiveSpecGroup", C_SpecializationInfo and C_SpecializationInfo.GetActiveSpecGroup)
  return num(g) and g >= 1 and g or 1
end

-- ── Forever: the talents are a trait tree ────────────────────────────────────
-- Forever is the retail engine (interface 16001): there is no per-tab
-- GetTalentInfo, the talents are C_Traits nodes. The way Blizzard's own talent
-- frame reads them (Blizzard_SharedTalentFrame.lua, via ui.ts): the config
-- C_ClassTalents.GetActiveConfigID(), its tree C_Traits.GetConfigInfo(config)
-- .treeIDs[1], the tree's nodes C_Traits.GetTreeNodes(tree), a node's state
-- C_Traits.GetNodeInfo(config, node) (currentRank, ranksPurchased,
-- activeEntry.entryID, entryIDs), its entry C_Traits.GetEntryInfo(config,
-- entry).definitionID and the definition C_Traits.GetDefinitionInfo(id).spellID.
-- A node is matched to the guide by that spell: the data's cells hold every
-- talent's rank 1 spell with its id (wow-data's talent table: the node's spell).
-- The documentation flags no return of these calls as secret (SecretArguments
-- only), but a value is still checked before it is used, and a node that
-- raises is skipped: the page shows less, never an error.
-- NOT VERIFIED IN THE GAME (written before Forever's first run of it): that
-- GetActiveConfigID answers on a class with no specialisations, that a
-- definition's spell is the cell's rank 1 spell, and that treeIDs[1] holds all
-- three trees. `/primer debug` prints what the client answered.

-- A call that may raise, outside try(): the first error is kept, nothing is
-- turned off (one odd node must not blind the rest).
local function safe(what, fn, ...)
  local ok, a, b = pcall(fn, ...)
  if ok then return a, b end
  if ns.fault then ns.fault(what, a) end
end

-- What the last Forever read found, for /primer debug.
R.probe = nil

function R.foreverTalents()
  local t = { byId = {}, points = { 0, 0, 0 }, total = 0, names = {} }
  local probe = { nodes = 0, ranked = 0, matched = 0, spent = 0 }
  R.probe = probe
  local data = ns.data
  local _, token = try("UnitClass", UnitClass, "player")
  if secret(token) then token = nil end
  local classId
  for id, c in pairs(data.classes) do
    if c.token == token then classId = id end
  end
  -- (the class's trees in its builds' order, which is Era's window order: Arms, Fury, Protection; a tree
  -- with no build, if the data ever has one, comes after, by id. The names are the builds', the data's own)
  local bySpell, place, ids = {}, {}, {}
  for _, c in ipairs(data.cells) do
    if c.class == classId then bySpell[c.spell] = c end
  end
  local function addTree(tab, name)
    if place[tab] then return end
    ids[#ids + 1] = tab
    place[tab] = #ids
    t.names[#ids] = name
  end
  for _, b in ipairs(classId and data.classes[classId].builds or {}) do
    local build = data.builds[b]
    if build then addTree(build.tree, build.name) end
  end
  local rest = {}
  for _, c in pairs(bySpell) do
    if not place[c.tab] then rest[c.tab] = true end
  end
  local more = {}
  for tab in pairs(rest) do
    more[#more + 1] = tab
  end
  table.sort(more)
  for _, tab in ipairs(more) do
    addTree(tab, nil)
  end
  probe.cells = 0
  for _ in pairs(bySpell) do
    probe.cells = probe.cells + 1
  end
  local level = num(try("UnitLevel", UnitLevel, "player")) or 1
  local function blind(why)
    probe.why = why
    -- (a character before its first point has nothing to read)
    probe.blind = level >= (ns.rules and ns.rules.FIRST_POINT_LEVEL or 10)
    return t
  end
  if not classId then return blind("class") end

  local config = num(try("C_ClassTalents.GetActiveConfigID", C_ClassTalents and C_ClassTalents.GetActiveConfigID))
  probe.config = config
  if not config then return blind("config") end
  local info = tbl(try("C_Traits.GetConfigInfo", C_Traits and C_Traits.GetConfigInfo, config))
  local trees = info and tbl(info.treeIDs)
  local tree = trees and num(trees[1])
  probe.tree = tree
  if not tree then return blind("tree") end
  local nodes = tbl(try("C_Traits.GetTreeNodes", C_Traits and C_Traits.GetTreeNodes, tree))
  if not nodes then return blind("nodes") end

  -- (what the game says is to spend: the tree's currency, its quantity left)
  local currencies =
    tbl(try("C_Traits.GetTreeCurrencyInfo", C_Traits and C_Traits.GetTreeCurrencyInfo, config, tree, true))
  if currencies then
    local left
    for _, cur in ipairs(currencies) do
      local q = tbl(cur) and num(cur.quantity)
      if q then left = (left or 0) + q end
    end
    t.unspent = left
    probe.unspent = left
  end

  local entrySpell = {}
  local function spellOf(entry)
    if entrySpell[entry] == nil then
      local e = tbl(safe("C_Traits.GetEntryInfo", C_Traits.GetEntryInfo, config, entry))
      local def = e and num(e.definitionID)
      local d = def and tbl(safe("C_Traits.GetDefinitionInfo", C_Traits.GetDefinitionInfo, def))
      entrySpell[entry] = d and num(d.spellID) or false
    end
    return entrySpell[entry]
  end
  for _, node in ipairs(nodes) do
    probe.nodes = probe.nodes + 1
    local n = num(node) and tbl(safe("C_Traits.GetNodeInfo", C_Traits.GetNodeInfo, config, node))
    if n then
      local active = tbl(n.activeEntry)
      local entry = active and num(active.entryID)
      if not entry then
        local list = tbl(n.entryIDs)
        entry = list and num(list[1])
      end
      -- (activeRank: what Blizzard's own buttons call taken, so a pick staged in the talent frame and not
      -- applied is not counted; currentRank is the fallback)
      local current = num(n.activeRank) or num(n.currentRank) or 0
      -- (the points put in; a node given free has none purchased)
      local bought = math.min(num(n.ranksPurchased) or current, current)
      if current > 0 then probe.ranked = probe.ranked + 1 end
      local spell = entry and spellOf(entry)
      local cell = spell and bySpell[spell]
      if cell then
        probe.matched = probe.matched + 1
        local at = place[cell.tab]
        t.byId[cell.id] = { rank = current, max = num(n.maxRanks) or cell.max, tab = at }
        t.points[at] = t.points[at] + bought
        t.total = t.total + bought
      end
    end
  end
  probe.spent = t.total
  if probe.nodes == 0 or probe.matched == 0 then return blind("matched") end
  return t
end

-- The talents a group has (the one in use unless told): by the talent's id,
-- { name, icon, rank, max, tab (the tree's place in the window: 1 to 3) }, the
-- points in each tree and in all, and the trees' names. The call is the
-- probe's own (no group named) for the group in use.
function R.talents(group, active)
  if ns.data and ns.data.game == "forever" then return R.foreverTalents() end
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
  if secret(name) then name = nil end
  if secret(token) then token = nil end
  local active = R.activeGroup()
  local groups = R.groups()
  if not group or group > groups then group = active end
  local snap = {
    level = num(try("UnitLevel", UnitLevel, "player")) or 1,
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
