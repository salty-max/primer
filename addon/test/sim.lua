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
    check(stage.from <= stage.to and #stage.rows > 0, "a stage with rows: " .. b.key)
    for _, row in ipairs(stage.rows) do
      check(text[row.say] and row.spell and row.level, "a row's word and facts: " .. b.key .. " " .. row.spell)
      check(row.level <= stage.to, "a row's level within its stage: " .. row.spell)
    end
  end
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
check(not _G["PrimerFrameTab4"], "three tabs")
check(PrimerFrame.selectedTab == ns.TAB.play, "the Play tab first")
SlashCmdList.PRIMER("")
check(not PrimerFrame:IsShown(), "/primer again closes it")
SlashCmdList.PRIMER("nonsense")
check(said("/primer opens the guide"), "an unknown word prints the usage")
ns.open(ns.TAB.role)
check(PrimerFrame:IsShown() and PrimerFrame.selectedTab == ns.TAB.role, "opened at the Role tab")
-- (the mock keeps no ids: the tab says its own)
local tab2 = _G.PrimerFrameTab2
tab2.GetID = function() return 2 end
tab2:GetScript("OnClick")(tab2)
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
    local t = { byId = {}, points = {}, total = 0 }
    for spell, rank in pairs(ranks) do
      local d = D.talents[spell]
      t.byId[d.id] =
        { name = "T", icon = 1, rank = rank, max = d.max, tab = d.tab == 161 and 1 or d.tab == 163 and 2 or 3 }
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
  r = R.resolve(at(24, ARMS15), 1, {})
  check(
    r.build == 1 and r.followed == "inferred" and r.far == 0 and not r.drift and not (r.splitTrees and r.splitTrees[1]),
    "points on Arms: the page follows Arms, nothing to say"
  )
  r = R.resolve(at(24, ARMS15), 1, { pickedBuild = 1 })
  check(r.followed == "picked" and r.build == 1, "a picked build is followed while the points fit it")
  r = R.resolve(at(24, FURY15), 1, { pickedBuild = 1 })
  check(
    r.followed == "inferred"
      and r.build == 2
      and r.drift
      and r.drift.kind == "build"
      and r.drift.from == 1
      and r.drift.to == 2,
    "points on Fury, Arms picked: the page follows Fury and says so"
  )
  local mark = r.drift.mark
  r = R.resolve(at(24, FURY15), 1, { pickedBuild = 1, driftSeen = mark, driftWay = "keep" })
  check(r.followed == "kept" and r.build == 1 and r.drift.seen, "kept: the pick is followed, the note stays dismissed")
  r = R.resolve(at(24, FURY15), 1, { pickedBuild = 1, driftSeen = mark })
  check(r.followed == "inferred" and r.build == 2 and r.drift.seen, "a note dismissed otherwise is not said again")
  r = R.resolve(at(24, PROT15), 1, { role = "damage", pickedBuild = 1, driftSeen = mark })
  check(
    r.drift and r.drift.kind == "role" and r.drift.role == "tank" and not r.drift.seen and r.role == "damage",
    "points toward a tank while on damage: a switch offered, the role not changed, a new drift said"
  )
  local roleMark = r.drift.mark
  r = R.resolve(at(24, PROT15), 1, { role = "damage", pickedBuild = 1, driftSeen = roleMark })
  check(r.drift.seen and r.role == "damage", "a dismissed role switch stays dismissed")
  r = R.resolve(at(24, FURY15), 1, { pickedBuild = 1, freestyle = true })
  check(r.drift == nil and r.splitTrees == nil and r.freestyle, "your own way: no drift and no split")
  r = R.resolve(at(24, { [12282] = 3, [12286] = 3, [12295] = 2, [12320] = 5, [12322] = 2 }), 1, {})
  check(
    r.splitTrees and r.splitTrees[1] == 1 and r.splitTrees[2] == 3 and r.build == 1,
    "points split between Arms and Fury: said, the page follows the one with more"
  )
  r = R.resolve(at(29, { [12282] = 3, [12286] = 3, [12295] = 5, [12320] = 5, [12298] = 4 }), 1, {})
  check(r.splitTrees and r.splitTrees[1] == 1, "the top tree under 60 percent is split too")
  local t1, t2 = R.split(at(24, ARMS15))
  check(t1 == nil and t2 == nil, "one tree is not a split")
  check(R.split(at(12, { [12282] = 2, [12320] = 1 })) == nil, "a few points are not called a split")
  -- a hybrid: a build whose path crosses trees is the nearest to points that cross them
  r = R.resolve(
    at(40, {
      [12282] = 3,
      [12286] = 3,
      [12295] = 5,
      [12290] = 2,
      [12296] = 1,
      [12834] = 3,
      [12163] = 5,
      [16493] = 2,
      [12292] = 1,
      [12700] = 5,
      [12294] = 1,
      [12320] = 5,
    }),
    1,
    {}
  )
  check(
    r.build == 1 and r.far <= R.TOLERANCE and not (r.splitTrees and r.splitTrees[1]) and not r.drift,
    "a hybrid the build's path declares fits: no split note"
  )
  -- a role change: the points off the nearest build of the new role
  r = R.resolve(at(20, { [12282] = 3, [12286] = 3, [12295] = 5 }), 1, { role = "tank" })
  check(
    r.role == "tank" and r.nearest == 3 and r.far == 11,
    "a role change counts the points that differ from the new role's nearest build"
  )
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
  check(PrimerFrame.count.text == "Warrior, level 12", "the window says who it is for")
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
    PrimerChar.groups[1].pickedBuild == 2 and PrimerPage.title.text == "Fury",
    "choosing a build keeps it and shows it"
  )

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
    PrimerChar.groups[1].role == "tank" and PrimerChar.groups[1].pickedBuild == nil,
    "Role: the switch is kept and the other role's build let go"
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
    PrimerPage.title.text == "Talent " .. ns.data.talents[12298].id or listTexts():find("Protection", 1, true),
    "Talents: the other group's talents are read (the points in Protection make it the tank)"
  )
  check(PrimerChar.groups[2] == nil or PrimerChar.groups[2].pickedBuild == nil, "(looking at it chooses nothing)")
  local prot
  for _, r in ipairs(PrimerList.rows) do
    if r.shown and r.text.text == "Protection" then prot = r end
  end
  check(prot, "the other group's build, from its own points")
  prot:GetScript("OnClick")(prot)
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
  check(PrimerFrame.count.text == "Warrior, level 12", "and draws when the fight is over")

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

  -- points spent: the build follows them, drift is said once with three ways on
  fresh(24, ARMS15)
  PrimerChar.groups[1] = { role = "damage", pickedBuild = 1 }
  PrimerFrame:Hide()
  ns.open(ns.TAB.play)
  check(
    PrimerPage.title.text == "Arms" and not pageTexts():find("no longer match", 1, true),
    "points that fit the pick: no note"
  )
  points(FURY15)
  G.fire("CHARACTER_POINTS_CHANGED")
  G.advance(0.4)
  check(
    PrimerPage.title.text == "Fury"
      and pageTexts():find(
        "Your points no longer match the build you chose. The page follows where they are now. These points follow Fury more than the Arms build you picked.",
        1,
        true
      ),
    "drift: said once, the page follows where the points are"
  )
  check(button("Keep Arms") and button("Follow Fury") and button("My own way"), "three ways on")
  click("Keep Arms")
  check(
    PrimerPage.title.text == "Arms" and not pageTexts():find("no longer match", 1, true) and not button("Keep Arms"),
    "kept: the pick stands and the note is gone"
  )
  PrimerFrame:Hide()
  ns.open(ns.TAB.play)
  check(
    not pageTexts():find("no longer match", 1, true) and PrimerPage.title.text == "Arms",
    "a dismissed note stays dismissed"
  )
  points(PROT15)
  G.fire("CHARACTER_POINTS_CHANGED")
  G.advance(0.4)
  check(
    pageTexts():find("These points look more like a tank than a damage build. Switch your role to Tank?", 1, true)
      and PrimerChar.groups[1].role == "damage",
    "drift toward another role: a switch offered, never made silently"
  )
  check(button("Switch") and button("Stay on Damage"), "switch or stay")
  click("Stay on Damage")
  check(not pageTexts():find("Switch your role", 1, true), "stay: dismissed")
  PrimerFrame:Hide()
  ns.open(ns.TAB.play)
  check(not pageTexts():find("Switch your role", 1, true), "and still dismissed when opened again")
  points(FURY15)
  G.fire("CHARACTER_POINTS_CHANGED")
  G.advance(0.4)
  check(
    pageTexts():find("These points follow Fury more than the Arms build you picked", 1, true),
    "the drift changed: said again"
  )
  click("Follow Fury")
  check(
    PrimerChar.groups[1].pickedBuild == 2
      and PrimerPage.title.text == "Fury"
      and not pageTexts():find("no longer match", 1, true),
    "follow: the build the points resemble is the pick now"
  )
  points(PROT15)
  G.fire("CHARACTER_POINTS_CHANGED")
  G.advance(0.4)
  click("Switch")
  check(
    PrimerChar.groups[1].role == "tank" and PrimerPage.title.text == "Protection",
    "switch: the role changes, the page follows"
  )

  -- your own way
  fresh(24, FURY15)
  PrimerChar.groups[1] = { role = "damage", pickedBuild = 1 }
  PrimerFrame:Hide()
  ns.open(ns.TAB.play)
  click("My own way")
  check(
    PrimerChar.groups[1].freestyle and not pageTexts():find("no longer match", 1, true) and shownRows() > 0,
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
    PrimerChar.groups[1].role == "tank" and pageTexts():find("Tank it is.", 1, true),
    "Role: the role changes at once"
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
  -- the picked build is still the nearest: no note that names it twice
  fresh(24, { [12282] = 3, [12286] = 3, [12295] = 2, [12298] = 5, [12297] = 2 })
  PrimerChar.groups[1] = { role = "damage", pickedBuild = 1 }
  PrimerFrame:Hide()
  ns.open(ns.TAB.play)
  check(
    PrimerPage.title.text == "Arms"
      and not pageTexts():find("more than the Arms build you picked", 1, true)
      and not button("Follow Arms"),
    "the picked build still the nearest: no note that follows what is picked"
  )
  -- a split note names the build the page follows, not the tree with most points
  PrimerChar.groups[1] = { role = "tank" }
  ns.open(ns.TAB.play)
  check(
    PrimerPage.title.text == "Protection"
      and pageTexts():find("This page follows the Protection build, the one for your role.", 1, true),
    "a split note names the build the page follows"
  )
  -- a stored role the class has no build for is not a role chosen
  fresh(12)
  PrimerChar.groups[1] = { role = "heal" }
  PrimerFrame:Hide()
  ns.open(ns.TAB.play)
  check(pageTexts():find("What do you want to play?", 1, true), "a role the class cannot play is asked again")
  -- split points
  fresh(24, { [12282] = 3, [12286] = 3, [12295] = 2, [12320] = 5, [12322] = 2 })
  PrimerFrame:Hide()
  ns.open(ns.TAB.play)
  check(
    pageTexts():find(
      "Your points are split between Arms and Fury. This page follows Arms, which has more. Pick one on the left to follow the other.",
      1,
      true
    ),
    "split points are said plainly"
  )
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

-- ── the minimap command ──────────────────────────────────────────────────────
SlashCmdList.PRIMER("minimap")
check(ns.option("minimapHidden") == true, "/primer minimap hides the button")
SlashCmdList.PRIMER("minimap")
check(ns.option("minimapHidden") == false, "and shows it again")

io.write(("✓ Primer: %d checks (%s)"):format(count, G.FOREVER and "Forever" or "Classic Era"), "\n")
