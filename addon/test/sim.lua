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
for n = 1, 3 do
  check(_G["PrimerFrameTab" .. n], "tab " .. n)
end
check(not _G["PrimerFrameTab4"], "three tabs: Overview, Plan, Talents")
check(ns.TAB.overview == 1 and ns.TAB.plan == 2, "the Overview is the first tab")
check(PrimerFrame.selectedTab == ns.TAB.plan, "the Plan tab first")
SlashCmdList.PRIMER("")
check(not PrimerFrame:IsShown(), "/primer again closes it")
SlashCmdList.PRIMER("nonsense")
check(said("/primer opens the guide"), "an unknown word prints the usage")
ns.open(ns.TAB.overview)
check(PrimerFrame:IsShown() and PrimerFrame.selectedTab == ns.TAB.overview, "opened at the Overview")
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
-- (the window leaves what it drew in ns.screen as tables: the header, the strip, the plan's lists, the
-- trees' cells, the overview: the tests read those, and press the strip's buttons through them)
local function pageTitle()
  local sc = ns.screen
  return sc.broken or (sc.empty and sc.empty.title) or (sc.header and sc.header.title) or ""
end
local function pageTexts()
  local sc, out = ns.screen, {}
  local function add(x)
    if x and x ~= "" then out[#out + 1] = x end
  end
  add(sc.broken)
  add(sc.brokenText)
  if sc.empty then
    add(sc.empty.title)
    add(sc.empty.text)
  end
  if sc.header then
    add(sc.header.title)
    add(sc.header.facts)
    add(sc.header.sentence)
    add(sc.header.chip and sc.header.chip.name)
  end
  if sc.strip then add(sc.strip.text) end
  for _, l in ipairs(sc.plan and sc.plan.lists or {}) do
    add(l.name)
    for _, r in ipairs(l.rows) do
      add(r.name)
      add(r.when)
      add(r.why)
    end
  end
  for _, h in ipairs(sc.plan and sc.plan.hardcore or {}) do
    add(h)
  end
  for _, b in ipairs(sc.overview and sc.overview.blocks or {}) do
    add(b)
  end
  for _, c in ipairs(sc.overview and sc.overview.card or {}) do
    add(c.heading)
    add(c.text)
  end
  for _, c in ipairs(sc.choose or {}) do
    add(ns.data.builds[c.build].name)
  end
  return table.concat(out, "\n")
end
local function shownRows()
  local n = 0
  for _, l in ipairs(ns.screen.plan and ns.screen.plan.lists or {}) do
    n = n + #l.rows
  end
  return n
end
local function planStep(name)
  for _, l in ipairs(ns.screen.plan and ns.screen.plan.lists or {}) do
    for _, r in ipairs(l.rows) do
      if r.name == name then return r end
    end
  end
end
local function button(text)
  for _, b in ipairs(ns.screen.strip and ns.screen.strip.buttons or {}) do
    if b[1] == text then return b end
  end
end
local function click(text)
  local b = button(text)
  check(b, "a button: " .. text)
  b[2]()
end
local function names()
  local out = {}
  for _, l in ipairs(ns.screen.plan and ns.screen.plan.lists or {}) do
    for _, r in ipairs(l.rows) do
      out[#out + 1] = r.name
    end
  end
  return table.concat(out, "|")
end
local function tell() -- an event, and the debounced draw it asks for
  G.fire("PLAYER_TALENT_UPDATE")
  G.advance(0.5)
end
local function use(role)
  for _, c in ipairs(ns.screen.choose or {}) do
    if c.role == role then c.use() end
  end
end
local function cell(spell)
  for _, c in ipairs(ns.screen.tree or {}) do
    if c.spell == spell then return c end
  end
end

if not G.FOREVER then
  local function points(map)
    s.ranks = {}
    for spell, rank in pairs(map) do
      s.ranks[ns.data.talents[spell].id] = rank
    end
  end
  local function fresh(level, map)
    PrimerChar.groups = {}
    s.level = level
    s.spells = set(100, 772, 78, 6343, 1715, 2687)
    points(map or {})
    PrimerFrame:Hide()
    ns.reader.reset()
  end
  local FURY15 = { [12320] = 5, [12322] = 5, [12318] = 5 }
  local ARMS15 = { [12282] = 3, [12286] = 3, [12295] = 5, [12290] = 2, [12296] = 1, [12834] = 1 }
  local FURY40 = { [12320] = 5, [12322] = 5, [12318] = 5, [23584] = 5, [12317] = 5 }

  -- three tabs, no list on the left, no Role tab (the tab frames are checked where /primer opens)
  check(PrimerList == nil and PrimerPage == nil, "no builds list, no page: the window is its own frames")

  -- before the first point: the class, no question, talents start at 10
  fresh(8)
  ns.open(ns.TAB.plan)
  check(
    ns.screen.header.title == "Warrior" and ns.screen.header.chip.name == "Talents start at level 10",
    "level 8: the class, and when talents start"
  )
  check(not ns.screen.strip or #ns.screen.strip.buttons == 0, "level 8: nothing asked")
  check(shownRows() > 0 and planStep("Spell 100").state == "ready", "level 8: the plan of the untalented kit")

  -- level 12, nothing spent: asked once, a card a role, the build we advise and Use this
  fresh(12)
  ns.open(ns.TAB.plan)
  check(
    ns.screen.strip and ns.screen.strip.text:find("What do you want to play?", 1, true),
    "level 12, nothing spent: the strip asks"
  )
  check(
    #ns.screen.choose == 2
      and ns.screen.choose[1].role == "damage"
      and ns.screen.choose[1].build == ns.rules.recommend(1, "damage"),
    "a card a role, the recommended build of each"
  )
  check(button("Not yet") and not button("Heal"), "Not yet, and only the roles the class has")
  check(
    ns.screen.header.title == "Warrior" and ns.screen.header.sentence:find("advises", 1, true),
    "the header: the class, no build yet"
  )
  use("tank")
  check(
    ns.screen.header.title == "Protection Warrior" and ns.screen.header.sentence == "A build you picked.",
    "Use this: the role's recommended build, picked"
  )
  check(
    ns.choice(1).role == "tank" and ns.choice(1).pickedBuild == ns.rules.recommend(1, "tank"),
    "and saved for the talent group"
  )
  check(not ns.screen.strip or not ns.screen.strip.text:find("What do you want", 1, true), "the question is gone")
  -- not yet
  fresh(12)
  ns.open(ns.TAB.plan)
  click("Not yet")
  check(
    ns.choice(1).notYet == 12
      and not ns.screen.choose
      and not (ns.screen.strip and ns.screen.strip.text:find("What do you want", 1, true)),
    "Not yet: held for the level"
  )
  PrimerFrame:Hide()
  G.advance(1)
  s.level = 13
  ns.open(ns.TAB.plan)
  check(not ns.screen.choose, "and not again this session (asked once, quietly)")
  ns.view.putOff = nil
  check(
    select(2, pcall(ns.open, ns.TAB.plan)) == nil and ns.screen.choose,
    "but asked again once the game is reloaded, a level later"
  )

  -- the header never changes under an event: a role chosen and two builds in it (Arms or Fury)
  fresh(15, {})
  ns.choice(1).role = "damage"
  ns.open(ns.TAB.plan)
  local before = ns.screen.header
  local rowsBefore = names()
  points(FURY15)
  tell()
  check(
    ns.screen.header.title == before.title and names() == rowsBefore,
    "a role chosen, points spent in Fury: the build does not flip"
  )
  -- no role chosen, points spent in one tree: the page follows them when it is opened, and then holds
  fresh(15, ARMS15)
  ns.open(ns.TAB.plan)
  local title = ns.screen.header.title
  check(
    title == "Arms Warrior" and ns.screen.header.sentence:find("several builds open", 1, true) ~= nil,
    "no pick, 15 Arms points leave Fury open too: the build Primer advises, and the header says so"
  )
  points(FURY40)
  s.level = 40
  tell()
  check(ns.screen.header.title == title, "the points move to Fury, the window stays on what it was opened on")
  check(ns.screen.header.facts:find("level 40", 1, true), "(the facts follow: the level)")
  -- the rows grey and light in place: the same list, a spell learned changes a word
  fresh(12)
  ns.choice(1).role = "damage"
  ns.choice(1).pickedBuild = ns.rules.recommend(1, "damage")
  ns.open(ns.TAB.plan)
  local list = names()
  local cold = planStep("Spell 7384")
  check(cold == nil or cold.state ~= "ready", "a spell not in the book is grey, in its place")
  s.spells[7384] = true
  s.level = 14
  tell()
  check(names() == list, "a spell learned: the same rows in the same places")
  -- scroll stays across an event
  PrimerPlan.vscroll = 33
  tell()
  check(PrimerPlan.vscroll == 33, "the scroll stays across an event")
  -- a new stage: said once, the rows replaced then
  local top = ns.data.builds[ns.rules.recommend(1, "damage")].stages[1].to
  s.level = top + 1
  tell()
  check(
    ns.screen.strip and ns.screen.strip.text == ("The plan changed at level %d."):format(top + 1) and button("Got it"),
    "a new stage: one line in the strip"
  )
  click("Got it")
  check(not (ns.screen.strip and ns.screen.strip.text:find("changed", 1, true)), "dismissed")

  -- the talents: the trees, the road's numbers, the next pick, the slider
  fresh(15, FURY15)
  ns.choice(1).role, ns.choice(1).pickedBuild = "damage", 2
  ns.open(ns.TAB.talents)
  check(#ns.screen.tree > 40, "the three trees as cells (" .. #ns.screen.tree .. ")")
  local first = ns.rules.marks(ns.data.builds[2], 1)
  local seen = {}
  for _, c in ipairs(ns.screen.tree) do
    if c.mark then seen[c.mark] = true end
    check(c.mark == first[c.spell], "a talent's number is the road's")
  end
  check(cell(12320).state == "taken" and cell(12320).rank == 5, "a talent taken is lit with its rank")
  local nextPick = ns.rules.nextPick(ns.reader.snapshot(), ns.data.builds[2], 1)
  check(cell(nextPick.spell).state == "next", "the next pick is ringed")
  local n = 0
  for _, c in ipairs(ns.screen.tree) do
    if c.state == "next" then n = n + 1 end
  end
  check(n == 1, "and only one")
  local marksBefore = {}
  for _, c in ipairs(ns.screen.tree) do
    marksBefore[c.spell] = c.mark
  end
  s.ranks[ns.data.talents[nextPick.spell].id] = (s.ranks[ns.data.talents[nextPick.spell].id] or 0) + 1
  tell()
  for _, c in ipairs(ns.screen.tree) do
    check(c.mark == marksBefore[c.spell], "a point spent moves a ring and a count, never a number")
  end
  local order = ns.screen.order
  check(order[#order] and order[1], "the order beside the trees")
  local here = false
  for _, o in ipairs(order) do
    if o.here then here = true end
  end
  check(here, "with 'you are here'")
  local head = ns.screen.header
  -- (the slider is a view: it draws the road at a level and changes nothing else)
  ns.view.slider = 40
  ns.page()
  local ranks = ns.rules.ranksAt(ns.data.builds[2], 1, 40)
  check(
    ns.screen.slider == 40 and cell(12320).rank == (ranks[12320] or 0),
    "the slider shows the road's ranks at level 40"
  )
  check(
    ns.screen.header.title == head.title and ns.screen.header.chip.name == head.chip.name,
    "and the header does not change"
  )
  ns.view.slider = nil
  ns.page()
  check(ns.screen.slider == nil, "Now returns it")

  -- the overview of a class with no overview of its own: its page and the roles
  fresh(12)
  ns.choice(1).role, ns.choice(1).pickedBuild = "damage", ns.rules.recommend(1, "damage")
  ns.open(ns.TAB.overview)
  check(
    pageTexts():find("Your road", 1, true)
      and pageTexts():find("The other roles", 1, true)
      and pageTexts():find("Also works", 1, true),
    "the overview: your road, the other roles, what also works"
  )

  -- Change role: a strip with the other roles, Cancel, and the role's recommended build
  fresh(25, ARMS15)
  ns.choice(1).role, ns.choice(1).pickedBuild = "damage", 1
  ns.open(ns.TAB.plan)
  check(ns.screen.header.change == true, "Change role is offered when the class has more than one")
  PrimerFrame.selectedTab = ns.TAB.plan
  ns.view.changing = true
  ns.page()
  check(button("Tank") and button("Cancel") and not button("Damage"), "Change role: the other roles and Cancel")
  click("Tank")
  check(
    ns.choice(1).role == "tank"
      and ns.choice(1).pickedBuild == ns.rules.recommend(1, "tank")
      and ns.screen.header.title == "Protection Warrior",
    "and the role takes its recommended build"
  )

  -- drift: a pick the points can no longer reach stays, with three ways on
  fresh(40, FURY40)
  ns.choice(1).role, ns.choice(1).pickedBuild = "damage", 1
  ns.open(ns.TAB.plan)
  check(ns.screen.header.title == "Arms Warrior", "a pick the points cannot reach stays on screen")
  check(
    button("Follow Fury")
      and button("My own way")
      and ns.screen.strip.text:find("follow Fury more than the Arms", 1, true),
    "the strip says so and offers three ways on"
  )
  click("My own way")
  check(
    ns.screen.header.sentence:find("Your own way", 1, true) and ns.screen.header.chip.name == "Your own way",
    "my own way"
  )
  click("Use the guide's picks again")
  check(ns.choice(1).freestyle == nil, "and back")

  -- the first point spent with the window open: the question's default is not a pick
  fresh(12)
  ns.open(ns.TAB.plan)
  check(ns.screen.choose and ns.screen.header.title == "Warrior", "level 12, asked: the class")
  points({ [12298] = 1 }) -- (one Protection point, in Blizzard's own window)
  tell()
  check(
    ns.screen.header.sentence:find("several builds open", 1, true) and button("Damage") and button("Tank"),
    "the point is spent: the page is worked out again from it, and the role is asked"
  )
  check(
    ns.screen.choose == nil,
    "and the question is gone because the point is, not because a build was chosen for them"
  )

  -- a second point narrows the open builds with the window open: no error, the page stays on what it was
  points({ [12298] = 5, [12297] = 5, [12299] = 5, [12303] = 5, [12945] = 3 })
  tell()
  check(not ns.screen.broken, "a second point with the window open: the page still draws")

  -- points that leave several roles open and nothing chosen: the role is asked
  fresh(24, { [12298] = 5, [12297] = 5, [12299] = 5 })
  ns.open(ns.TAB.plan)
  check(
    button("Damage") and button("Tank") and ns.screen.strip.text:find("What do you want to play?", 1, true),
    "several roles open: asked, never guessed"
  )
  click("Tank")
  check(
    ns.choice(1).role == "tank" and ns.screen.header.title == "Protection Warrior",
    "and the answer sets the role's build"
  )

  -- the strip lays its buttons flush at the right, one or three
  fresh(12)
  ns.open(ns.TAB.plan)
  check(#ns.screen.strip.buttons == 1, "the question has one button")

  -- the tooltip of a cell and of a row never raises, whatever the game says
  ns.open(ns.TAB.talents)
  local frame = ns.screen.tree[1].frame
  local setTalent = GameTooltip.SetTalent
  GameTooltip.SetTalent = function() error("API unsupported") end
  check(
    pcall(frame:GetScript("OnEnter"), frame),
    "a SetTalent that raises costs the tooltip's first line, not an error"
  )
  GameTooltip.SetTalent = setTalent

  -- a Hardcore realm
  fresh(12)
  s.season = ns.rules.HARDCORE
  ns.choice(1).role, ns.choice(1).pickedBuild = "damage", 1
  ns.open(ns.TAB.plan)
  check(ns.screen.header.facts:find("Hardcore realm", 1, true), "the header names a Hardcore realm")
  s.season = 0

  -- nothing read in combat: the window waits
  fresh(12)
  ns.open(ns.TAB.plan)
  local reads = s.reads
  s.combat = true
  tell()
  check(s.reads == reads, "in a fight the window reads nothing")
  s.combat = false
  G.advance(3)
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
      check(pageTitle() and pageTitle() ~= "Something went wrong", why .. ": a page, tab " .. tab)
    end
  end
  s.spells = set(100, 772, 78)
  s.level, s.ranks = 12, {}
  PrimerChar.groups = {}
  ns.choice(1).role, ns.choice(1).pickedBuild = "damage", 1 -- (a role chosen: the plan is drawn, not the question)
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
      pageTitle() == "The guide cannot read your character",
      "talents unreadable: the page says so, not '31 points to spend'"
    )
    check(not pageTexts():find("talent points to spend", 1, true), "and gives no advice drawn from none taken")
    C_SpecializationInfo.GetTalentInfo = talentCall
    PrimerFrame:Hide()
    ns.open(ns.TAB.talents)
    check(pageTitle() ~= "The guide cannot read your character", "closed and opened again, the guide tries again")
    local book, known = C_SpellBook.IsSpellInSpellBook, C_SpellBook.IsSpellKnown
    C_SpellBook.IsSpellInSpellBook, C_SpellBook.IsSpellKnown = unsupported, unsupported
    PrimerFrame:Hide()
    ns.open(ns.TAB.plan)
    check(
      pageTitle() == "The guide cannot read your character" and shownRows() == 0,
      "the book unreadable: the same plain page, no lines"
    )
    C_SpellBook.IsSpellInSpellBook, C_SpellBook.IsSpellKnown = book, known
    PrimerFrame:Hide()
    ns.open(ns.TAB.plan)
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
  ns.open(ns.TAB.plan)
  check(
    pageTitle() == (G.FOREVER and "No guide for Forever yet" or "No guide for Hunter yet"),
    "a Hunter: the page says no guide, never a blank"
  )
  check(shownRows() == 0 and ns.screen.empty ~= nil, "(no lines, an empty page that says why)")
  for i, call in ipairs(calls) do
    call[1][call[2]] = all[i]
  end
  UnitClass = unitClass
  ns.reader.reset()

  -- a page that fails is a note, the window a calm page, the error kept once
  local page = ns.rules.page
  ns.rules.page = function() error("boom") end
  ns.faults = {}
  local ok = pcall(ns.open, ns.TAB.plan)
  check(ok and pageTitle() == "Something went wrong", "a page that fails says so plainly")
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
  ns.open(ns.TAB.plan)
  check(pageTitle() ~= "Something went wrong", "and the window draws again once it can")
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
  ns.open(ns.TAB.plan)
  check(
    ns.screen.header.title == "Paladin" and ns.screen.header.chip.name == "Talents start at level 10",
    "Paladin at 9: the class, talents start at 10"
  )
  check(
    planStep("Spell 465").state == "ready"
      and planStep("Spell 20154").state == "ready"
      and planStep("Spell 19740").state == "book",
    "Paladin at 9: the spells in the book plain, the ones to learn grey"
  )
  ns.open(ns.TAB.overview)
  check(
    pageTexts():find("You fight in melee with a seal on you", 1, true)
      and pageTexts():find("Good at", 1, true)
      and pageTexts():find("Your resource", 1, true)
      and pageTexts():find("Your road", 1, true)
      and pageTexts():find("The other roles", 1, true),
    "Paladin: the overview in the narrator's voice, the road, the other roles"
  )
  check(
    ns.screen.overview.card[1].text:find("Most guides level a paladin as Retribution", 1, true),
    "the road says why, from the role's recommendation"
  )

  -- level 24, Retribution picked: one recommended road, the other kept to be recognised
  s.level = 24
  s.spells = set(20154, 635, 465, 19740, 20271, 853)
  points({ [20101] = 5, [25956] = 2, [20060] = 3, [26022] = 2, [20375] = 1, [20117] = 5 })
  ns.choice(1).role, ns.choice(1).pickedBuild = "damage", ns.rules.recommend(2, "damage")
  PrimerFrame:Hide()
  ns.reader.reset()
  ns.open(ns.TAB.plan)
  check(ns.screen.header.title == "Retribution Paladin", "Paladin at 24: the build and the class")
  check(planStep("Spell 20271") and planStep("Spell 20271").state == "ready", "Judgement is a plain row")
  local rowsAt24 = names()
  s.spells[24275] = true
  tell()
  check(names() == rowsAt24, "a spell learned: the plan keeps every row where it was")
  s.season = ns.rules.HARDCORE
  ns.reader.reset()
  PrimerFrame:Hide()
  ns.open(ns.TAB.plan)
  check(
    #ns.screen.plan.hardcore > 0 and ns.screen.header.facts:find("Hardcore realm", 1, true),
    "a Hardcore realm: its lines, and the header says so"
  )
  s.season = 0

  -- the Frost Mage: one role, nothing to change, the others as 'also works'
  play("MAGE", "Mage", 8, { [61] = "Frost", [41] = "Fire", [81] = "Arcane" })
  s.level, s.spells = 24, set(168, 116, 122, 118)
  ns.open(ns.TAB.plan)
  check(
    ns.screen.header.change == false and ns.screen.header.title == "Frost Mage" and not ns.screen.choose,
    "the Mage has one role: its page is Frost's, nothing to ask, no Change role"
  )
  ns.open(ns.TAB.overview)
  check(
    pageTexts():find("Also works", 1, true) and pageTexts():find("Fire", 1, true),
    "the Mage's overview names what also works"
  )
  ns.open(ns.TAB.talents)
  check(#ns.screen.tree > 40, "the Mage's trees")

  UnitClass, s.treeNames = warriorClass, warriorTrees
  s.ranks, s.spells, s.level = {}, {}, 12
  PrimerChar.groups = {}
  ns.reader.reset()
end

-- ── the data layout (M-A): roles and the trees' cells ───────────────────────
if not G.FOREVER then
  for classId, class in pairs(D.classes) do
    local seen = {}
    for _, id in ipairs(class.builds) do
      seen[D.builds[id].role] = true
    end
    for role in pairs(seen) do
      local r = class.roles and class.roles[role]
      check(
        r ~= nil and D.builds[r.build] and D.builds[r.build].role == role,
        class.key .. ": one recommended build for the " .. role .. " role"
      )
      check(r ~= nil and ns.guideText[r.why] ~= nil, class.key .. ": the " .. role .. " recommendation says why")
    end
    local cells, trees = 0, {}
    for _, c in ipairs(D.cells) do
      if c.class == classId then
        cells = cells + 1
        trees[c.tab] = true
        check(
          c.row >= 0 and c.row <= 6 and c.col >= 0 and c.col <= 3 and c.max >= 1,
          class.key .. ": a cell " .. c.spell .. " has a row, a column and ranks"
        )
      end
    end
    local n = 0
    for _ in pairs(trees) do
      n = n + 1
    end
    check(n == 3 and cells > 40, class.key .. ": three trees of cells (" .. cells .. ")")
  end
  check(D.inferred == nil, "Era's cells are the client's own, not inferred")
end

-- ── the minimap command ──────────────────────────────────────────────────────
SlashCmdList.PRIMER("minimap")
check(ns.option("minimapHidden") == true, "/primer minimap hides the button")
SlashCmdList.PRIMER("minimap")
check(ns.option("minimapHidden") == false, "and shows it again")

io.write(("✓ Primer: %d checks (%s)"):format(count, G.FOREVER and "Forever" or "Classic Era"), "\n")
