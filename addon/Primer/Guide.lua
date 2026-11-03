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
-- (the data's own, English, where the game does not say).
function G.name(snap, build)
  for _, t in pairs(data().talents) do
    local info = t.tab == build.tree and snap.talents.byId[t.id]
    if info then return snap.talents.names[info.tab] or build.name end
  end
  return build.name
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
-- else the role's build with the most points, else its first.
function G.build(snap, class, role, saved)
  local mine = G.builds(class, role)
  for _, id in ipairs(mine) do
    if id == saved then return id end
  end
  local best, most = mine[1], 0
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
      if snap.knows(row.spell) then
        table.insert(out, row)
      else
        unlearned = unlearned + 1
      end
    end
  end
  return out, unlearned
end

-- The build's talents in order, as the character stands: each step with its
-- state ("done", "partly", "later"), the rank it has and the talents it names
-- ({ spell, info (the game's: name, icon, rank, max) }), and the index of the
-- next pick (nil: all taken).
function G.steps(build, snap)
  local out, nextStep = {}, nil
  for i, step in ipairs(build.path) do
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

-- The points the character can spend now: one a level from 10, less what it
-- has put in.
function G.unspent(snap)
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

-- (a few points off a build still fit it: a choice of weapon, a talent taken
-- early. The split note waits for 5 points, so one or two do not shout it.)
G.TOLERANCE, G.SPLIT_SHARE, G.SPLIT_GAP, G.SPLIT_FROM = 3, 0.6, 5, 5

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
  local earned = math.max(0, math.min(snap.level, G.MAX_LEVEL) - G.FIRST_POINT_LEVEL + 1)
  return math.max(math.min(earned, G.POINTS), snap.talents.total)
end

-- The points a build would have in each tree (by place) after n points of its path.
function G.expected(snap, build, n)
  local out = {}
  for _, step in ipairs(build.path) do
    if n <= 0 then break end
    local count = math.min(n, step.points[2] - step.points[1] + 1)
    local at = G.treeIndex(snap, data().talents[step.talent or step.any[1]].tab)
    if at then out[at] = (out[at] or 0) + count end
    n = n - count
  end
  return out
end

-- How many of the character's points the build would not have put where they are.
function G.differ(snap, build, n)
  local want, off = G.expected(snap, build, n), 0
  for tree, have in pairs(snap.talents.points) do
    off = off + math.max(0, have - (want[tree] or 0))
  end
  return off
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

-- The two trees the points are split between, when they are: the top tree under
-- 60 percent of what is spent, or two trees within 5 points (from 5 spent).
function G.split(snap)
  local total = snap.talents.total
  if total < G.SPLIT_FROM then return nil end
  local trees = {}
  for tree, have in pairs(snap.talents.points) do
    table.insert(trees, { tree = tree, have = have })
  end
  table.sort(trees, function(a, b)
    if a.have ~= b.have then return a.have > b.have end
    return a.tree < b.tree
  end)
  local top, second = trees[1], trees[2]
  if second and (top.have < G.SPLIT_SHARE * total or top.have - second.have <= G.SPLIT_GAP) then
    return top.tree, second.tree
  end
end

-- What the character is on: its phase, role (the one it chose, else the points'),
-- the build the page follows and why ("picked": the build it picked, its points
-- still fit; "kept": it kept the pick the points left; "inferred": the nearest
-- build to the points; "default": nothing spent yet), a drift to say once
-- (kind "build" or "role", with the marker the player's dismissal is kept
-- by), the split trees. A freestyle character has no drift and no split.
-- choice is the group's own: role, pickedBuild, freestyle, driftSeen, driftWay.
function G.resolve(snap, class, choice)
  local r = { phase = G.phase(snap), freestyle = choice.freestyle and true or false }
  r.roleChosen = false
  r.role = G.role(snap, class, choice.role)
  for _, role in ipairs(G.roles(class)) do
    if role == choice.role then r.roleChosen = true end
  end
  local picked
  for _, id in ipairs(G.builds(class, r.role)) do
    if id == choice.pickedBuild then picked = id end
  end
  if r.phase ~= "spent" then
    r.build = picked or G.build(snap, class, r.role, nil)
    r.followed = picked and "picked" or "default"
    return r
  end
  local n = G.earned(snap)
  local role, far = G.nearest(snap, class, r.role)
  local any, anyFar = G.nearest(snap, class, nil)
  r.nearest, r.far = role, far
  if picked and G.differ(snap, data().builds[picked], n) <= G.TOLERANCE then
    r.build, r.followed = picked, "picked"
  else
    r.build, r.followed = role, "inferred"
    if far > G.TOLERANCE then r.splitTrees = { G.split(snap) } end
    local mark = role .. ":" .. r.role .. ":" .. (any or "")
    if anyFar <= G.TOLERANCE and far > G.TOLERANCE and data().builds[any].role ~= r.role then
      r.drift = { kind = "role", role = data().builds[any].role, build = any, mark = mark }
    elseif picked and picked ~= role then
      r.drift = { kind = "build", from = picked, to = role, mark = mark }
    end
    if r.drift and choice.driftSeen == r.drift.mark then
      if r.drift.kind == "build" and choice.driftWay == "keep" then
        r.build, r.followed = picked, "kept"
      end
      r.drift.seen = true
    end
  end
  if r.freestyle then
    r.drift, r.splitTrees = nil, nil
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
  return choice.notYet == nil or snap.level > choice.notYet
end
