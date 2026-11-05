-- Primer played through every class with content, spec, level, tab and state, on one game (FOREVER=1 for
-- Forever). Each case sets a character up, opens the window, draws every tab, hovers and clicks everything on
-- the page, levels up, respecs and goes in and out of combat, and must end with:
--   no Lua error, no fault Primer kept (ns.faults), no call the strict game refuses,
--   no frame bigger than the screen or anchored off it, no text cut short (ns.fit), no semicolon or exclamation
--   mark in a word shown, no spell or talent icon left as the question mark, nothing read in combat.
-- A failure names the case. docs/testing.md says what this cannot see (the live client).
--   luajit addon/test/matrix.lua           the matrix
--   FOREVER=1 luajit addon/test/matrix.lua secrets   Forever's secret values: every call of the game Primer makes
--                                          answers with secret values (whole, then field by field), and the page
--                                          must show nothing of it rather than raise (docs/testing.md)
local MODE = arg and arg[1] or "matrix"

local X = dofile("addon/test/secrets.lua")
if MODE == "secrets" then
  -- (a secret value keeps its type for type() and refuses everything else, as the client's do)
  PRIMER_BEFORE_LOAD = function() X.patchType() end
end
local G = dofile("addon/test/game.lua")
local s, ns = G.state, G.ns
local D, TAB = ns.data, ns.TAB
local T = s.traits -- (Forever's trait tree, nil on Era)
local started = os.clock()

-- ── the kit's battery: the walk of what is shown, the audits, the hover and the click, the failure list
local B = dofile("addon/test/battery.lua")
B.trackTextures(G)
B.shownByDefault()

-- Text the mock's width estimate (0.55 of the size a character) calls cut that a person has to judge in the game:
-- each with why. Anything that is a reason, or that wraps, never goes here.
local CUT_OK = {
  ["The guide cannot read your character"] = "the heading of the page that says the game hid the talents: 36 characters at size 24 in 440, estimated 475. Look at it in the game (docs/testing.md checklist)",
}
local b = B.new({
  G = G,
  name = "Primer",
  roots = function() return PrimerFrame and { PrimerFrame } or {} end,
  cut = function() return ns.fit() end,
  cutOk = CUT_OK,
  faults = function()
    local faults = ns.faults
    ns.faults = {}
    return faults
  end,
  -- (an icon that did not resolve shows the question mark; in secrets mode that is the fallback)
  badPicture = function(r) return MODE ~= "secrets" and r.texture == ns.kit.QUESTION end,
  skip = function(f)
    return f.name and (f.name:find("^PrimerFrameTab%d") or f.name == "PrimerFrameCloseButton")
      or f == PrimerFrame.CloseButton
  end,
})
local failures, fail, try, audit, touch = b.failures, b.fail, b.try, b.audit, b.touch

-- ── the characters
local LEVELS = { 1, 2, 9, 10, 11, 20, 40, 60 }
local realClass = UnitClass
local classes = {}
for id, c in pairs(D.classes) do
  classes[#classes + 1] = { id = id, token = c.token, key = c.key, class = c }
end
table.sort(classes, function(a, b) return a.id < b.id end)

local function treesOf(c)
  local trees = {}
  for _, bid in ipairs(c.class.builds) do
    trees[D.builds[bid].tree] = D.builds[bid].name
  end
  return trees
end

local function ranksOf(build, level)
  local map = {}
  for spell, rank in pairs(ns.rules.ranksAt(build, 1, level)) do
    map[D.talents[spell].id] = rank
  end
  return map
end

local function spellsAt(c, level)
  local known = { [168] = true, [100] = true, [772] = true, [78] = true }
  for _, bid in ipairs(c.class.builds) do
    for _, stage in ipairs(D.builds[bid].stages) do
      for _, row in ipairs(stage.rows or {}) do
        if row.level <= level then known[row.spell] = true end
      end
      for _, name in ipairs({ "opening", "loop", "between", "low" }) do
        for _, st in ipairs(stage.plan and stage.plan[name] or {}) do
          if st.spell and st.level and st.level <= level then known[st.spell] = true end
        end
      end
    end
  end
  return known
end

local secretUnitClass
local playing -- (the character UnitClass answers for; secrets mode wraps UnitClass itself, so it is not replaced)
local function setup(c, level, state)
  playing = function() return c.class.key:sub(1, 1):upper() .. c.class.key:sub(2), c.token, c.id end
  if not secretUnitClass then UnitClass = playing end
  s.treeNames = treesOf(c)
  s.level, s.season, s.combat = level, state.hardcore and ns.rules.HARDCORE or 0, false
  s.spells = spellsAt(c, level)
  s.ranks = {}
  if state.build then s.ranks = ranksOf(D.builds[state.build], level) end
  if T then T.points = (not state.build and level >= 10) and 1 or 0 end
  PrimerChar.groups, PrimerChar.welcomed = {}, nil
  if state.role then ns.choice(1).role = state.role end
  if state.pick then
    ns.choice(1).role = D.builds[state.pick].role
    ns.choice(1).pickedBuild = state.pick
  end
  ns.view.putOff = nil
  ns.reader.reset()
  if PrimerFrame then PrimerFrame:Hide() end
  s.printed = {}
  GameTooltip.lines = {}
  ns.faults = {}
end

local function describe(c, level, state)
  local bits = { c.token, "level " .. level }
  if state.build then bits[#bits + 1] = "points in " .. D.builds[state.build].name end
  if state.pick then bits[#bits + 1] = "picked " .. D.builds[state.pick].name end
  if state.role then bits[#bits + 1] = "stored role " .. state.role end
  if not (state.build or state.pick or state.role) then bits[#bits + 1] = "nothing spent" end
  if state.hardcore then bits[#bits + 1] = "Hardcore" end
  return table.concat(bits, ", ")
end

local cases, draws = 0, 0
local function play(c, level, state)
  local case = describe(c, level, state)
  cases = cases + 1
  if not try(case, "setup", setup, c, level, state) then return end
  for _, tab in ipairs({ TAB.level, TAB.talents, TAB.class }) do
    local label = case .. ", tab " .. tab
    if try(label, "open", ns.open, tab) then
      draws = draws + 1
      G.advance(0.5)
      audit(label)
      touch(label)
      audit(label .. " (after clicks)")
      try(label, "reopen", ns.open, tab)
    end
  end
  -- a level-up, a respec, a fight
  local label = case .. ", events"
  try(label, "level up", function()
    s.level = level + 1
    G.fire("PLAYER_LEVEL_UP", level + 1)
    G.advance(0.5)
    s.level = level
  end)
  try(label, "respec", function()
    local other = state.build and c.class.builds[(state.build % #c.class.builds) + 1] or c.class.builds[1]
    s.ranks = ranksOf(D.builds[c.class.builds[(level % #c.class.builds) + 1]], level)
    for event in pairs(G.registered) do
      if event:find("TALENT") or event:find("TRAIT") or event:find("POINTS") then G.fire(event) end
    end
    G.advance(0.5)
  end)
  try(label, "a fight", function()
    local before = s.reads
    s.combat = true
    G.fire("PLAYER_REGEN_DISABLED")
    G.fire("PLAYER_LEVEL_UP", level + 1)
    G.fire("PLAYER_TALENT_UPDATE")
    G.advance(1)
    if s.reads ~= before then fail(label, ("%d reads of the game in combat"):format(s.reads - before)) end
    s.combat = false
    G.fire("PLAYER_REGEN_ENABLED")
    G.advance(1)
  end)
  audit(label)
  if PrimerFrame then PrimerFrame:Hide() end
end

G.login()
local function matrix()
  for _, c in ipairs(classes) do
    local states = { {} }
    for _, bid in ipairs(c.class.builds) do
      states[#states + 1] = { build = bid }
      states[#states + 1] = { pick = bid }
    end
    for role in pairs(c.class.roles or {}) do
      states[#states + 1] = { role = role }
    end
    for _, level in ipairs(LEVELS) do
      for _, state in ipairs(states) do
        play(c, level, state)
        -- (Hardcore is an Era realm, and changes the Class tab alone: a few levels show it)
        if not G.FOREVER and (level == 2 or level == 10 or level == 40 or level == 60) then
          local hc = {}
          for k, v in pairs(state) do
            hc[k] = v
          end
          hc.hardcore = true
          play(c, level, hc)
        end
      end
    end
  end
end

-- ── secret values (Forever): each call Primer makes of the game, one at a time, answers with secrets
local TALENT_CALLS = {
  ["C_ClassTalents.GetActiveConfigID"] = true,
  ["C_Traits.GetConfigInfo"] = true,
  ["C_Traits.GetTreeNodes"] = true,
  ["C_Traits.GetNodeInfo"] = true,
  ["C_Traits.GetEntryInfo"] = true,
  ["C_Traits.GetDefinitionInfo"] = true,
  UnitClass = true,
}
local function secrets()
  if not G.FOREVER then
    io.write("✓ secrets: Classic Era has no secret values, nothing to run\n")
    return
  end
  local warrior, mage
  for _, c in ipairs(classes) do
    if c.token == "WARRIOR" then warrior = c end
    if c.token == "MAGE" then mage = c end
  end
  local ran = 0
  local done = X.drive(G, {
    globals = { "UnitClass", "UnitName", "UnitGUID", "UnitRace", "UnitSex", "UnitLevel", "UnitFactionGroup" },
    -- (UnitClass answers as the class being played)
    original = function(name)
      if name == "UnitClass" then
        return function(...) return playing(...) end
      end
    end,
    each = function(label, name)
      secretUnitClass = name == "UnitClass"
      local before = #failures
      -- (a Warrior with forty points down Fury, a Mage at the first point)
      for _, sc in ipairs({ { warrior, 40, { build = warrior.class.builds[2] } }, { mage, 10, {} } }) do
        local case = label .. " (" .. describe(sc[1], sc[2], sc[3]) .. ")"
        play(sc[1], sc[2], sc[3])
        for i = before + 1, #failures do
          failures[i] = case .. ": " .. failures[i]
        end
        before = #failures
        ran = ran + 1
      end
      -- (a hidden GUID keeps the book the character has, with its choices)
      if name == "UnitGUID" then
        local case = label .. " (logging in)"
        local book = PrimerChar
        book.marker = true
        local ok, err = pcall(ns.login)
        if not ok then
          fail(case, "login raised: " .. tostring(err))
        elseif PrimerChar ~= book or not PrimerChar.marker then
          fail(case, "the saved book was replaced")
        end
      end
      -- (the talents: a call that cannot be read leaves nothing taken, never a guess)
      if TALENT_CALLS[name] then
        local case = label .. " (reading talents)"
        setup(warrior, 40, { build = warrior.class.builds[2] })
        ns.reader.reset()
        local ok, t = pcall(ns.reader.foreverTalents)
        if not ok then
          fail(case, "the reader raised: " .. tostring(t))
        elseif t.total ~= 0 then
          fail(case, ("%d points read from secret values"):format(t.total))
        end
      end
    end,
  })
  secretsRan = ran
  secretsTargets = done.targets
  secretsFlagged = done.flagged
end

if MODE == "secrets" then
  secrets()
else
  matrix()
end
UnitClass = realClass

if MODE == "secrets" then
  b.finish(
    ("✓ secrets: %d functions answered with secret values, whole and field by field, %d pages played, %d of them flagged by the documentation (%.1fs)"):format(
      secretsTargets or 0,
      secretsRan or 0,
      secretsFlagged or 0,
      os.clock() - started
    ),
    "matrix"
  )
end
b.finish(
  ("✓ matrix: %d cases, %d tab draws, %d hovers, %d clicks, %d words, %s, %.1fs (%s)"):format(
    cases,
    draws,
    b.hovers,
    b.clicks,
    b.texts,
    G.strict and G.strict.report():match("^%d+ calls") or "lenient",
    os.clock() - started,
    G.FOREVER and "Forever" or "Classic Era"
  )
)
