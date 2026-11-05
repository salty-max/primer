-- The guide's rules, played over what the character is (Reader.lua's snapshot)
-- and the game's own data (Guide_<game>.lua, ns.data): which page there is,
-- the role and the build, the stage for the level, the rows true now and the
-- talents taken. No frame and no game call here, so the test can play any
-- character. A row shows only when it is true for the character now: its
-- level reached, its talents taken, its spell in the book. The page for a
-- level 12 warrior is shorter, never wrong.
local _, ns = ...
local G = {}
ns.rules = G

-- (Enum.SeasonID.SeasonOfDiscovery in the client's own documentation: runes
-- change every class, so the guide stays quiet there. Hardcore and the rest
-- are Era with the same classes: the guide stays on.)
G.SEASON_OF_DISCOVERY = 2
G.ROLES = { "damage", "tank", "heal" }
-- (Enum.SeasonID.Hardcore: Hardcore realms are Era with the same classes, and their advice is the build's own `hardcore` lines)
G.HARDCORE = (Enum and Enum.SeasonID and Enum.SeasonID.Hardcore) or 3
-- (a talent point is spent at level N + 9, the 51 of a full tree by 60)
G.FIRST_POINT_LEVEL, G.MAX_LEVEL, G.POINTS = 10, 60, 51

local function data() return ns.data end

-- The class (its id in the data) a token is, if the guide has it.
function G.classOf(token)
  for id, c in pairs(data().classes) do
    if c.token == token then return id end
  end
end

-- Which page there is: "season" (Season of Discovery), "game" (nothing written
-- for this game), "class" (nothing for this class), or "guide" and the class.
-- Never another game's advice in place of a missing one.
function G.page(snap)
  if snap.season == G.SEASON_OF_DISCOVERY then return "season" end
  if next(data().builds) == nil then return "game" end
  local class = G.classOf(snap.token)
  if not class then return "class" end
  return "guide", class
end

-- Forever asks the spec (every spec is viable there, the role follows from it); Era is frozen and asks the role.
function G.specFirst() return data().game == "forever" end

-- The class's builds in the data's order, or only a role's.
function G.builds(class, role)
  local out = {}
  for _, id in ipairs(data().classes[class].builds) do
    if not role or data().builds[id].role == role then table.insert(out, id) end
  end
  return out
end

-- The roles the class has a build for, in the family's order.
function G.roles(class)
  local has, out = {}, {}
  for _, id in ipairs(data().classes[class].builds) do
    has[data().builds[id].role] = true
  end
  for _, role in ipairs(G.ROLES) do
    if has[role] then table.insert(out, role) end
  end
  return out
end

-- The build the page advises for a role: the data's (class.roles, with its reason), else the role's first.
function G.recommend(class, role)
  local c = data().classes[class]
  local r = c.roles and c.roles[role]
  if r and data().builds[r.build] then return r.build end
  return G.builds(class, role)[1]
end

-- The build a group picked, if it is still one of the class's.
function G.pickedOf(class, choice)
  for _, id in ipairs(G.builds(class)) do
    if id == choice.pickedBuild then return id end
  end
end

-- Forever: a role stored before the spec was the question (PrimerChar from an earlier version) becomes that role's
-- recommended spec, once (before points are spent). The role stays stored and no build id is touched. Returns whether it changed anything.
-- Only before points are spent: after that the stored role already limits the candidates and the points decide the build.
function G.migrate(snap, class, choice)
  if not G.specFirst() or G.phase(snap) == "spent" or G.pickedOf(class, choice) then return false end
  for _, role in ipairs(G.roles(class)) do
    if role == choice.role then
      choice.pickedBuild = G.recommend(class, role)
      return choice.pickedBuild ~= nil
    end
  end
  return false
end

-- The talent a spell (rank 1's) is, as the character has it: { rank, max,
-- name, icon }, or nil when the game does not list it.
function G.talent(snap, spell)
  local t = data().talents[spell]
  return t and snap.talents.byId[t.id]
end
local function rankOf(snap, spell)
  local t = G.talent(snap, spell)
  return t and t.rank or 0
end

-- The points the character has in a build's own tree: its place in the window
-- is found from a talent of the data the game lists (the tree's id is the
-- data's, its place the game's).
function G.points(snap, build)
  for _, t in pairs(data().talents) do
    if t.tab == build.tree then
      local info = snap.talents.byId[t.id]
      if info then return snap.talents.points[info.tab] or 0 end
    end
  end
  return 0
end

-- A build's name: its tree's, the game's, as the character's window lists it
-- (the data's own, English, where the game does not say), with the variant after it
-- when two builds share a tree.
function G.name(snap, build)
  local name = build.name
  for _, t in pairs(data().talents) do
    local info = t.tab == build.tree and snap.talents.byId[t.id]
    if info then
      name = snap.talents.names[info.tab] or build.name
      break
    end
  end
  -- (two builds on one tree, a Feral Druid as a cat or a bear: the content's variant tells them apart)
  if build.variant then return ("%s (%s)"):format(name, ns.say(build.variant)) end
  return name
end

-- The role: the one the player set, if the class has a build for it, else the
-- role of the build the character has put the most points in, else of the
-- class's first build.
function G.role(snap, class, saved)
  local roles = G.roles(class)
  for _, role in ipairs(roles) do
    if role == saved then return role end
  end
  local best, most = nil, 0
  for _, id in ipairs(G.builds(class)) do
    local n = G.points(snap, data().builds[id])
    if n > most then
      best, most = id, n
    end
  end
  return data().builds[best or G.builds(class)[1]].role
end

-- The build: the one the player chose, if it is the class's and the role's,
-- else the role's build with the most points, else the one we advise for the role.
function G.build(snap, class, role, saved)
  local mine = G.builds(class, role)
  for _, id in ipairs(mine) do
    if id == saved then return id end
  end
  local best, most = G.recommend(class, role) or mine[1], 0
  for _, id in ipairs(mine) do
    local n = G.points(snap, data().builds[id])
    if n > most then
      best, most = id, n
    end
  end
  return best
end

-- The stage of the build for the level: its index, or nil with the level the
-- build starts at (a Protection warrior's page opens at 10).
-- A stage may serve one phase of the character (stage.phase: untalented, choose
-- or spent): the one for the character's phase comes first, else the one that
-- names none.
function G.stage(build, level, phase)
  local plain
  for i, st in ipairs(build.stages) do
    if level >= st.from and level <= st.to then
      if st.phase and st.phase == phase then return i end
      if not st.phase and not plain then plain = i end
    end
  end
  if plain then return plain end
  for i, st in ipairs(build.stages) do
    if level >= st.from and level <= st.to then return i end
  end
  if level < build.stages[1].from then return nil, build.stages[1].from end
  return #build.stages
end

-- A stage's rows true now, in order, and how many only wait for the book (the
-- level is reached and the talents are taken, the spell not learned yet).
function G.rows(stage, snap)
  local out, unlearned = {}, 0
  for _, row in ipairs(stage.rows) do
    local ok = snap.level >= row.level
    if ok and row.talent then ok = rankOf(snap, row.talent) > 0 end
    for _, spell in ipairs(ok and row.talents or {}) do
      if rankOf(snap, spell) == 0 then ok = false end
    end
    if ok then
      if snap.knows(row.spell, row.family) then
        table.insert(out, row)
      else
        unlearned = unlearned + 1
      end
    end
  end
  return out, unlearned
end

-- A plan step as the character stands: "ready" (shown plain), or why it is not
-- yet: "level" (and the level it comes at), "talent" (and the talent spell it
-- needs) or "book" (the level is reached and the spell is not learned). A line
-- of text alone, and the spell every character has, are always ready.
function G.stepState(step, snap)
  if not step.spell or step.common then return "ready" end
  if snap.level < step.level then return "level", step.level end
  if step.talent and rankOf(snap, step.talent) == 0 then return "talent", step.talent end
  for _, spell in ipairs(step.talents or {}) do
    if rankOf(snap, spell) == 0 then return "talent", spell end
  end
  if not snap.knows(step.spell, step.family) then return "book" end
  return "ready"
end

-- The build's talents in order, as the character stands: each step with its
-- state ("done", "partly", "later"), the rank it has and the talents it names
-- ({ spell, info (the game's: name, icon, rank, max) }), and the index of the
-- next pick (nil: all taken).
function G.steps(build, snap, road)
  local out, nextStep = {}, nil
  for i, step in ipairs(G.roads(build)[road or 1].path) do
    local options = {}
    for _, spell in ipairs(step.any or { step.talent }) do
      table.insert(options, { spell = spell, info = G.talent(snap, spell) })
    end
    local rank = 0
    for _, o in ipairs(options) do
      rank = math.max(rank, o.info and o.info.rank or 0)
    end
    local state = rank >= step.rank and "done" or rank > 0 and "partly" or "later"
    if state ~= "done" and not nextStep then nextStep = i end
    table.insert(out, { step = step, options = options, rank = rank, state = state })
  end
  return out, nextStep
end

-- The ranks a road would have put in each talent by a level (point N at level N + 9): by rank 1's spell.
-- A choice gives the rank to each of its options.
function G.ranksAt(build, road, level)
  local out = {}
  local points = math.max(0, math.min(level, G.MAX_LEVEL) - G.FIRST_POINT_LEVEL + 1)
  for _, step in ipairs(G.roads(build)[road or 1].path) do
    if points <= 0 then break end
    local count = step.points[2] - step.points[1] + 1
    local n = math.min(points, count)
    for _, spell in ipairs(step.any or { step.talent }) do
      out[spell] = math.max(out[spell] or 0, step.rank - count + n)
    end
    points = points - n
  end
  return out
end

-- The numbers the road gives its talents, in the order it first takes them (a choice's options share one),
-- and how many there are: they belong to the road, not to the character.
function G.marks(build, road)
  local out, n = {}, 0
  for _, step in ipairs(G.roads(build)[road or 1].path) do
    local options = step.any or { step.talent }
    local fresh = false
    for _, spell in ipairs(options) do
      if not out[spell] then fresh = true end
    end
    if fresh then
      n = n + 1
      for _, spell in ipairs(options) do
        out[spell] = out[spell] or n
      end
    end
  end
  return out, n
end

-- The next pick of a road as the character stands: its step, the talent (a choice: the one taken, else the first),
-- the level the point comes at and which of the step's points it is. nil: every point of the road is taken.
function G.nextPick(snap, build, road)
  local steps, index = G.steps(build, snap, road)
  if not index then return nil end
  local s = steps[index]
  local count = s.step.points[2] - s.step.points[1] + 1
  local taken = math.max(0, s.rank - (s.step.rank - count))
  local o = s.options[1]
  for _, x in ipairs(s.options) do
    if x.info and x.info.rank > 0 then o = x end
  end
  return {
    index = index,
    spell = o.spell,
    info = o.info,
    level = s.step.level[1] + taken,
    -- (the talent's own rank this point reaches, of its ranks: a talent a road takes in two steps counts on)
    number = s.step.rank - count + taken + 1,
    of = data().talents[o.spell].max,
    step = s,
  }
end

-- The pick the road makes at a level (nil: no point comes at that level, or the road has run out), as nextPick
-- gives it: the talent (a choice: the first option), which of the step's points it is, and how many the step has.
function G.pickAt(snap, build, road, level)
  for _, step in ipairs(G.roads(build)[road or 1].path) do
    if level >= step.level[1] and level <= step.level[2] then
      local spell = (step.any or { step.talent })[1]
      return {
        spell = spell,
        info = G.talent(snap, spell),
        level = level,
        number = step.rank - (step.level[2] - step.level[1] + 1) + (level - step.level[1]) + 1,
        of = data().talents[spell].max,
        step = step,
      }
    end
  end
end

-- The points the character can spend now: one a level from 10, less what it
-- has put in.
function G.unspent(snap)
  -- (Forever: the trait tree's own currency says it, whatever the level cap is)
  if type(snap.talents.unspent) == "number" then return math.max(0, snap.talents.unspent) end
  local earned = math.max(0, math.min(snap.level, G.MAX_LEVEL) - G.FIRST_POINT_LEVEL + 1)
  return math.max(0, math.min(earned, G.POINTS) - snap.talents.total)
end

-- ── the phases of a character, and the build its points follow ───────────────
-- A phase is the character's (and each talent group's) state, never the
-- guide's: 1 "untalented" (before level 10), 2 "choose" (points to spend, none
-- spent), 3 "spent". The phase of two talent groups is each group's own (a
-- snapshot is one group's). An archetype (a build) is the guide's content: the
-- path of each says where its points go, so the points a build would have by
-- now, tree by tree, are read off the path and nothing is declared twice (a
-- hybrid is a build whose path crosses trees).

function G.phase(snap)
  if snap.level < G.FIRST_POINT_LEVEL then return "untalented" end
  if snap.talents.total == 0 then return "choose" end
  return "spent"
end

-- A tree's place in the window (1 to 3), from a talent of it the game lists.
function G.treeIndex(snap, tab)
  for _, t in pairs(data().talents) do
    local info = t.tab == tab and snap.talents.byId[t.id]
    if info then return info.tab end
  end
end

-- The points the character is held to: what its level has earned, or what it
-- has spent if that is more.
function G.earned(snap)
  if type(snap.talents.unspent) == "number" then return snap.talents.total + math.max(0, snap.talents.unspent) end
  local earned = math.max(0, math.min(snap.level, G.MAX_LEVEL) - G.FIRST_POINT_LEVEL + 1)
  return math.max(math.min(earned, G.POINTS), snap.talents.total)
end

-- A build's roads: another order of the same points for the same build (the
-- same role and tree), each with a plain name, none of them a drift. The first
-- is the build's own path, which has no name unless there are others.
function G.roads(build)
  if not build.roads then return { { path = build.path } } end
  local out = {}
  for i, road in ipairs(build.roads) do
    out[i] = { name = road.name, path = road.path or build.path }
  end
  return out
end

-- The road a page advises, ours and from the research (never the player's choice):
-- the recommended one, the Hardcore road on a Hardcore realm where the build has
-- one, or, when the points clearly follow another road kept only to be
-- recognised, that one (the second answer is true: said quietly, no drift).
function G.pickRoad(snap, build)
  local roads = G.roads(build)
  if #roads < 2 then return 1, false end
  local main = (snap.season == G.HARDCORE and build.hardcoreRoad) or build.recommended or 1
  -- (recognised only while the build can still be reached: a road to a build out of reach is no road)
  if G.phase(snap) == "spent" and G.reachable(snap, build) then
    local near, tie = G.road(snap, build)
    if near ~= main and not tie then
      -- (any road of the build is known: the recommended one, and those kept only to be recognised)
      if near == build.recommended then return near, true end
      for _, n in ipairs(build.recognised or {}) do
        if n == near then return near, true end
      end
    end
  end
  return main, false
end

-- The points a build would have in each tree (by place) after n points of a road
-- of it (the first by default).
function G.expected(snap, build, n, path)
  local out = {}
  for _, step in ipairs(path or build.path) do
    if n <= 0 then break end
    local count = math.min(n, step.points[2] - step.points[1] + 1)
    local at = G.treeIndex(snap, data().talents[step.talent or step.any[1]].tab)
    if at then out[at] = (out[at] or 0) + count end
    n = n - count
  end
  return out
end

-- How many of the character's points the build would not have put where they
-- are (by its nearest road, and which road that is).
function G.differ(snap, build, n)
  local best, which
  for i, road in ipairs(G.roads(build)) do
    local want, off = G.expected(snap, build, n, road.path), 0
    for tree, have in pairs(snap.talents.points) do
      off = off + math.max(0, have - (want[tree] or 0))
    end
    if not best or off < best then
      best, which = off, i
    end
  end
  return best, which
end

-- The road of a build the points follow: the nearest, and whether more than one
-- is as near (both fit: no points yet, or points the roads share).
function G.road(snap, build)
  local roads = G.roads(build)
  if #roads < 2 then return 1, false end
  local n, best, which, ties = G.earned(snap), nil, 1, 0
  for i, road in ipairs(roads) do
    local want, off = G.expected(snap, build, n, road.path), 0
    for tree, have in pairs(snap.talents.points) do
      off = off + math.max(0, have - (want[tree] or 0))
    end
    if not best or off < best then
      best, which, ties = off, i, 1
    elseif off == best then
      ties = ties + 1
    end
  end
  return which, ties > 1
end

-- The nearest build (of a role, or any) to the points: its id and how far off.
function G.nearest(snap, class, role)
  local n, best, far = G.earned(snap), nil, nil
  for _, id in ipairs(G.builds(class, role)) do
    local off = G.differ(snap, data().builds[id], n)
    -- (a tie goes to the build whose own tree holds more, then to the writer's order)
    if
      not far
      or off < far
      or (off == far and G.points(snap, data().builds[id]) > G.points(snap, data().builds[best]))
    then
      best, far = id, off
    end
  end
  return best, far
end

-- The two trees holding most of the points (for the page that says none of
-- the builds fits them).
function G.split(snap)
  local trees = {}
  for tree, have in pairs(snap.talents.points) do
    if have > 0 then table.insert(trees, { tree = tree, have = have }) end
  end
  table.sort(trees, function(x, y)
    if x.have ~= y.have then return x.have > y.have end
    return x.tree < y.tree
  end)
  if trees[2] then return trees[1].tree, trees[2].tree end
end

-- Whether a build can still be reached by the points the character has. A build
-- needs its own tree to hold `required` of the 51 points (31 for the builds
-- written so far, read off the path) and may spend the rest anywhere, so a
-- build stays open while the points spent OUTSIDE its tree are no more than
-- the rest (20 of 51): five early points in Holy rule out nothing. This is
-- feasibility, never dominance: the tree with most points is not the build.
-- It is what the deepest talent of the build's own tree asks of that tree (the
-- points before it) and the point it takes itself: not what the path happens to
-- put there (Fury's path puts 32 in Fury, the build needs 31).
function G.required(build)
  local need = 0
  for _, road in ipairs(G.roads(build)) do
    for _, step in ipairs(road.path) do
      for _, spell in ipairs(step.any or { step.talent }) do
        local t = data().talents[spell]
        if t and t.tab == build.tree then need = math.max(need, t.req + 1) end
      end
    end
  end
  return need > 0 and need or 31
end
-- The points a full character spends: where the longest path of the game's
-- builds ends (51 on Era, whatever the guide covers on Forever), not a number
-- typed for Era.
function G.budget()
  local most = 0
  for _, b in pairs(data().builds) do
    local last = b.path[#b.path]
    if last then most = math.max(most, last.points[2]) end
  end
  return most > 0 and most or G.POINTS
end
function G.reachable(snap, build)
  local tree = G.treeIndex(snap, build.tree)
  local off = snap.talents.total - (tree and snap.talents.points[tree] or 0)
  return off <= G.budget() - G.required(build)
end

-- The class's builds (of a role, or all) the points still leave open, in the
-- writer's order.
function G.open(snap, class, role)
  local out = {}
  for _, id in ipairs(G.builds(class, role)) do
    if G.reachable(snap, data().builds[id]) then table.insert(out, id) end
  end
  return out
end

-- What the character is on: its phase, role (the one it chose or its build's),
-- the build the page is for and how ("picked": the build it picked, kept
-- whatever its points do, a pick is never swapped under it; "points": its
-- points leave exactly one build open; "open": they leave several open and
-- nothing says which, so the page shows the build we advise for the role (the window asks the
-- role when the open builds span several), never guessing from the tree with most points; "none": nothing spent yet; "own": their own
-- way). Candidates are the chosen role's builds (a Damage paladin can only be
-- Retribution, whatever the points), else every build of the class. A drift
-- is said only when the picked build can no longer be reached (kind "build",
-- to the nearest build still open in its role, or kind "role" when only
-- another role's builds are open), with the marker the player's dismissal is
-- kept by. choice is the group's own: role, pickedBuild, freestyle, driftSeen.
-- The window freezes the role and build it shows (it changes only on the
-- player's own click), so a point spent updates the facts, never what the
-- page is for.
function G.resolve(snap, class, choice)
  local r = { phase = G.phase(snap), freestyle = choice.freestyle and true or false }
  local chosen
  for _, role in ipairs(G.roles(class)) do
    if role == choice.role then chosen = role end
  end
  r.roleChosen = chosen ~= nil
  local picked
  for _, id in ipairs(G.builds(class, chosen)) do
    if id == choice.pickedBuild then picked = id end
  end
  r.role = chosen or (picked and data().builds[picked].role) or G.role(snap, class, nil)
  if r.phase ~= "spent" then
    r.build = picked or G.build(snap, class, r.role, nil)
    r.followed = picked and "picked" or "default"
    r.mode = r.freestyle and "own" or picked and "picked" or "none"
    return r
  end
  local candidates = chosen or picked and data().builds[picked].role or nil
  local open = G.open(snap, class, candidates)
  local n = G.earned(snap)
  local function nearest(list)
    local best, far
    for _, id in ipairs(list) do
      local off = G.differ(snap, data().builds[id], n)
      if not far or off < far then
        best, far = id, off
      end
    end
    return best
  end
  if picked then
    r.build, r.followed, r.mode = picked, "picked", "picked"
    if not G.reachable(snap, data().builds[picked]) then
      -- (the pick can no longer be reached: say so once, offer the nearest that can)
      local to = nearest(G.open(snap, class, r.role))
      local mark = picked .. ":" .. (to or "") .. ":" .. r.role
      if to then
        r.drift = { kind = "build", from = picked, to = to, mark = mark }
      else
        local build = nearest(G.open(snap, class, nil))
        if build and data().builds[build].role ~= r.role then
          r.drift = { kind = "role", role = data().builds[build].role, build = build, mark = mark .. ":" .. build }
        else
          r.unreachable = true
        end
      end
      if r.drift and choice.driftSeen == r.drift.mark then r.drift.seen = true end
    end
  elseif #open == 1 then
    r.build, r.followed, r.mode = open[1], "points", "points"
  elseif #open > 1 then
    -- (never asked which build: the page shows the one we advise for the role if it is open, else the first open; the window asks the role)
    local rec = G.recommend(class, data().builds[open[1]].role)
    r.build, r.followed, r.mode, r.open = open[1], "points", "open", open
    for _, id in ipairs(open) do
      if id == rec then r.build = rec end
    end
  else
    -- (none of the role's builds can be reached: another role's may be, then a switch is offered)
    r.build, r.followed, r.mode = nearest(G.builds(class, candidates)), "points", "points"
    local other = nearest(G.open(snap, class, nil))
    if candidates and other then
      r.drift = {
        kind = "role",
        role = data().builds[other].role,
        build = other,
        mark = r.build .. ":" .. other .. ":" .. r.role,
        unpicked = true,
      }
      if choice.driftSeen == r.drift.mark then r.drift.seen = true end
    else
      r.unreachable = true
    end
  end
  if not chosen and not picked then r.role = data().builds[r.build].role end
  if r.mode == "own" or r.freestyle then
    r.mode, r.drift, r.open, r.unreachable = "own", nil, nil, nil
  end
  return r
end

-- The advice for a role (the level-10 recommendation): the builds that fit it
-- in the writer's order, the first three picks of the first, each with its
-- reason (the content may say more: advice[class][role].say).
function G.advice(class, role)
  local builds, picks = G.builds(class, role), {}
  local first = builds[1] and data().builds[builds[1]]
  for i = 1, first and math.min(3, #first.path) or 0 do
    table.insert(picks, first.path[i])
  end
  local own = data().advice and data().advice[class] and data().advice[class][role]
  return { builds = builds, picks = picks, say = own and own.say }
end

-- Whether the level-10 question is to be asked now: points to spend and none
-- spent, no role chosen for this group, not put off at this level.
function G.asking(snap, choice, class)
  -- (a role the class has no build for is no role chosen, as resolve reads it;
  -- the role is looked at first so a stored one never reads the talents)
  for _, role in ipairs(G.roles(class)) do
    if role == choice.role then return false end
  end
  if G.phase(snap) ~= "choose" then return false end
  -- (a class with one role has nothing to ask: its page is that role's. On Forever the question is the spec, so a class
  -- with one build has nothing to ask, and a class with three damage specs asks)
  if G.specFirst() then
    if #G.builds(class) < 2 or G.pickedOf(class, choice) then return false end
  elseif #G.roles(class) < 2 then
    return false
  end
  return choice.notYet == nil or snap.level > choice.notYet
end
