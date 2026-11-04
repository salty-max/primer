-- Primer played through: a login, /primer opening the window with its three
-- tabs, the minimap button, the guide's rules and words (every key has its
-- text), the rules over a character (the page for the game, the class and the
-- season, the role, the build, the stage, the rows true now, the talents
-- taken), the three pages as the window draws them, and nothing asked of
-- combat. FOREVER=1: Forever's client (no build is written for it yet).
local G = dofile("addon/test/game.lua")
local s, ns = G.state, G.ns
local count = 0
local function check(ok, what)
  if not ok then error("✗ " .. what, 2) end
  count = count + 1
end
local function said(text)
  for _, line in ipairs(s.printed) do
    if line:find(text, 1, true) then return true end
  end
  return false
end
local D = ns.data

-- ── the guide's rules ────────────────────────────────────────────────────────
check(D.game == (G.FOREVER and "forever" or "classic"), "this game's rules")
local text, builds = ns.guideText, 0
check(type(text) == "table", "the guide's words")
for id, b in pairs(D.builds) do
  builds = builds + 1
  check(D.classes[b.class] and D.classes[b.class].key, "a class for every build: " .. id)
  for _, key in ipairs({ b.intro, b.note }) do
    check(text[key], "a word for " .. key)
  end
  for _, step in ipairs(b.path) do
    check(text[step.why], "a reason for " .. b.key)
  end
  check(#b.stages >= 3 and #b.stages <= 4, "its stages: " .. b.key)
  for _, stage in ipairs(b.stages) do
    check(stage.from <= stage.to and (stage.rows or stage.plan), "a stage with rows or a plan: " .. b.key)
    for _, row in ipairs(stage.rows or {}) do
      check(text[row.say] and row.spell and row.level, "a row's word and facts: " .. b.key .. " " .. row.spell)
      check(row.level <= stage.to, "a row's level within its stage: " .. row.spell)
    end
    if stage.plan then
      -- (every line of a plan has its words, every spell its level, the loop ends on the line with no condition)
      local plan = stage.plan
      for _, name in ipairs({ "opening", "loop", "between", "low" }) do
        for i, st in ipairs(plan[name] or {}) do
          check(st.spell or st.text, "a plan step is a spell or a text: " .. b.key)
          check(text[st.why] and (not st.cond or text[st.cond]), "a plan step's words: " .. b.key .. " " .. name .. i)
          check(not st.spell or (st.level and st.level <= stage.to), "a plan step's level within its stage: " .. b.key)
          check(
            name ~= "loop" or (i == #plan.loop) == (st.cond == nil),
            "only the loop's last line has no condition: " .. b.key
          )
        end
      end
      check(#plan.opening > 0 and #plan.loop > 0, "a plan has an opening and a loop: " .. b.key)
    end
  end
  check(b.line and text[b.line], "a build's line for the overview: " .. b.key)
  check(ns.say(b.intro) == text[b.intro], "ns.say gives a word by its key")
end
if G.FOREVER then
  check(builds == 0, "Forever: no build written yet")
else
  check(
    builds == 9 and D.builds[1] and D.builds[2] and D.builds[3],
    "Classic Era: the Warrior's, Paladin's and Mage's nine builds"
  )
  check(D.classes[2].token == "PALADIN" and #D.classes[2].builds == 3, "the Paladin's class")
  check(D.classes[8].token == "MAGE" and #D.classes[8].builds == 3, "the Mage's class")
  check(D.classes[1].token == "WARRIOR", "the Warrior's class")
end
check(ns.say("no such key") == "no such key", "a missing word shows as itself")

-- ── a first login ────────────────────────────────────────────────────────────
check(not PrimerFrame, "no window before it is asked for")
G.login()
check(PrimerChar and PrimerChar.guid == s.guid, "the guide is this character's")
check(PrimerMinimapButton, "the minimap button, named for Keyring")
check(ns.kit.MINIMAP_ANGLES.Primer == ns.option("minimapAngle"), "the button at the kit's place")

-- ── nothing asked of combat ──────────────────────────────────────────────────
for event in pairs(G.registered) do
  check(
    not event:find("COMBAT") and not event:find("^UNIT_") and not event:find("SPELLCAST"),
    "no combat event: " .. event
  )
end

-- ── /primer ──────────────────────────────────────────────────────────────────
check(SlashCmdList.PRIMER and SLASH_PRIMER1 == "/primer", "the slash command")
SlashCmdList.PRIMER("")
check(PrimerFrame and PrimerFrame:IsShown(), "/primer opens the window")
for n = 1, 4 do
  check(_G["PrimerFrameTab" .. n], "tab " .. n)
end
check(not _G["PrimerFrameTab5"], "four tabs: Overview, Play, Talents, Role")
check(ns.TAB.overview == 1 and ns.TAB.play == 2, "the Overview is the first tab")
check(PrimerFrame.selectedTab == ns.TAB.play, "the Play tab first")
SlashCmdList.PRIMER("")
check(not PrimerFrame:IsShown(), "/primer again closes it")
SlashCmdList.PRIMER("nonsense")
check(said("/primer opens the guide"), "an unknown word prints the usage")
ns.open(ns.TAB.role)
check(PrimerFrame:IsShown() and PrimerFrame.selectedTab == ns.TAB.role, "opened at the Role tab")
-- (the mock keeps no ids: the tab says its own)
local tab3 = _G.PrimerFrameTab3
tab3.GetID = function() return 3 end
tab3:GetScript("OnClick")(tab3)
check(PrimerFrame.selectedTab == ns.TAB.talents, "a click on a tab chooses it")

-- ── the rules over a character ───────────────────────────────────────────────
local R = ns.rules
local function snap(o)
  o = o or {}
  local spells = o.spells or {}
  return {
    level = o.level or 12,
    token = o.token or "WARRIOR",
    className = o.className or "Warrior",
    season = o.season or 0,
    knows = function(id) return spells[id] == true end,
    talents = o.talents or { byId = {}, points = {}, total = 0 },
  }
end
local function set(...)
  local t = {}
  for _, id in ipairs({ ... }) do
    t[id] = true
  end
  return t
end

-- the page: the season, the game, the class
check(R.page(snap({ season = 2 })) == "season", "Season of Discovery: the guide is quiet")
if G.FOREVER then
  check(R.page(snap()) == "game", "Forever: no guide for the game yet, never Era's")
  check(R.page(snap({ season = 2 })) == "season", "the season first, on Forever too")
else
  check(R.page(snap({ season = 3 })) == "guide", "Hardcore is Era: the guide stays on")
  check(R.page(snap({ season = 0 })) == "guide", "Classic Era, no season: the guide is on")
  check(R.page(snap({ season = 11 })) == "guide", "Fresh realms: on")
  local kind, class = R.page(snap())
  check(kind == "guide" and class == 1, "a warrior has a guide")
  check(R.page(snap({ token = "DRUID" })) == "class", "a druid has none written: the class page, nothing of another's")
end

if not G.FOREVER then
  local arms, fury, prot = D.builds[1], D.builds[2], D.builds[3]
  local function taken(ranks)
    -- (the game lists all three trees, a tree with no points as 0)
    local t = { byId = {}, points = { 0, 0, 0 }, total = 0 }
    for spell, rank in pairs(ranks) do
      local d = D.talents[spell]
      -- (a tree's place in the window: its place among its class's three trees)
      local place
      for _, c in pairs(D.classes) do
        local trees = {}
        for _, id in ipairs(c.builds) do
          trees[#trees + 1] = D.builds[id].tree
        end
        table.sort(trees)
        for i, tree in ipairs(trees) do
          if tree == d.tab then place = i end
        end
      end
      t.byId[d.id] = { name = "T", icon = 1, rank = rank, max = d.max, tab = place }
      t.points[t.byId[d.id].tab] = (t.points[t.byId[d.id].tab] or 0) + rank
      t.total = t.total + rank
    end
    return t
  end

  -- the phases, the build the points follow, the drift, the split, a role change
  local function at(level, ranks) return snap({ level = level, talents = taken(ranks) }) end
  local ARMS15 = { [12282] = 3, [12286] = 3, [12295] = 5, [12290] = 2, [12296] = 1, [12834] = 1 }
  local FURY15 = { [12320] = 5, [12322] = 5, [12318] = 5 }
  local PROT15 = { [12298] = 5, [12297] = 5, [12299] = 5 }
  check(
    R.phase(at(5, {})) == "untalented" and R.phase(at(12, {})) == "choose" and R.phase(at(24, ARMS15)) == "spent",
    "the phases: untalented, choose, spent"
  )
  check(
    R.asking(at(12, {}), {}, 1) and not R.asking(at(12, {}), { role = "tank" }, 1),
    "level 10, none spent, no role: the question; a role chosen: not asked again"
  )
  check(
    not R.asking(at(5, {}), {}, 1) and not R.asking(at(24, ARMS15), {}, 1),
    "not asked before level 10 nor once points are spent"
  )
  check(
    not R.asking(at(12, {}), { notYet = 12 }, 1) and R.asking(at(13, {}), { notYet = 12 }, 1),
    "'not yet' holds for the level and asks again after the next"
  )
  local r = R.resolve(at(12, {}), 1, {})
  check(
    r.phase == "choose" and r.build == 1 and r.followed == "default" and not r.roleChosen,
    "nothing spent: the default build, no role chosen"
  )
  r = R.resolve(at(12, {}), 1, { role = "tank" })
  check(
    r.build == 3 and r.roleChosen and r.followed == "default",
    "a respec to zero keeps the stored role: its build, advice not a question"
  )
  -- the points of the first n steps of a build's path (a level n + 9 character who followed it)
  local function along(id, n)
    local ranks = {}
    for _, step in ipairs(D.builds[id].path) do
      local count = math.min(n, step.points[2] - step.points[1] + 1)
      if count <= 0 then break end
      local spell = step.talent or step.any[1]
      ranks[spell] = (ranks[spell] or 0) + count
      n = n - count
    end
    return ranks
  end
  local HOLY5 = { [20257] = 5 }

  -- the user's case: a Paladin with 5 Holy points, nothing elsewhere
  r = R.resolve(at(14, HOLY5), 2, { role = "damage" })
  check(
    r.build == 6 and r.role == "damage" and r.mode == "points" and not r.open,
    "role Damage, 5 points in Holy: Retribution, whatever the points (a Damage paladin can only be Retribution)"
  )
  r = R.resolve(at(14, HOLY5), 2, { role = "heal" })
  check(r.build == 7 and r.mode == "points", "role Heal, the same points: Holy")
  r = R.resolve(at(14, HOLY5), 2, {})
  check(
    r.mode == "open"
      and #r.open == 3
      and r.open[1] == 6
      and r.build == 6
      and not r.roleChosen
      and r.followed == "points",
    "no role chosen: the points leave all three builds open, the page does not guess Holy from the tree with most points"
  )
  r = R.resolve(at(14, HOLY5), 2, { pickedBuild = 6 })
  check(
    r.mode == "picked" and r.build == 6 and r.drift == nil and not r.unreachable,
    "a picked Retribution with 5 early points in Holy: kept, no drift, the path's tolerance never fires for harmless off-tree points"
  )
  -- feasibility: 20 points outside a build's tree keep it open, 21 close it
  check(R.reachable(at(29, along(7, 20)), D.builds[6]), "20 points in Holy: Retribution is still reachable")
  check(not R.reachable(at(30, along(7, 21)), D.builds[6]), "21 points in Holy: Retribution is out of reach")
  r = R.resolve(at(30, along(7, 21)), 2, {})
  check(
    r.mode == "points" and r.build == 7 and not r.open,
    "21 points in Holy and no role: only Holy is open, so the points do tell"
  )
  r = R.resolve(at(30, along(7, 21)), 2, { role = "damage" })
  check(
    r.build == 6
      and r.role == "damage"
      and not r.unreachable
      and r.drift
      and r.drift.kind == "role"
      and r.drift.role == "heal"
      and r.drift.unpicked,
    "a Damage paladin with 21 points in Holy: Retribution is out of reach, only Holy is open, a switch is offered and nothing is switched"
  )
  check(R.split(at(30, along(7, 21))) == nil, "21 points in one tree are no split")
  check(
    R.required(D.builds[2]) == 31 and R.required(D.builds[1]) == 31 and R.required(D.builds[6]) == 31,
    "a build needs 31 in its own tree (its deepest talent's 30 and the point itself), not what its path happens to put there"
  )
  check(
    R.reachable(at(29, along(1, 20)), D.builds[2]),
    "20 points in Arms: Fury (whose path has 32 in Fury) is still reachable"
  )
  -- a road is recognised only while the build can be reached
  local road, recognised = R.pickRoad(at(34, along(7, 25)), D.builds[6])
  check(
    road == 1 and recognised == false,
    "25 points in Holy: Retribution cannot be reached, so no road of it is recognised"
  )
  road, recognised = R.pickRoad(at(19, along(7, 10)), D.builds[6])
  check(road == 2 and recognised == true, "10 points in Holy at 19: reachable, the other road is recognised")
  -- a picked build whose points can no longer reach it: said once, the nearest open build offered
  r = R.resolve(at(34, along(7, 25)), 2, { role = "damage", pickedBuild = 6 })
  check(
    r.drift
      and r.drift.kind == "role"
      and r.drift.role == "heal"
      and r.drift.build == 7
      and r.build == 6
      and r.role == "damage",
    "a picked Retribution with 25 Holy points: unreachable, another role's build is open, a switch is offered and nothing is switched"
  )
  r = R.resolve(at(34, along(2, 25)), 1, { role = "damage", pickedBuild = 1 })
  check(
    r.drift and r.drift.kind == "build" and r.drift.from == 1 and r.drift.to == 2 and r.build == 1,
    "a picked Arms with 25 Fury points: unreachable, Fury is open in the role, the page stays on Arms and says so"
  )
  local mark = r.drift.mark
  r = R.resolve(at(34, along(2, 25)), 1, { role = "damage", pickedBuild = 1, driftSeen = mark })
  check(r.build == 1 and r.drift.seen, "kept: the pick stands, the note stays dismissed")
  r = R.resolve(at(34, along(7, 25)), 2, { role = "damage", pickedBuild = 6, driftSeen = "other" })
  check(r.drift and not r.drift.seen, "a dismissal of another drift does not hide this one")
  -- nothing is reachable: the points fit no build (21 in Holy, 21 in Protection)
  local spread = along(7, 21)
  for spell, rank in pairs(along(8, 21)) do
    spread[spell] = (spread[spell] or 0) + rank
  end
  r = R.resolve(at(51, spread), 2, {})
  check(
    r.unreachable and r.mode == "points" and not r.open,
    "21 points in Holy and 21 in Protection: no build fits, the page says so and shows the nearest"
  )
  -- a picked build with nothing at all open: the page stays on the pick and says so
  r = R.resolve(at(51, spread), 2, { role = "damage", pickedBuild = 6 })
  check(
    r.unreachable and r.build == 6 and r.followed == "picked",
    "a pick when no build fits the points: the page stays on it"
  )
  -- an open role with two builds: the page shows the first and asks which
  r = R.resolve(at(14, { [12298] = 5 }), 1, { role = "damage" })
  check(
    r.mode == "open" and #r.open == 2 and r.open[1] == 1 and r.roleChosen,
    "role Damage, 5 points in Protection: Arms and Fury are both open, the page asks which"
  )
  -- a respec to zero: the stored role stays, nothing is asked
  r = R.resolve(at(14, {}), 2, { role = "damage" })
  check(
    r.phase == "choose" and r.build == 6 and r.roleChosen and r.mode == "none",
    "a respec to zero keeps the role, no question"
  )
  r = R.resolve(at(24, ARMS15), 1, { role = "damage", freestyle = true })
  check(r.mode == "own" and r.drift == nil and not r.open, "your own way: no drift, no question")
  -- a role change: the points off the nearest build of the new role
  local near, far = R.nearest(at(20, { [12282] = 3, [12286] = 3, [12295] = 5 }), 1, "tank")
  check(near == 3 and far == 11, "a role change counts the points that differ from the new role's nearest build")
  local advice = R.advice(1, "tank")
  check(
    #advice.builds == 1 and advice.builds[1] == 3 and #advice.picks == 3 and advice.picks[1] == prot.path[1],
    "the advice: the role's builds and the first three picks of the first"
  )

  -- the roles and builds
  check(table.concat(R.roles(1), ",") == "damage,tank", "the warrior's roles: damage and tank (no healer written)")
  check(#R.builds(1) == 3 and #R.builds(1, "damage") == 2 and R.builds(1, "tank")[1] == 3, "the builds of a role")
  check(R.role(snap(), 1, nil) == "damage", "the default role: the first build's")
  check(R.role(snap(), 1, "tank") == "tank", "the role the player set")
  check(R.role(snap(), 1, "heal") == "damage", "a role the class has no build for is ignored")
  local deep = snap({ talents = taken({ [12297] = 5, [12298] = 5 }) })
  check(R.role(deep, 1, nil) == "tank", "no choice: the tree with the most points sets the role")
  check(R.role(deep, 1, "damage") == "damage", "the player's switch outranks the points")
  check(R.build(snap(), 1, "damage", nil) == 1, "the default build: the first of the role")
  check(R.build(snap(), 1, "damage", 2) == 2, "the build the player chose")
  check(R.build(snap(), 1, "tank", 2) == 3, "a chosen build of another role is ignored")
  check(R.build(snap(), 1, "damage", 99) == 1, "a build id the data lacks is ignored")
  local furyDeep = snap({ talents = taken({ [12320] = 5, [12322] = 5 }) })
  check(R.build(furyDeep, 1, "damage", nil) == 2, "no choice: the role's build with the most points")

  -- the stage for the level
  check(
    R.stage(arms, 1) == 1 and R.stage(arms, 19) == 1 and R.stage(arms, 20) == 2 and R.stage(arms, 60) == 3,
    "the stage for the level"
  )
  check(
    R.stage({ stages = { { from = 1, to = 60, phase = "choose" } } }, 30, "spent") == 1,
    "a stage that names another phase is still the level's, never the last"
  )
  check(
    R.stage({ stages = { { from = 1, to = 60, phase = "choose" }, { from = 1, to = 60 } } }, 30, "choose") == 1,
    "a stage for the phase comes first"
  )
  local none, starts = R.stage(prot, 4)
  check(none == nil and starts == 10, "Protection starts at 10: before it, no stage")
  check(R.stage(prot, 10) == 1, "and has its stage at 10")

  -- the rows true now
  local book = set(100, 772, 78, 6343, 1715, 2687)
  local rows, unlearned = R.rows(arms.stages[1], snap({ level = 12, spells = book }))
  check(#rows == 6 and unlearned == 1, "level 12: the spells in the book, one learnable and not learned")
  check(rows[1].spell == 100 and rows[6].spell == 2687, "the rows keep the writer's order")
  rows, unlearned = R.rows(arms.stages[1], snap({ level = 5, spells = book }))
  check(#rows == 3 and unlearned == 0, "level 5: the rows above the level are left out, not counted")
  rows = R.rows(arms.stages[1], snap({ level = 12, spells = set(100) }))
  check(#rows == 1, "a spell not in the book is left out")
  -- a talent's row waits for the talent
  local s2 = arms.stages[2]
  local book2 = set(6673, 100, 845, 5308, 7384, 1464, 2458, 1680, 12292)
  local base = R.rows(s2, snap({ level = 36, spells = book2 }))
  local withTalents = R.rows(s2, snap({ level = 36, spells = book2, talents = taken({ [12295] = 5, [12292] = 1 }) }))
  local function has(list, spell)
    for _, r in ipairs(list) do
      if r.spell == spell then return true end
    end
    return false
  end
  check(not has(base, 12292) and has(withTalents, 12292), "a talent's own row shows once the talent is taken")
  check(has(withTalents, 1680) and has(base, 1680), "a row with no talent need shows by level and book")
  check(
    not has(base, 2458)
      and has(R.rows(s2, snap({ level = 36, spells = book2, talents = taken({ [12295] = 5 }) })), 2458),
    "Berserker Stance waits for Tactical Mastery"
  )

  -- the talents taken
  local steps, nextStep = R.steps(arms, snap({ talents = taken({}) }))
  check(#steps == 15 and nextStep == 1 and steps[1].state == "later", "nothing taken: the first step is next")
  steps, nextStep = R.steps(arms, snap({ talents = taken({ [12282] = 3, [12286] = 1 }) }))
  check(
    steps[1].state == "done" and steps[2].state == "partly" and steps[2].rank == 1 and nextStep == 2,
    "a step done, the next one partly taken"
  )
  steps = R.steps(
    arms,
    snap({
      talents = taken({
        [12282] = 3,
        [12286] = 3,
        [12295] = 5,
        [12290] = 2,
        [12296] = 1,
        [12834] = 3,
        [12163] = 5,
        [16493] = 2,
        [12292] = 1,
        [12281] = 5,
      }),
    })
  )
  check(steps[10].state == "done" and #steps[10].options == 4, "a choice step is done when one of its talents is full")
  check(R.talent(snap(), 12282) == nil, "a talent the game does not list is nil")
  check(
    R.unspent(snap({ level = 9 })) == 0
      and R.unspent(snap({ level = 10 })) == 1
      and R.unspent(snap({ level = 12 })) == 3,
    "points from level 10, one a level"
  )
  check(R.unspent(snap({ level = 12, talents = taken({ [12282] = 3 }) })) == 0, "less what is spent")
  check(R.unspent(snap({ level = 60, talents = taken({}) })) == 51, "51 at most")
end

-- ── the window as it draws ───────────────────────────────────────────────────
local function pageTexts()
  local out = { PrimerPage.title.text or "", PrimerPage.sub.text or "" }
  for _, pool in ipairs({ PrimerPage.paragraphs, PrimerPage.texts, PrimerPage.pairs }) do
    for _, x in ipairs(pool) do
      if x.shown ~= false then
        table.insert(out, x.text or (x.value and x.value.text) or "")
        if x.value then table.insert(out, x.label.text or "") end
      end
    end
  end
  for _, h in ipairs(PrimerPage.headings) do
    if h.shown ~= false and h.text then table.insert(out, h.text.text or "") end
  end
  if PrimerPage.note.shown then table.insert(out, PrimerPage.note.text or "") end
  return table.concat(out, "\n")
end
local function listTexts()
  local out = {}
  for _, r in ipairs(PrimerList.rows) do
    if r.shown then
      table.insert(out, (r.text.text or "") .. "|" .. (r.under.text or "") .. "|" .. (r.count.text or ""))
    end
  end
  return table.concat(out, "\n")
end
local function press(text)
  for _, b in ipairs(PrimerPage.buttonPool) do
    if b.shown and b.text == text then
      b:GetScript("OnClick")(b)
      return
    end
  end
  error("no button: " .. text, 2)
end
-- a plan step by its spell's name (the game's, here "Spell <id>" as the mock names it, or the text of a line)
local function planStep(name)
  for _, r in ipairs(ns.planRows) do
    if r.shown and r.name.text:find(name, 1, true) then return r end
  end
end
local function readySteps()
  local n = 0
  for _, r in ipairs(ns.planRows) do
    if r.shown and r.state == "ready" then n = n + 1 end
  end
  return n
end
local function shownRows()
  local n = 0
  for _, r in ipairs(ns.playRows) do
    if r.shown then n = n + 1 end
  end
  return n
end

if G.FOREVER then
  ns.open(ns.TAB.play)
  check(PrimerPage.title.text == "No guide for Forever yet", "Forever: the page says so, in the house voice")
  check(
    pageTexts():find("Classic Era's advice would send you wrong", 1, true),
    "and says why, never showing Era's text"
  )
  check(shownRows() == 0, "no line of any build on Forever")
  for n = 2, 3 do
    ns.open(n)
    check(PrimerPage.title.text == "No guide for Forever yet", "the same page on every tab: " .. n)
  end
else
  s.spells = set(100, 772, 78, 6343, 1715, 2687)
  ns.open(ns.TAB.play)
  check(
    PrimerPage.title.text == "Arms" and PrimerPage.sub.text == "Level 1 to 19",
    "Play: the build and the stage for the level"
  )
  check(shownRows() == 6, "Play: six lines, the spells in the book")
  local first = ns.playRows[1]
  check(
    first.name.text == "Spell 100" and first.slot.icon.texture == 100100,
    "Play: the name and picture are the game's, by id"
  )
  check(first.facts.text == "In Spell 2457, before the pull", "Play: the form and the moment, in the data's words")
  check(first.say.text == ns.say("warrior-arms.s1.r1"), "Play: the line's reason is the writer's")
  check(
    pageTexts():find("1 spell for this stage is not in your book yet.", 1, true),
    "Play: the spell to learn is counted"
  )
  check(
    pageTexts():find("Checked on Classic Era 1.15.9.70576, 2026-11-03.", 1, true),
    "Play: the footer says which game and day it was checked against"
  )
  check(
    PrimerFrame.state.text == "Arms Warrior. Damage. Level 12. Not chosen yet.",
    "every page says what it is for: the build, the class, the role, the level and how it was chosen"
  )
  check(
    listTexts():find("Arms|Damage", 1, true)
      and listTexts():find("Fury|Damage", 1, true)
      and not listTexts():find("Protection", 1, true),
    "the builds offered are the role's"
  )
  -- a level up changes the page
  s.level = 20
  s.spells[845] = true
  G.fire("PLAYER_LEVEL_UP", 20)
  G.advance(0.5)
  check(PrimerPage.sub.text == "Level 20 to 39", "a level up while the window is open: the next stage")
  s.level = 12

  -- the tree's name is the game's, by place: a game that names it otherwise is believed
  s.treeNames[161] = "Armes"
  ns.open(ns.TAB.play)
  check(
    PrimerPage.title.text == "Armes" and listTexts():find("Armes|Damage", 1, true),
    "a build is named as the game names its tree"
  )
  s.treeNames[161] = "Arms"
  ns.open(ns.TAB.play)

  -- the build chooser
  local fury
  for _, r in ipairs(PrimerList.rows) do
    if r.shown and r.text.text == "Fury" then fury = r end
  end
  fury:GetScript("OnClick")(fury)
  check(
    PrimerPage.title.text == "Fury" and PrimerChar.groups[1].pickedBuild == nil,
    "a click on another build only looks: nothing is chosen"
  )
  check(
    pageTexts():find("Looking at Fury, not your build.", 1, true)
      and PrimerFrame.state.text == "Looking at Fury, not your build. Yours is Arms.",
    "and says so loudly, and who yours is"
  )
  press("Back to Arms")
  check(
    PrimerPage.title.text == "Arms" and PrimerFrame.state.text:find("Arms Warrior", 1, true),
    "back: the page is yours again"
  )
  fury = nil
  for _, r in ipairs(PrimerList.rows) do
    if r.shown and r.text.text == "Fury" then fury = r end
  end
  fury:GetScript("OnClick")(fury)
  press("Use this build")
  check(
    PrimerChar.groups[1].pickedBuild == 2
      and PrimerPage.title.text == "Fury"
      and PrimerFrame.state.text == "Fury Warrior. Damage. Level 12. Following your pick.",
    "using a build chooses it, the page and its header follow"
  )

  -- a class with no overview written: its page and its builds
  ns.open(ns.TAB.overview)
  check(
    PrimerPage.title.text == "Warrior"
      and pageTexts():find("Stances change what you can press.", 1, true)
      and pageTexts():find("Arms", 1, true)
      and not pageTexts():find("Good at", 1, true),
    "Warrior, Overview: no overview written, the class's page and the builds"
  )
  ns.open(ns.TAB.play)

  -- the Talents tab: names and pictures are the game's, what is taken is read
  s.ranks[ns.data.talents[12320].id] = 3
  ns.open(ns.TAB.talents)
  check(PrimerPage.title.text == "Talent " .. ns.data.talents[12320].id, "Talents: the talent's name, the game's")
  check(listTexts():find("3/5", 1, true), "Talents: the rank taken of the step")
  check(
    pageTexts():find(
      "No talent points to spend. Your next pick is Talent " .. ns.data.talents[12320].id .. ", at level 10.",
      1,
      true
    ),
    "Talents: level 12 with 3 points in, none to spend, the next pick by the game's name"
  )
  check(pageTexts():find("Your next pick is", 1, true), "Talents: the next pick")
  check(
    pageTexts():find("Where players split: the filler before", 1, true),
    "Talents: where players split, the writer's fragment after its lead-in"
  )
  s.ranks[ns.data.talents[12320].id] = nil

  -- the Role tab: the switch, and the builds it offers
  ns.open(ns.TAB.role)
  check(
    PrimerPage.title.text == "Fury" and listTexts():find("Damage||2", 1, true) and listTexts():find("Tank||1", 1, true),
    "Role: the build's page, the roles with their builds"
  )
  local tank
  for _, r in ipairs(PrimerList.rows) do
    if r.shown and r.text.text == "Tank" then tank = r end
  end
  tank:GetScript("OnClick")(tank)
  check(
    PrimerChar.groups[1].role == "damage" and pageTexts():find("Looking at Tank, not your role.", 1, true),
    "Role: a click on another role only looks"
  )
  press("Use this role")
  check(
    PrimerChar.groups[1].role == "tank" and PrimerChar.groups[1].pickedBuild == nil,
    "Role: using it keeps the switch and lets the other role's build go"
  )
  check(PrimerPage.title.text == "Protection", "Role: the role's build shows")
  ns.open(ns.TAB.play)
  check(
    PrimerPage.title.text == "Protection" and PrimerPage.sub.text == "Level 10 to 19",
    "Play: Protection's first stage at level 12"
  )
  s.level = 4
  ns.open(ns.TAB.play)
  check(
    pageTexts():find("This build starts at level 10. Come back then.", 1, true) and shownRows() == 0,
    "Play: before Protection's first stage, the page says when it starts"
  )
  s.level = 12
  PrimerChar.groups[1] = {}
  PrimerFrame:Hide() -- (what the page is for is worked out when it is opened)

  -- the window keeps itself current
  for _, e in ipairs({
    "PLAYER_ENTERING_WORLD",
    "PLAYER_LEVEL_UP",
    "SPELLS_CHANGED",
    "LEARNED_SPELL_IN_SKILL_LINE",
    "TRAINER_UPDATE",
    "CHARACTER_POINTS_CHANGED",
    "PLAYER_TALENT_UPDATE",
    "ACTIVE_TALENT_GROUP_CHANGED",
  }) do
    check(G.registered[e], "listens for " .. e)
  end
  check(not G.registered.TRAIT_CONFIG_UPDATED, "an event this client lacks is skipped, the login went on")
  ns.open(ns.TAB.play)
  s.level = 12
  local before = ns.draws
  for _, e in ipairs({
    "SPELLS_CHANGED",
    "TRAINER_UPDATE",
    "LEARNED_SPELL_IN_SKILL_LINE",
    "SPELLS_CHANGED",
    "PLAYER_LEVEL_UP",
  }) do
    G.fire(e)
  end
  check(ns.draws == before, "a burst of events draws nothing at once")
  G.advance(0.4)
  check(ns.draws == before + 1, "and one draw a moment later, not five")
  check(shownRows() == 6, "(nothing new yet)")
  s.spells[7384] = true
  G.fire("SPELLS_CHANGED")
  G.advance(0.4)
  check(shownRows() == 7 and ns.playRows[7].spell == 7384, "a spell learned shows in the list without a reload")
  check(
    not pageTexts():find("not in your book yet", 1, true),
    "and the spell waiting for the trainer is no longer counted"
  )
  PrimerFrame:Hide()
  s.spells[7384] = nil
  ns.open(ns.TAB.play)
  check(shownRows() == 6, "a closed window is drawn afresh when it opens")
  s.spells[7384] = true

  -- talent groups: one on Era, the switch absent
  ns.open(ns.TAB.talents)
  check(not listTexts():find("Primary", 1, true), "Talents: one group, no switch")
  local calls = GetNumSpecGroups
  GetNumSpecGroups, C_SpecializationInfo.GetActiveSpecGroup = nil, nil
  ns.refresh()
  check(
    PrimerPage.title.text ~= nil and not listTexts():find("Primary", 1, true),
    "a client without the group calls has one group, and nothing breaks"
  )
  GetNumSpecGroups = calls
  ns.reader.reset()
  C_SpecializationInfo.GetActiveSpecGroup = function() return s.group end
  -- two groups (the Forever way): the switch, a build for each, the other group's talents read
  s.groups = 2
  s.otherRanks[ns.data.talents[12297].id] = 5
  s.otherRanks[ns.data.talents[12298].id] = 5
  ns.open(ns.TAB.talents)
  check(
    listTexts():find("Primary||in use", 1, true) and listTexts():find("Secondary||", 1, true),
    "Talents: two groups, the switch with the one in use named"
  )
  local secondary
  for _, r in ipairs(PrimerList.rows) do
    if r.shown and r.text.text == "Secondary" then secondary = r end
  end
  secondary:GetScript("OnClick")(secondary)
  check(
    PrimerFrame.state.text:find("Talent group 2.", 1, true)
      and PrimerFrame.state.text:find("Guessing from your points.", 1, true),
    "Talents: the other group's talents are read, 10 points in Protection leave the builds open, the header says it guesses"
  )
  check(PrimerChar.groups[2] == nil or PrimerChar.groups[2].pickedBuild == nil, "(looking at it chooses nothing)")
  ns.choice(2).pickedBuild = 3
  ns.refresh() -- (a choice: what the page is for is worked out again)
  check(
    PrimerChar.groups[2].pickedBuild == 3 and (PrimerChar.groups[1].pickedBuild == nil),
    "a build is chosen for the group looked at, the first group's untouched"
  )
  ns.open(ns.TAB.play)
  check(PrimerPage.title.text == "Arms", "Play follows the group in use")
  s.group = 2
  G.fire("ACTIVE_TALENT_GROUP_CHANGED")
  G.advance(0.4)
  check(PrimerPage.title.text == "Protection", "when the group in use changes, Play follows it")
  s.group, s.groups = 1, 1
  s.otherRanks = {}
  G.fire("ACTIVE_TALENT_GROUP_CHANGED")
  G.advance(0.4)
  PrimerChar.groups = {}

  -- nothing in combat
  s.combat = true
  s.reads = 0
  ns.open(ns.TAB.talents)
  ns.refresh()
  check(s.reads == 0, "in combat the guide reads nothing of the game")
  check(PrimerFrame.count.text == "In combat. The guide waits.", "in combat the window says it waits")
  s.combat = false
  G.advance(2.1)
  check(
    PrimerFrame.state.text:find("Warrior", 1, true) and PrimerFrame.count.text == "",
    "and draws when the fight is over"
  )

  -- the season
  s.season = 2
  ns.open(ns.TAB.play)
  check(PrimerPage.title.text == "Season of Discovery", "Season of Discovery: the guide is quiet")
  check(shownRows() == 0, "and shows no line")
  s.season = 3
  ns.open(ns.TAB.play)
  check(PrimerPage.title.text == "Arms", "Hardcore: the guide is on")
  s.season = 0

  -- a class with no guide
  local classToken = UnitClass
  UnitClass = function() return "Druid", "DRUID", 11 end
  ns.open(ns.TAB.play)
  check(
    PrimerPage.title.text == "No guide for Druid yet" and PrimerPage.sub.text == "Classic Era",
    "a class with no guide: the page says so"
  )
  check(
    pageTexts():find("The page stays empty rather than guess.", 1, true) and shownRows() == 0,
    "and shows nothing of another class"
  )
  UnitClass = classToken
end

-- ── the phase flow as the window draws it ────────────────────────────────────
if not G.FOREVER then
  local function points(map)
    s.ranks = {}
    for spell, rank in pairs(map) do
      s.ranks[ns.data.talents[spell].id] = rank
    end
  end
  local function button(text)
    for _, b in ipairs(PrimerPage.buttonPool) do
      if b.shown and b.text == text then return b end
    end
  end
  local function click(text)
    local b = button(text)
    check(b, "a button: " .. text)
    b:GetScript("OnClick")(b)
  end
  local function fresh(level, map)
    PrimerChar.groups = {}
    s.level = level
    s.spells = set(100, 772, 78, 6343, 1715, 2687)
    points(map or {})
  end
  local FURY25 = { [12320] = 5, [12322] = 5, [12318] = 5, [23584] = 5, [12317] = 5 }
  local PROT25 = { [12298] = 5, [12297] = 5, [12299] = 5, [12303] = 5, [12945] = 3, [12809] = 1, [12797] = 1 }
  local ARMS15 = { [12282] = 3, [12286] = 3, [12295] = 5, [12290] = 2, [12296] = 1, [12834] = 1 }
  local FURY15 = { [12320] = 5, [12322] = 5, [12318] = 5 }
  local PROT15 = { [12298] = 5, [12297] = 5, [12299] = 5 }

  -- level 10 or more, nothing spent: asked once, quietly, with a glow
  fresh(12)
  PrimerFrame:Hide()
  ns.open(ns.TAB.play)
  check(
    pageTexts():find("You have talent points to spend.", 1, true)
      and pageTexts():find("What do you want to play?", 1, true),
    "level 12, nothing spent: Play asks what you want to play"
  )
  check(
    button("Damage") and button("Tank") and button("Not yet") and not button("Heal"),
    "the roles the class has, and 'not yet'"
  )
  check(ns.glowing, "the minimap button glows while the question waits")
  check(shownRows() > 0, "(the page below it is still the page)")
  click("Tank")
  check(PrimerChar.groups[1].role == "tank" and not ns.glowing, "a role chosen is kept and the glow goes")
  check(
    PrimerPage.title.text == "Protection"
      and pageTexts():find("Then these first.", 1, true)
      and pageTexts():find("Builds that fit: Protection.", 1, true),
    "then the builds that fit and the advice"
  )
  check(not pageTexts():find("What do you want to play?", 1, true), "and the question is not asked again")
  PrimerFrame:Hide()
  ns.open(ns.TAB.play)
  check(
    not pageTexts():find("What do you want to play?", 1, true) and pageTexts():find("Then these first.", 1, true),
    "reopened (a respec to zero looks the same): the role is kept, the advice shows"
  )
  -- not yet
  fresh(12)
  PrimerFrame:Hide()
  ns.open(ns.TAB.play)
  click("Not yet")
  check(
    PrimerChar.groups[1].notYet == 12
      and not ns.glowing
      and pageTexts():find("Fine. The page stays on the untalented kit until you pick.", 1, true),
    "'not yet': the page stays, the glow goes"
  )
  PrimerFrame:Hide()
  ns.open(ns.TAB.play)
  check(not pageTexts():find("What do you want to play?", 1, true), "not asked twice at the same level")
  s.level = 13
  G.fire("PLAYER_LEVEL_UP", 13)
  G.advance(0.4)
  check(
    not ns.glowing and not pageTexts():find("What do you want to play?", 1, true),
    "not asked twice in one session, whatever the level"
  )
  ns.view.putOff = nil -- (the game reloaded)
  G.fire("PLAYER_LEVEL_UP", 13)
  G.advance(0.4)
  check(
    ns.glowing and pageTexts():find("What do you want to play?", 1, true),
    "asked again at the next level, in the next session"
  )
  -- a level 5 warrior: nothing to ask
  fresh(5)
  PrimerFrame:Hide()
  ns.open(ns.TAB.play)
  check(
    not pageTexts():find("talent points to spend", 1, true) and not ns.glowing,
    "before level 10: no question, no glow"
  )
  -- the glow is read with the window closed
  fresh(12)
  PrimerFrame:Hide()
  G.fire("PLAYER_LEVEL_UP", 12)
  G.advance(0.4)
  check(ns.glowing, "the glow follows the game with the window closed")
  PrimerChar.groups[1].role = "damage"
  G.fire("PLAYER_TALENT_UPDATE")
  G.advance(0.4)
  check(not ns.glowing, "and goes when a role is chosen")

  -- points spent: a picked build stays, drift is said once with three ways on
  fresh(34, ARMS15)
  PrimerChar.groups[1] = { role = "damage", pickedBuild = 1 }
  PrimerFrame:Hide()
  ns.open(ns.TAB.play)
  check(
    PrimerPage.title.text == "Arms" and not pageTexts():find("no longer reach", 1, true),
    "points that fit the pick: no note"
  )
  points(FURY25)
  G.fire("CHARACTER_POINTS_CHANGED")
  G.advance(0.4)
  check(
    PrimerPage.title.text == "Arms" and PrimerFrame.state.text == "Arms Warrior. Damage. Level 34. Following your pick.",
    "drift: a point spent never swaps the page, the build and the header stay the pick"
  )
  check(
    pageTexts():find(
      "Your points can no longer reach the build you chose. This page stays on it until you say otherwise. These points follow Fury more than the Arms build you picked.",
      1,
      true
    ),
    "and the drift is said, once"
  )
  check(button("Keep Arms") and button("Follow Fury") and button("My own way"), "three ways on")
  press("Keep Arms")
  check(
    PrimerPage.title.text == "Arms" and not pageTexts():find("no longer reach", 1, true) and not button("Keep Arms"),
    "kept: the pick stands and the note is gone"
  )
  PrimerFrame:Hide()
  ns.open(ns.TAB.play)
  check(
    not pageTexts():find("no longer reach", 1, true) and PrimerPage.title.text == "Arms",
    "a dismissed note stays dismissed"
  )
  points(PROT25)
  G.fire("CHARACTER_POINTS_CHANGED")
  G.advance(0.4)
  check(
    pageTexts():find("These points look more like a tank than a damage build. Switch your role to Tank?", 1, true)
      and PrimerChar.groups[1].role == "damage"
      and PrimerPage.title.text == "Arms",
    "drift toward another role: a switch offered, never made silently, the page unchanged"
  )
  check(button("Switch") and button("Stay on Damage"), "switch or stay")
  press("Stay on Damage")
  check(not pageTexts():find("Switch your role", 1, true) and PrimerPage.title.text == "Arms", "stay: dismissed")
  PrimerFrame:Hide()
  ns.open(ns.TAB.play)
  check(not pageTexts():find("Switch your role", 1, true), "and still dismissed when opened again")
  points(FURY25)
  G.fire("CHARACTER_POINTS_CHANGED")
  G.advance(0.4)
  check(
    pageTexts():find("These points follow Fury more than the Arms build you picked", 1, true),
    "the drift changed: said again"
  )
  press("Follow Fury")
  check(
    PrimerChar.groups[1].pickedBuild == 2
      and PrimerPage.title.text == "Fury"
      and not pageTexts():find("no longer reach", 1, true),
    "follow: the build the points resemble is the pick now, by the player's click"
  )
  points(PROT25)
  G.fire("CHARACTER_POINTS_CHANGED")
  G.advance(0.4)
  press("Switch")
  check(
    PrimerChar.groups[1].role == "tank" and PrimerPage.title.text == "Protection",
    "switch: the role changes, the page follows"
  )

  -- the page never changes under the player: every moment of the trace, a test
  -- (a) no role chosen, points move to Holy: the page does not flip while the window is open
  fresh(20, { [12282] = 3 })
  PrimerChar.groups[1] = {}
  PrimerFrame:Hide()
  ns.open(ns.TAB.play)
  local before = PrimerFrame.state.text
  check(
    before == "Arms Warrior. Damage. Level 20. Guessing from your points.",
    "no pick, 3 points: three builds are open, the header says it is guessing"
  )
  check(
    pageTexts():find("Your points leave Arms, Fury and Protection open. Which are you going for?", 1, true),
    "and the page asks which"
  )
  check(button("Damage") and button("Tank") and not button("Heal"), "with the roles the open builds have")
  points(PROT25)
  G.fire("CHARACTER_POINTS_CHANGED")
  G.advance(0.4)
  check(
    PrimerFrame.state.text == before and PrimerPage.title.text == "Arms",
    "(a) points that move to another tree do not swap role or build under the player"
  )
  PrimerFrame:Hide()
  ns.open(ns.TAB.play)
  s.level = 34
  PrimerFrame:Hide()
  ns.open(ns.TAB.play)
  check(
    PrimerFrame.state.text == "Protection Warrior. Tank. Level 34. Following your points.",
    "and the next time it is opened the points are read again: 25 in Protection leave only that build open"
  )
  s.level = 20
  -- (b) a role chosen, two builds in it, points move between them: no flip
  fresh(34, ARMS15)
  PrimerChar.groups[1] = { role = "damage" }
  PrimerFrame:Hide()
  ns.open(ns.TAB.play)
  check(PrimerPage.title.text == "Arms", "(b) a role chosen, nothing picked: the nearest build to the points")
  points(FURY25)
  G.fire("CHARACTER_POINTS_CHANGED")
  G.advance(0.4)
  check(PrimerPage.title.text == "Arms", "(b) and it does not flip to Fury while the window is open")
  -- (d) a refresh keeps the scroll, a click on a tab or a build starts at the top
  PrimerPage.scrolled = nil
  local scrolls = 0
  local scrollTo = PrimerPage.ScrollTo
  PrimerPage.ScrollTo = function(self, y)
    scrolls = scrolls + 1
    return scrollTo(self, y)
  end
  G.fire("SPELLS_CHANGED")
  G.advance(0.4)
  check(scrolls == 0, "(d) an event refreshes in place: the page is not sent back to the top")
  ns.open(ns.TAB.talents)
  check(scrolls == 1, "(d) a tab starts the page at the top")
  PrimerPage.ScrollTo = scrollTo
  -- (e) the talent in view stays when a point is spent
  fresh(34, { [12282] = 3 })
  PrimerChar.groups[1] = { role = "damage", pickedBuild = 1 }
  PrimerFrame:Hide()
  ns.open(ns.TAB.talents)
  local shown = PrimerPage.title.text
  check(shown == "Talent " .. ns.data.talents[12286].id, "(e) the next pick is in view when the tab opens")
  points({ [12282] = 3, [12286] = 3 })
  G.fire("CHARACTER_POINTS_CHANGED")
  G.advance(0.4)
  check(
    PrimerPage.title.text == shown,
    "(e) a point spent updates that talent in place, the page does not move on to the next"
  )
  -- (f) a click on a build or a role looks, and nothing is chosen until Use
  PrimerFrame:Hide()
  ns.open(ns.TAB.role)
  local each
  for _, row in ipairs(PrimerList.rows) do
    if row.shown and row.text.text == "Tank" then each = row end
  end
  each:GetScript("OnClick")(each)
  check(
    PrimerChar.groups[1].role == "damage"
      and PrimerFrame.state.text:find("Looking at Tank, not your role. Yours is Damage.", 1, true),
    "(f) a click on a role only looks"
  )
  press("Back to Damage")
  check(PrimerFrame.state.text:find("Arms Warrior", 1, true), "(f) and back is one click")

  -- your own way
  fresh(34, FURY25)
  PrimerChar.groups[1] = { role = "damage", pickedBuild = 1 }
  PrimerFrame:Hide()
  ns.open(ns.TAB.play)
  click("My own way")
  check(
    PrimerChar.groups[1].freestyle and not pageTexts():find("no longer reach", 1, true) and shownRows() > 0,
    "own way: no notes, the spells and priorities stay"
  )
  ns.open(ns.TAB.talents)
  check(
    pageTexts():find(
      "Your own way, then. The spells, openings and priorities stay. The picks and the notes don't.",
      1,
      true
    ) and not listTexts():find("Talents in order", 1, true),
    "own way: no picks on Talents"
  )
  click("Use the guide's picks again")
  check(
    not PrimerChar.groups[1].freestyle and listTexts():find("Talents in order", 1, true),
    "and the way back is one button"
  )

  -- a build looked at from another role is used with its role (no click lost)
  fresh(34, ARMS15)
  PrimerChar.groups[1] = {}
  PrimerFrame:Hide()
  ns.open(ns.TAB.role)
  local other
  for _, row in ipairs(PrimerList.rows) do
    if row.shown and row.text.text == "Tank" then other = row end
  end
  other:GetScript("OnClick")(other)
  local protection
  for _, row in ipairs(PrimerList.rows) do
    if row.shown and row.text.text == "Protection" then protection = row end
  end
  protection:GetScript("OnClick")(protection)
  press("Use this build")
  check(
    PrimerChar.groups[1].pickedBuild == 3
      and PrimerChar.groups[1].role == "tank"
      and PrimerPage.title.text == "Protection",
    "a build looked at from another role: using it takes the role with it, the click is not lost"
  )
  PrimerFrame:Hide()
  points(ARMS15)
  ns.open(ns.TAB.play)
  check(
    PrimerPage.title.text == "Protection",
    "and the pick holds when the window is opened again, whatever the points say"
  )
  -- the header's word follows the character: a respec leaves no points to follow
  fresh(34, PROT25)
  PrimerChar.groups[1] = {}
  PrimerFrame:Hide()
  ns.open(ns.TAB.play)
  check(
    PrimerFrame.state.text:find("Following your points.", 1, true),
    "points that leave one build open: the header says it follows them"
  )
  points({})
  G.fire("PLAYER_TALENT_UPDATE")
  G.advance(0.4)
  check(
    PrimerPage.title.text == "Protection" and not PrimerFrame.state.text:find("Following your points.", 1, true),
    "a respec to zero: the build stays, the header no longer says it follows points"
  )
  -- in your own way, looking at another build still says so
  fresh(34, FURY25)
  PrimerChar.groups[1] = { role = "damage", pickedBuild = 1, freestyle = true }
  PrimerFrame:Hide()
  ns.open(ns.TAB.talents)
  local fury2
  for _, row in ipairs(PrimerList.rows) do
    if row.shown and row.text.text == "Fury" then fury2 = row end
  end
  fury2:GetScript("OnClick")(fury2)
  check(
    button("Use this build") and button("Back to Arms"),
    "your own way: a look at another build has its banner and its buttons"
  )
  press("Back to Arms")

  -- a role change on the Role tab: counts, the cost, kept per group
  fresh(20, { [12282] = 3, [12286] = 3, [12295] = 5 })
  PrimerChar.groups[1] = { role = "damage" }
  PrimerFrame:Hide()
  ns.open(ns.TAB.role)
  check(
    pageTexts():find("Your points already follow the Arms build.", 1, true),
    "Role: points that follow the build say so"
  )
  local tank
  for _, row in ipairs(PrimerList.rows) do
    if row.shown and row.text.text == "Tank" then tank = row end
  end
  tank:GetScript("OnClick")(tank)
  check(
    PrimerChar.groups[1].role == "damage" and pageTexts():find("Looking at Tank, not your role.", 1, true),
    "Role: looking at it first"
  )
  press("Use this role")
  check(
    PrimerChar.groups[1].role == "tank" and pageTexts():find("Tank it is.", 1, true),
    "Role: using it changes the role at once"
  )
  check(
    pageTexts():find(
      "11 points differ from the Protection build for level 20. A respec would move them, and a respec costs gold.",
      1,
      true
    ),
    "Role: the points that differ and the cost, no figure"
  )
  check(PrimerPage.title.text == "Protection", "Role: builds re-filtered")
  -- early points off the build's tree harm nothing: a picked build keeps its page and says nothing
  fresh(24, { [12282] = 3, [12286] = 3, [12295] = 2, [12298] = 5, [12297] = 2 })
  PrimerChar.groups[1] = { role = "damage", pickedBuild = 1 }
  PrimerFrame:Hide()
  ns.open(ns.TAB.play)
  check(
    PrimerPage.title.text == "Arms"
      and not pageTexts():find("can no longer reach", 1, true)
      and not button("Follow Fury"),
    "7 points in Protection under a picked Arms: reachable, no note"
  )
  -- a role with one build left open: the points tell, no question
  PrimerChar.groups[1] = { role = "tank" }
  PrimerFrame:Hide()
  ns.open(ns.TAB.play)
  check(
    PrimerPage.title.text == "Protection"
      and PrimerFrame.state.text:find("Following your points.", 1, true)
      and not pageTexts():find("Which are you going for?", 1, true),
    "role Tank: one build, the points follow it"
  )
  -- the points fit no build: said plainly, the nearest shown
  fresh(51, {
    [12282] = 3,
    [12286] = 3,
    [12295] = 5,
    [12290] = 2,
    [12296] = 1,
    [12834] = 3,
    [12163] = 4,
    [12298] = 5,
    [12297] = 5,
    [12299] = 5,
    [12303] = 5,
    [12945] = 1,
  })
  PrimerChar.groups[1] = { role = "damage" }
  PrimerFrame:Hide()
  ns.open(ns.TAB.play)
  check(
    pageTexts():find(
      "Your points are split between Arms and Protection, so none of the builds fits them. This page shows the nearest, Arms.",
      1,
      true
    ),
    "21 points in each of two trees: no build fits, said plainly, the nearest shown"
  )
  -- a role chosen with two builds open: the page asks which build
  fresh(14, { [12298] = 5 })
  PrimerChar.groups[1] = { role = "damage" }
  PrimerFrame:Hide()
  ns.open(ns.TAB.play)
  check(
    pageTexts():find("Your points leave Arms and Fury open. Which are you going for?", 1, true)
      and button("Use Arms")
      and button("Use Fury"),
    "role Damage, 5 points in Protection: Arms and Fury are open, the page asks which build"
  )
  press("Use Fury")
  check(PrimerChar.groups[1].pickedBuild == 2 and PrimerPage.title.text == "Fury", "using one picks it")
  -- the user's case: a Paladin with 5 Holy points, role Damage stored, is Retribution
  -- a stored role the class has no build for is not a role chosen
  fresh(12)
  PrimerChar.groups[1] = { role = "heal" }
  PrimerFrame:Hide()
  ns.open(ns.TAB.play)
  check(pageTexts():find("What do you want to play?", 1, true), "a role the class cannot play is asked again")
  fresh(12)
  s.spells = {}
  s.ranks = {}
  PrimerFrame:Hide()
end

-- ── an API that raises ───────────────────────────────────────────────────────
-- The client documents calls it then refuses ("API unsupported in this version
-- of World of Warcraft": GetNumSpecGroups on Classic Era, found in the game).
-- Every call the guide makes is one that may, and the window opens all the
-- same: the safe default (one group, no season, no talents, nothing in the
-- book), the error kept once for /primer debug, never a Lua error.
do
  local function unsupported() error("Script_Call: API unsupported in this version of World of Warcraft.") end
  local calls = {
    { _G, "GetNumSpecGroups" },
    { _G, "GetNumTalentTabs" },
    { _G, "GetNumTalents" },
    { _G, "UnitClass" },
    { _G, "UnitLevel" },
    { C_SpecializationInfo, "GetActiveSpecGroup" },
    { C_SpecializationInfo, "GetTalentInfo" },
    { C_SpecializationInfo, "GetSpecializationInfo" },
    { C_Seasons, "GetActiveSeason" },
    { C_SpellBook, "IsSpellInSpellBook" },
    { C_SpellBook, "IsSpellKnown" },
    { C_Spell, "GetSpellInfo" },
  }
  local function opens(why)
    for tab = 1, 3 do
      local ok, err = pcall(ns.open, tab)
      check(ok, why .. ", tab " .. tab .. ": " .. tostring(err))
      check(PrimerPage.title.text and PrimerPage.title.text ~= "Something went wrong", why .. ": a page, tab " .. tab)
    end
  end
  s.spells = set(100, 772, 78)
  for _, call in ipairs(calls) do
    local owner, name = call[1], call[2]
    local was = owner[name]
    owner[name] = unsupported
    ns.reader.reset()
    ns.faults = {}
    opens(name .. " raises")
    -- (a call no page needs on a game is never made: Forever's page says there is no guide)
    local made = { GetNumSpecGroups = 1, UnitClass = 1, UnitLevel = 1, GetActiveSpecGroup = 1, GetActiveSeason = 1 }
    check((G.FOREVER and not made[name]) or next(ns.faults) ~= nil, name .. ": the error is kept for /primer debug")
    owner[name] = was
  end
  -- the game would not say the talents or the book: no advice from defaults, and a reopened window tries again
  if not G.FOREVER then
    local talentCall = C_SpecializationInfo.GetTalentInfo
    s.level = 40
    C_SpecializationInfo.GetTalentInfo = unsupported
    ns.reader.reset()
    ns.open(ns.TAB.talents)
    check(
      PrimerPage.title.text == "The guide cannot read your character",
      "talents unreadable: the page says so, not '31 points to spend'"
    )
    check(not pageTexts():find("talent points to spend", 1, true), "and gives no advice drawn from none taken")
    C_SpecializationInfo.GetTalentInfo = talentCall
    PrimerFrame:Hide()
    ns.open(ns.TAB.talents)
    check(
      PrimerPage.title.text ~= "The guide cannot read your character",
      "closed and opened again, the guide tries again"
    )
    local book, known = C_SpellBook.IsSpellInSpellBook, C_SpellBook.IsSpellKnown
    C_SpellBook.IsSpellInSpellBook, C_SpellBook.IsSpellKnown = unsupported, unsupported
    PrimerFrame:Hide()
    ns.open(ns.TAB.play)
    check(
      PrimerPage.title.text == "The guide cannot read your character" and shownRows() == 0,
      "the book unreadable: the same plain page, no lines"
    )
    C_SpellBook.IsSpellInSpellBook, C_SpellBook.IsSpellKnown = book, known
    PrimerFrame:Hide()
    ns.open(ns.TAB.play)
    s.level = 12
  end

  -- a Hunter, no guide written, every call raising: the class page, never a blank
  local all = {}
  for _, call in ipairs(calls) do
    all[#all + 1] = call[1][call[2]]
    if call[2] ~= "UnitClass" then call[1][call[2]] = unsupported end
  end
  local unitClass = UnitClass
  UnitClass = function() return "Hunter", "HUNTER", 3 end
  ns.reader.reset()
  ns.faults = {}
  opens("a Hunter with every call raising")
  ns.open(ns.TAB.play)
  check(
    PrimerPage.title.text == (G.FOREVER and "No guide for Forever yet" or "No guide for Hunter yet"),
    "a Hunter: the page says no guide, never a blank"
  )
  check(shownRows() == 0 and #PrimerList.rows > 0 and PrimerList.rows[1].shown, "(the list says nothing here yet)")
  for i, call in ipairs(calls) do
    call[1][call[2]] = all[i]
  end
  UnitClass = unitClass
  ns.reader.reset()

  -- a page that fails is a note, the window a calm page, the error kept once
  local page = ns.rules.page
  ns.rules.page = function() error("boom") end
  ns.faults = {}
  local ok = pcall(ns.open, ns.TAB.play)
  check(ok and PrimerPage.title.text == "Something went wrong", "a page that fails says so plainly")
  check(
    not pageTexts():find("boom", 1, true) and not pageTexts():find("stack", 1, true),
    "and shows the player no stack"
  )
  check(ns.faults.window and ns.faults.window:find("boom", 1, true), "the error is kept")
  s.printed = {}
  SlashCmdList.PRIMER("debug")
  check(said("window: ") and said("boom"), "/primer debug says what went wrong")
  ns.faults = {}
  s.printed = {}
  SlashCmdList.PRIMER("debug")
  check(said("Nothing has gone wrong."), "/primer debug says so when nothing did")
  ns.rules.page = page
  ns.open(ns.TAB.play)
  check(PrimerPage.title.text ~= "Something went wrong", "and the window draws again once it can")
  s.spells = {}
end

-- ── the Paladin and the Mage as the window draws them ────────────────────────
if not G.FOREVER then
  local function points(map)
    s.ranks = {}
    for spell, rank in pairs(map) do
      s.ranks[ns.data.talents[spell].id] = rank
    end
  end
  local function button(text)
    for _, b in ipairs(PrimerPage.buttonPool) do
      if b.shown and b.text == text then return b end
    end
  end
  local function click(text)
    local b = button(text)
    check(b, "a button: " .. text)
    b:GetScript("OnClick")(b)
  end
  local function play(token, name, id, trees)
    UnitClass = function() return name, token, id end
    s.treeNames = trees
    s.ranks, s.spells, s.level = {}, {}, 9
    PrimerChar.groups = {}
    ns.reader.reset()
    PrimerFrame:Hide()
  end
  local warriorClass, warriorTrees = UnitClass, s.treeNames

  -- the Retribution Paladin
  play("PALADIN", "Paladin", 2, { [381] = "Retribution", [382] = "Holy", [383] = "Protection" })
  s.spells = set(20154, 635, 465)
  ns.open(ns.TAB.play)
  check(
    PrimerPage.title.text == "Retribution" and PrimerPage.sub.text == "Level 1 to 9",
    "Paladin at 9: the untalented kit"
  )
  check(
    planStep("Spell 465").state == "ready"
      and planStep("Spell 20154").state == "ready"
      and planStep("Spell 19740").state == "book"
      and not pageTexts():find("What do you want to play?", 1, true),
    "Paladin at 9: the plan, the spells in the book plain, the ones to learn grey, and no question yet"
  )
  ns.open(ns.TAB.overview)
  check(
    PrimerPage.title.text == "Paladin"
      and PrimerPage.sub.text == "Classic Era"
      and pageTexts():find("You fight in melee with a seal on you", 1, true)
      and pageTexts():find("Good at", 1, true)
      and pageTexts():find("Bad at", 1, true)
      and pageTexts():find("Your resource", 1, true)
      and pageTexts():find("Levelling", 1, true)
      and pageTexts():find("At level 10", 1, true)
      and pageTexts():find("Damage. One big weapon, a seal and Judgement.", 1, true)
      and pageTexts():find("Heal. Heals the group.", 1, true)
      and pageTexts():find("Tank. Holds the monsters on you.", 1, true),
    "Paladin, Overview: the class in general, the builds in a line each with their roles, what to do at level 10"
  )
  check(not pageTexts():find("What do you want to play?", 1, true), "the Overview never asks the level-10 question")
  local holy
  for _, row in ipairs(PrimerList.rows) do
    if row.shown and row.text.text == "Holy" then holy = row end
  end
  holy:GetScript("OnClick")(holy)
  check(
    PrimerFrame.selectedTab == ns.TAB.role and pageTexts():find("Looking at Holy, not your build.", 1, true),
    "a build clicked on the Overview is looked at on the Role tab, nothing chosen"
  )
  press("Back to Retribution")
  ns.open(ns.TAB.talents)
  check(
    pageTexts():find("Level 10 to 14, points 1 to 5", 1, true)
      and pageTexts():find("No talent points to spend. Your next pick is", 1, true)
      and pageTexts():find("Judgement and your seals cost less mana, and mana is what stops a paladin.", 1, true),
    "Paladin at 9, Talents: the first pick, at level 10, and why"
  )
  s.level, s.spells = 12, set(20154, 635, 465, 20271, 19740, 21082, 498, 853, 1152, 633, 1022)
  PrimerFrame:Hide()
  ns.open(ns.TAB.play)
  check(
    pageTexts():find("You have talent points to spend.", 1, true)
      and pageTexts():find("What do you want to play?", 1, true)
      and button("Damage")
      and button("Tank")
      and button("Heal")
      and button("Not yet"),
    "Paladin at 10 or more, nothing spent: the question, with all three roles"
  )
  check(
    PrimerPage.sub.text == "Level 10 to 19"
      and planStep("Spell 20271").state == "ready"
      and planStep("Spell 19742").state == "level",
    "Paladin at 12: the stage, the plan, Blessing of Wisdom grey until its level"
  )
  -- the rotation plan: its lists, its lines, its greying
  local function stepsOf(name)
    local out = {}
    for _, r in ipairs(ns.planRows) do
      if r.shown and r.name.text:find(name, 1, true) then out[#out + 1] = r end
    end
    return out
  end
  check(
    pageTexts():find("Opening", 1, true)
      and pageTexts():find("Loop", 1, true)
      and pageTexts():find("Between fights", 1, true)
      and pageTexts():find("Low mana", 1, true)
      and pageTexts():find("Big cooldowns", 1, true),
    "the plan: the opening, the loop, between fights, low mana and the big cooldowns"
  )
  check(
    pageTexts():find("Pick what you will do most. You can change it later, and a respec costs gold.", 1, true)
      and pageTexts():find("Most of this page waits on Judgement. If it is not ready, hit the monster.", 1, true),
    "the voice: the level-10 prompt says what to weigh and what a change costs, and the loop carries the build's one dry remark"
  )
  local judgement = stepsOf("Spell 20271")
  check(
    judgement[1].name.text == "3. Spell 20271"
      and judgement[1].say.text == "As soon as the monster is in range. It spends the seal on you."
      and judgement[2].name.text == "1. Spell 20271"
      and judgement[2].say.text == "The moment it is ready. It is most of your damage, so do not sit on it.",
    "a step: its number in its list, the game's name by id, when it applies and why, in that order"
  )
  local attack = stepsOf("Spell 6603")
  check(
    attack[1].state == "ready" and attack[2].say.text == "If nothing above applies. Swings are the rest of your damage.",
    "the last line of the loop is the one that applies when nothing above does, and Attack is always ready"
  )
  check(
    planStep("Keep swinging").state == "ready" and planStep("Keep swinging").slot.spell == nil,
    "a line of text alone is always ready"
  )
  check(
    planStep("Spell 19742").say.text:find("^Level 14%. When"),
    "a step that comes at a later level says which, then the rest"
  )
  check(
    planStep("Spell 633").state == "ready" or planStep("Spell 633").state == "book",
    "the big cooldowns are listed with the spell"
  )
  s.level = 25
  PrimerFrame:Hide()
  ns.open(ns.TAB.play)
  local command = planStep("Spell 20375")
  check(
    command.state == "talent" and command.say.text:find("^Needs Talent " .. ns.data.talents[20375].id .. "%. "),
    "a step that needs a talent not taken is grey and names it"
  )
  local righteous = false
  for _, r in ipairs(ns.planRows) do
    if r.shown and r.spell == 20154 and r.state == "ready" and r.say.text:find("until Seal of Command", 1, true) then
      righteous = true
    end
  end
  check(
    righteous,
    "level 25 without Seal of Command: Seal of Righteousness is pressable whatever the weapon, so there is always a seal"
  )
  points({ [20375] = 1 })
  s.spells[20375] = true
  G.fire("CHARACTER_POINTS_CHANGED")
  G.advance(0.4)
  check(planStep("Spell 20375").state == "ready", "taken and learned: the step is plain, in place, with no reload")
  s.ranks, s.level = {}, 12
  PrimerFrame:Hide()
  ns.open(ns.TAB.play)

  click("Damage")
  check(
    PrimerPage.title.text == "Retribution"
      and pageTexts():find("Builds that fit: Retribution.", 1, true)
      and pageTexts():find("A damage paladin works with a seal and Judgement", 1, true)
      and pageTexts():find("Judgement comes back sooner, so you press it more often.", 1, true),
    "Paladin picks Damage: Retribution, the advice and the first three picks"
  )
  s.level = 19
  PrimerChar.groups = {}
  points({ [20101] = 5, [25956] = 2, [20060] = 3 })
  PrimerFrame:Hide()
  ns.open(ns.TAB.play)
  check(
    PrimerPage.title.text == "Retribution" and not pageTexts():find("What do you want to play?", 1, true),
    "Paladin with points spent: Retribution, no question"
  )
  ns.open(ns.TAB.talents)
  check(
    pageTexts():find("Level 20 to 21, points 11 to 12", 1, true)
      and pageTexts():find("Your next pick is Talent " .. ns.data.talents[26022].id, 1, true)
      and pageTexts():find("You run faster, and the points cost you nothing you needed.", 1, true)
      and listTexts():find("5/5", 1, true)
      and listTexts():find("2/2", 1, true)
      and listTexts():find("3/5", 1, true),
    "Paladin with 10 points: the next pick is Pursuit of Justice at 20, the taken ones counted"
  )

  -- one recommended road per build (ours, from the research), the other recognised and never a drift
  local REASON =
    "Most guides take this road. The other road trades Seal of Command until level 30 and early damage for mana and heals a hit does not spoil."
  s.level, s.season = 12, 0
  PrimerChar.groups = {}
  points({})
  PrimerChar.groups[1] = { role = "damage", pickedBuild = 6 }
  PrimerFrame:Hide()
  ns.open(ns.TAB.talents)
  check(
    pageTexts():find(REASON, 1, true) and not listTexts():find("Road", 1, true),
    "Retribution: one recommended road with the price of the other in a line, and no chooser"
  )
  check(
    listTexts():find("0/5", 1, true) and pageTexts():find("Talent " .. ns.data.talents[20101].id, 1, true),
    "the recommended road is the Retribution-first one: Benediction first"
  )
  s.level = 19
  points({ [20257] = 5, [20205] = 5 })
  PrimerFrame:Hide()
  ns.open(ns.TAB.talents)
  check(
    pageTexts():find("These points follow the other way to this build. It reaches the same place.", 1, true)
      and not pageTexts():find(REASON, 1, true)
      and not pageTexts():find("can no longer reach", 1, true)
      and not listTexts():find("Road", 1, true),
    "10 points in Holy at level 19 on a picked Retribution: the points follow the other way, said quietly, no drift, no chooser"
  )
  check(
    listTexts():find("5/5", 1, true),
    "and the page advises along that road from where they are (Divine Intellect and Spiritual Focus taken)"
  )
  check(
    pageTexts():find("Your next pick is Talent " .. ns.data.talents[20042].id, 1, true),
    "the next pick on the other road is Improved Blessing of Might"
  )
  points({ [20101] = 5 })
  s.level = 14
  PrimerFrame:Hide()
  ns.open(ns.TAB.talents)
  check(pageTexts():find(REASON, 1, true), "5 points in Benediction: the recommended road, no note about another")
  -- what the points do while the window is open never changes the road in view
  points({ [20257] = 5 })
  G.fire("CHARACTER_POINTS_CHANGED")
  G.advance(0.4)
  check(pageTexts():find(REASON, 1, true), "the road in view does not change under the player")
  -- a Hardcore realm uses the Hardcore road, and says so
  s.season = 3
  points({})
  s.level = 12
  PrimerFrame:Hide()
  ns.open(ns.TAB.talents)
  check(
    PrimerFrame.state.text:find("Hardcore realm: this is the safer road.", 1, true)
      and pageTexts():find(
        "On a Hardcore realm this is the safer road. The other road trades that safety for damage.",
        1,
        true
      )
      and pageTexts():find("Talent " .. ns.data.talents[20257].id, 1, true),
    "Hardcore realm: the Holy-first road, said in the header and on the page, without asking"
  )
  points({ [20101] = 5 })
  s.level = 14
  PrimerFrame:Hide()
  ns.open(ns.TAB.talents)
  check(
    pageTexts():find("These points follow the other way to this build. It reaches the same place.", 1, true)
      and not PrimerFrame.state.text:find("Hardcore realm: this is the safer road.", 1, true),
    "Hardcore realm, points on the Retribution-first road: recognised quietly, advised along that road"
  )
  s.season = 0
  points({})
  s.level = 12
  -- Hardcore lines only on a Hardcore realm
  PrimerChar.groups[1] = { role = "damage", pickedBuild = 6 }
  PrimerFrame:Hide()
  ns.open(ns.TAB.play)
  check(not pageTexts():find("Hardcore", 1, true), "Retribution on a normal realm: no Hardcore lines")
  s.season = 3
  PrimerFrame:Hide()
  ns.open(ns.TAB.play)
  check(
    pageTexts():find("Hardcore", 1, true) and pageTexts():find("Never run out of mana in a fight.", 1, true),
    "Retribution on a Hardcore realm: the Hardcore lines"
  )
  s.season = 0
  points({})

  -- the player's case: the guide they followed starts with 5 points in Holy
  s.level = 14
  PrimerChar.groups = {}
  points({ [20257] = 5 })
  PrimerFrame:Hide()
  ns.open(ns.TAB.play)
  check(
    PrimerFrame.state.text:find("Guessing from your points.", 1, true)
      and pageTexts():find("Your points leave Retribution, Holy and Protection open. Which are you going for?", 1, true)
      and button("Damage")
      and button("Heal")
      and button("Tank"),
    "Paladin with 5 points in Holy, no role chosen: the page does not say Holy, it asks which role"
  )
  click("Damage")
  check(
    PrimerPage.title.text == "Retribution"
      and PrimerFrame.state.text == "Retribution Paladin. Damage. Level 14. Following your points.",
    "and with Damage chosen it is Retribution, whatever the points"
  )
  PrimerChar.groups = {}

  -- the Frost Mage
  play("MAGE", "Mage", 8, { [41] = "Fire", [61] = "Frost", [81] = "Arcane" })
  s.spells = set(133, 168, 1459)
  ns.open(ns.TAB.play)
  check(
    PrimerPage.title.text == "Frost"
      and PrimerPage.sub.text == "Level 1 to 9"
      and planStep("Spell 168").state == "ready"
      and planStep("Spell 133").state == "ready"
      and planStep("Spell 116").state == "book",
    "Mage at 9: the untalented kit, the spells in the book plain, Frostbolt grey"
  )
  check(
    pageTexts():find("Opening", 1, true)
      and pageTexts():find("Read from the top and press the first line that applies, then start again.", 1, true)
      and listTexts():find("Fire|Damage", 1, true)
      and listTexts():find("Arcane|Damage", 1, true),
    "Mage at 9: the plan, and the three damage builds offered"
  )
  s.level, s.spells = 12, set(133, 168, 1459, 116, 5504, 2136, 587, 118, 5143, 122)
  PrimerFrame:Hide()
  ns.open(ns.TAB.play)
  check(
    pageTexts():find("What do you want to play?", 1, true)
      and button("Damage")
      and not button("Tank")
      and not button("Heal"),
    "Mage at 10 or more, nothing spent: the question, damage only"
  )
  click("Damage")
  check(
    pageTexts():find("Builds that fit: Frost, Fire, Arcane.", 1, true)
      and pageTexts():find("The safest way to level alone.", 1, true)
      and pageTexts():find("Your Frost and Fire spells are resisted less.", 1, true),
    "Mage picks Damage: all three builds, the advice and the first three picks"
  )
  s.level = 19
  PrimerChar.groups = {}
  points({ [29438] = 3, [11070] = 2, [11071] = 3, [11207] = 2 })
  PrimerFrame:Hide()
  ns.open(ns.TAB.play)
  check(
    PrimerPage.title.text == "Frost" and not pageTexts():find("What do you want to play?", 1, true),
    "Mage with points spent: Frost follows the points, no question"
  )
  ns.open(ns.TAB.talents)
  check(
    pageTexts():find("Level 20 to 22, points 11 to 13", 1, true)
      and pageTexts():find("2 of 5", 1, true)
      and pageTexts():find("The rest of Ice Shards: it is in every build that fights one monster.", 1, true),
    "Mage with 10 points: Ice Shards is the next pick, 2 of 5 taken"
  )
  -- the other way to play a stage: the crowd, with its own lists
  s.level = 25
  PrimerChar.groups[1] = { role = "damage", pickedBuild = 9 }
  s.spells = set(168, 1459, 116, 122, 2136, 10, 120, 1449, 6603)
  PrimerFrame:Hide()
  ns.open(ns.TAB.play)
  check(
    pageTexts():find("A crowd of monsters", 1, true)
      and pageTexts():find("For a pack you can root with Frost Nova.", 1, true),
    "Frost: the crowd style has its own heading and its line on when it is for"
  )
  local blizzard = {}
  for _, r in ipairs(ns.planRows) do
    if r.shown and r.name.text:find("Spell 10", 1, true) and r.spell == 10 then blizzard[#blizzard + 1] = r end
  end
  check(
    #blizzard == 1 and blizzard[1].state == "ready",
    "Blizzard is in the crowd's list only, and plain when it is learned"
  )
  local shatter
  for _, r in ipairs(ns.planRows) do
    if r.shown and r.spell == 116 and r.say.text:find("frozen", 1, true) then shatter = r end
  end
  check(shatter and shatter.state == "talent", "Frostbolt on a frozen monster waits for Shatter, and says so")
  points({ [11170] = 5 })
  G.fire("CHARACTER_POINTS_CHANGED")
  G.advance(0.4)
  shatter = nil
  for _, r in ipairs(ns.planRows) do
    if r.shown and r.spell == 116 and r.say.text:find("frozen", 1, true) then shatter = r end
  end
  check(shatter and shatter.state == "ready", "Shatter taken: the line is plain, in place")
  points({})
  s.level = 19
  -- ten points in Fire leave every build open: the page asks, it does not guess a Fire mage
  PrimerChar.groups = {}
  points({ [11069] = 5, [11119] = 5 })
  PrimerFrame:Hide()
  ns.open(ns.TAB.play)
  check(
    pageTexts():find("Your points leave Frost, Fire and Arcane open. Which are you going for?", 1, true)
      and PrimerFrame.state.text:find("Guessing from your points.", 1, true),
    "Mage with ten points in Fire: every build is open, the page asks and says it is guessing"
  )
  -- twenty-one points in Fire close the others: then the points tell
  local fire = {}
  local left = 21
  for _, step in ipairs(ns.data.builds[10].path) do
    local count = math.min(left, step.points[2] - step.points[1] + 1)
    if count <= 0 then break end
    local spell = step.talent or step.any[1]
    fire[spell] = (fire[spell] or 0) + count
    left = left - count
  end
  points(fire)
  s.level = 30
  PrimerFrame:Hide()
  ns.open(ns.TAB.play)
  check(
    PrimerPage.title.text == "Fire" and PrimerFrame.state.text:find("Following your points.", 1, true),
    "Mage with 21 points in Fire: only Fire is open, the page follows it"
  )

  UnitClass, s.treeNames = warriorClass, warriorTrees
  s.ranks, s.spells, s.level = {}, {}, 12
  PrimerChar.groups = {}
  ns.reader.reset()
end

-- ── the minimap command ──────────────────────────────────────────────────────
SlashCmdList.PRIMER("minimap")
check(ns.option("minimapHidden") == true, "/primer minimap hides the button")
SlashCmdList.PRIMER("minimap")
check(ns.option("minimapHidden") == false, "and shows it again")

io.write(("✓ Primer: %d checks (%s)"):format(count, G.FOREVER and "Forever" or "Classic Era"), "\n")
