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
function G.stage(build, level)
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
