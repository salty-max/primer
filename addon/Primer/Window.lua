-- The guide's window: the family's (the kit's K.gameWindow: portrait, title
-- bar), a header that says what the page is for, a strip for the one thing
-- that needs the player (a question, a drift, a change of stage), and three
-- tabs under the bottom edge: Overview (the class, in the narrator's voice),
-- Plan (what to press, in order, one line a row) and Talents (the trees with
-- the road drawn on them). Opened by /primer, the minimap button and Keyring's
-- (ns.toggle, never a hook on a Blizzard frame).
--
-- It reads the game when it draws and never in combat (Reader.lua). What the
-- page is for is frozen while the window is open: a point spent, a level or a
-- spell learned greys and lights the rows, moves a ring and a count, and
-- swaps nothing. It changes when the player clicks or opens the window again.
-- What the player chose (the role, the build) is PrimerChar's.
local _, ns = ...
local K, L = ns.kit, ns.kit.L
local T = K.T
local G = ns.rules

local TABS = { overview = 1, plan = 2, talents = 3 }
ns.TAB = TABS

local W = K.BOOK_W
local EDGE = 8
local HEAD_H, STRIP_H = 62, 40
local COL = 352 -- (a column of the plan)
local ROW_H = 28

local frame, head, strip, sheet, plan, overview, talents
local view = {} -- this session's: subjects (what each talent group's page is for), group, putOff, changing, slider, stage
ns.view = view -- (for the tests)
ns.screen = {} -- what the last draw put on screen, as tables (for the tests)

-- ── words ────────────────────────────────────────────────────────────────────
local function roleName(role)
  if role == "tank" then return L["Tank"] end
  if role == "heal" then return L["Heal"] end
  return L["Damage"]
end
local function gameName() return ns.forever and L["Forever"] or L["Classic Era"] end
local function capital(s) return (s:gsub("^%l", string.upper)) end
local function spellName(id) return ns.reader.spell(id) or L["Unknown spell"] end
local function reasons() return type(PrimerSettings) == "table" and PrimerSettings.showReasons == true end

-- ── a painter for the scrolling pages ────────────────────────────────────────
-- The Plan and the Overview are laid out from the top each draw, from pools of
-- rows and labels made once. A list never has more or fewer rows than the stage
-- gives it, so what changes under an event is a colour and a word.
local function painter(area)
  local P = { area = area, rows = {}, labels = {}, ri = 0, li = 0 }
  function P.begin()
    P.ri, P.li = 0, 0
    for _, r in ipairs(P.rows) do
      r:Hide()
    end
    for _, l in ipairs(P.labels) do
      l:Hide()
    end
  end
  function P.label(x, y, width, text, color, size, font)
    P.li = P.li + 1
    local l = P.labels[P.li]
    if not l then
      l = K.label(area.child, K.BODY_FONT, 12, T.text)
      l:SetJustifyV("TOP")
      P.labels[P.li] = l
    end
    l:SetFont(font or K.BODY_FONT, size or 12, "")
    l:SetTextColor(unpack(color or T.text))
    l:ClearAllPoints()
    l:SetPoint("TOPLEFT", area.child, "TOPLEFT", x, -y)
    l:SetWidth(width)
    l:SetSpacing(2)
    l:SetWordWrap(true)
    l:SetText(text)
    l:Show()
    local h = l:GetStringHeight()
    return y + (type(h) == "number" and h or 14)
  end
  function P.row()
    P.ri = P.ri + 1
    local r = P.rows[P.ri]
    if not r then
      r = CreateFrame("Frame", nil, area.child)
      r.slot = K.slot(r, 24)
      r.slot:SetPoint("TOPLEFT", 0, -2)
      r.num = K.label(r, K.BODY_FONT, 11, T.soft)
      r.num:SetPoint("TOPLEFT", 28, -7)
      r.name = K.label(r, K.TITLE_FONT, 13, T.text)
      r.name:SetPoint("TOPLEFT", 46, -5)
      r.name:SetWordWrap(false)
      r.when = K.label(r, K.BODY_FONT, 11, T.soft)
      r.when:SetWordWrap(false)
      r.why = K.label(r, K.BODY_FONT, 11, T.soft)
      r.why:SetWordWrap(true)
      r.slot:SetScript("OnEnter", function(self)
        if not GameTooltip then return end
        local ok, err = pcall(function()
          GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
          if self.spell then GameTooltip:SetSpellByID(self.spell) end
          if self.reason then GameTooltip:AddLine(self.reason, T.accent[1], T.accent[2], T.accent[3], true) end
          GameTooltip:Show()
        end)
        if not ok then ns.fault("tooltip", err) end
      end)
      r.slot:SetScript("OnLeave", function()
        if GameTooltip then GameTooltip:Hide() end
      end)
      P.rows[P.ri] = r
    end
    r:Show()
    return r
  end
  return P
end

-- ── a step of the plan ───────────────────────────────────────────────────────
local STEP_ICON = "Interface\\Icons\\INV_Misc_Note_01"

-- A plan step's condition: the writer's clause, or the situations a row of the older form names.
local function whenOf(step)
  if step.cond then return capital(ns.say(step.cond)) end
  if step.when then
    local out = {}
    for _, w in ipairs(step.when) do
      table.insert(out, ns.say("when." .. w))
    end
    return capital(table.concat(out, ", "))
  end
  return ""
end

local function stanceOf(step)
  if not step.stance then return nil end
  local names = {}
  for _, key in ipairs(step.stance) do
    table.insert(names, spellName(ns.data.stances[key]))
  end
  return L["In %s"]:format(table.concat(names, L[" or "]))
end

-- What a step the character cannot press yet needs, in one clause.
local function needs(snap, state, extra)
  if state == "level" then return L["Level %d"]:format(extra) end
  if state == "talent" then
    local talent = G.talent(snap, extra)
    return L["Needs %s"]:format(talent and talent.name or spellName(extra))
  end
  return L["Not in your book yet, learn it at your trainer"]
end

-- One row: [n] [icon] name, then when (or what it needs, grey). Returns the next y.
local function placeStep(P, x, y, width, snap, step, number, last)
  local r = P.row()
  local name, icon
  if step.spell then
    name, icon = ns.reader.spell(step.spell)
    name = name or L["Unknown spell"]
    icon = step.icon or icon
  else
    name, icon = ns.say(step.text), STEP_ICON
  end
  local state, extra = G.stepState(step, snap)
  local ready = state == "ready"
  local when = ready and whenOf(step) or needs(snap, state, extra)
  if ready and when == "" and last then when = L["If nothing above applies"] end
  local stance = ready and stanceOf(step)
  if stance then when = when ~= "" and (when .. ", " .. stance:lower()) or stance end
  local why = step.why and capital(ns.say(step.why)) or nil
  r:ClearAllPoints()
  r:SetPoint("TOPLEFT", P.area.child, "TOPLEFT", x, -y)
  r:SetSize(width, ROW_H)
  r.slot.spell, r.slot.reason = step.spell, why and (why .. ".") or nil
  K.setSlot(r.slot, icon or K.QUESTION, nil, nil, not ready)
  r.num:SetText(number and tostring(number) or "")
  r.name:SetText(name)
  r.name:SetTextColor(unpack(ready and T.text or T.soft))
  local used = r.name:GetStringWidth()
  used = math.min(190, (type(used) == "number" and used or #name * 7) + 10)
  r.when:ClearAllPoints()
  r.when:SetPoint("TOPLEFT", 46 + used, -6)
  r.when:SetWidth(width - 56 - used)
  r.when:SetText(when)
  r.when:SetTextColor(unpack(ready and T.soft or T.gold))
  local h = ROW_H
  if reasons() and why then
    r.why:ClearAllPoints()
    r.why:SetPoint("TOPLEFT", 46, -ROW_H + 4)
    r.why:SetWidth(width - 50)
    r.why:SetText(why .. ".")
    r.why:Show()
    local sh = r.why:GetStringHeight()
    h = ROW_H + (type(sh) == "number" and sh or 12) - 2
    r:SetHeight(h)
  else
    r.why:Hide()
  end
  local out = {
    n = number,
    spell = step.spell,
    name = name,
    state = state,
    when = when,
    why = why,
    text = step.text and name or nil,
  }
  return y + h, out
end

-- ── the stage's plan ─────────────────────────────────────────────────────────
-- A stage written as rows (the older form) reads as a loop of lines, so one painter serves both.
local function planOf(stage)
  if stage.plan then return stage.plan end
  local loop = {}
  for _, row in ipairs(stage.rows or {}) do
    local step = {}
    for k, v in pairs(row) do
      step[k] = v
    end
    step.why = row.say
    step.say = nil
    table.insert(loop, step)
  end
  return { opening = stage.opening and { { text = stage.opening } } or {}, loop = loop }
end

local function drawPlan(P, snap, b, stage)
  local screen = ns.screen
  screen.plan = { lists = {} }
  local p = planOf(stage)
  local function block(x, y, heading, hint, steps, numbered, bigSay)
    if not (steps and #steps > 0) then return y end
    y = P.label(x, y, COL - 10, heading, T.gold, 14, K.TITLE_FONT) + 2
    if hint then y = P.label(x, y, COL - 10, hint, T.soft, 11) + 2 end
    local list = { name = heading, rows = {} }
    for i, step in ipairs(steps) do
      local out
      y, out = placeStep(
        P,
        x,
        y,
        COL - 6,
        snap,
        step,
        numbered and i or nil,
        numbered and i == #steps and heading == L["Then repeat, top to bottom"]
      )
      table.insert(list.rows, out)
    end
    table.insert(screen.plan.lists, list)
    if bigSay then y = P.label(x, y, COL - 10, capital(ns.say(bigSay)) .. ".", T.text, 11) end
    return y + 8
  end
  local left, right = 0, COL + 22
  local y1 = block(left, 0, L["Opening"], L["Before the pull, in order."], p.opening, true)
  y1 = block(
    left,
    y1,
    L["Then repeat, top to bottom"],
    L["Press the first line that applies, then start again."],
    p.loop,
    true
  )
  local y2 = block(right, 0, L["Between fights"], nil, p.between, true)
  y2 = block(right, y2, L["When your mana is low"], nil, p.low, true)
  if p.big and #p.big.spells > 0 then
    local steps = {}
    for _, step in ipairs(p.big.spells) do
      local copy = {}
      for k, v in pairs(step) do
        copy[k] = v
      end
      copy.why = nil
      table.insert(steps, copy)
    end
    y2 = block(right, y2, L["Big cooldowns"], nil, steps, false, p.big.say)
  end
  if b.hardcore and snap.season == G.HARDCORE then
    y2 = P.label(right, y2, COL - 10, L["Hardcore"], T.gold, 14, K.TITLE_FONT) + 2
    screen.plan.hardcore = {}
    for _, key in ipairs(b.hardcore) do
      y2 = P.label(right, y2, COL - 10, ns.say(key), T.text, 11) + 4
      table.insert(screen.plan.hardcore, ns.say(key))
    end
  end
  return math.max(y1, y2)
end

-- ── the strip: the one thing that needs the player ───────────────────────────
local function setStrip(text, buttons)
  ns.screen.strip = text and { text = text, buttons = buttons or {} } or nil
  strip:SetShown(text ~= nil)
  if not text then return end
  strip.text:SetText(text)
  local n = buttons and #buttons or 0
  for i, b in ipairs(strip.buttons) do
    local a = buttons and buttons[i]
    if a then
      -- (the buttons sit at the right edge, the last one flush, whatever their number)
      b:ClearAllPoints()
      b:SetPoint("RIGHT", strip, "RIGHT", -((n - i) * 118) - 2, 0)
      K.setButton(b, a[1], 110)
      b.click = a[2]
      b:Show()
    else
      b:Hide()
    end
  end
  strip.text:SetWidth(W - 2 * EDGE - 40 - (buttons and #buttons or 0) * 118)
end

local function pickBuild(id, group)
  local choice = ns.choice(group)
  -- (a build is a role's: using it takes the role with it)
  choice.role = ns.data.builds[id].role
  choice.pickedBuild, choice.freestyle, choice.driftSeen = id, nil, nil
  view.changing = nil
  ns.refresh()
end

local function pickRole(class, role, group)
  local choice = ns.choice(group)
  choice.role, choice.pickedBuild, choice.freestyle, choice.driftSeen, choice.notYet =
    role, G.recommend(class, role), nil, nil, nil
  view.changing = nil
  ns.refresh()
end

local function treeName(snap, tree) return snap.talents.names[tree] or L["Tree %d"]:format(tree) end
local function roleLike(role)
  if role == "tank" then return L["a tank"] end
  if role == "heal" then return L["a healer"] end
  return L["a damage build"]
end

-- (the question is asked once in a session: "not yet" holds until the game is reloaded, and for the level)
local function asking(snap, choice, class) return not view.putOff and G.asking(snap, choice, class) end

-- What the strip says now: the first that applies.
local function stripFor(snap, class, r, choice, tab, stage)
  if view.changing and #G.roles(class) > 1 then
    local buttons = {}
    for _, role in ipairs(G.roles(class)) do
      if role ~= r.role then
        table.insert(buttons, { roleName(role), function() pickRole(class, role, snap.group) end })
      end
    end
    table.insert(buttons, {
      L["Cancel"],
      function()
        view.changing = nil
        ns.page()
      end,
    })
    local text = ns.forever and L["Pick the role you want to play."]
      or L["Pick the role you want to play. A respec costs gold."]
    return text, buttons
  end
  if r.phase == "spent" and r.mode == "open" and r.open and not r.roleChosen and not view.putOff then
    -- (the open builds span several roles and nothing says which: the role is asked, never guessed)
    local seen, buttons = {}, {}
    for _, id in ipairs(r.open) do
      local role = ns.data.builds[id].role
      if not seen[role] then
        seen[role] = true
        -- (the role's build the points leave open: the one we advise if it is, else the first)
        local open = G.recommend(class, role)
        local reach = {}
        for _, o in ipairs(r.open) do
          if ns.data.builds[o].role == role then
            reach[#reach + 1] = o
            if o == open then
              reach = { o }
              break
            end
          end
        end
        table.insert(buttons, { roleName(role), function() pickBuild(reach[1], snap.group) end })
      end
    end
    if #buttons > 1 then
      table.insert(buttons, {
        L["Not yet"],
        function()
          view.putOff = true
          ns.page()
        end,
      })
      return L["Your points leave more than one role open. What do you want to play?"], buttons
    end
  end
  if r.freestyle then
    return L["You are on your own way: no picks, no notes."],
      {
        {
          L["Use the guide's picks again"],
          function()
            choice.freestyle = nil
            ns.refresh()
          end,
        },
      }
  end
  if tab == TABS.plan and asking(snap, choice, class) then
    return ns.forever and L["You have a talent point to spend. What do you want to play?"]
      or L["You have a talent point to spend. What do you want to play? A respec costs gold, so pick what you will do most."],
      {
        {
          L["Not yet"],
          function()
            choice.notYet = snap.level
            view.putOff = true
            ns.page()
          end,
        },
      }
  end
  if r.phase == "spent" then
    local drift = r.drift
    if drift and not drift.seen then
      if drift.kind == "build" then
        local from, to = G.name(snap, ns.data.builds[drift.from]), G.name(snap, ns.data.builds[drift.to])
        return L["Your points can no longer reach the build you chose. These points follow %s more than the %s build you picked."]:format(
          to,
          from
        ),
          {
            {
              L["Keep %s"]:format(from),
              function()
                choice.driftSeen = drift.mark
                ns.page()
              end,
            },
            { L["Follow %s"]:format(to), function() pickBuild(drift.to, snap.group) end },
            {
              L["My own way"],
              function()
                choice.freestyle = true
                ns.refresh()
              end,
            },
          }
      end
      return (drift.unpicked and (L["None of your role's builds can be reached by your points."] .. " ") or "")
        .. L["These points look more like %s than %s. Switch your role to %s?"]:format(
          roleLike(drift.role),
          roleLike(r.role),
          roleName(drift.role)
        ),
        {
          {
            L["Switch"],
            function()
              choice.role, choice.pickedBuild, choice.driftSeen = drift.role, nil, nil
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
        }
    elseif r.unreachable then
      local near = G.name(snap, ns.data.builds[r.build])
      local top, second = G.split(snap)
      if r.followed == "picked" then
        return L["Your points fit none of the builds. This page stays on %s, the build you picked."]:format(near)
      elseif top and second then
        return L["Your points are split between %s and %s, so none of the builds fits them. This page shows the nearest, %s."]:format(
          treeName(snap, top),
          treeName(snap, second),
          near
        )
      end
      return L["Your points fit none of the builds. This page shows the nearest, %s."]:format(near)
    end
  end
  if tab == TABS.plan and view.stageNote and view.stageNote.group == snap.group then
    return L["The plan changed at level %d."]:format(view.stageNote.from),
      {
        {
          L["Got it"],
          function()
            view.stageNote = nil
            ns.page()
          end,
        },
      }
  end
  if tab == TABS.plan and stage and stage.about then return ns.say(stage.about) end
end

-- ── the header ───────────────────────────────────────────────────────────────
local function pointsOn(snap, build)
  if G.phase(snap) ~= "spent" then return nil end
  local n = G.earned(snap)
  return n - G.differ(snap, build, n), n
end

-- The sentence on how the page was chosen, one of a closed list.
local function sentenceFor(snap, r)
  local b = ns.data.builds[r.build]
  local on, of = pointsOn(snap, b)
  local text
  if r.mode == "own" then
    return L["Your own way. The plan stays, the picks and the notes do not."]
  elseif r.unreachable then
    text = L["Your points fit none of the builds. This is the nearest."]
  elseif r.drift and r.mode == "picked" and not r.drift.seen and r.drift.kind == "build" then
    text = L["These points follow %s more than the %s build you picked."]:format(
      G.name(snap, ns.data.builds[r.drift.to]),
      G.name(snap, b)
    )
  elseif r.recognised then
    text = L["Your points follow the other way to this build. It reaches the same place."]
  elseif r.hardcoreRoad then
    text = L["The safer road for a Hardcore realm."]
  elseif r.mode == "picked" then
    text = L["A build you picked."]
  elseif r.mode == "points" then
    text = L["Your points follow this build."]
  elseif r.mode == "open" then
    text = L["Your points leave several builds open. This is the one Primer advises."]
  else
    text = L["The road Primer advises for %s."]:format(roleName(r.role):lower())
  end
  if on and not r.unreachable then text = text .. " " .. L["%d of %d points are on it."]:format(on, of) end
  return text
end

local function drawHeader(snap, class, r)
  local b = ns.data.builds[r.build]
  local facts = { roleName(r.role), L["level %d"]:format(snap.level) }
  if snap.season == G.HARDCORE then table.insert(facts, L["Hardcore realm"]) end
  if snap.groups > 1 then table.insert(facts, L["talent group %d"]:format(snap.group)) end
  local screen = ns.screen
  -- (the page is a build's once the player has a role, a pick or points: before that it is the class's)
  local hasBuild = r.phase == "spent" or r.roleChosen or r.mode == "picked" or r.mode == "own" or #G.roles(class) == 1
  screen.header = {
    title = hasBuild and ("%s %s"):format(G.name(snap, b), snap.className) or snap.className,
    facts = capital(table.concat(facts, ", ")) .. ".",
    sentence = sentenceFor(snap, r),
    change = #G.roles(class) > 1 and r.phase ~= "untalented",
  }
  local pick = r.mode ~= "own" and G.nextPick(snap, b, r.road)
  if r.mode == "own" then
    screen.header.chip = { name = L["Your own way"], detail = "" }
  elseif snap.level < G.FIRST_POINT_LEVEL then
    screen.header.chip = { name = L["Talents start at level 10"], detail = "" }
  elseif pick then
    screen.header.chip = {
      name = pick.info and pick.info.name or spellName(pick.spell),
      detail = L["Level %d, %d of %d"]:format(pick.level, pick.number, pick.of),
    }
  else
    screen.header.chip = { name = L["Points all spent"], detail = "" }
  end
  head.title:SetText(screen.header.title)
  head.facts:SetText(screen.header.facts)
  head.sentence:SetText(screen.header.sentence)
  head.change:SetShown(screen.header.change)
  head.chipName:SetText(screen.header.chip.name)
  head.chipDetail:SetText(screen.header.chip.detail)
end

-- ── the pages ────────────────────────────────────────────────────────────────
local planPaint, overviewPaint
local function show(area)
  for _, a in ipairs({ plan, overview, talents }) do
    a:SetShown(a == area)
  end
end

local function empty(kind, snap)
  local title, text
  if kind == "season" then
    title = L["Season of Discovery"]
    text =
      L["Runes change how every class plays in Season of Discovery, so the guide stays quiet here rather than give you the wrong order."]
  elseif kind == "game" then
    title = L["No guide for %s yet"]:format(gameName())
    text = ns.forever
        and L["Forever has talents Classic Era does not, and has changed some it shares. Classic Era's advice would send you wrong, so none of it is shown here. The guide will be written from Forever's own talents and spells."]
      or L["Nothing is written for this game yet."]
  else
    title = L["No guide for %s yet"]:format(snap.className)
    text = L["No guide is written for %s on %s yet. The page stays empty rather than guess."]:format(
      snap.className,
      gameName()
    )
  end
  ns.screen.empty = { title = title, text = text }
  ns.screen.header = {
    title = snap.className,
    facts = gameName() .. ".",
    sentence = "",
    change = false,
    chip = { name = "", detail = "" },
  }
  head.title:SetText(snap.className)
  head.facts:SetText(gameName() .. ".")
  head.sentence:SetText("")
  head.change:Hide()
  head.chipName:SetText("")
  head.chipDetail:SetText("")
  setStrip(nil)
  show(plan)
  planPaint.begin()
  plan.toggle:Hide()
  local y = planPaint.label(0, 0, 700, title, T.gold, 16, K.TITLE_FONT) + 6
  y = planPaint.label(0, y, 700, text, T.text, 13)
  plan.child:SetHeight(y + 24)
  plan:ScrollTo(0)
end

-- The level-10 question: one card a role, the build we advise for it and the price, and Use this.
local function drawChoose(P, snap, class)
  ns.screen.choose = {}
  local y = P.label(0, 0, 700, L["What do you want to play?"], T.gold, 16, K.TITLE_FONT) + 8
  local x = 0
  for _, role in ipairs(G.roles(class)) do
    local id = G.recommend(class, role)
    local b = ns.data.builds[id]
    local cy = 0
    local cardY = y
    cy = P.label(x, cardY, 224, ("%s: %s"):format(roleName(role), G.name(snap, b)), T.gold, 14, K.TITLE_FONT) + 4
    cy = P.label(
      x,
      cy,
      224,
      ns.say(ns.data.classes[class].roles[role] and ns.data.classes[class].roles[role].why or b.line),
      T.text,
      12
    ) + 6
    local picks = {}
    for i = 1, math.min(3, #b.path) do
      local step = b.path[i]
      local spell = step.talent or step.any[1]
      local info = G.talent(snap, spell)
      table.insert(picks, info and info.name or spellName(spell))
    end
    cy = P.label(x, cy, 224, L["First picks: %s."]:format(table.concat(picks, ", ")), T.soft, 11) + 6
    local card = P.row()
    card:ClearAllPoints()
    card:SetPoint("TOPLEFT", P.area.child, "TOPLEFT", x, -cy)
    card:SetSize(224, 1)
    card.slot:Hide()
    card.num:SetText("")
    card.name:SetText("")
    card.when:SetText("")
    card.why:Hide()
    card.use = card.use or K.button(card, L["Use this"], 110)
    card.use:ClearAllPoints()
    card.use:SetPoint("TOPLEFT", 0, 0)
    card.use:SetScript("OnClick", function() pickRole(class, role, snap.group) end)
    card.use:Show()
    table.insert(ns.screen.choose, { role = role, build = id, use = function() pickRole(class, role, snap.group) end })
    x = x + 240
  end
  return y + 240
end

local function drawPlanTab(snap, class, r, choice)
  local screen = ns.screen
  show(plan)
  local P = planPaint
  P.begin()
  for _, row in ipairs(P.rows) do
    if row.slot then row.slot:Show() end
    if row.use then row.use:Hide() end
  end
  local b = ns.data.builds[r.build]
  local idx, starts = G.stage(b, snap.level, r.phase)
  local stage = idx and b.stages[idx]
  -- the stage changed under an open window: said once, in the strip
  view.stages = view.stages or {}
  local last = view.stages[snap.group]
  if stage and last and last.build == r.build and last.idx ~= idx then
    view.stageNote = { group = snap.group, from = stage.from }
  end
  view.stages[snap.group] = { build = r.build, idx = idx }
  setStrip(stripFor(snap, class, r, choice, TABS.plan, stage))
  local y
  if asking(snap, choice, class) and not r.freestyle then
    -- (the choose cards use the pool's rows for their buttons)
    y = drawChoose(P, snap, class)
    plan.toggle:Hide()
  elseif not stage then
    y = P.label(0, 0, 700, L["This build starts at level %d. Come back then."]:format(starts), T.text, 13)
  else
    screen.stage = { from = stage.from, to = stage.to }
    y = drawPlan(P, snap, b, stage)
    local recommended = G.recommend(class, b.role)
    y = P.label(
      0,
      y + 4,
      700,
      (
        r.build ~= recommended
          and (L["Primer has no press-order written for this build as the one it advises. It shows what it has."] .. " ")
        or ""
      )
        .. L["A sensible way to play, not the only one. Cooldowns and procs in a real fight will change the order."]
        .. " "
        .. L["Checked on %s %s, %s."]:format(gameName(), b.build, b.checked),
      T.soft,
      11
    )
    screen.footer = true
    plan.toggle:ClearAllPoints()
    plan.toggle:SetPoint("TOPLEFT", plan.child, "TOPLEFT", 0, -(y + 6))
    plan.toggle:Show()
    y = y + 34
  end
  if not stage then plan.toggle:Hide() end
  plan.child:SetHeight(y + 24)
end

local function drawOverviewTab(snap, class, r)
  show(overview)
  setStrip(stripFor(snap, class, r, ns.choice(snap.group), TABS.overview))
  local P = overviewPaint
  P.begin()
  local c = ns.data.classes[class]
  local ov = c.overview
  local screen = ns.screen
  screen.overview = { blocks = {}, card = {} }
  local y = 0
  local function block(heading, text)
    if heading then
      y = P.label(0, y, 430, heading, T.gold, 14, K.TITLE_FONT) + 2
      table.insert(screen.overview.blocks, heading)
    end
    y = P.label(0, y, 430, text, T.text, 13) + 10
    table.insert(screen.overview.blocks, text)
  end
  if ov and ov.who then
    block(nil, ns.say(ov.who))
  else
    block(nil, ns.say(c.text))
  end
  for _, part in ipairs({
    { L["Good at"], "good" },
    { L["Bad at"], "bad" },
    { L["Your resource"], "resource" },
    { L["Levelling"], "levelling" },
    { L["At level 10"], "ten" },
  }) do
    if ov and ov[part[2]] then block(part[1], ns.say(ov[part[2]])) end
  end
  -- the card: your road, the other roles, what also works
  local b = ns.data.builds[r.build]
  local cy = 0
  local x = 460
  local function card(heading, text)
    cy = P.label(x, cy, 260, heading, T.gold, 14, K.TITLE_FONT) + 2
    cy = P.label(x, cy, 260, text, T.text, 12) + 10
    table.insert(screen.overview.card, { heading = heading, text = text })
  end
  local role = c.roles and c.roles[b.role]
  local why = role and ns.say(role.why) or ns.say(b.line)
  if b.roadWhy then why = why .. " " .. ns.say(r.hardcoreRoad and b.hardcoreWhy or b.roadWhy) end
  card(L["Your road"], ("%s. %s"):format(G.name(snap, b), why))
  local others = {}
  for _, role2 in ipairs(G.roles(class)) do
    if role2 ~= b.role then
      local id = G.recommend(class, role2)
      table.insert(
        others,
        ("%s: %s. %s"):format(roleName(role2), G.name(snap, ns.data.builds[id]), ns.say(ns.data.builds[id].line))
      )
    end
  end
  if #others > 0 then card(L["The other roles"], table.concat(others, "\n")) end
  local also = {}
  for _, id in ipairs(G.builds(class, b.role)) do
    if id ~= G.recommend(class, b.role) then
      table.insert(also, ("%s. %s"):format(G.name(snap, ns.data.builds[id]), ns.say(ns.data.builds[id].line)))
    end
  end
  if #also > 0 then card(L["Also works"], table.concat(also, "\n")) end
  if b.hardcore and snap.season == G.HARDCORE then
    card(
      L["Hardcore"],
      table.concat(
        (function()
          local t = {}
          for _, key in ipairs(b.hardcore) do
            table.insert(t, ns.say(key))
          end
          return t
        end)(),
        "\n"
      )
    )
  end
  overview.child:SetHeight(math.max(y, cy) + 24)
end

local function drawTalentsTab(snap, class, r, choice)
  show(talents)
  setStrip(stripFor(snap, class, r, choice, TABS.talents))
  local b = ns.data.builds[r.build]
  local screen = ns.screen
  local level = view.slider
  if level and level == snap.level then level = nil end
  ns.tree.draw(talents.tree, snap, class, b, r.road, level)
  screen.tree = talents.tree.model
  screen.slider = level
  -- the order beside the trees: the road's runs, what is taken dimmed, "you are here" before the next
  local steps, nextStep = G.steps(b, snap, r.road)
  local list = {}
  local y = 0
  local P = talents.order
  P.begin()
  for i, s in ipairs(steps) do
    if i == nextStep and not level then
      y = P.label(0, y, 140, L["Level %d: you are here"]:format(snap.level), T.gold, 11) + 2
      table.insert(list, { here = true })
    end
    local o = s.options[1]
    local name, icon = o.info and o.info.name or spellName(o.spell), o.info and o.info.icon
    if #s.options > 1 then name = L["One of %d talents"]:format(#s.options) end
    local lv = s.step.level[1] == s.step.level[2] and tostring(s.step.level[1])
      or ("%d-%d"):format(s.step.level[1], s.step.level[2])
    local text = ("%s  %s  %d/%d"):format(
      lv,
      icon and ("|T%s:14:14:0:0|t %s"):format(icon, name) or name,
      s.rank,
      s.step.rank
    )
    local color = s.state == "done" and T.soft or i == nextStep and T.gold or T.text
    y = P.label(0, y, 140, text, color, 11) + 3
    table.insert(list, { text = text, state = s.state })
  end
  talents.order.area.child:SetHeight(y + 12)
  screen.order = list
  -- the slider: a view, never a state; the header does not change
  talents.slider.syncing = true
  talents.slider:SetValue(level or snap.level)
  talents.slider.syncing = false
  local shown = level or snap.level
  talents.sliderText:SetText(
    level
        and L["The road at level %d: %d points."]:format(
          level,
          math.max(0, math.min(level, G.MAX_LEVEL) - G.FIRST_POINT_LEVEL + 1)
        )
      or L["Level %d: the points you have."]:format(snap.level)
  )
  talents.now:SetShown(level ~= nil)
  local pick = G.nextPick(snap, b, r.road)
  local note = ns.say(b.note)
  if pick and not level then
    note =
      L["Next: %s. %s"]:format(pick.info and pick.info.name or spellName(pick.spell), ns.say(pick.step.step.why) .. ".")
  end
  talents.note:SetText(note)
  screen.note = note
  talents.groupButton:SetShown(snap.groups > 1)
  screen.level = shown
end

-- ── drawing ──────────────────────────────────────────────────────────────────
local waiting = false
local refresh

-- The guide could not draw this page: said plainly, no stack, kept for /primer debug.
local function broken(title, text)
  pcall(function()
    show(plan)
    planPaint.begin()
    local y = planPaint.label(0, 0, 700, title or L["Something went wrong"], T.gold, 16, K.TITLE_FONT) + 6
    plan.toggle:Hide()
    planPaint.label(
      0,
      y,
      700,
      text
        or L["This page would not draw. Close the window and open it again. If it keeps happening, /primer debug says what it was."],
      T.text,
      13
    )
    setStrip(nil)
    ns.screen.plan, ns.screen.tree, ns.screen.overview, ns.screen.choose = nil, nil, nil, nil
    ns.screen.broken = title or L["Something went wrong"]
    ns.screen.brokenText = text
      or L["This page would not draw. Close the window and open it again. If it keeps happening, /primer debug says what it was."]
  end)
end

-- What the page is for, fixed while the window is open: the role and build the
-- player picked or the points led to when it was opened (or when the player
-- last chose), never swapped by a point spent or a level gained.
local function model(snap, class, r)
  view.subjects = view.subjects or {}
  local sub = view.subjects[snap.group]
  -- (a new phase, a first point spent or level 10 reached, is worked out again: the question's default is not a pick)
  if not (sub and sub.phase == r.phase and ns.data.builds[sub.build] and ns.data.builds[sub.build].class == class) then
    sub = { role = r.role, build = r.build, mode = r.mode, phase = r.phase }
    sub.road, sub.recognised = G.pickRoad(snap, ns.data.builds[r.build])
    view.subjects[snap.group] = sub
  end
  r.role, r.build, r.mode = sub.role, sub.build, sub.mode
  r.road, r.recognised = sub.road, sub.recognised
  local shown = ns.data.builds[r.build]
  -- (said only where the Hardcore road is the advice: not in your own way, not before the first point, not out of reach)
  r.hardcoreRoad = snap.season == G.HARDCORE
    and shown.hardcoreRoad == r.road
    and not r.recognised
    and r.mode ~= "own"
    and r.phase ~= "untalented"
    and not r.unreachable
    and not (r.drift and not r.drift.seen)
  return r
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
  ns.screen = { tab = frame.selectedTab }
  local kind, class = G.page(snap)
  if kind ~= "guide" then return empty(kind, snap) end
  local choice = ns.choice(snap.group)
  local r = model(snap, class, G.resolve(snap, class, choice))
  ns.draws = (ns.draws or 0) + 1 -- (for the tests: one draw for a burst of events)
  drawHeader(snap, class, r)
  local n = frame.selectedTab
  if n == TABS.overview then
    drawOverviewTab(snap, class, r)
  elseif n == TABS.talents then
    drawTalentsTab(snap, class, r, choice)
  else
    drawPlanTab(snap, class, r, choice)
  end
  -- What a page cannot do without is what the game would not say (the talents
  -- taken, the spells in the book): no advice drawn from defaults.
  if ns.reader.blind() then
    broken(
      L["The guide cannot read your character"],
      L["This version of the game would not tell the guide your spells or talents, so it shows nothing rather than guess. /primer debug says which."]
    )
  end
end

-- mode: "event" (the game told something: facts update in place, the scroll
-- stays), "page" (the player went to another tab: the page from its top),
-- "choice" (the player chose: what the page is for is worked out again).
function refresh(mode)
  view.mode = mode
  if mode == "choice" then view.subjects = nil end
  local ok, err = pcall(draw)
  if not ok then
    ns.fault("window", err)
    broken()
  end
  if mode ~= "event" then
    for _, a in ipairs({ plan, overview }) do
      if a then a:ScrollTo(0) end
    end
  end
end
function ns.refresh() refresh("choice") end
function ns.page() refresh("page") end

-- The one line in chat at level 10, once per character: a point to spend. (No glow: a glow is decoration.)
local function welcome()
  local snap = ns.reader.snapshot()
  if not snap or snap.group ~= snap.active then return end
  local _, class = G.page(snap)
  if not class or PrimerChar.welcomed then return end
  if G.asking(snap, ns.choice(snap.group), class) then
    PrimerChar.welcomed = true
    print(ns.PREFIX .. L["You have a talent point to spend. /primer says what to pick."])
  end
end

-- What the game tells shows a moment later, a burst of events as one look.
local pending = false
function ns.changed()
  if pending then return end
  pending = true
  C_Timer.After(0.3, function()
    pending = false
    local ok, err = pcall(welcome)
    if not ok then ns.fault("welcome", err) end
    refresh("event")
  end)
end

local function selectTab(n)
  frame.selectedTab = n
  K.selectTab(frame, n)
  view.group = nil
  refresh("page")
end

-- The other talent group is the one in use now: look at that.
function ns.groupChanged()
  view.group = nil
  ns.changed()
end

local function build()
  local window = K.gameWindow("PrimerFrame", "Primer", ns.ICON)
  frame = window or K.dialog("PrimerFrame", "Primer")
  PrimerSettings = PrimerSettings or {}
  K.movable(frame, W, K.BOOK_H, K.place(PrimerSettings, "window"))
  frame.count = K.label(frame, K.BODY_FONT, 11, T.gold) -- (only to say it waits in a fight)
  frame.count:SetPoint("BOTTOMLEFT", 20, 14)
  -- the header: the build, what the page is for, the next pick
  head = CreateFrame("Frame", nil, frame)
  head:SetPoint("TOPLEFT", 66, -26)
  head:SetPoint("TOPRIGHT", -16, -26)
  head:SetHeight(HEAD_H)
  head.title = K.label(head, K.TITLE_FONT, 18, T.gold)
  head.title:SetPoint("TOPLEFT", 0, 0)
  head.facts = K.label(head, K.BODY_FONT, 12, T.text)
  head.facts:SetPoint("TOPLEFT", head.title, "BOTTOMLEFT", 0, -3)
  head.sentence = K.label(head, K.BODY_FONT, 11, T.soft)
  head.sentence:SetPoint("BOTTOMLEFT", 0, 0)
  head.sentence:SetWidth(W - 66 - 16 - 190)
  head.change = K.button(head, L["Change role"], 100)
  head.change:SetPoint("TOPRIGHT", -196, -2)
  head.change:SetScript("OnClick", function()
    view.changing = not view.changing or nil
    ns.page()
  end)
  head.chip = CreateFrame("Frame", nil, head)
  head.chip:SetSize(186, HEAD_H - 4)
  head.chip:SetPoint("TOPRIGHT", 0, 0)
  local back = head.chip:CreateTexture(nil, "BACKGROUND")
  back:SetAllPoints()
  back:SetColorTexture(0, 0, 0, 0.35)
  head.chipLabel = K.label(head.chip, K.BODY_FONT, 10, T.soft)
  head.chipLabel:SetPoint("TOPLEFT", 8, -5)
  head.chipLabel:SetText(L["Next pick"])
  head.chipName = K.label(head.chip, K.TITLE_FONT, 13, T.gold)
  head.chipName:SetPoint("TOPLEFT", 8, -19)
  head.chipName:SetWidth(172)
  head.chipName:SetWordWrap(false)
  head.chipDetail = K.label(head.chip, K.BODY_FONT, 11, T.text)
  head.chipDetail:SetPoint("TOPLEFT", 8, -37)
  -- the strip: the one thing that needs the player (fixed height, so nothing below it moves)
  strip = CreateFrame("Frame", nil, frame)
  strip:SetPoint("TOPLEFT", EDGE + 6, -(26 + HEAD_H + 6))
  strip:SetPoint("TOPRIGHT", -EDGE - 6, -(26 + HEAD_H + 6))
  strip:SetHeight(STRIP_H)
  strip.text = K.label(strip, K.BODY_FONT, 12, T.accent)
  strip.text:SetPoint("LEFT", 8, 0)
  strip.text:SetJustifyV("MIDDLE")
  strip.text:SetSpacing(2)
  strip.buttons = {}
  for i = 1, 3 do
    local b = K.button(strip, "", 110)
    b:SetScript("OnClick", function(self)
      if self.click then self.click() end
    end)
    strip.buttons[i] = b
  end
  -- the sheet under them
  sheet = K.panel(frame)
  sheet:SetPoint("TOPLEFT", EDGE, -(26 + HEAD_H + 6 + STRIP_H + 4))
  sheet:SetPoint("BOTTOMRIGHT", -EDGE, EDGE)
  local inner = W - 2 * EDGE - 40
  plan = K.scrollArea(sheet, inner, "PrimerPlan")
  plan:SetPoint("TOPLEFT", 14, -12)
  plan:SetPoint("BOTTOMRIGHT", -18, 10)
  overview = K.scrollArea(sheet, inner, "PrimerOverview")
  overview:SetPoint("TOPLEFT", 14, -12)
  overview:SetPoint("BOTTOMRIGHT", -18, 10)
  planPaint, overviewPaint = painter(plan), painter(overview)
  -- the Talents tab: the three trees, the order, the slider
  talents = CreateFrame("Frame", nil, sheet)
  talents:SetPoint("TOPLEFT", 14, -10)
  talents:SetPoint("BOTTOMRIGHT", -14, 8)
  talents.tree = ns.tree.new(talents)
  talents.tree.frame:SetPoint("TOPLEFT", 0, 0)
  local orderArea = K.scrollArea(talents, 146, "PrimerOrder")
  orderArea:SetPoint("TOPLEFT", talents.tree.frame, "TOPRIGHT", 14, -4)
  orderArea:SetPoint("BOTTOMRIGHT", talents, "BOTTOMRIGHT", -14, 44)
  talents.order = painter(orderArea)
  talents.slider = CreateFrame("Slider", nil, talents)
  talents.slider:SetOrientation("HORIZONTAL")
  talents.slider:SetSize(300, 16)
  talents.slider:SetPoint("TOPLEFT", talents.tree.frame, "BOTTOMLEFT", 20, -14)
  local track = talents.slider:CreateTexture(nil, "BACKGROUND")
  track:SetColorTexture(T.rule[1], T.rule[2], T.rule[3], 1)
  track:SetPoint("LEFT", 0, 0)
  track:SetPoint("RIGHT", 0, 0)
  track:SetHeight(3)
  talents.slider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
  talents.slider:SetMinMaxValues(G.FIRST_POINT_LEVEL, G.MAX_LEVEL)
  talents.slider:SetValueStep(1)
  talents.slider:SetObeyStepOnDrag(true)
  talents.slider:SetScript("OnValueChanged", function(self, value)
    if self.syncing then return end
    view.slider = math.floor(value + 0.5)
    ns.page()
  end)
  talents.sliderText = K.label(talents, K.BODY_FONT, 11, T.soft)
  talents.sliderText:SetPoint("LEFT", talents.slider, "RIGHT", 12, 0)
  talents.now = K.button(talents, L["Now"], 60)
  talents.now:SetPoint("LEFT", talents.sliderText, "RIGHT", 10, 0)
  talents.now:SetScript("OnClick", function()
    view.slider = nil
    ns.page()
  end)
  talents.groupButton = K.button(talents, L["Switch talent group"], 130)
  talents.groupButton:SetPoint("BOTTOMRIGHT", talents, "BOTTOMRIGHT", -2, 10)
  talents.groupButton:SetScript("OnClick", function()
    local snap = ns.reader.snapshot()
    if snap then view.group = (view.group or snap.active) == 1 and 2 or 1 end
    ns.page()
  end)
  talents.note = K.label(talents, K.BODY_FONT, 11, T.text)
  talents.note:SetPoint("TOPLEFT", talents.slider, "BOTTOMLEFT", -20, -12)
  talents.note:SetWidth(3 * ns.TREE_W)
  talents.note:SetSpacing(2)
  -- the reasons toggle, on the Plan (kept for the account)
  local toggle = K.button(plan.child, L["Show the reasons"], 140)
  toggle:SetPoint("TOPRIGHT", plan.child, "TOPRIGHT", -10, 0)
  toggle:SetScript("OnClick", function()
    PrimerSettings.showReasons = not reasons() or nil
    toggle:SetText(reasons() and L["Hide the reasons"] or L["Show the reasons"])
    ns.page()
  end)
  plan.toggle = toggle
  frame.selectedTab = TABS.plan
  frame:SetScript("OnShow", function()
    ns.reader.reset() -- (a call that failed is tried again when the window is opened again)
    view.subjects, view.changing, view.stages, view.stageNote = nil, nil, nil, nil -- (what the page is for is worked out again when it is opened)
    toggle:SetText(reasons() and L["Hide the reasons"] or L["Show the reasons"])
    selectTab(frame.selectedTab)
  end)
  K.tabs(frame, { L["Overview"], L["Plan"], L["Talents"] }, selectTab)
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
    selectTab(f.selectedTab)
  else
    f:Show() -- (its OnShow shows the tab)
  end
end
