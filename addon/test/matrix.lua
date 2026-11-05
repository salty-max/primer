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
local rawtype = type
local kinds = setmetatable({}, { __mode = "k" })
if MODE == "secrets" then
  -- (a secret value keeps its type for type() and refuses everything else, as the client's do)
  PRIMER_BEFORE_LOAD = function()
    function type(v) return kinds[v] or rawtype(v) end
  end
end
local G = dofile("addon/test/game.lua")
local s, ns = G.state, G.ns
local D, TAB = ns.data, ns.TAB
local T = s.traits -- (Forever's trait tree, nil on Era)
local started = os.clock()

-- ── the walk: a window's frames, their texts and pictures (the mock keeps kids and regions)
local createTexture = G.methods.CreateTexture
G.methods.CreateTexture = function(self, ...)
  local o = createTexture(self, ...)
  o.parent = self
  self.regions = self.regions or {}
  table.insert(self.regions, o)
  return o
end

-- (a frame the client makes is shown until something hides it: the mock's frames start hidden, so here they
-- start shown, and the walk sees a page as the player's game draws it)
local createFrame = CreateFrame
function CreateFrame(kind, ...)
  local f = createFrame(kind, ...)
  f.shown = true
  return f
end

local function shownFrames()
  local out = {}
  -- (inside a scroll frame a page is as tall as it needs: only what the screen shows is held to its size)
  local function walk(f, scrolled)
    if not f.shown then return end
    out[#out + 1] = f
    f.scrolled = scrolled
    for _, kid in ipairs(f.kids or {}) do
      walk(kid, scrolled or f.kind == "ScrollFrame")
    end
    if f.scrollChild and f.scrollChild.parent ~= f then walk(f.scrollChild, true) end
  end
  if PrimerFrame then walk(PrimerFrame, false) end
  return out
end

local function plain(text)
  return (tostring(text):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|T.-|t", ""):gsub("|n", " "))
end

-- every word on the page and in a tooltip just shown
local function words(extra)
  local out = {}
  for _, f in ipairs(shownFrames()) do
    if type(f.text) == "string" then out[#out + 1] = f.text end
    if type(f.titleText) == "string" then out[#out + 1] = f.titleText end
    for _, r in ipairs(f.regions or {}) do
      if r.shown and type(r.text) == "string" then out[#out + 1] = r.text end
    end
  end
  for _, line in ipairs(GameTooltip.lines or {}) do
    out[#out + 1] = tostring(line)
  end
  for _, line in ipairs(s.printed) do
    out[#out + 1] = line
  end
  for _, x in ipairs(extra or {}) do
    out[#out + 1] = x
  end
  return out
end

local SCREEN_W, SCREEN_H = UIParent.w, UIParent.h
local FRACTION = {
  LEFT = 0,
  RIGHT = 1,
  TOP = 1,
  BOTTOM = 0,
  CENTER = 0.5,
}
local function fractions(point)
  local h = point:find("LEFT") and 0 or point:find("RIGHT") and 1 or 0.5
  local v = point:find("TOP") and 1 or point:find("BOTTOM") and 0 or 0.5
  return h, v
end

local hovers, clicks, texts = 0, 0, 0
-- Text the mock's width estimate (0.55 of the size a character) calls cut that a person has to judge in the game:
-- each with why. Anything that is a reason, or that wraps, never goes here.
local CUT_OK = {
  ["The guide cannot read your character"] = "the heading of the page that says the game hid the talents: 36 characters at size 24 in 440, estimated 475. Look at it in the game (docs/testing.md checklist)",
}
local failures = {}
local function fail(case, what) failures[#failures + 1] = case .. ": " .. what end

-- (the page as it stands: what the case demands of it)
local function tipWords(case)
  for _, line in ipairs(GameTooltip.lines or {}) do
    local t = plain(line)
    texts = texts + 1
    if t:find("[;!]") then fail(case, "a semicolon or exclamation mark in a tooltip: " .. t:sub(1, 60)) end
    if t:find("[\128-\255]") then fail(case, "not plain ASCII in a tooltip: " .. t:sub(1, 60)) end
  end
  if G.strict and #G.strict.violations > 0 then
    for _, v in ipairs(G.strict.violations) do
      fail(case, "the strict game refused: " .. v)
    end
    G.strict.violations = {}
  end
  if next(ns.faults) then
    for what, err in pairs(ns.faults) do
      fail(case, "Primer kept a fault: " .. what .. ": " .. tostring(err):sub(1, 120))
    end
    ns.faults = {}
  end
end

local function audit(case)
  local sc = ns.screen
  -- sizes and places: the mock does not lay frames out, so a frame bigger than the screen, or a window
  -- anchored so that it leaves it, is what can be seen here
  local scale = PrimerFrame:GetScale()
  if PrimerFrame.w * scale > SCREEN_W or PrimerFrame.h * scale > SCREEN_H then
    fail(
      case,
      ("the window is %dx%d on a %dx%d screen"):format(PrimerFrame.w * scale, PrimerFrame.h * scale, SCREEN_W, SCREEN_H)
    )
  end
  local p = PrimerFrame.point
  if p and p[2] == UIParent and type(p[4]) == "number" then
    local ph, pv = fractions(p[1])
    local rh, rv = fractions(p[3] or p[1])
    local x, y = p[4], p[5] or 0
    local left = rh * SCREEN_W + x - ph * PrimerFrame.w * scale
    local bottom = rv * SCREEN_H + y - pv * PrimerFrame.h * scale
    if
      left < 0
      or bottom < 0
      or left + PrimerFrame.w * scale > SCREEN_W
      or bottom + PrimerFrame.h * scale > SCREEN_H
    then
      fail(case, ("the window is anchored off the screen (left %d, bottom %d)"):format(left, bottom))
    end
  end
  for _, f in ipairs(shownFrames()) do
    if not f.scrolled and (f.w > SCREEN_W or f.h > SCREEN_H) then
      fail(case, ("a frame is %dx%d, bigger than the screen (%s)"):format(f.w, f.h, f.name or f.kind))
    end
  end
  -- text cut short, where a reason is printed
  local cut = ns.fit()
  for i = #cut, 1, -1 do
    if CUT_OK[plain(cut[i])] then table.remove(cut, i) end
  end
  if #cut > 0 then
    local where = ""
    for _, f in ipairs(shownFrames()) do
      for _, r in ipairs(f.regions or {}) do
        if r.kind == "FontString" and r.shown and r.IsTruncated and r:IsTruncated() then
          where = (" [%d wide, size %d, in %s]"):format(r.w, r.font, f.name or f.kind)
        end
      end
    end
    fail(case, "text cut short: " .. plain(cut[1]):sub(1, 60) .. where)
  end
  -- the words
  for _, w in ipairs(words()) do
    texts = texts + 1
    local t = plain(w)
    if t:find("[;!]") then fail(case, "a semicolon or exclamation mark: " .. t:sub(1, 60)) end
    if t:find("[\128-\255]") then fail(case, "not plain ASCII: " .. t:sub(1, 60)) end
  end
  -- the pictures: a spell or talent icon that did not resolve shows the question mark
  for _, f in ipairs(shownFrames()) do
    for _, r in ipairs(f.regions or {}) do
      if MODE ~= "secrets" and r.kind == "Texture" and r.shown and r.texture == ns.kit.QUESTION then
        fail(case, "an icon left as the question mark")
        break
      end
    end
  end
  if next(ns.faults) then
    for what, err in pairs(ns.faults) do
      fail(case, "Primer kept a fault: " .. what .. ": " .. tostring(err):sub(1, 120))
    end
    ns.faults = {}
  end
  if G.strict and #G.strict.violations > 0 then
    for _, v in ipairs(G.strict.violations) do
      fail(case, "the strict game refused: " .. v)
    end
    G.strict.violations = {}
  end
end

local function skipped(f)
  return f.name and (f.name:find("^PrimerFrameTab%d") or f.name == "PrimerFrameCloseButton")
    or f == PrimerFrame.CloseButton
end

-- hover and click everything on the page that answers to it
local function touch(case)
  local list = shownFrames()
  for _, f in ipairs(list) do
    if not skipped(f) then
      for _, script in ipairs({ "OnEnter", "OnLeave" }) do
        local fn = f.scripts[script]
        if fn then
          hovers = hovers + 1
          local ok, err = xpcall(fn, debug.traceback, f)
          if not ok then fail(case, ("%s on %s: %s"):format(script, f.name or f.kind, tostring(err):sub(1, 200))) end
          if script == "OnEnter" then tipWords(case .. " (tooltip)") end
        end
      end
    end
  end
  for _, f in ipairs(list) do
    if not skipped(f) then
      for _, script in ipairs({ "OnClick", "OnMouseUp" }) do
        local fn = f.scripts[script]
        if fn then
          clicks = clicks + 1
          local ok, err = xpcall(fn, debug.traceback, f, "LeftButton")
          if not ok then fail(case, ("%s on %s: %s"):format(script, f.name or f.kind, tostring(err):sub(1, 200))) end
        end
      end
    end
  end
  G.advance(0.5)
end

local function try(case, what, fn, ...)
  local ok, err = xpcall(fn, debug.traceback, ...)
  if not ok then fail(case, what .. ": " .. tostring(err):sub(1, 300)) end
  return ok
end

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
local boom = {}
for _, m in ipairs({
  "__index",
  "__newindex",
  "__len",
  "__call",
  "__concat",
  "__add",
  "__sub",
  "__mul",
  "__div",
  "__mod",
  "__pow",
  "__unm",
  "__lt",
  "__le",
  "__tostring",
}) do
  boom[m] = function() error("attempt to use a secret value", 2) end
end
local function secret(kind)
  -- (a userdata: LuaJIT ignores __len on a table and pairs and ipairs read it raw, so only this raises on all of them)
  local v = newproxy(true)
  local mt = getmetatable(v)
  for k, f in pairs(boom) do
    mt[k] = f
  end
  kinds[v] = kind
  s.secrets[v] = true
  return v
end
-- whole: every value comes back secret. fields: a table comes back plain, every value inside it secret
local function secretize(v, whole)
  local t = rawtype(v)
  if v == nil then return nil end
  if t == "table" and not kinds[v] then -- (a secret is a userdata, never a table here)
    if whole then return secret("table") end
    local out = {}
    for k, x in pairs(v) do
      out[k] = secretize(x, false)
    end
    return out
  end
  return kinds[v] and v or secret(t)
end
local function pack(...) return { n = select("#", ...), ... } end
local function secretized(fn, whole)
  return function(...)
    local r = pack(fn(...))
    for i = 1, r.n do
      r[i] = secretize(r[i], whole)
    end
    return unpack(r, 1, r.n)
  end
end

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
  local targets = {}
  for name, value in pairs(_G) do
    if rawtype(value) == "table" and name:find("^C_") and name ~= "C_Timer" then
      for fname, fn in pairs(value) do
        if rawtype(fn) == "function" then targets[#targets + 1] = { name .. "." .. fname, value, fname } end
      end
    end
  end
  for _, name in ipairs({ "UnitClass", "UnitName", "UnitGUID", "UnitRace", "UnitSex", "UnitLevel", "UnitFactionGroup" }) do
    targets[#targets + 1] = { name, _G, name }
  end
  table.sort(targets, function(a, b) return a[1] < b[1] end)
  local flagged = G.strict and G.strict.flagged or {}
  local warrior, mage
  for _, c in ipairs(classes) do
    if c.token == "WARRIOR" then warrior = c end
    if c.token == "MAGE" then mage = c end
  end
  local ran = 0
  for _, target in ipairs(targets) do
    local name, tbl, key = target[1], target[2], target[3]
    local original = tbl[key]
    secretUnitClass = name == "UnitClass"
    if secretUnitClass then original = function(...) return playing(...) end end
    for _, whole in ipairs({ true, false }) do
      tbl[key] = secretized(original, whole)
      local before = #failures
      -- (a Warrior with forty points down Fury, a Mage at the first point)
      local label = ("%s answering %s"):format(name, whole and "secret" or "with secret fields")
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
    end
    tbl[key] = original
  end
  local n = 0
  for _ in pairs(flagged) do
    n = n + 1
  end
  secretsRan = ran
  secretsTargets = #targets
  secretsFlagged = n
end

if MODE == "secrets" then
  secrets()
else
  matrix()
end
UnitClass = realClass

if #failures > 0 then
  -- (the first of each kind, so one cause is not a thousand lines)
  local seen, out = {}, {}
  for _, f in ipairs(failures) do
    local kind = f:gsub("^.-: ", ""):gsub("%d+", "#"):sub(1, 70)
    if not seen[kind] then
      seen[kind] = 0
      out[#out + 1] = f
    end
    seen[kind] = seen[kind] + 1
  end
  io.stderr:write(("✗ matrix: %d failures in %d kinds\n"):format(#failures, #out))
  for _, f in ipairs(out) do
    io.stderr:write("  ", f, "\n")
  end
  os.exit(1)
end
if MODE == "secrets" then
  io.write(
    ("✓ secrets: %d functions answered with secret values, whole and field by field, %d pages played, %d of them flagged by the documentation (%.1fs)\n"):format(
      secretsTargets or 0,
      secretsRan or 0,
      secretsFlagged or 0,
      os.clock() - started
    )
  )
  os.exit(0)
end
io.write(
  ("✓ matrix: %d cases, %d tab draws, %d hovers, %d clicks, %d words, %s, %.1fs (%s)\n"):format(
    cases,
    draws,
    hovers,
    clicks,
    texts,
    G.strict and G.strict.report():match("^%d+ calls") or "lenient",
    os.clock() - started,
    G.FOREVER and "Forever" or "Classic Era"
  )
)
