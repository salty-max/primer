-- The guide's window: the family's (the kit's K.gameWindow: portrait, title
-- bar) with the builds on the left and the page on the right, the tabs under
-- the bottom edge: Play (the opening and the priority for the level), Talents
-- (the build's talents in order, what is taken, the next pick) and Role
-- (damage, tank or heal, and what the build is for). Opened by /primer, the
-- minimap button and Keyring's (ns.toggle, never a hook on a Blizzard frame).
--
-- It reads the game when it draws and never in combat (Reader.lua): in a fight
-- the window waits, then draws. What the player chose (the build, the role)
-- is PrimerChar's.
local _, ns = ...
local K, L = ns.kit, ns.kit.L
local T = K.T
local G = ns.rules

local TABS = { overview = 1, play = 2, talents = 3, role = 4 }
ns.TAB = TABS

local frame, left, list, page
local view = {} -- what this session picked on the Talents tab: step, group; putOff: the question put off
ns.view = view -- (for the tests)
local rows = {} -- the Play page's lines, pooled
ns.playRows = rows -- (for the tests)

-- ── words ────────────────────────────────────────────────────────────────────
local function roleName(role)
  if role == "tank" then return L["Tank"] end
  if role == "heal" then return L["Heal"] end
  return L["Damage"]
end
local function gameName() return ns.forever and L["Forever"] or L["Classic Era"] end
local function groupName(g) return g == 1 and L["Primary"] or L["Secondary"] end
local function levels(a, b)
  if a == b then return L["Level %d"]:format(a) end
  return L["Level %d to %d"]:format(a, b)
end
local function capital(s) return (s:gsub("^%l", string.upper)) end

-- A spell's name as the game gives it (never typed here), by id.
local function spellName(id)
  local name = ns.reader.spell(id)
  return name or L["Unknown spell"]
end

-- A row's second line: the forms it is pressed in and the moment, in the data's words.
local function facts(row)
  local parts = {}
  if row.stance then
    local names = {}
    for _, key in ipairs(row.stance) do
      table.insert(names, spellName(ns.data.stances[key]))
    end
    table.insert(parts, L["In %s"]:format(table.concat(names, L[" or "])))
  end
  for _, w in ipairs(row.when or {}) do
    table.insert(parts, ns.say("when." .. w))
  end
  return capital(table.concat(parts, ", "))
end

-- ── a line of the priority ───────────────────────────────────────────────────
-- The game's own slot for the spell (its picture by id), its name, the form
-- and the moment under it, then the reason.
local function line(i)
  local r = rows[i]
  if r then return r end
  r = CreateFrame("Frame", nil, page.child)
  r:SetSize(page.width, 60)
  r.slot = K.slot(r, 36)
  r.slot:SetPoint("TOPLEFT", 2, -4)
  r.name = K.label(r, K.TITLE_FONT, 15, T.text)
  r.name:SetPoint("TOPLEFT", r.slot, "TOPRIGHT", 10, -1)
  r.name:SetPoint("RIGHT", -4, 0)
  r.name:SetWordWrap(false)
  r.facts = K.label(r, K.BODY_FONT, 11, T.soft)
  r.facts:SetPoint("TOPLEFT", r.name, "BOTTOMLEFT", 0, -4)
  r.facts:SetPoint("RIGHT", -4, 0)
  r.facts:SetWordWrap(false)
  r.say = K.label(r, K.BODY_FONT, 13, T.text)
  r.say:SetPoint("TOPLEFT", r.slot, "BOTTOMLEFT", 0, -8)
  r.say:SetWidth(page.width - 8)
  r.say:SetSpacing(3)
  r.slot:SetScript("OnEnter", function(self)
    if not (GameTooltip and self.spell) then return end
    -- (a tooltip the client refuses is no error out of a mouse-over)
    local ok, err = pcall(function()
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:SetSpellByID(self.spell)
      GameTooltip:Show()
    end)
    if not ok then ns.fault("tooltip", err) end
  end)
  r.slot:SetScript("OnLeave", function()
    if GameTooltip then GameTooltip:Hide() end
  end)
  rows[i] = r
  return r
end

local function place(i, row)
  local r = line(i)
  local name, icon = ns.reader.spell(row.spell)
  r.spell = row.spell
  K.setSlot(r.slot, icon)
  r.name:SetText(name or L["Unknown spell"])
  r.facts:SetText(facts(row))
  r.say:SetText(ns.say(row.say))
  local h = 4 + 36 + 8 + r.say:GetStringHeight() + 14
  r:SetHeight(h)
  page:place(r, h)
end

-- ── a rotation plan ──────────────────────────────────────────────────────────
-- A stage's plan (the writer's): the opening in order, the loop read from the
-- top (the first line that applies, then again), between fights, low mana and
-- the big cooldowns, each step the game's own icon and name by id and one line:
-- when it applies, what to do, why. A step the character cannot press yet is
-- grey and says why (the level it comes at, the talent it needs, or that it is
-- not in the book yet): the plan grows as the character levels.
local planSteps = {} -- the plan's steps, pooled
ns.planRows = planSteps -- (for the tests)
local STEP_ICON = "Interface\\Icons\\INV_Misc_Note_01"

local function stepFrame(i)
  local r = planSteps[i]
  if r then return r end
  r = CreateFrame("Frame", nil, page.child)
  r:SetSize(page.width, 40)
  r.slot = K.slot(r, 30)
  r.slot:SetPoint("TOPLEFT", 2, -3)
  r.name = K.label(r, K.TITLE_FONT, 14, T.text)
  r.name:SetPoint("TOPLEFT", r.slot, "TOPRIGHT", 10, 0)
  r.name:SetPoint("RIGHT", -4, 0)
  r.name:SetWordWrap(false)
  r.say = K.label(r, K.BODY_FONT, 12, T.soft)
  r.say:SetPoint("TOPLEFT", r.name, "BOTTOMLEFT", 0, -3)
  r.say:SetWidth(page.width - 50)
  r.say:SetSpacing(2)
  r.slot:SetScript("OnEnter", function(self)
    if not (GameTooltip and self.spell) then return end
    local ok, err = pcall(function()
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:SetSpellByID(self.spell)
      GameTooltip:Show()
    end)
    if not ok then ns.fault("tooltip", err) end
  end)
  r.slot:SetScript("OnLeave", function()
    if GameTooltip then GameTooltip:Hide() end
  end)
  planSteps[i] = r
  return r
end

-- A step's line: when it applies, what to do, why, each a clause with a full stop.
local function sentence(step, last)
  local parts = {}
  if step.cond then
    table.insert(parts, capital(ns.say(step.cond)))
  elseif last then
    table.insert(parts, L["If nothing above applies"])
  end
  if step.stance then
    local names = {}
    for _, key in ipairs(step.stance) do
      table.insert(names, spellName(ns.data.stances[key]))
    end
    table.insert(parts, L["In %s"]:format(table.concat(names, L[" or "])))
  end
  if step.say then table.insert(parts, capital(ns.say(step.say))) end
  if step.why then table.insert(parts, capital(ns.say(step.why))) end
  return #parts > 0 and (table.concat(parts, ". ") .. ".") or ""
end

-- One step placed on the page: its number (none in the big cooldowns), icon
-- and name, and its line, grey with the reason when it cannot be pressed yet.
local used = 0
local function placeStep(snap, step, number, last)
  used = used + 1
  local r = stepFrame(used)
  local name, icon
  if step.spell then
    name, icon = ns.reader.spell(step.spell)
    name = name or L["Unknown spell"]
    icon = step.icon or icon -- (a spell every character has: the picture the action bar gives it)
  else
    name, icon = ns.say(step.text), STEP_ICON
  end
  local state, extra = G.stepState(step, snap)
  r.spell, r.state = step.spell, state -- (state: for the tests)
  K.setSlot(r.slot, icon or K.QUESTION, nil, nil, state ~= "ready")
  r.name:SetText(number and ("%d. %s"):format(number, name) or name)
  r.name:SetTextColor(unpack(state == "ready" and T.text or T.soft))
  local words = sentence(step, last)
  local because
  if state == "level" then
    because = L["Level %d"]:format(extra) .. "."
  elseif state == "talent" then
    local talent = G.talent(snap, extra)
    because = L["Needs %s"]:format(talent and talent.name or spellName(extra)) .. "."
  elseif state == "book" then
    because = L["Not in your book yet"] .. "."
  end
  if because then words = words ~= "" and (because .. " " .. words) or because end
  r.say:SetText(words)
  r.say:SetTextColor(unpack(state == "ready" and T.text or T.soft))
  local h = words == "" and 38 or math.max(4 + 16 + 3 + r.say:GetStringHeight() + 10, 40)
  r:SetHeight(h)
  page:place(r, h)
end

local function drawPlan(snap, plan, dry)
  used = 0
  local function block(heading, hint, lines)
    if not (lines and #lines > 0) then return end
    page:section(heading)
    if hint then page:paragraph(hint, T.soft) end
    for i, step in ipairs(lines) do
      placeStep(snap, step, i, heading == L["Loop"] and i == #lines)
    end
  end
  block(L["Opening"], nil, plan.opening)
  block(
    L["Loop"],
    L["Read from the top and press the first line that applies, then start again."]
      .. (dry and (" " .. ns.say(dry)) or ""),
    plan.loop
  )
  block(L["Between fights"], nil, plan.between)
  block(L["Low mana"], nil, plan.low)
  if plan.alt then
    -- (another way to play this stage, with its own lists)
    page:section(ns.say(plan.alt.name))
    page:paragraph(capital(ns.say(plan.alt.say)) .. ".", T.soft)
    block(L["Opening"], nil, plan.alt.opening)
    block(L["Loop"], nil, plan.alt.loop)
    block(L["Between fights"], nil, plan.alt.between)
    block(L["Low mana"], nil, plan.alt.low)
  end
  if plan.big and #plan.big.spells > 0 then
    page:section(L["Big cooldowns"])
    for _, step in ipairs(plan.big.spells) do
      step.why = nil
      placeStep(snap, step, nil, false)
    end
    page:paragraph(capital(ns.say(plan.big.say)) .. ".", T.text)
  end
end

-- ── the empty pages ──────────────────────────────────────────────────────────
-- The class's crest where the character has one, the book's icon else.
local function crest(snap) return K.crest(snap and snap.token, ns.ICON) end

local function empty(kind, snap)
  local title, sub, text
  if kind == "season" then
    title, sub = L["Season of Discovery"], L["The guide is quiet here"]
    text =
      L["Runes change how every class plays in Season of Discovery, so the guide stays quiet here rather than give you the wrong order."]
  elseif kind == "game" then
    title, sub = L["No guide for %s yet"]:format(gameName()), snap.className
    text = ns.forever
        and L["Forever has talents Classic Era does not, and has changed some it shares. Classic Era's advice would send you wrong, so none of it is shown here. The guide will be written from Forever's own talents and spells."]
      or L["Nothing is written for this game yet."]
  else
    title, sub = L["No guide for %s yet"]:format(snap.className), gameName()
    text = L["No guide is written for %s on %s yet. The page stays empty rather than guess."]:format(
      snap.className,
      gameName()
    )
  end
  list:begin()
  list:add("note", L["Nothing here yet."])
  list:finish()
  page:start(title, sub, crest(snap))
  page:paragraph(text, T.text)
  page:finish()
end

-- ── the list on the left ─────────────────────────────────────────────────────
local function pickBuild(id, group)
  local choice = ns.choice(group)
  -- (picking a build is taking the guide again: its way, its notes)
  -- (a build is a role's: using one looked at from another role takes the role with it)
  choice.role = ns.data.builds[id].role
  choice.pickedBuild, choice.freestyle, choice.driftSeen = id, nil, nil
  view.step, view.look = nil, nil
  ns.refresh()
end

-- The builds on offer (the role's), the one the page shows picked out. A click
-- only LOOKS at a build (the page says so, and says how to use it): nothing is
-- chosen until the player presses Use this build.
local function buildList(snap, class, role, shown, heading, mine)
  list:add("section", heading)
  for _, id in ipairs(G.builds(class, role)) do
    local b = ns.data.builds[id]
    local r = list:add("entry", G.name(snap, b), id == mine and L["yours"] or nil, roleName(b.role))
    r:SetScript("OnClick", function()
      view.look = id ~= mine and { build = id } or nil
      view.step = nil
      ns.page()
    end)
    if id == shown then list:pick(r) end
  end
end

-- ── what the points say ─────────────────────────────────────────────────────
-- The quiet block at the top of a page: the level-10 question (asked once, never
-- a pop-up), the advice once a role is chosen, the points split between trees,
-- the points no longer fitting the pick (said once, three ways on) and a drift
-- toward another role (a switch offered, never made silently). The voice never
-- scolds: a drift is a fact about points. Nothing here for a freestyle
-- character, and nothing but the spells' pages.
local function treeName(snap, tree) return snap.talents.names[tree] or L["Tree %d"]:format(tree) end
-- "Holy", "Holy and Retribution", "Fury, Arms and Protection"
local function listNames(names)
  if #names < 2 then return names[1] or "" end
  return table.concat(names, ", ", 1, #names - 1) .. L[" and "] .. names[#names]
end
local function roleLike(role)
  if role == "tank" then return L["a tank"] end
  if role == "heal" then return L["a healer"] end
  return L["a damage build"]
end
local function choose(choice, field, value)
  return function()
    choice[field] = value
    ns.refresh()
  end
end

-- (the question is asked once in a session: "not yet" holds until the game is reloaded, and for the level)
local function asking(snap, choice, class) return not view.putOff and G.asking(snap, choice, class) end

local pickRole -- (the Role section's, a choice)

local function notes(snap, class, r, choice, tab)
  if r.looking then
    -- (looking is not choosing: said loudly, one button to use it, one to go back)
    local back = function()
      view.look, view.step = nil, nil
      ns.page()
    end
    if r.looking == "role" then
      page:paragraph(L["Looking at %s, not your role."]:format(roleName(r.role)), T.accent)
      page:buttons({
        { L["Use this role"], function() pickRole(r.role, r.mineRole, snap.group) end },
        { L["Back to %s"]:format(roleName(r.mineRole)), back },
      })
    else
      page:paragraph(L["Looking at %s, not your build."]:format(G.name(snap, ns.data.builds[r.build])), T.accent)
      page:buttons({
        { L["Use this build"], function() pickBuild(r.build, snap.group) end },
        { L["Back to %s"]:format(G.name(snap, ns.data.builds[r.mine])), back },
      })
    end
    return
  end
  if r.freestyle then return end
  if tab == TABS.play and asking(snap, choice, class) then
    page:section(L["You have talent points to spend."])
    page:paragraph(L["What do you want to play?"], T.text)
    -- (the narrator: what to weigh, and what a change costs where the cost is known)
    page:paragraph(
      ns.forever and L["Pick what you will do most. You can change it later."]
        or L["Pick what you will do most. You can change it later, and a respec costs gold."],
      T.soft
    )
    local buttons = {}
    for _, role in ipairs(G.roles(class)) do
      table.insert(buttons, {
        roleName(role),
        function()
          choice.role, choice.pickedBuild, choice.notYet = role, nil, nil
          view.roleSaid = nil
          ns.refresh()
        end,
      })
    end
    table.insert(buttons, {
      L["Not yet"],
      function()
        choice.notYet = snap.level
        view.putOff = true
        ns.page() -- (putting it off changes nothing the page is for)
      end,
    })
    page:buttons(buttons)
  elseif tab == TABS.play and r.phase == "choose" and r.roleChosen then
    -- (a role chosen, no points spent: the advice shows, the question does not)
    local advice = G.advice(class, r.role)
    page:section(L["Then these first."])
    local names = {}
    for _, id in ipairs(advice.builds) do
      table.insert(names, G.name(snap, ns.data.builds[id]))
    end
    page:paragraph(L["Builds that fit: %s."]:format(table.concat(names, ", ")), T.text)
    if advice.say then page:paragraph(ns.say(advice.say), T.text) end
    for _, step in ipairs(advice.picks) do
      local spell = step.talent or step.any[1]
      local info = G.talent(snap, spell)
      page:paragraph(("%s. %s"):format(info and info.name or spellName(spell), ns.say(step.why)), T.text)
    end
  elseif tab == TABS.play and view.putOff and r.phase == "choose" then
    page:paragraph(L["Fine. The page stays on the untalented kit until you pick."], T.soft)
  end
  if r.phase ~= "spent" then return end
  if r.open then
    -- (the points leave several builds open and nothing says which: the page says so
    -- and asks, never guessing from the tree with most points)
    local names = {}
    for _, id in ipairs(r.open) do
      table.insert(names, G.name(snap, ns.data.builds[id]))
    end
    page:paragraph(L["Your points leave %s open. Which are you going for?"]:format(listNames(names)), T.text)
    local buttons = {}
    if not r.roleChosen then
      local seen = {}
      for _, id in ipairs(r.open) do
        local role = ns.data.builds[id].role
        if not seen[role] then
          seen[role] = true
          table.insert(buttons, {
            roleName(role),
            function()
              choice.role, choice.pickedBuild = role, nil
              view.step = nil
              ns.refresh()
            end,
          })
        end
      end
    else
      for _, id in ipairs(r.open) do
        table.insert(buttons, {
          L["Use %s"]:format(G.name(snap, ns.data.builds[id])),
          function() pickBuild(id, snap.group) end,
        })
      end
    end
    page:buttons(buttons)
  elseif r.unreachable then
    local near = G.name(snap, ns.data.builds[r.build])
    local top, second = G.split(snap)
    if r.followed == "picked" then
      page:paragraph(
        L["Your points fit none of the builds. This page stays on %s, the build you picked."]:format(near),
        T.soft
      )
    elseif top and second then
      page:paragraph(
        L["Your points are split between %s and %s, so none of the builds fits them. This page shows the nearest, %s."]:format(
          treeName(snap, top),
          treeName(snap, second),
          near
        ),
        T.soft
      )
    else
      page:paragraph(L["Your points fit none of the builds. This page shows the nearest, %s."]:format(near), T.soft)
    end
  end
  local drift = r.drift
  if not drift or drift.seen then return end
  if drift.kind == "build" then
    local from, to = G.name(snap, ns.data.builds[drift.from]), G.name(snap, ns.data.builds[drift.to])
    page:paragraph(
      L["Your points can no longer reach the build you chose. This page stays on it until you say otherwise."]
        .. " "
        .. L["These points follow %s more than the %s build you picked."]:format(to, from),
      T.soft
    )
    page:buttons({
      {
        L["Keep %s"]:format(from),
        function()
          choice.driftSeen = drift.mark
          ns.page() -- (keeping the pick: the page is what it was)
        end,
      },
      {
        L["Follow %s"]:format(to),
        function() pickBuild(drift.to, snap.group) end,
      },
      { L["My own way"], choose(choice, "freestyle", true) },
    })
  else
    page:paragraph(
      (drift.unpicked and (L["None of your role's builds can be reached by your points."] .. " ") or "")
        .. L["These points look more like %s than %s. Switch your role to %s?"]:format(
          roleLike(drift.role),
          roleLike(r.role),
          roleName(drift.role)
        ),
      T.soft
    )
    page:buttons({
      {
        L["Switch"],
        function()
          choice.role, choice.pickedBuild, choice.driftSeen = drift.role, nil, nil
          view.step = nil
          ns.refresh()
        end,
      },
      {
        L["Stay on %s"]:format(roleName(r.role)),
        function()
          choice.driftSeen = drift.mark
          ns.page()
        end,
      },
    })
  end
end

-- ── Play ─────────────────────────────────────────────────────────────────────
local function drawPlay(snap, class, r, choice)
  local role, id = r.role, r.build
  local b = ns.data.builds[id]
  list:begin()
  buildList(snap, class, role, id, L["Build"], r.mine)
  list:finish()
  local idx, starts = G.stage(b, snap.level, r.phase)
  local stage = idx and b.stages[idx]
  page:start(G.name(snap, b), stage and levels(stage.from, stage.to) or roleName(b.role), crest(snap))
  notes(snap, class, r, choice, TABS.play)
  if not stage then
    page:paragraph(L["This build starts at level %d. Come back then."]:format(starts), T.text)
    page:finish(view.keep)
    return
  end
  if stage.about then page:text({ ns.say(stage.about) }) end
  local shown, unlearned = {}, 0
  if stage.plan then
    drawPlan(snap, stage.plan, b.dry)
  else
    if stage.opening then
      page:section(L["Opening"])
      page:paragraph(ns.say(stage.opening), T.text)
    end
    shown, unlearned = G.rows(stage, snap)
    page:section(L["Priority"])
    for i, row in ipairs(shown) do
      place(i, row)
    end
    if #shown == 0 then
      page:paragraph(L["Nothing in your book fits this stage yet. Your trainer has more."], T.soft)
    end
  end
  if b.hardcore and snap.season == G.HARDCORE then
    page:section(L["Hardcore"])
    for _, key in ipairs(b.hardcore) do
      page:paragraph(ns.say(key), T.text)
    end
  end
  if unlearned > 0 then
    page:paragraph(
      K.plural(
        unlearned,
        "%d spell for this stage is not in your book yet.",
        "%d spells for this stage are not in your book yet."
      ):format(unlearned),
      T.soft
    )
  end
  page:paragraph(
    L["A sensible way to play, not the only one. Cooldowns and procs in a real fight will change the order."]
      .. " "
      .. L["Checked on %s %s, %s."]:format(gameName(), b.build, b.checked),
    T.soft
  )
  page:finish(view.keep)
end

-- ── Talents ──────────────────────────────────────────────────────────────────
local function optionName(o) return o.info and o.info.name or spellName(o.spell) end
local function optionIcon(o)
  if o.info and o.info.icon then return o.info.icon end
  local _, icon = ns.reader.spell(o.spell)
  return icon or K.QUESTION
end
-- The talent a step shows: a choice shows the one taken, else it is "one of".
local function stepFace(s)
  if #s.options == 1 then return optionName(s.options[1]), optionIcon(s.options[1]) end
  for _, o in ipairs(s.options) do
    if o.info and o.info.rank > 0 then return optionName(o), optionIcon(o) end
  end
  return L["One of %d talents"]:format(#s.options), K.QUESTION
end

local function drawTalents(snap, class, r, choice)
  local role, id = r.role, r.build
  local b = ns.data.builds[id]
  local steps, nextStep = G.steps(b, snap, r.road)
  local picked = math.min(view.step or nextStep or #steps, #steps)
  view.step = picked -- (the talent in view stays: a point spent updates it, it does not move on)
  list:begin()
  if snap.groups > 1 then
    -- (a second talent group: look at either one's build, the one in use named)
    list:add("section", L["Talents"])
    for g = 1, snap.groups do
      local row = list:add("row", groupName(g), g == snap.active and L["in use"] or nil)
      row:SetScript("OnClick", function()
        view.group, view.step = g, nil
        ns.page()
      end)
      if g == snap.group then list:pick(row) end
    end
    list:gap(6)
  end
  buildList(snap, class, role, id, L["Build"], r.mine)
  if r.freestyle then
    -- (their own way: no picks, no notes; the way back is one button)
    list:finish()
    page:start(G.name(snap, b), roleName(b.role), crest(snap))
    notes(snap, class, r, choice, TABS.talents) -- (looking at another build still says so)
    page:paragraph(
      L["Your own way, then. The spells, openings and priorities stay. The picks and the notes don't."],
      T.text
    )
    page:buttons({ { L["Use the guide's picks again"], choose(choice, "freestyle", nil) } })
    page:finish(view.keep)
    return
  end
  local roads = G.roads(b)
  if #roads > 1 then
    -- (another order of the same points for the same build: neither is a drift)
    list:gap(6)
    list:add("section", L["Road"])
    for i, road in ipairs(roads) do
      local row = list:add("row", ns.say(road.name), i == r.road and L["yours"] or nil)
      row:SetScript("OnClick", function()
        choice.roads = choice.roads or {}
        choice.roads[id] = i
        view.step = nil
        ns.refresh()
      end)
      if i == r.road then list:pick(row) end
    end
  end
  list:gap(6)
  list:add("section", L["Talents in order"])
  for i, s in ipairs(steps) do
    local name, icon = stepFace(s)
    local row = list:add(
      "entry",
      ("|T%s:16:16:0:0|t %s"):format(icon, name),
      ("%d/%d"):format(s.rank, s.step.rank),
      levels(s.step.level[1], s.step.level[2])
    )
    row:SetScript("OnClick", function()
      view.step = i
      ns.page()
    end)
    if s.state == "done" then row.text:SetTextColor(unpack(T.soft)) end
    if i == nextStep then row.text:SetTextColor(unpack(T.accent)) end
    if i == picked then list:pick(row) end
  end
  list:finish()

  local s = steps[picked]
  local name, icon = stepFace(s)
  page:start(
    name,
    ("%s, %s"):format(
      levels(s.step.level[1], s.step.level[2]),
      L["points %d to %d"]:format(s.step.points[1], s.step.points[2])
    ),
    K.icon(icon)
  )
  notes(snap, class, r, choice, TABS.talents)
  if #roads > 1 then
    local names = {}
    for i, road in ipairs(roads) do
      names[i] = ns.say(road.name)
    end
    page:paragraph(
      L["This build has more than one road for its first points, and none is wrong: %s."]:format(listNames(names)),
      T.soft
    )
    if r.phase == "spent" then
      page:paragraph(
        r.fitBoth and L["Your points fit every road."] or L["Your points follow %s."]:format(ns.say(roads[r.fit].name)),
        T.soft
      )
    end
  end
  local unspent = G.unspent(snap)
  local summary
  if not nextStep then
    summary = L["Every talent of this build is taken. Nothing left to decide."]
  elseif unspent > 0 then
    summary = K.plural(unspent, "You have %d talent point to spend.", "You have %d talent points to spend.")
      :format(unspent) .. " " .. L["Your next pick is %s."]:format((stepFace(steps[nextStep])))
  else
    summary = L["No talent points to spend. Your next pick is %s, at level %d."]:format(
      (stepFace(steps[nextStep])),
      steps[nextStep].step.level[1]
    )
  end
  page:text({ summary, ns.say(s.step.why) })
  if #s.options > 1 then
    page:section(L["Pick one"])
    for _, o in ipairs(s.options) do
      page:row(optionName(o), L["%d of %d"]:format(o.info and o.info.rank or 0, s.step.rank))
    end
  else
    page:row(L["Taken"], L["%d of %d"]:format(s.rank, s.step.rank))
  end
  page:row(L["Build"], G.name(snap, b))
  page:paragraph(ns.say(b.note), T.soft)
  -- (the writer's split is the rest of a sentence: where players split, it)
  if b.split then page:paragraph(L["Where players split: %s"]:format(ns.say(b.split)), T.soft) end
  page:finish(view.keep)
end

-- ── Role ─────────────────────────────────────────────────────────────────────
function pickRole(role, current, group)
  local choice = ns.choice(group)
  choice.role = role
  view.step, view.roleSaid, view.look = nil, role, nil
  if current ~= role then
    choice.pickedBuild, choice.driftSeen = nil, nil
  end
  ns.refresh()
end

local function drawRole(snap, class, r, choice)
  local role, id = r.role, r.build
  local b = ns.data.builds[id]
  list:begin()
  list:add("section", L["Role"])
  for _, each in ipairs(G.roles(class)) do
    local row = list:add("row", roleName(each), #G.builds(class, each))
    row:SetScript("OnClick", function()
      view.look = each ~= r.mineRole and { role = each } or nil
      view.step = nil
      ns.page()
    end)
    if each == role then list:pick(row) end
  end
  list:gap(6)
  buildList(snap, class, role, id, L["Build"], r.mine)
  list:finish()
  page:start(G.name(snap, b), roleName(b.role), crest(snap))
  if view.roleSaid == role then page:paragraph(L["%s it is."]:format(roleName(role)), T.text) end
  notes(snap, class, r, choice, TABS.role)
  if r.freestyle then
    page:paragraph(L["You are on your own way: no picks, no notes."], T.soft)
    page:buttons({ { L["Use the guide's picks again"], choose(choice, "freestyle", nil) } })
  elseif r.phase == "spent" then
    -- (what a role change would move: a count off the nearest build, and the fact of the cost)
    local nearest, far = G.nearest(snap, class, role)
    local near = G.name(snap, ns.data.builds[nearest])
    if far == 0 then
      page:paragraph(L["Your points already follow the %s build."]:format(near), T.soft)
    else
      -- (the cost of a respec is said only where it is known: Classic Era's gold, Forever's untried)
      local one, many =
        "%d point differs from the %s build for level %d. A respec would move it, and a respec costs gold.",
        "%d points differ from the %s build for level %d. A respec would move them, and a respec costs gold."
      if ns.forever then
        one, many =
          "%d point differs from the %s build for level %d. A respec would move it.",
          "%d points differ from the %s build for level %d. A respec would move them."
      end
      page:paragraph(K.plural(far, one, many):format(far, near, snap.level), T.soft)
    end
  end
  local words = { ns.say(b.intro) }
  if b.dry then table.insert(words, ns.say(b.dry)) end
  page:text(words)
  page:row(L["Role"], roleName(b.role))
  page:row(L["Checked"], ("%s %s, %s"):format(gameName(), b.build, b.checked))
  page:finish(view.keep)
end

-- ── Overview ─────────────────────────────────────────────────────────────────
-- The class in general, in the narrator's voice: who it is, what it is good and
-- bad at, its resource, how levelling goes, the builds in a line each and what
-- to do at level 10 (the class's `overview` in the data; a class without one
-- shows its page and the builds).
local function drawOverview(snap, class)
  local c = ns.data.classes[class]
  list:begin()
  list:add("section", L["Builds"])
  for _, id in ipairs(G.builds(class)) do
    local b = ns.data.builds[id]
    local row = list:add("entry", G.name(snap, b), nil, roleName(b.role))
    row:SetScript("OnClick", function()
      view.look, view.step = { build = id }, nil
      ns.open(TABS.role) -- (the Role tab is where a build is read about)
    end)
  end
  list:finish()
  page:start(snap.className, gameName(), crest(snap))
  local ov = c.overview
  local function part(heading, key)
    if ov and ov[key] then
      page:section(heading)
      page:paragraph(ns.say(ov[key]), T.text)
    end
  end
  if ov and ov.who then
    page:text({ ns.say(ov.who) })
  else
    page:text({ ns.say(c.text) })
  end
  part(L["Good at"], "good")
  part(L["Bad at"], "bad")
  part(L["Your resource"], "resource")
  part(L["Levelling"], "levelling")
  page:section(L["Builds"])
  for _, id in ipairs(G.builds(class)) do
    local b = ns.data.builds[id]
    page:row(G.name(snap, b), roleName(b.role) .. ". " .. ns.say(b.line))
  end
  part(L["At level 10"], "ten")
  page:finish(view.keep)
end

-- ── drawing ──────────────────────────────────────────────────────────────────
local waiting = false
local refresh

-- The guide could not draw this page: said plainly, no stack, and kept for
-- /primer debug (ns.fault). Even this is guarded: a window never raises.
local function broken(title, text)
  pcall(function()
    for _, r in ipairs(rows) do
      r:Hide()
    end
    for _, r in ipairs(planSteps) do
      r:Hide()
    end
    list:begin()
    list:add("note", L["Nothing here yet."])
    list:finish()
    frame.state:SetText("")
    page:start(title or L["Something went wrong"], "", K.icon(ns.ICON))
    page:paragraph(
      text
        or L["This page would not draw. Close the window and open it again. If it keeps happening, /primer debug says what it was."],
      T.text
    )
    page:finish()
  end)
end

-- What the page is for, fixed while the window is open: the role and build the
-- player picked or the points led to when it was opened (or when the player
-- last chose), never swapped by a point spent or a level gained: those update
-- the facts, the ticks and the notes in place. A click on another build or role
-- only LOOKS (view.look): the page is that build's, says so, and the player's
-- own stays named until they press Use.
local function model(snap, class, r, choice)
  -- (one for each talent group: looking at the other group and back never works the first one out again)
  view.subjects = view.subjects or {}
  local sub = view.subjects[snap.group]
  if not (sub and ns.data.builds[sub.build] and ns.data.builds[sub.build].class == class) then
    sub = { role = r.role, build = r.build, mode = r.mode }
    sub.road, sub.roadBoth = G.road(snap, ns.data.builds[r.build])
    view.subjects[snap.group] = sub
  end
  r.role, r.build, r.mode = sub.role, sub.build, sub.mode
  r.mine, r.mineRole = sub.build, sub.role
  local look = view.look
  if look and look.build and look.build ~= r.mine and ns.data.builds[look.build] then
    r.build, r.role, r.looking = look.build, ns.data.builds[look.build].role, "build"
  elseif look and look.role and look.role ~= r.mineRole then
    -- (the first build of that role its points leave open, never the tree with most points)
    r.role, r.build, r.looking = look.role, G.open(snap, class, look.role)[1] or G.builds(class, look.role)[1], "role"
  else
    view.look = nil
  end
  -- the road of the build shown (another order of the same points): the player's choice for it, else the one the points follow
  local roads = G.roads(ns.data.builds[r.build])
  local chosen = choice.roads and choice.roads[r.build]
  if r.build == r.mine then
    r.road, r.roadBoth = sub.road, sub.roadBoth
  else
    r.road, r.roadBoth = G.road(snap, ns.data.builds[r.build])
  end
  if chosen and roads[chosen] then r.road = chosen end
  -- (what the points follow is worked out fresh each draw, apart from the road the page lists)
  r.fit, r.fitBoth = G.road(snap, ns.data.builds[r.build])
  return r
end

-- The line on every tab that says what the page is for.
local function header(snap, r)
  local mine = G.name(snap, ns.data.builds[r.mine])
  if r.looking == "role" then
    return L["Looking at %s, not your role. Yours is %s."]:format(roleName(r.role), roleName(r.mineRole))
  elseif r.looking then
    return L["Looking at %s, not your build. Yours is %s."]:format(G.name(snap, ns.data.builds[r.build]), mine)
  end
  local parts = { L["%s %s."]:format(mine, snap.className), L["%s."]:format(roleName(r.role)) }
  if snap.groups > 1 then table.insert(parts, L["Talent group %d."]:format(snap.group)) end
  table.insert(parts, L["%s."]:format(L["Level %d"]:format(snap.level)))
  -- (the build stays what it was, the word follows the character: no points to follow after a respec)
  local mode = r.mode == "picked" and L["Following your pick."]
    or r.mode == "open" and r.phase == "spent" and L["Guessing from your points."]
    or r.mode == "points" and r.phase == "spent" and L["Following your points."]
    or r.mode == "own" and L["Your own way."]
    or L["Not chosen yet."]
  table.insert(parts, mode)
  return table.concat(parts, " ")
end

local function draw()
  if not (frame and frame:IsShown()) then return end
  -- (the Talents tab may look at the other talent group, the rest follow the one in use)
  local snap = ns.reader.snapshot(frame.selectedTab == TABS.talents and view.group or nil)
  if not snap then
    -- (a fight: nothing is read, the window looks again in a moment)
    frame.count:SetText(L["In combat. The guide waits."])
    if not waiting then
      waiting = true
      local again = view.mode
      C_Timer.After(2, function()
        waiting = false
        refresh(again)
      end)
    end
    return
  end
  snap.className = snap.className or L["Unknown class"]
  frame.count:SetText("")
  frame.state:SetText("")
  -- (the Play page's lines are ours: the page hides only its own blocks)
  for _, r in ipairs(rows) do
    r:Hide()
  end
  for _, r in ipairs(planSteps) do
    r:Hide()
  end
  local kind, class = G.page(snap)
  if kind ~= "guide" then
    ns.setGlow(false)
    return empty(kind, snap)
  end
  local choice = ns.choice(snap.group)
  local r = model(snap, class, G.resolve(snap, class, choice), choice)
  frame.state:SetText(header(snap, r))
  -- (the minimap button glows while the level-10 question waits to be asked)
  if snap.group == snap.active then ns.setGlow(asking(snap, choice, class)) end
  ns.draws = (ns.draws or 0) + 1 -- (for the tests: one draw for a burst of events)
  local n = frame.selectedTab
  if n == TABS.overview then
    drawOverview(snap, class)
  elseif n == TABS.talents then
    drawTalents(snap, class, r, choice)
  elseif n == TABS.role then
    drawRole(snap, class, r, choice)
  else
    drawPlay(snap, class, r, choice)
  end
  -- What a page cannot do without is what the game would not say (the talents
  -- taken, the spells in the book): no advice drawn from defaults, a page that
  -- says so in its place.
  if ns.reader.blind() then
    broken(
      L["The guide cannot read your character"],
      L["This version of the game would not tell the guide your spells or talents, so it shows nothing rather than guess. /primer debug says which."]
    )
  end
end

-- mode: "event" (the game told something: facts update in place, the scroll
-- stays), "page" (the player went to another tab or looked at another build:
-- the page from its top), "choice" (the player chose: what the page is for is
-- worked out again).
function refresh(mode)
  view.mode = mode
  view.keep = mode == "event"
  if mode == "choice" then view.subjects = nil end
  local ok, err = pcall(draw)
  if not ok then
    ns.fault("window", err)
    broken()
  end
end
function ns.refresh() refresh("choice") end
function ns.page() refresh("page") end

-- What the game tells shows a moment later, a burst of events as one look:
-- the glow on the minimap button (whether the level-10 question waits, read
-- out of combat even with the window closed) and the open window's page.
local pending = false
local function glow()
  local snap = ns.reader.snapshot()
  if not snap then return end -- (a fight: nothing is read)
  local kind, class = G.page(snap)
  ns.setGlow(kind == "guide" and asking(snap, ns.choice(snap.group), class))
end
function ns.changed()
  if pending then return end
  pending = true
  C_Timer.After(0.3, function()
    pending = false
    local ok, err = pcall(glow)
    if not ok then ns.fault("glow", err) end
    refresh("event")
  end)
end

local function show(n)
  frame.selectedTab = n
  K.selectTab(frame, n)
  view.step, view.group = nil, nil
  refresh("page")
end

-- The other talent group is the one in use now: look at that.
function ns.groupChanged()
  view.step, view.group = nil, nil
  ns.changed()
end

local function build()
  local window = K.gameWindow("PrimerFrame", "Primer", ns.ICON)
  frame = window or K.dialog("PrimerFrame", "Primer")
  PrimerSettings = PrimerSettings or {}
  K.movable(frame, K.BOOK_W, K.BOOK_H, K.place(PrimerSettings, "window"))
  local edge = window and 8 or 14
  frame.count = K.label(frame, K.BODY_FONT, 11, T.gold) -- (only to say it waits in a fight)
  frame.count:SetPoint("TOPLEFT", 64, -36)
  left = K.panel(frame, true)
  left:SetPoint("TOPLEFT", edge, -58)
  left:SetPoint("BOTTOMLEFT", edge, edge)
  left:SetWidth(244)
  local sheet = K.panel(frame)
  sheet:SetPoint("TOPLEFT", left, "TOPRIGHT", 4, 32)
  sheet:SetPoint("BOTTOMRIGHT", -edge, edge)
  list = K.list(left, nil, {}, false, "PrimerList")
  list:ClearAllPoints()
  list:SetPoint("TOPLEFT", left, "TOPLEFT", 12, -12)
  list:SetPoint("BOTTOMRIGHT", left, "BOTTOMRIGHT", -18, 12)
  -- the line that says what the page is for, on every tab, above the page
  frame.state = K.label(sheet, K.BODY_FONT, 12, T.accent)
  frame.state:SetPoint("TOPLEFT", 26, -12)
  frame.state:SetPoint("TOPRIGHT", -22, -12)
  frame.state:SetJustifyV("TOP")
  frame.state:SetSpacing(2)
  page = K.page(sheet, "PrimerPage", { labelWidth = 110, pairs = {} })
  page:ClearAllPoints()
  page:SetPoint("TOPLEFT", sheet, "TOPLEFT", 26, -48)
  page:SetPoint("BOTTOMRIGHT", sheet, "BOTTOMRIGHT", -22, 14)
  frame.selectedTab = TABS.play
  frame:SetScript("OnShow", function()
    ns.reader.reset() -- (a call that failed is tried again when the window is opened again)
    view.subjects, view.look = nil, nil -- (what the page is for is worked out again when it is opened)
    show(frame.selectedTab)
  end)
  K.tabs(frame, { L["Overview"], L["Play"], L["Talents"], L["Role"] }, show)
end

function ns.window()
  if not frame then build() end
  return frame
end
function ns.toggle()
  local f = ns.window()
  f:SetShown(not f:IsShown())
end
function ns.open(n)
  local f = ns.window()
  f.selectedTab = n or f.selectedTab
  if f:IsShown() then
    show(f.selectedTab)
  else
    f:Show() -- (its OnShow shows the tab)
  end
end
