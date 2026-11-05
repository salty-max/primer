-- Primer played through: a login, /primer opening the window with its three
-- tabs, the minimap button, the guide's rules and words (every key has its
-- text), the rules over a character (the page for the game, the class and the
-- season, the role, the build, the stage, the rows true now, the talents
-- taken), the three pages as the window draws them, and nothing asked of
-- combat. FOREVER=1: Forever's client (the Warrior's three builds are written for it).
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
local K_BOOK_H = ns.kit.BOOK_H

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
  check(
    builds == 21
      and D.builds[1].key == "warrior-arms"
      and D.builds[2].key == "warrior-fury"
      and D.builds[3].key == "warrior-protection"
      and D.builds[9].key == "mage-frost"
      and D.builds[10].key == "mage-fire"
      and D.builds[11].key == "mage-arcane"
      and D.builds[12].key == "rogue-assassination"
      and D.builds[13].key == "rogue-combat"
      and D.builds[14].key == "rogue-subtlety"
      and D.builds[15].key == "warlock-affliction"
      and D.builds[16].key == "warlock-demonology"
      and D.builds[17].key == "warlock-destruction"
      and D.builds[18].key == "shaman-elemental"
      and D.builds[19].key == "shaman-enhancement"
      and D.builds[20].key == "shaman-restoration"
      and D.builds[21].key == "hunter-beast-mastery"
      and D.builds[22].key == "hunter-marksmanship"
      and D.builds[23].key == "hunter-survival"
      and D.builds[24].key == "priest-shadow"
      and D.builds[25].key == "priest-discipline"
      and D.builds[26].key == "priest-holy",
    "Forever: the Warrior's Arms, Fury and Protection, the Mage's Frost, Fire and Arcane, the Rogue's Assassination, Combat and Subtlety, the Warlock's Affliction, Demonology and Destruction, the Shaman's Elemental, Enhancement and Restoration, the Hunter's Beast Mastery, Marksmanship and Survival, the Priest's Shadow, Discipline and Holy"
  )
  check(D.classes[1].token == "WARRIOR" and #D.classes[1].builds == 3, "Forever: the Warrior's class")
  check(D.classes[1].roles.damage.build == 1 and D.classes[1].roles.tank.build == 3, "Forever: one build a role")
  check(D.classes[8].token == "MAGE" and #D.classes[8].builds == 3, "Forever: the Mage's class")
  check(D.classes[8].roles.damage.build == 9, "Forever: the Mage's one recommended build is Frost")
  check(D.classes[4].token == "ROGUE" and #D.classes[4].builds == 3, "Forever: the Rogue's class")
  check(D.classes[4].roles.damage.build == 13, "Forever: the Rogue's one recommended build is Combat")
  check(D.classes[9].token == "WARLOCK" and #D.classes[9].builds == 3, "Forever: the Warlock's class")
  check(D.classes[9].roles.damage.build == 15, "Forever: the Warlock's one recommended build is Affliction")
  check(D.classes[7].token == "SHAMAN" and #D.classes[7].builds == 3, "Forever: the Shaman's class")
  check(
    D.classes[7].roles.damage.build == 19 and D.classes[7].roles.heal.build == 20,
    "Forever: the Shaman's recommended builds are Enhancement for damage and Restoration for healing"
  )
  check(D.classes[3].token == "HUNTER" and #D.classes[3].builds == 3, "Forever: the Hunter's class")
  check(D.classes[3].roles.damage.build == 21, "Forever: the Hunter's one recommended build is Beast Mastery")
  check(D.classes[5].token == "PRIEST" and #D.classes[5].builds == 3, "Forever: the Priest's class")
  check(
    D.classes[5].roles.damage.build == 24 and D.classes[5].roles.heal.build == 25,
    "Forever: the Priest's recommended builds are Shadow for damage and Discipline for healing"
  )
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
check(not _G["PrimerFrameTab4"], "three tabs: Level, Talents, Class")
check(ns.TAB.level == 1 and ns.TAB.talents == 2 and ns.TAB.class == 3, "the Level tab is the first")
check(PrimerFrame.selectedTab == ns.TAB.level, "the Level tab first")
SlashCmdList.PRIMER("")
check(not PrimerFrame:IsShown(), "/primer again closes it")
SlashCmdList.PRIMER("nonsense")
check(said("/primer opens the guide"), "an unknown word prints the usage")
ns.open(ns.TAB.class)
check(PrimerFrame:IsShown() and PrimerFrame.selectedTab == ns.TAB.class, "opened at the Class tab")
-- (the mock keeps no ids: the tab says its own)
local tab2 = _G.PrimerFrameTab2
tab2.GetID = function() return 2 end
tab2:GetScript("OnClick")(tab2)
check(PrimerFrame.selectedTab == ns.TAB.talents, "a click on a tab chooses it")
ns.open(ns.TAB.level)

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
  local kind, class = R.page(snap())
  check(kind == "guide" and class == 1, "Forever: a warrior has a guide, its own")
  check(R.page(snap({ token = "DRUID" })) == "class", "Forever: a druid has none written yet, never Era's")
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

-- ── the Level page as it draws ───────────────────────────────────────────────
-- (the window leaves what it drew in ns.screen as tables: the title, the facts, the spine, the pick, the opening,
-- the loop, the question: the tests read those, and press the buttons through them)
local TAB = ns.TAB
local function pageTitle()
  local sc = ns.screen
  return sc.broken or (sc.empty and sc.empty.title) or sc.title or ""
end
local function pageTexts()
  local sc, out = ns.screen, {}
  local function add(x)
    if x and x ~= "" then out[#out + 1] = x end
  end
  add(sc.broken)
  add(sc.brokenText)
  add(sc.title)
  add(sc.sub)
  if sc.empty then
    add(sc.empty.title)
    add(sc.empty.text)
  end
  if sc.question then add(sc.question.text) end
  for _, t in ipairs(sc.text or {}) do
    add(t)
  end
  return table.concat(out, "\n")
end
local function shownRows() return #(ns.screen.loop or {}) end
local function tell() -- an event, and the debounced draw it asks for
  G.fire("PLAYER_TALENT_UPDATE")
  G.advance(0.5)
end
local function press(text) -- a button of the question
  for _, b in ipairs(ns.screen.question and ns.screen.question.buttons or {}) do
    if b[1] == text then return b[2]() end
  end
  check(false, "a button: " .. text)
end
local function look(level) -- a row of the spine clicked
  for _, r in ipairs(ns.spineRows) do
    if r.shown and r.level == level then return r.scripts.OnClick(r) end
  end
  check(false, "a spine row for level " .. level)
end
local function spineLevels()
  local out = {}
  for _, r in ipairs(ns.screen.spine or {}) do
    out[#out + 1] = r.level
  end
  return out
end
-- The information budget, held by every page the tests draw: a pick, an opening of at most 5 steps and a loop of at
-- most 6, every reason printed under its step and wrapped to the page (the row as tall as both), three facts at
-- most, a line of the loop that fits, and nothing cut with an ellipsis.
local function budget(why)
  local sc = ns.screen
  check(#sc.facts <= 3, why .. ": at most three facts in the header")
  check(
    sc.legacy or (#(sc.opening or {}) <= ns.BUDGET.opening and #(sc.loop or {}) <= ns.BUDGET.loop),
    why .. ": the steps stay few"
  )
  for _, list in ipairs({ sc.opening or {}, sc.loop or {}, sc.rarely or {} }) do
    for _, r in ipairs(list) do
      if r.state == "ready" and not sc.legacy then
        check(#r.name + 1 + #r.clause <= 56, why .. ": a line fits: " .. r.line)
      end
      check(sc.legacy or r.why, why .. ": every step has its reason printed: " .. r.name)
    end
  end
  if sc.pick and sc.pick.why then
    check(pageTexts():find(sc.pick.why, 1, true), why .. ": the pick's reason is printed")
  end
  -- (the rows in order: the pick, the opening, the loop; each reason on screen is the model's)
  local expected = {}
  if sc.pick then expected[#expected + 1] = sc.pick.why or false end
  for _, list in ipairs({ sc.opening or {}, sc.loop or {}, sc.rarely or {} }) do
    for _, r in ipairs(list) do
      expected[#expected + 1] = r.why or false
    end
  end
  for i, want in ipairs(expected) do
    local row = ns.stepRows[i]
    check(row and row.shown, why .. ": row " .. i .. " is on screen")
    check(want == false or (row.reason.shown and row.reason.text == want), why .. ": row " .. i .. " prints its reason")
  end
  local onScreen = 0
  for _, row in ipairs(ns.stepRows) do
    if row.shown then
      onScreen = onScreen + 1
      if row.reason.shown then
        check(not row.reason.nowrap and row.reason.w > 0, why .. ": a reason wraps to the page")
        check(
          row.h >= row.text:GetStringHeight() + row.reason:GetStringHeight(),
          why .. ": the row grows to fit its reason"
        )
      end
    end
  end
  check(
    onScreen == #(sc.opening or {}) + #(sc.loop or {}) + #(sc.rarely or {}) + (sc.pick and 1 or 0),
    why .. ": a row for each step"
  )
  check(not pageTexts():find("...", 1, true), why .. ": no ellipsis")
  check(
    not pageTexts():find("..", 1, true) and not pageTexts():find(" %.") and not pageTexts():find(" ,"),
    why .. ": no doubled full stop, no space before one"
  )
  local cut = ns.fit()
  check(#cut == 0, why .. ": nothing cut short (" .. (cut[1] or "") .. ")")
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
    ns.view.putOff = nil
    PrimerFrame:Hide()
    s.level = level
    s.spells = set(100, 772, 78, 6343, 1715, 2687)
    points(map or {})
    ns.reader.reset()
  end
  local ARMS15 = { [12282] = 3, [12286] = 3, [12295] = 5, [12290] = 2, [12296] = 1, [12834] = 1 }

  -- before the first point: the level, no question, talents start at 10
  fresh(8)
  ns.open(TAB.level)
  check(
    ns.screen.title == "Level 8" and ns.screen.facts[1] == "Warrior",
    "level 8: the page is the level, the class a fact"
  )
  check(ns.screen.pick and ns.screen.pick.text == "Talents start at level 10", "level 8: when talents start")
  check(ns.screen.question == nil, "level 8: nothing is asked")
  local levels = spineLevels()
  check(levels[1] == 8 and levels[#levels] >= 40, "the spine runs from the character's level to 40")
  check(
    ns.screen.spine[1].here and not ns.screen.spine[2].here and ns.screen.spine[1].selected,
    "and marks where you are"
  )
  budget("level 8")

  -- level 10: one question, one idea
  fresh(10)
  ns.open(TAB.level)
  check(
    ns.screen.question and ns.screen.question.replaces and #ns.screen.roles == 2,
    "level 10: one question, the roles"
  )
  check(ns.screen.loop == nil and ns.screen.opening == nil, "and nothing else on the page")
  press("Not yet")
  check(ns.screen.question == nil and shownRows() > 0, "'not yet' draws the plan")
  tell()
  check(ns.screen.question == nil, "and an event does not ask again")
  fresh(10)
  ns.open(TAB.level)
  press("Tank")
  check(
    ns.data.builds[ns.view.subjects[1].build].role == "tank" and ns.screen.question == nil,
    "a role chosen: its recommended build"
  )
  check(ns.screen.change, "and a way to change it")
  budget("level 10 tank")

  -- the Talents tab leaves the question to the Level tab
  fresh(10)
  ns.open(TAB.talents)
  check(ns.screen.asked and not ns.screen.tree, "the Talents tab with a question pending: answer it on the Level tab")
  check(not PrimerFrame.left.shown and not PrimerFrame.sheet.shown, "the Talents tab takes both panels: no list on it")
  ns.open(TAB.level)

  -- a page is not swapped under the player: a point, a level, looking at another level
  fresh(24, ARMS15)
  ns.open(TAB.level)
  local was = ns.view.subjects[1].build
  points({
    [12282] = 3,
    [12286] = 3,
    [12295] = 5,
    [12290] = 2,
    [12296] = 1,
    [12834] = 1,
    [12320] = 5,
    [12322] = 5,
    [12318] = 5,
    [23584] = 5,
  })
  s.level = 34
  tell()
  check(ns.view.subjects[1].build == was, "points spent and a level gained while open: the page is not swapped")
  check(ns.screen.title == "Level 34", "the page follows the character's level")
  look(38)
  check(ns.screen.title == "Level 38" and ns.screen.back, "looking at level 38: said, with the way back")
  check(pageTexts():find("Looking at level 38.", 1, true), "plainly")
  check(ns.view.subjects[1].build == was, "looking changes the level and nothing the page is for")
  check(ns.screen.facts[2] == "level 34", "the header keeps the character's level")
  s.level = 35
  tell()
  check(ns.screen.title == "Level 38", "a level gained while looking does not move the page")
  ns.screen.back()
  check(ns.screen.title == "Level 35" and not ns.screen.back, "and back to the character's own")

  -- the Class tab of a class with no overview written (the Warrior): its text and its builds
  ns.open(TAB.class)
  check(ns.screen.tab == TAB.class and ns.screen.title == "Warrior", "the Class tab says the class")
  check(
    #ns.screen.blocks == 1 and ns.screen.blocks[1].heading == nil and ns.screen.blocks[1].text:find("Stance", 1, true),
    "a class with no overview: its text alone"
  )
  check(#ns.screen.roles == 2, "and a row for each of its two roles")
  ns.open(TAB.level)

  -- the Retribution Paladin: the pick, the opening, the loop
  local function play(token, name, id, trees)
    UnitClass = function() return name, token, id end
    s.treeNames = trees
    s.ranks, s.spells, s.level = {}, {}, 9
    PrimerChar.groups = {}
    ns.reader.reset()
    PrimerFrame:Hide()
  end
  local warriorClass, warriorTrees = UnitClass, s.treeNames
  local function build(key)
    for _, b in pairs(ns.data.builds) do
      if b.key == key then return b end
    end
  end
  play("PALADIN", "Paladin", 2, { [381] = "Retribution", [382] = "Holy", [383] = "Protection" })
  local ret = build("paladin-retribution")
  local known = {}
  for _, st in ipairs(ret.stages) do
    for _, part in ipairs({ st.plan.opening, st.plan.loop, st.plan.between or {}, st.plan.low or {} }) do
      for _, x in ipairs(part) do
        if x.spell then known[x.spell] = true end
      end
    end
  end
  s.spells = known
  s.level = 24
  points(ns.rules.ranksAt(ret, 1, 24))
  ns.choice(1).role, ns.choice(1).pickedBuild = "damage", ret.id
  ns.open(TAB.level)
  check(ns.screen.title == "Level 24" and ns.screen.facts[1] == "Retribution", "the Retribution Paladin at 24")
  check(
    ns.screen.pick and ns.screen.pick.text:find("^Next pick: ") or ns.screen.pick.text:find("^Every point"),
    "the next pick"
  )
  check(
    ns.screen.opening and #ns.screen.opening >= 3 and ns.screen.loop and #ns.screen.loop >= 4,
    "the opening and the loop"
  )
  check(ns.screen.pick.why and ns.screen.opening[1].why, "the reasons are printed, not asked for")
  check(
    ns.screen.rarely and #ns.screen.rarely >= 1 and ns.screen.rarely[1].why and ns.screen.rarely[1].icon,
    "the rarest lines as rows like the others: a picture, a condition, the reason printed"
  )
  for i, r in ipairs(ns.screen.loop) do
    check(r.n == i, "the loop is numbered")
  end
  check(
    ns.screen.loop[#ns.screen.loop].clause == "If nothing above applies",
    "and ends on what applies when nothing does"
  )
  budget("Retribution at 24")
  -- the Class tab of the Retribution Paladin: the overview, a row a role, the Hardcore lines on a Hardcore realm
  ns.open(TAB.class)
  sc = ns.screen
  local heads = {}
  for _, bl in ipairs(sc.blocks) do
    heads[bl.heading or "who"] = bl.text
  end
  check(
    heads.who and heads["Good at"] and heads["Bad at"] and heads["Your resource"] and heads["Levelling"],
    "the Class tab: who, good at, bad at, the resource, levelling"
  )
  check(heads.who:find("You fight in melee with a seal on you", 1, true), "in the narrator's voice, from the content")
  check(
    #sc.roles == 3 and sc.roles[1].mine and not sc.roles[2].mine and not sc.roles[3].mine,
    "a row a role, the build you are on marked"
  )
  for _, row in ipairs(sc.roles) do
    check(
      row.reason ~= "" and not row.reason:find("..", 1, true) and not row.reason:find(" %."),
      "a role's reason is a sentence: " .. row.role
    )
  end
  check(sc.hardcore == nil, "no Hardcore lines on a normal realm")
  for _, text in ipairs(sc.text) do
    check(not text:find("...", 1, true) and not text:find("..", 1, true), "the Class tab's text is plain")
  end
  check(#ns.fit() == 0, "the Class tab: nothing cut short")
  -- an event while it is open changes nothing it shows
  s.level = s.level + 1
  tell()
  check(ns.screen.roles[1].mine and #ns.screen.blocks == #sc.blocks, "an event does not change the Class tab")
  s.season = ns.rules.HARDCORE
  ns.reader.reset()
  PrimerFrame:Hide()
  ns.open(TAB.class)
  check(ns.screen.hardcore and #ns.screen.hardcore == 4, "on a Hardcore realm, its lines")
  s.season = 0
  ns.reader.reset()
  s.level = s.level - 1
  PrimerFrame:Hide()
  ns.open(TAB.level)
  -- before a role or a pick: the class's page, no build of its own, no Hardcore lines for the default
  PrimerChar.groups = {}
  ns.view.putOff = nil
  PrimerFrame:Hide()
  s.level, s.ranks, s.season = 5, {}, ns.rules.HARDCORE
  ns.reader.reset()
  ns.open(TAB.class)
  local anyMine = false
  for _, row in ipairs(ns.screen.roles) do
    anyMine = anyMine or row.mine
  end
  check(
    not anyMine and ns.screen.hardcore == nil,
    "level 5, no build chosen: nothing marked yours, no Hardcore lines for a default"
  )
  s.season, s.level = 0, 24
  points(ns.rules.ranksAt(ret, 1, 24))
  ns.choice(1).role, ns.choice(1).pickedBuild = "damage", ret.id
  ns.reader.reset()
  PrimerFrame:Hide()
  ns.open(TAB.level)
  -- every row of the page has its picture, and a spell not learned yet is dimmed, never black
  for _, list in ipairs({ ns.screen.opening or {}, ns.screen.loop or {}, ns.screen.rarely or {} }) do
    for _, r in ipairs(list) do
      check(r.icon, "a row has a picture: " .. r.name)
    end
  end
  for _, row in ipairs(ns.stepRows) do
    if row.shown and row.slot.icon.color and row.slot.icon.color[1] < 1 then
      check(
        row.slot.icon.desat and row.slot.icon.color[1] >= 0.8 and row.slot.icon.color[1] == ns.DIM,
        "a row not pressable yet is grey at the one dimming, never below 0.8"
      )
    elseif row.shown and row.slot.icon.color then
      check(not row.slot.icon.desat, "a row that can be pressed keeps its colour")
    end
  end

  -- the pick's rank is the talent's own: the rank the road holds once the point at that level is spent
  do
    local snap0, n = ns.reader.snapshot(), 0
    for road = 1, #ns.rules.roads(ret) do
      for level = 10, 40 do
        local pick = ns.rules.pickAt(snap0, ret, road, level)
        if pick then
          n = n + 1
          check(
            pick.number == ns.rules.ranksAt(ret, road, level)[pick.spell],
            "level " .. level .. ": the pick's rank is the road's"
          )
        end
      end
    end
    check(n > 30, "the ranks of the picks were compared (" .. n .. ")")
  end
  -- a point not spent yet is neither on the road nor off it: 14 spent at level 24, one to spend, all 14 on the road
  points(ns.rules.ranksAt(ret, 1, 23))
  ns.reader.reset()
  ns.open(TAB.level)
  check(
    ns.screen.sub:find("14 of 14 points are on it", 1, true),
    "the sentence counts the points spent: " .. ns.screen.sub
  )
  check(ns.screen.pick.text:find("rank %d+ of %d+"), "the pick says which rank it takes next")
  points(ns.rules.ranksAt(ret, 1, 24))
  ns.reader.reset()
  PrimerFrame:Hide()
  ns.open(TAB.level)
  for level = 24, 40 do
    look(level)
    check(ns.screen.title == "Level " .. level, "looking at " .. level)
    budget("Retribution looking at " .. level)
  end
  -- a spell above the level looked at is grey in its place
  look(24)
  s.level = 24
  ns.page()
  -- the whole spine is one list
  local seen = spineLevels()
  check(seen[1] == 24 and seen[#seen] >= 40, "the spine for the Paladin")
  -- the Talents tab: the trees with the road on them, a stepper that only looks, the pick and its reason
  PrimerFrame:Hide()
  s.level = 24
  points(ns.rules.ranksAt(ret, 1, 24))
  ns.open(TAB.talents)
  local sc = ns.screen
  check(sc.tab == TAB.talents and sc.tree and #sc.tree > 20, "the Talents tab draws the cells of the trees")
  local windows, states = {}, { taken = 0, road = 0, next = 0, off = 0 }
  for _, c in ipairs(sc.tree) do
    windows[c.window] = true
    states[c.state] = states[c.state] + 1
    check(c.frame.shown, "a cell is on screen")
  end
  check(windows[1] and windows[2] and windows[3], "all three trees")
  check(states.taken > 0 and states.next > 0 and states.road > 0, "taken cells lit and the next pick ringed")
  check(ns.TREES_W <= 720, "three trees fit the whole width of the book (" .. ns.TREES_W .. " pixels)")
  check(ns.TREE_H + ns.FOOTER_H + 16 <= K_BOOK_H - 58 - 8 - 12 - 8, "the trees and the footer fit the page with a gap")
  local levelTab = (function()
    ns.open(TAB.level)
    local text = ns.screen.pick.text
    ns.open(TAB.talents)
    return text
  end)()
  check(
    levelTab == "Next pick: " .. ns.screen.pick.text and ns.screen.pick.caption == "Next pick",
    "the Talents tab says the next pick as the Level tab does: " .. ns.screen.pick.text
  )
  check(ns.talentsTab.pick.text == ns.screen.pick.text, "and shows it")
  check(sc.stepper == 24 and not sc.looking and not sc.back, "the stepper rests on the character's level")
  check(
    sc.pick.why and ns.talentsTab.why.text == sc.pick.why,
    "the next pick's own reason is printed under it: " .. tostring(sc.pick.why)
  )
  check(ns.talentsTab.level.text == "Level 24", "the stepper says the level")
  local function press(w) w.scripts.OnClick(w) end
  -- gates: every label fits its own gutter (the next tree starts clear of it); marks and ranks keep to their corners
  local gates = 0
  for _, tree in ipairs(ns.talentsTab.tree.trees) do
    for _, g in pairs(tree.gates) do
      if g.shown then
        gates = gates + 1
        check(
          g:GetStringWidth() <= ns.TREE_GUTTER - 4 and g.w == ns.TREE_GUTTER - 4,
          "a gate label (" .. g.text .. ") fits its gutter"
        )
      end
    end
    for _, c in pairs(tree.cells) do
      if c.shown then
        check(
          c.mark:GetStringWidth() + c.rankText:GetStringWidth() + 4 <= c.w,
          "a cell's mark and its rank fit side by side in it"
        )
        check(
          #(c.mark.text or "") <= 2 and c.mark:GetStringWidth() + c.rankText:GetStringWidth() <= c.w + 4,
          "a two-digit mark and the rank stay inside the cell"
        )
      end
    end
  end
  check(gates >= 6, "the gates are labelled (" .. gates .. ")")
  -- the game's own look: what cannot be had is dimmed, what can is in full colour
  for _, c in ipairs(sc.tree) do
    local v = c.frame.icon.color and c.frame.icon.color[1]
    check(
      v == (c.state == "off" and 0.65 or 1),
      "a cell is " .. (c.state == "off" and "dimmed" or "in full colour") .. " (" .. c.state .. ")"
    )
  end
  -- the caption is one line
  check(ns.talentsTab.level:GetStringWidth() <= ns.talentsTab.level.w, "the stepper's label fits")
  check(
    ns.talentsTab.panel.shown and not PrimerFrame.left.shown and not PrimerFrame.sheet.shown,
    "the Talents tab takes both panels"
  )
  local taken24 = states.taken
  -- the stepper: forward is the next level something arrives, back returns, the ends hold
  press(ns.talentsTab.next)
  check(ns.screen.looking and ns.screen.stepper == 25 and ns.screen.back, "forward looks at the next level")
  check(
    ns.screen.pick.caption == "Looking at level 25." and ns.talentsTab.level.text == "Level 25",
    "and says so in the block, over the pick"
  )
  press(ns.talentsTab.prev)
  check(not ns.screen.looking and ns.screen.stepper == 24, "back steps back to the character's own")
  press(ns.talentsTab.prev)
  check(ns.screen.looking and ns.screen.stepper == 23, "and on below it: why a talent was taken")
  press(ns.talentsTab.next)
  for _ = 1, #ns.screen.levels + 3 do
    press(ns.talentsTab.next)
  end
  check(ns.screen.stepper == ns.screen.levels[#ns.screen.levels], "the last level holds")
  check(
    ns.screen.stepper == ns.rules.MAX_LEVEL,
    "the stepper runs to the last level the road has (" .. ns.screen.stepper .. ")"
  )
  local function lookAt(level)
    ns.view.looking = level
    ns.page()
  end
  lookAt(38)
  sc = ns.screen
  check(sc.looking and sc.stepper == 38 and sc.back, "looking at level 38, said with the way back")
  check(
    sc.pick.caption == "Looking at level 38." and ns.talentsTab.why.text == sc.pick.why and sc.pick.why,
    "the pick and its reason follow the level looked at"
  )
  local taken38 = 0
  for _, c in ipairs(sc.tree) do
    if c.state == "taken" then taken38 = taken38 + 1 end
  end
  check(taken38 > taken24, "the trees show the road at 38")
  check(
    ns.view.subjects[1].build == ret.id or ns.data.builds[ns.view.subjects[1].build].key == "paladin-retribution",
    "looking changes no more than the level"
  )
  check(#ns.fit() == 0, "the Talents tab: nothing cut short")
  -- a page that fails on the Talents tab is a plain note there, not a half-drawn tree
  local pagefn = ns.rules.page
  ns.rules.page = function() error("boom") end
  ns.faults = {}
  lookAt(30)
  check(
    ns.screen.broken == "Something went wrong" and ns.talentsTab.ask.shown and not ns.talentsTab.tree.frame.shown,
    "the Talents tab says plainly when it cannot draw"
  )
  ns.rules.page = pagefn
  lookAt(38)
  -- (the Level tab looks at the same level)
  ns.open(TAB.level)
  check(ns.screen.title == "Level 38" and ns.screen.back, "the Level tab keeps the level looked at")
  ns.open(TAB.talents)
  ns.screen.back()
  check(ns.screen.stepper == 24 and not ns.screen.looking, "and back to my own")
  PrimerFrame:Hide()
  ns.open(TAB.level)

  -- a character that knows only a higher rank of a spell still has it (the game gives each rank its own id)
  do
    local seal
    for _, st in ipairs(ret.stages) do
      for _, x in ipairs(st.plan.loop) do
        if x.spell == 20154 then seal = x end
      end
    end
    check(seal and #seal.family > 1, "a spell with ranks carries its family")
    local before = s.spells
    s.spells = {}
    for id in pairs(before) do
      s.spells[id] = id ~= 20154 and id ~= 21084 or nil
    end
    s.spells[20287] = true -- (rank 2 alone)
    ns.reader.reset()
    ns.open(TAB.level)
    local row
    for _, r in ipairs(ns.screen.loop) do
      if r.spell == 20154 then row = r end
    end
    check(row and row.state == "ready", "knowing only Seal of Righteousness rank 2, the spell is known")
    s.spells[20287] = nil
    ns.reader.reset()
    ns.open(TAB.level)
    for _, r in ipairs(ns.screen.loop) do
      if r.spell == 20154 then row = r end
    end
    check(row.state == "book", "and knowing no rank, it waits for the trainer")
    s.spells = before
    ns.reader.reset()
    ns.open(TAB.level)
  end

  -- every text the guide has: no doubled full stop, no space before one
  for key, text in pairs(ns.guideText) do
    check(
      not text:find("..", 1, true) and not text:find(" %.") and not text:find(" ,"),
      "the guide's text " .. key .. " is punctuated"
    )
  end
  check(
    ns.stop("A reason.") == "A reason." and ns.stop("A reason") == "A reason.",
    "a full stop is added only when missing"
  )

  -- the spine: the pick first, then New: and the spells on a line of their own
  for _, r in ipairs(ns.screen.spine) do
    check(not r.under:find("%.\n") and not r.under:find("%. New"), "the spine does not mix its parts with full stops")
    if r.under:find("New: ", 1, true) then
      check(r.under:find("^New: ") or r.under:find("\nNew: "), "the new spells are on a line of their own")
    end
  end

  -- /primer fit: nothing cut short, then one text that is
  s.printed = {}
  SlashCmdList.PRIMER("fit")
  check(said("Nothing is cut short."), "/primer fit says so when nothing is cut")
  local count0 = PrimerFrame.count
  count0.nowrap, count0.w = true, 10
  count0:SetText("A long fact that cannot fit")
  s.printed = {}
  SlashCmdList.PRIMER("fit")
  check(said("A long fact that cannot fit"), "/primer fit names a text the client cut")
  count0.nowrap, count0.w = false, 0
  PrimerFrame:Hide()
  s.printed = {}
  SlashCmdList.PRIMER("fit")
  check(said("Open the window first."), "/primer fit asks for the window open")

  -- every stage of every Paladin build, at its own first level and looking at its last: the budget holds
  local function stages(b, pick)
    for _, st in ipairs(b.stages) do
      local own = math.max(10, st.from)
      for _, shown in ipairs({ own, math.min(st.to, 40) }) do
        s.level = own
        s.ranks = {}
        points(ns.rules.ranksAt(b, 1, own))
        ns.choice(1).role, ns.choice(1).pickedBuild = b.role, b.id
        ns.view.looking = nil
        ns.reader.reset()
        PrimerFrame:Hide()
        ns.open(TAB.level)
        if shown > own then look(shown) end
        if ns.screen.loop then budget(("%s stage %d-%d, level %d"):format(b.key, st.from, st.to, shown)) end
      end
    end
  end
  for _, b in pairs(ns.data.builds) do
    if b.class == "PALADIN" or b.class == 2 or b.key:find("^paladin") then
      for _, st in ipairs(b.stages) do
        for _, part in ipairs({ st.plan and st.plan.opening or {}, st.plan and st.plan.loop or {} }) do
          for _, x in ipairs(part) do
            if x.spell then s.spells[x.spell] = true end
          end
        end
      end
      stages(b)
    end
  end

  -- the game's talent tooltip is asked for on Era only: Forever's SetTalent takes other arguments and raised "bad
  -- argument #3" from inside Blizzard's code, so there the spell's tooltip is the one shown
  do
    local was, tip, calls = ns.forever, _G.GameTooltip, 0
    _G.GameTooltip = {
      SetTalent = function()
        calls = calls + 1
        return true
      end,
    }
    ns.forever = false
    check(ns.talentTip({ talent = 7 }) == true and calls == 1, "on Era the game's own talent tooltip is asked for")
    ns.forever = true
    check(
      not ns.talentTip({ talent = 7 }) and calls == 1,
      "on Forever SetTalent is never called, the spell's tooltip is shown"
    )
    ns.forever, _G.GameTooltip = was, tip
  end

  -- a greyed step of the opening says what it needs, and every step has its reason in a tooltip
  play("MAGE", "Mage", 8, { [61] = "Frost", [41] = "Fire", [81] = "Arcane" })
  s.level, s.spells = 2, set(168)
  ns.open(TAB.level)
  local grey
  for _, o in ipairs(ns.screen.opening or {}) do
    if o.state == "level" then grey = o end
  end
  check(
    grey and grey.clause:find("^Level %d") and grey.why,
    "a step not yet reachable is grey in the opening with the level it needs, and its reason"
  )

  -- a Mage before level 10 has no specialisation: the header says the class, the page says it advises
  play("MAGE", "Mage", 8, { [61] = "Frost", [41] = "Fire", [81] = "Arcane" })
  s.level, s.spells = 2, set(168)
  ns.open(TAB.level)
  check(
    ns.screen.facts[1] == "Mage" and ns.screen.facts[2] == "level 2",
    "a level 2 Mage is not called Frost in the header"
  )
  PrimerChar.groups = {}
  s.season = ns.rules.HARDCORE
  ns.open(TAB.class)
  local mineMage = false
  for _, row in ipairs(ns.screen.roles) do
    mineMage = mineMage or row.mine
  end
  check(
    not mineMage and ns.screen.hardcore == nil,
    "a level 2 Mage: the Class tab marks nothing yours and has no Hardcore lines for a default"
  )
  s.season = 0
  PrimerFrame:Hide()

  -- the Frost Mage: one role, nothing to ask
  play("MAGE", "Mage", 8, { [61] = "Frost", [41] = "Fire", [81] = "Arcane" })
  s.level, s.spells = 24, set(168, 116, 122, 118)
  ns.open(TAB.level)
  check(
    ns.screen.facts[1] == "Frost" and not ns.screen.question and not ns.screen.change,
    "the Mage has one role: nothing to ask, no Change role"
  )
  budget("Frost at 24")
  -- a spell not learned yet (Counterspell at 24, the character is 22) is dimmed, not black
  s.level = 22
  PrimerFrame:Hide()
  ns.reader.reset()
  ns.open(TAB.level)
  local dimmed = 0
  for _, row in ipairs(ns.stepRows) do
    if row.shown and row.slot.icon.color and row.slot.icon.color[1] == ns.DIM and row.slot.icon.desat then
      dimmed = dimmed + 1
    end
  end
  check(dimmed > 0, "a row not pressable yet is grey with its own picture (" .. dimmed .. " rows)")
  s.level = 24
  PrimerFrame:Hide()
  ns.reader.reset()
  ns.open(TAB.level)
  -- a row that stands for the best of a few spells shows the real one the character knows
  check(
    ns.screen.opening[1].spell == 168 and ns.screen.opening[1].state == "ready",
    "the armour row shows Frost Armor at 24"
  )
  s.level, s.spells[7302] = 32, true
  PrimerFrame:Hide()
  ns.reader.reset()
  ns.open(TAB.level)
  check(ns.screen.opening[1].spell == 7302, "and Ice Armor once the character has it")
  check(ns.screen.opening[1].why:find("Mage Armor", 1, true), "with the alternative in the reason")
  -- looking at a later level: the best that level has
  s.spells[7302] = nil
  s.level = 24
  PrimerFrame:Hide()
  ns.reader.reset()
  ns.open(TAB.level)
  ns.view.looking = 33
  ns.page()
  check(
    ns.screen.opening[1].spell == 7302 and ns.screen.opening[1].state == "ready",
    "looking at level 33: Ice Armor, which that level has"
  )
  ns.view.looking = nil
  s.level, s.spells[7302] = 32, true
  s.level, s.spells[7302] = 24, nil
  PrimerFrame:Hide()
  ns.reader.reset()
  ns.open(TAB.level)
  ns.open(TAB.talents)
  check(ns.screen.tree and #ns.screen.tree > 20 and not ns.screen.asked, "the Mage's trees")
  ns.open(TAB.level)
  for _, b in pairs(ns.data.builds) do
    if b.key:find("^mage") then
      for _, st in ipairs(b.stages) do
        for _, part in ipairs({ st.plan and st.plan.opening or {}, st.plan and st.plan.loop or {} }) do
          for _, x in ipairs(part) do
            if x.spell then s.spells[x.spell] = true end
          end
        end
      end
      stages(b)
    end
  end

  UnitClass, s.treeNames = warriorClass, warriorTrees
  s.ranks, s.spells = {}, {}
  ns.reader.reset()
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
    ns.open(ns.TAB.level)
    check(
      pageTitle() == "The guide cannot read your character",
      "talents unreadable: the page says so, not '31 points to spend'"
    )
    check(not pageTexts():find("talent points to spend", 1, true), "and gives no advice drawn from none taken")
    C_SpecializationInfo.GetTalentInfo = talentCall
    PrimerFrame:Hide()
    ns.open(ns.TAB.level)
    check(pageTitle() ~= "The guide cannot read your character", "closed and opened again, the guide tries again")
    local book, known = C_SpellBook.IsSpellInSpellBook, C_SpellBook.IsSpellKnown
    C_SpellBook.IsSpellInSpellBook, C_SpellBook.IsSpellKnown = unsupported, unsupported
    PrimerFrame:Hide()
    ns.open(ns.TAB.level)
    check(
      pageTitle() == "The guide cannot read your character" and shownRows() == 0,
      "the book unreadable: the same plain page, no lines"
    )
    C_SpellBook.IsSpellInSpellBook, C_SpellBook.IsSpellKnown = book, known
    PrimerFrame:Hide()
    ns.open(ns.TAB.level)
    s.level = 12
  end

  -- a class with no guide written (the first of these that this game's data lacks), every call raising: the class page, never a blank
  local bare
  for _, c in ipairs({
    { 3, "Hunter", "HUNTER" },
    { 5, "Priest", "PRIEST" },
    { 2, "Paladin", "PALADIN" },
    { 11, "Druid", "DRUID" },
  }) do
    if not D.classes[c[1]] then
      bare = c
      break
    end
  end
  assert(bare, "every class has a guide: this test needs a class without one")
  local all = {}
  for _, call in ipairs(calls) do
    all[#all + 1] = call[1][call[2]]
    if call[2] ~= "UnitClass" then call[1][call[2]] = unsupported end
  end
  local unitClass = UnitClass
  UnitClass = function() return bare[2], bare[3], bare[1] end
  ns.reader.reset()
  ns.faults = {}
  opens("a " .. bare[2] .. " with every call raising")
  ns.open(ns.TAB.level)
  check(pageTitle() == "No guide for " .. bare[2] .. " yet", "a class with no guide: the page says so, never a blank")
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
  local ok = pcall(ns.open, ns.TAB.level)
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
  ns.open(ns.TAB.level)
  check(pageTitle() ~= "Something went wrong", "and the window draws again once it can")
  s.spells = {}
end

-- ── every pick has a reason of its own (the Talents tab prints it, never the road's generic line)
for _, b in pairs(ns.data.builds) do
  for road, r in ipairs(ns.rules.roads(b)) do
    for i, step in ipairs(r.path) do
      check(
        step.why and ns.say(step.why) ~= step.why and ns.say(step.why) ~= "",
        b.key .. " road " .. road .. " pick " .. i .. " has its own reason"
      )
      check(
        step.why and not ns.say(step.why):lower():find("%f[%a]road%f[%A]") and #ns.say(step.why) <= 170,
        b.key .. " road " .. road .. " pick " .. i .. ": a reason about the talent, short"
      )
    end
  end
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

-- ── Forever's talent reader (C_Traits, mocked in game.lua) ───────────────────
if G.FOREVER then
  local reader, T = ns.reader, s.traits
  local function id(spell) return ns.data.talents[spell].id end
  local function read(level)
    s.level = level
    reader.reset()
    reader.probe = nil
    return reader.snapshot().talents
  end
  local arms, fury = 12286, ns.data.builds[2].path[1].talent
  check(ns.data.talents[arms].tab == 161 and ns.data.talents[fury].tab == 164, "Forever: Arms 161, Fury 164")

  -- level 1, nothing taken, nothing to spend: read, not blind
  s.ranks, T.points = {}, 0
  local t = read(1)
  check(t.total == 0 and t.points[1] == 0 and t.points[3] == 0, "Forever, level 1: no points, three trees")
  check(not reader.blind(), "Forever, level 1: the page is not blind")
  check(
    reader.probe.config == 7 and reader.probe.nodes > 40 and reader.probe.ranked == 0,
    "Forever: the probe counts nodes"
  )
  check(
    reader.probe.matched == reader.probe.cells,
    "Forever: every cell of the class is a node (the extra class spell is not)"
  )

  -- some points: by the talent's id, the tree's place, rank 0 listed
  s.ranks = { [id(arms)] = 3, [id(16462)] = 2, [id(fury)] = 1 }
  T.points = 4
  t = read(20)
  check(
    t.byId[id(arms)].rank == 3
      and t.byId[id(arms)].tab == 1
      and t.names[1] == "Arms"
      and t.names[2] == "Fury"
      and t.names[3] == "Protection",
    "Forever: a talent's rank, its tree's place (the builds' order) and the trees' names"
  )
  check(
    t.byId[id(fury)].tab == 2 and t.points[1] == 5 and t.points[2] == 1 and t.total == 6,
    "Forever: the points per tree"
  )
  check(reader.probe.ranked == 3 and reader.probe.spent == 6, "Forever: nodes with ranks")
  check(t.byId[id(12294)] and t.byId[id(12294)].rank == 0, "Forever: a talent with no rank is listed at 0")
  check(ns.rules.treeIndex({ talents = t }, 161) == 1, "the guide finds a tree's place")
  local sn = reader.snapshot()
  check(
    ns.rules.unspent(sn) == 4 and ns.rules.earned(sn) == 10,
    "Forever: the points to spend are the tree's currency, not a level's"
  )
  check(ns.rules.budget() == 51, "the budget is where the guide's longest path ends")

  -- a node given free has a rank and costs no point
  T.free = { [id(arms)] = true }
  t = read(20)
  check(t.byId[id(arms)].rank == 3 and t.points[1] == 2 and t.total == 3, "Forever: a free rank is not a point spent")
  T.free = {}

  -- a pick staged and not applied (currentRank above activeRank) is not a talent the character has
  T.staged = { [id(arms)] = 1 }
  t = read(20)
  check(t.byId[id(arms)].rank == 2 and t.points[1] == 4, "Forever: a staged pick is not counted")
  T.staged = nil

  -- a node that raises or answers a secret is skipped, the rest is read
  local before = 0
  for _ in pairs(ns.faults) do
    before = before + 1
  end
  T.raise[10000 + id(arms)] = true
  T.secret[10000 + id(fury)] = true
  t = read(20)
  check(
    t.byId[id(arms)] == nil and t.byId[id(fury)] == nil and t.byId[id(16462)].rank == 2,
    "Forever: a failing node is left out, not an error"
  )
  check(
    ns.faults["C_Traits.GetNodeInfo"] ~= nil and not reader.blind(),
    "Forever: the failure is kept for /primer debug, the page still reads"
  )
  T.raise, T.secret = {}, {}

  -- no currency: the level says, as on Era
  T.points = nil
  sn = reader.snapshot()
  check(ns.rules.unspent(sn) == 5, "Forever: no currency falls back on the level (11 earned at 20, 6 spent)")

  -- no config: blind from level 10, not before
  T.config = nil
  read(1)
  check(not reader.blind() and reader.probe.why == "config", "Forever, level 1, no config: nothing to read, not blind")
  read(40)
  check(reader.blind(), "Forever, level 40, no config: the page says it cannot read")
  T.config = 7
  T.points = 0

  -- combat: nothing is asked
  s.combat = true
  s.reads = 0
  check(reader.snapshot() == nil and s.reads == 0, "Forever: nothing is read in combat")
  SlashCmdList.PRIMER("debug")
  check(s.reads == 0, "Forever: /primer debug reads nothing in combat")
  s.combat = false

  -- /primer debug says what the client answered
  s.ranks, s.level = { [id(arms)] = 3 }, 20
  reader.reset()
  s.printed = {}
  SlashCmdList.PRIMER("debug")
  check(said("config 7, tree 700, nodes"), "/primer debug on Forever: the config and the node counts")
  s.ranks = {}
end

-- ── Forever asks the spec (the pages, the rules, a stored role from before) ──────────────────────────────────
if G.FOREVER then
  local T = s.traits
  local WARRIOR = UnitClass
  local function id(spell) return ns.data.talents[spell].id end
  local function fresh(token, name, classId, level, map, unspent)
    UnitClass = token == "WARRIOR" and WARRIOR or function() return name, token, classId end
    PrimerChar.groups, PrimerChar.welcomed = {}, nil
    ns.view.putOff = nil
    PrimerFrame:Hide()
    s.level, s.spells, s.ranks, T.points = level, set(168, 100, 772, 78), {}, unspent or 0
    for spell, rank in pairs(map or {}) do
      s.ranks[id(spell)] = rank
    end
    ns.reader.reset()
    s.printed = {}
  end
  local function buttonNames()
    local out = {}
    for _, b in ipairs(ns.screen.question.buttons) do
      out[#out + 1] = b[1]
    end
    return table.concat(out, ",")
  end

  -- a Mage at level 10, nothing spent: the spec is the question, the role beside each, no role question
  fresh("MAGE", "Mage", 8, 10, {}, 1)
  ns.open(TAB.level)
  local sc = ns.screen
  check(
    sc.question and sc.question.replaces and sc.roles == nil,
    "Forever, Mage at 10: one question, not a role question"
  )
  check(
    sc.question.text == "You have a talent point to spend. Which spec do you want to play?",
    "and it asks which spec"
  )
  check(sc.specs and #sc.specs == 3, "a line for each of the Mage's three specs")
  for i, spec in ipairs(sc.specs) do
    check(
      spec.role == "damage" and spec.line:find("^%a+, damage%. ") and spec.build == ns.data.classes[8].builds[i],
      "a spec's line: its name, its role, then the content's line: " .. spec.line
    )
    check(
      spec.line:find(ns.stop(ns.say(ns.data.builds[spec.build].line)), 1, true),
      "and the line is the content's own"
    )
  end
  check(buttonNames() == "Frost,Fire,Arcane,Not yet", "a button a spec, and Not yet")
  check(sc.facts[1] == "Mage" and sc.facts[2] == "level 10", "the header says the class until a spec is chosen")
  s.printed = {}
  G.fire("PLAYER_LEVEL_UP")
  G.advance(0.5)
  check(said("You have a talent point to spend."), "said once in chat")
  s.printed = {}
  G.fire("PLAYER_LEVEL_UP")
  G.advance(0.5)
  check(not said("You have a talent point to spend."), "and not twice")
  check(not pageTexts():find("[;!]"), "no semicolon and no exclamation mark on the question")

  -- the Class tab before a spec is chosen: the specs as the choices, none yours, a button each
  ns.open(TAB.class)
  sc = ns.screen
  check(
    #sc.specs == 3 and not sc.specs[1].mine and not sc.specs[2].mine and not sc.specs[3].mine,
    "the Class tab: three specs, none yours"
  )
  check(sc.title == "Mage" and sc.facts[1] == "Mage", "and the class in the header")
  check(sc.choose[9] and sc.choose[10] and sc.choose[11], "and a way to choose each")

  -- a spec chosen: its build and its role, the header says the spec, the Class tab marks it
  ns.open(TAB.level)
  press("Fire")
  check(ns.screen.question == nil and ns.screen.facts[1] == "Fire", "Fire chosen: no question, the header says Fire")
  check(
    ns.view.subjects[1].build == 10 and ns.choice(1).pickedBuild == 10 and ns.choice(1).role == "damage",
    "its build and its role are stored"
  )
  check(ns.screen.change, "and a way to change it")
  ns.open(TAB.class)
  sc = ns.screen
  check(not sc.specs[1].mine and sc.specs[2].mine and not sc.specs[3].mine, "the Class tab marks Fire (yours)")
  check(sc.specs[2].line:find("^Damage %(yours%)%. "), "in the row")
  check(sc.choose[10] == nil and sc.choose[9] and sc.choose[11], "and offers the other two")
  sc.choose[11]()
  check(ns.choice(1).pickedBuild == 11 and ns.screen.facts[1] == "Arcane", "Play Arcane: changed from the Class tab")
  ns.open(TAB.level)
  ns.screen.change()
  check(buttonNames() == "Frost,Fire,Cancel", "Change spec: the other specs and Cancel")
  press("Frost")
  check(ns.choice(1).pickedBuild == 9 and ns.screen.facts[1] == "Frost", "and Frost is chosen")

  -- Not yet: the plan is drawn, the header still says the class
  fresh("MAGE", "Mage", 8, 10, {}, 1)
  ns.open(TAB.level)
  press("Not yet")
  check(ns.screen.question == nil and shownRows() > 0, "Forever, Not yet: the plan is drawn")
  check(
    ns.screen.facts[1] == "Mage" and ns.choice(1).pickedBuild == nil,
    "and nothing is stored, the header says the class"
  )

  -- before level 10 nothing is asked and nothing is chosen
  fresh("MAGE", "Mage", 8, 2, {}, 0)
  ns.open(TAB.level)
  check(ns.screen.question == nil and ns.screen.facts[1] == "Mage", "Forever, Mage at 2: no question, the class")
  ns.open(TAB.class)
  check(not ns.screen.specs[1].mine and next(ns.screen.choose) == nil, "and the Class tab offers nothing to choose yet")

  -- points spent in Fire: the build follows the points, the header says the spec
  local fire = ns.data.builds[10]
  fresh("MAGE", "Mage", 8, 49, ns.rules.ranksAt(fire, 1, 49), 0)
  ns.open(TAB.level)
  check(
    ns.screen.question == nil and ns.screen.facts[1] == "Fire",
    "Forever, 40 points, most of them in Fire: the points say Fire, the header says Fire"
  )
  ns.open(TAB.class)
  check(ns.screen.specs[2].mine, "and the Class tab marks Fire")
  -- a few points leave every spec open: not asked (points are spent), the advised spec is named
  fresh("MAGE", "Mage", 8, 14, ns.rules.ranksAt(fire, 1, 14), 0)
  ns.open(TAB.level)
  check(
    ns.screen.question == nil and ns.rules.phase(ns.reader.snapshot()) == "spent",
    "Forever, 5 points: spent, not asked"
  )

  -- a Warrior at 10: three specs, two roles, the role beside each, a spec chosen takes its role
  fresh("WARRIOR", "Warrior", 1, 10, {}, 1)
  ns.open(TAB.level)
  sc = ns.screen
  check(sc.specs and #sc.specs == 3 and sc.roles == nil, "Forever, Warrior at 10: three specs")
  check(
    sc.specs[1].role == "damage" and sc.specs[2].role == "damage" and sc.specs[3].role == "tank",
    "Arms and Fury deal damage, Protection tanks"
  )
  check(sc.specs[3].line:find("^Protection, tank%. "), "and the line says so")
  press("Protection")
  check(
    ns.choice(1).role == "tank" and ns.choice(1).pickedBuild == 3 and ns.screen.facts[1] == "Protection",
    "Protection chosen: its role comes with it"
  )

  -- a role stored before the spec was the question: its recommended spec, once, the role kept
  fresh("WARRIOR", "Warrior", 1, 10, {}, 1)
  PrimerChar.groups[1] = { role = "tank" }
  ns.open(TAB.level)
  check(ns.screen.question == nil and ns.screen.facts[1] == "Protection", "a stored tank role: Protection, no question")
  check(ns.choice(1).role == "tank" and ns.choice(1).pickedBuild == 3, "the role is kept, the spec stored once")
  ns.choice(1).pickedBuild = 2 -- (a later pick is never mapped over)
  ns.rules.migrate(ns.reader.snapshot(), 1, ns.choice(1))
  check(ns.choice(1).pickedBuild == 2, "and a pick is never overwritten")
  fresh("WARRIOR", "Warrior", 1, 10, {}, 1)
  PrimerChar.groups[1] = { role = "damage" }
  ns.open(TAB.level)
  check(
    ns.choice(1).pickedBuild == ns.data.classes[1].roles.damage.build and ns.screen.question == nil,
    "a stored damage role: the damage spec we advise"
  )
  fresh("WARRIOR", "Warrior", 1, 10, {}, 1)
  PrimerChar.groups[1] = { role = "heal" } -- (a role the class has no build for is no role)
  ns.open(TAB.level)
  check(
    ns.screen.question ~= nil and ns.choice(1).pickedBuild == nil,
    "a stored role the class lacks: asked, nothing mapped"
  )

  -- a stored role with points already spent is not turned into a pick: the points decide
  local fury = ns.data.builds[2]
  fresh("WARRIOR", "Warrior", 1, 49, ns.rules.ranksAt(fury, 1, 49), 0)
  PrimerChar.groups[1] = { role = "tank" }
  ns.open(TAB.level)
  check(ns.choice(1).pickedBuild == nil, "a stored role with points spent: nothing mapped, the points decide")

  -- a Warrior who put it off and spent a few points: the open specs span two roles, so the spec is asked, not the role
  fresh("WARRIOR", "Warrior", 1, 10, {}, 1)
  ns.open(TAB.level)
  press("Not yet")
  s.level, T.points = 12, 0
  s.ranks[id(ns.data.builds[2].path[1].talent)] = 3
  ns.reader.reset()
  ns.view.putOff = nil
  PrimerFrame:Hide()
  ns.open(TAB.level)
  check(
    ns.screen.question
      and ns.screen.question.text:find("which spec", 1, true) == nil
      and ns.screen.question.text:find("Which spec", 1, true)
      and ns.screen.specs
      and #ns.screen.specs == 3,
    "Forever, open specs of two roles: the spec is asked, a line each"
  )
  check(buttonNames() == "Arms,Fury,Protection,Not yet", "with the specs as the buttons")
  press("Protection")
  check(ns.choice(1).role == "tank" and ns.choice(1).pickedBuild == 3, "and the choice takes its role")

  check(ns.rules.specFirst(), "the rules know it is Forever")
  UnitClass, s.ranks, T.points = WARRIOR, {}, 0
  PrimerFrame:Hide()
end

-- ── the minimap command ──────────────────────────────────────────────────────
SlashCmdList.PRIMER("minimap")
check(ns.option("minimapHidden") == true, "/primer minimap hides the button")
SlashCmdList.PRIMER("minimap")
check(ns.option("minimapHidden") == false, "and shows it again")

if G.strict then
  check(#G.strict.violations == 0, "no call the documentation refuses: " .. table.concat(G.strict.violations, " | "))
  io.write(G.strict.report(), "\n")
end
io.write(("✓ Primer: %d checks (%s)"):format(count, G.FOREVER and "Forever" or "Classic Era"), "\n")
