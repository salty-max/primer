-- The guide's window, a book like the family's others (the kit's K.book: the
-- game's window, a list on the left, a page on the right, tabs along the
-- bottom). Level, Talents, Class. The Level tab is the spine: the left list is
-- the levels at which something arrives, from the character's level to 40, and
-- the page is the selected level's: the pick, the opening, the loop. Talents
-- and Class are not written yet. Opened by /primer, the minimap button and
-- Keyring's (ns.toggle, never a hook on a Blizzard frame).
--
-- It reads the game when it draws and never in combat (Reader.lua). What the
-- page is for (the role and the build) is frozen while the window is open:
-- a point spent, a level or a spell learned changes a colour and a word, and
-- swaps nothing. Looking at another level is looking: it changes the page's
-- level and nothing else, until the player says "back".
local _, ns = ...
local K, L = ns.kit, ns.kit.L
local T = K.T
local G = ns.rules

local TAB = { level = 1, talents = 2, class = 3 }
ns.TAB = TAB

-- One idea a screen, held in steps: a page has a pick, an opening of at most 5 steps and a loop of at most 6, each
-- with its reason printed under it (the check holds the content to it, the lowest-priority lines of a loop go to a
-- note, `rarely`). The page scrolls when they are longer than the window; nothing is cut.
ns.BUDGET = { opening = 5, loop = 6, spine = 40 }

local book, list, page, talents, roadList
local view = {} -- this session's: subjects (what each talent group's page is for), looking, putOff, changing, why
ns.view = view -- (for the tests)
ns.screen = {} -- what the last draw put on screen, as tables (for the tests)
local spine = {} -- the list's rows (a pool, made at the tab's load, for the tests)
ns.spineRows = spine
ns.roadRows = {} -- the Talents tab's list (a pool, for the tests)
ns.stepRows = {} -- the page's rows (a pool, for the tests)

-- ── words ────────────────────────────────────────────────────────────────────
local function roleName(role)
  if role == "tank" then return L["Tank"] end
  if role == "heal" then return L["Heal"] end
  return L["Damage"]
end
local function gameName() return ns.forever and L["Forever"] or L["Classic Era"] end
local function capital(s) return (s:gsub("^%l", string.upper)) end
local function spellName(id) return ns.reader.spell(id) or L["Unknown spell"] end
local function number(n) return type(n) == "number" and n or 0 end

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
  return L["Learn it at your trainer"]
end

-- A step's state at the level looked at: the character's own, as it stands; another level, by the spell's level alone.
local function stateAt(step, snap, level)
  if level == snap.level then return G.stepState(step, snap) end
  if step.spell and not step.common and level < step.level then return "level", step.level end
  return "ready"
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

-- ── the parts of the page ────────────────────────────────────────────────────
-- Rows of the page: a number, the spell's icon (its tooltip), the name and its clause on one line that wraps
-- rather than clips, and under it the reason, always printed. Made once, set in place on every look.
local rows = {}
-- (an icon's tooltip: the spell's)
local function slotTips(slot)
  slot:SetScript("OnEnter", function(self)
    if not GameTooltip then return end
    local ok, err = pcall(function()
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      if self.spell then GameTooltip:SetSpellByID(self.spell) end
      GameTooltip:Show()
    end)
    if not ok then ns.fault("tooltip", err) end
  end)
  slot:SetScript("OnLeave", function()
    if GameTooltip then GameTooltip:Hide() end
  end)
end
-- A row's text and, under it, its reason in the dimmer body text, both wrapped to the page; the row as tall as they
-- are, with room under it. Returns its height. (narrow: room kept at the right)
local ROW_PAD, ROW_GAP = 6, 12
local function fillRow(r, line, why)
  r.text:SetWidth(page.width - 56)
  r.text:SetText(line)
  local h = ROW_PAD + math.max(16, number(r.text:GetStringHeight()))
  r.reason:SetWidth(page.width - 56)
  r.reason:ClearAllPoints()
  r.reason:SetPoint("TOPLEFT", r, "TOPLEFT", 52, -h)
  r.reason:SetShown(why ~= nil)
  r.reason:SetText(why or "")
  if why then h = h + 2 + number(r.reason:GetStringHeight()) end
  h = math.max(28, h) + ROW_GAP
  r:SetHeight(h)
  return h
end
local function row(i)
  local r = rows[i]
  if r then return r end
  r = CreateFrame("Frame", nil, page.child)
  r:SetWidth(page.width)
  r.slot = K.slot(r, 22)
  r.slot:SetPoint("TOPLEFT", 22, -2)
  r.num = K.label(r, K.BODY_FONT, 11, T.soft)
  r.num:SetPoint("TOPLEFT", 4, -7)
  r.text = K.label(r, K.BODY_FONT, 12, T.text)
  r.text:SetPoint("TOPLEFT", 52, -6)
  r.text:SetWidth(page.width - 56)
  r.text:SetWordWrap(true)
  r.text:SetSpacing(2)
  r.reason = K.label(r, K.BODY_FONT, 12, T.soft)
  r.reason:SetWidth(page.width - 56)
  r.reason:SetWordWrap(true)
  r.reason:SetSpacing(2)
  slotTips(r.slot)
  rows[i] = r
  ns.stepRows[i] = r
  return r
end

-- A row set for a step: [n] [icon] Name  clause, grey in its place with what it needs when it cannot be pressed.
-- Returns the model the tests read.
local STEP_ICON = "Interface\\Icons\\INV_Misc_Note_01"
local function setStep(r, snap, step, n, level, last)
  local name, icon
  if step.spell then
    name, icon = ns.reader.spell(step.spell)
    name = name or L["Unknown spell"]
    icon = step.icon or icon
  else
    name, icon = ns.say(step.text), STEP_ICON
  end
  local state, extra = stateAt(step, snap, level)
  local ready = state == "ready"
  local clause = ready and whenOf(step) or needs(snap, state, extra)
  if ready and clause == "" and last then clause = L["If nothing above applies"] end
  local stance = ready and stanceOf(step)
  if stance then clause = clause ~= "" and (clause .. ", " .. stance:lower()) or stance end
  local why = step.why and ns.stop(capital(ns.say(step.why))) or nil
  r.slot.spell = step.spell
  K.setSlot(r.slot, icon or K.QUESTION, nil, nil, not ready)
  r.num:SetText(n and tostring(n) or "")
  local line = K.hex(ready and T.text or T.soft) .. name .. "|r"
  if clause ~= "" then line = line .. "  " .. K.hex(ready and T.soft or T.gold) .. clause .. "|r" end
  local h = fillRow(r, line, why)
  return {
    h = h,
    n = n,
    spell = step.spell,
    name = name,
    clause = clause,
    state = state,
    why = why,
    line = name .. (clause ~= "" and ("  " .. clause) or ""),
  }
end

local function hideRows()
  for _, r in ipairs(rows) do
    r:Hide()
  end
end

-- ── the questions ────────────────────────────────────────────────────────────
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

-- What needs the player now, the first that applies: { text, buttons, replaces } (replaces: it is the page,
-- one idea; else a note above the plan), or nil. Roles, if the question is which one.
local function questionFor(snap, class, r, choice)
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
    return {
      text = ns.forever and L["Pick the role you want to play."]
        or L["Pick the role you want to play. A respec costs gold."],
      buttons = buttons,
      replaces = true,
    }
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
      return {
        text = L["Your points leave more than one role open. What do you want to play?"],
        buttons = buttons,
        replaces = true,
      }
    end
  end
  if r.freestyle then
    return {
      text = L["You are on your own way: no picks, no notes."],
      buttons = {
        {
          L["Use the guide's picks again"],
          function()
            choice.freestyle = nil
            ns.refresh()
          end,
        },
      },
    }
  end
  if asking(snap, choice, class) then
    local buttons = {}
    for _, role in ipairs(G.roles(class)) do
      table.insert(buttons, { roleName(role), function() pickRole(class, role, snap.group) end })
    end
    table.insert(buttons, {
      L["Not yet"],
      function()
        choice.notYet = snap.level
        view.putOff = true
        ns.page()
      end,
    })
    return {
      text = ns.forever and L["You have a talent point to spend. What do you want to play?"]
        or L["You have a talent point to spend. What do you want to play? A respec costs gold, so pick what you will do most."],
      buttons = buttons,
      replaces = true,
      roles = true,
    }
  end
  if r.phase == "spent" then
    local drift = r.drift
    if drift and not drift.seen then
      if drift.kind == "build" then
        local from, to = G.name(snap, ns.data.builds[drift.from]), G.name(snap, ns.data.builds[drift.to])
        return {
          text = L["Your points can no longer reach the build you chose. These points follow %s more than the %s build you picked."]:format(
            to,
            from
          ),
          buttons = {
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
          },
          replaces = true,
        }
      end
      return {
        text = (drift.unpicked and (L["None of your role's builds can be reached by your points."] .. " ") or "")
          .. L["These points look more like %s than %s. Switch your role to %s?"]:format(
            roleLike(drift.role),
            roleLike(r.role),
            roleName(drift.role)
          ),
        buttons = {
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
        },
        replaces = true,
      }
    elseif r.unreachable then
      local near = G.name(snap, ns.data.builds[r.build])
      local top, second = G.split(snap)
      if r.followed == "picked" then
        return {
          text = L["Your points fit none of the builds. This page stays on %s, the build you picked."]:format(near),
        }
      elseif top and second then
        return {
          text = L["Your points are split between %s and %s, so none of the builds fits them. This page shows the nearest, %s."]:format(
            treeName(snap, top),
            treeName(snap, second),
            near
          ),
        }
      end
      return { text = L["Your points fit none of the builds. This page shows the nearest, %s."]:format(near) }
    end
  end
end

-- ── the header, folded into the book's title area ────────────────────────────
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

-- The count beside the portrait: at most three facts (the build, the level, and the realm or the group when it matters).
local function setFacts(snap, class, r)
  local b = ns.data.builds[r.build]
  local hasBuild = r.phase == "spent" or r.roleChosen or r.mode == "picked" or r.mode == "own" or #G.roles(class) == 1
  local facts = { hasBuild and G.name(snap, b) or snap.className, L["level %d"]:format(snap.level) }
  if snap.season == G.HARDCORE then
    table.insert(facts, L["Hardcore"])
  elseif snap.groups > 1 then
    table.insert(facts, L["talent group %d"]:format(snap.group))
  end
  local text = capital(table.concat(facts, ", "))
  book.frame.count:SetText(text)
  ns.screen.facts = facts
  return hasBuild
end

-- ── the spine: the levels at which something arrives ────────────────────────
-- Every level from the character's to 40 that brings a pick or a spell, the character's own always: { level, pick, spells }.
local function arrivals(snap, b, road)
  local top = math.max(ns.BUDGET.spine, snap.level)
  local spells = {} -- level -> names
  local seen = {}
  for _, stage in ipairs(b.stages) do
    local p = planOf(stage)
    for _, part in ipairs({ p.opening, p.loop, p.rarely, p.between, p.low }) do
      for _, step in ipairs(part or {}) do
        if
          step.spell
          and not step.common
          and not step.talent
          and not seen[step.spell]
          and step.level
          and step.level > 1
        then
          seen[step.spell] = true
          spells[step.level] = spells[step.level] or {}
          table.insert(spells[step.level], ns.reader.spell(step.spell) or L["Unknown spell"])
        end
      end
    end
  end
  local out = {}
  for level = snap.level, top do
    local pick = G.pickAt(snap, b, road, level)
    if pick or spells[level] or level == snap.level then
      table.insert(out, { level = level, pick = pick, spells = spells[level] or {} })
    end
  end
  return out
end

local function spineStyle(r, kind)
  if kind ~= "level" then return K.listStyle(r, kind) end
  -- (each line's edges at its own top, as the kit's entry: a RIGHT anchor would hold its middle at the row's)
  r.count:SetPoint("TOPRIGHT", -4, -6)
  r.count:SetTextColor(unpack(T.gold))
  r.text:SetPoint("TOPLEFT", 4, -4)
  r.text:SetPoint("TOPRIGHT", r.count, "TOPLEFT", -4, 2)
  r.text:SetFont(K.BODY_FONT, 13, "")
  r.text:SetTextColor(unpack(T.text))
  r.under:SetPoint("TOPLEFT", 4, -22)
  r.under:SetWidth(K.ROW_WIDTH - 8)
  r.under:SetWordWrap(true)
  r.under:SetSpacing(2)
  local h = r.under:GetStringHeight()
  return 28 + number(h)
end

local function pickName(pick) return pick.info and pick.info.name or spellName(pick.spell) end

local function drawSpine(snap, b, r, shown)
  list:begin()
  local model = {}
  for _, a in ipairs(arrivals(snap, b, r.road)) do
    -- (one form: the pick first, then "New:" and the spells on a line of their own)
    local parts = {}
    if snap.level < G.FIRST_POINT_LEVEL and a.level == snap.level then parts[1] = L["Talents start at level 10"] end
    if a.pick then parts[#parts + 1] = ("%s %d/%d"):format(pickName(a.pick), a.pick.number, a.pick.of) end
    if #a.spells > 0 then parts[#parts + 1] = L["New: %s"]:format(table.concat(a.spells, ", ")) end
    local under = #parts > 0 and table.concat(parts, "\n") or L["Nothing new"]
    local here = a.level == snap.level
    local entry = list:add("level", L["Level %d"]:format(a.level), here and L["You are here"] or nil, under)
    entry.level = a.level
    entry:SetScript("OnClick", function()
      view.looking = (a.level ~= snap.level) and a.level or nil
      ns.page()
    end)
    if a.level == shown then list:pick(entry) end
    table.insert(model, { level = a.level, here = here, selected = a.level == shown, under = under })
  end
  list:finish()
  ns.screen.spine = model
end

-- ── the level page ───────────────────────────────────────────────────────────
local function drawLevel(snap, class, r, choice)
  local screen = ns.screen
  local b = ns.data.builds[r.build]
  local own = snap.level
  local shown = view.looking or own
  if shown == own then view.looking = nil end
  screen.level, screen.text = shown, {}
  local sentence = sentenceFor(snap, r)
  local pick = r.mode ~= "own" and (shown == own and G.nextPick(snap, b, r.road) or G.pickAt(snap, b, r.road, shown))
    or nil
  if shown < G.FIRST_POINT_LEVEL then pick = nil end
  page:start(
    L["Level %d"]:format(shown),
    sentence,
    function(p) p.tex:SetTexture((pick and pick.info and pick.info.icon) or ns.ICON) end
  )
  screen.title, screen.sub = L["Level %d"]:format(shown), sentence
  hideRows()
  drawSpine(snap, b, r, shown)
  local q = questionFor(snap, class, r, choice)
  screen.question = q and { text = q.text, buttons = q.buttons, replaces = q.replaces } or nil
  local function paragraph(text, color)
    page:paragraph(text, color)
    table.insert(screen.text, text)
  end
  if shown ~= own then
    paragraph(L["Looking at level %d."]:format(shown), T.gold)
    screen.back = function()
      view.looking = nil
      ns.page()
    end
    page:buttons({ { L["Back to my level"], screen.back } })
  end
  if q then
    paragraph(q.text, T.accent)
    if q.roles then
      screen.roles = {}
      for _, role in ipairs(G.roles(class)) do
        local id = G.recommend(class, role)
        local rb = ns.data.builds[id]
        local cr = ns.data.classes[class].roles[role]
        local line = ("%s: %s."):format(roleName(role), G.name(snap, rb))
          .. (cr and (" " .. ns.stop(ns.say(cr.why))) or "")
        table.insert(screen.roles, { role = role, build = id, line = line })
        paragraph(line, T.text)
      end
    end
    page:buttons(q.buttons)
    if q.replaces then return end
  end
  -- the plan of the stage the level is in
  local idx, starts = G.stage(b, shown, r.phase)
  local stage = idx and b.stages[idx]
  if not stage then
    paragraph(L["This build starts at level %d. Come back then."]:format(starts), T.text)
    return
  end
  screen.stage = { from = stage.from, to = stage.to }
  screen.legacy = stage.plan == nil -- (a stage written as rows, the older form: no step budget yet)
  local plan = planOf(stage)
  local n = 0
  local function nextRow()
    n = n + 1
    local x = row(n)
    page:place(x, 0)
    x:Show()
    x.slot:Show()
    return x
  end
  local function section(title)
    page.y = page.y + 8
    page:section(title)
  end
  -- the pick, its reason under it
  screen.pick = nil
  if r.mode ~= "own" and (pick or shown < G.FIRST_POINT_LEVEL or (shown == own and not pick)) then
    local x = nextRow()
    local text, why
    if pick then
      text = (shown == own and L["Next pick: %s, %d of %d"] or L["Pick: %s, %d of %d"]):format(
        pickName(pick),
        pick.number,
        pick.of
      )
      why = pick.step.step and pick.step.step.why or pick.step.why
      why = why and ns.stop(capital(ns.say(why))) or nil
    elseif shown < G.FIRST_POINT_LEVEL then
      text = L["Talents start at level 10"]
    else
      text = L["Every point of this road is spent"]
    end
    x.slot.spell = pick and pick.spell
    K.setSlot(x.slot, pick and pick.info and pick.info.icon or ns.ICON)
    x.num:SetText("")
    page.y = page.y + fillRow(x, K.hex(T.gold) .. text .. "|r", why)
    screen.pick = { text = text, why = why }
    table.insert(screen.text, text)
    if why then table.insert(screen.text, why) end
  end
  screen.rows = {}
  local function steps(title, group, key, closing)
    if not (group and #group > 0) then return end
    section(title)
    screen[key] = {}
    for i, step in ipairs(group) do
      local x = nextRow()
      local out = setStep(x, snap, step, i, shown, closing and i == #group)
      page.y = page.y + out.h
      table.insert(screen[key], out)
      table.insert(screen.text, out.line)
      if out.why then table.insert(screen.text, out.why) end
    end
  end
  steps(L["Opening"], plan.opening, "opening")
  steps(L["Then repeat, top to bottom"], plan.loop, "loop", true)
  if plan.rarely and #plan.rarely > 0 then
    local parts = {}
    for _, step in ipairs(plan.rarely) do
      local name = step.spell and (ns.reader.spell(step.spell) or L["Unknown spell"]) or ns.say(step.text)
      local state, extra = stateAt(step, snap, shown)
      local clause = state == "ready" and whenOf(step) or needs(snap, state, extra)
      local why = step.why and ns.say(step.why)
      table.insert(
        parts,
        ns.stop(("%s, %s%s"):format(name, (clause:gsub("^%u", string.lower)), why and (": " .. why) or ""))
      )
    end
    local text = L["Rarely: %s"]:format(table.concat(parts, " "))
    page.y = page.y + 4
    page:paragraph(text, T.soft)
    screen.rarely = text
    table.insert(screen.text, text)
  end
  if #G.roles(class) > 1 and r.phase ~= "untalented" and not q then
    screen.change = function()
      view.changing = true
      ns.page()
    end
    page:buttons({ { L["Change role"], screen.change } })
  end
end

-- ── the other tab: not written yet, it says its name ─────────────────────
local function placeholder(n, name)
  local label
  return {
    whole = true,
    build = function(f)
      label = K.label(f, K.TITLE_FONT, 24, T.gold)
      label:SetPoint("CENTER", f, "CENTER", 0, 0)
      label:SetText(name)
    end,
    show = function(shown) label:SetShown(shown == n) end,
    refresh = function() ns.screen = { tab = n, placeholder = name } end,
  }
end

-- ── drawing ──────────────────────────────────────────────────────────────────
local waiting = false

local function emptyWords(kind, snap)
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
  return title, text
end

local function empty(kind, snap)
  local title, text = emptyWords(kind, snap)
  ns.screen.empty = { title = title, text = text }
  book.frame.count:SetText(gameName())
  list:begin()
  list:finish()
  page:start(title, "")
  hideRows()
  page:paragraph(text)
  page:finish()
end

-- ── the Talents tab: the three trees with the road drawn on them ─────────────
-- The road's order on the left (a click looks at that level), the trees on the right, a slider under them to look
-- at the road at another level: looking, as on the Level tab, and nothing the page is for changes.
local function emptyTalents(kind, snap)
  local title, text = emptyWords(kind, snap)
  ns.screen.empty = { title = title, text = text }
  book.frame.count:SetText(gameName())
  roadList:begin()
  roadList:finish()
  talents.tree.frame:Hide()
  talents.slider:Hide()
  talents.sliderText:SetText("")
  talents.looking:Hide()
  talents.back:Hide()
  talents.road:SetText("")
  talents.ask:SetText(title .. "\n\n" .. text)
  talents.ask:Show()
end

local function drawTalents(snap, class, r, choice)
  local screen = ns.screen
  local b = ns.data.builds[r.build]
  local own = snap.level
  local shown = view.looking or own
  if shown == own then view.looking = nil end
  local looking = shown ~= own
  screen.level = shown
  local q = questionFor(snap, class, r, choice)
  screen.question = q and { text = q.text, buttons = q.buttons, replaces = q.replaces } or nil
  roadList:begin()
  if q and q.replaces then
    -- (a question comes first, and is answered on the Level tab, one place)
    talents.tree.frame:Hide()
    talents.slider:Hide()
    talents.looking:Hide()
    talents.back:Hide()
    talents.road:SetText("")
    talents.sliderText:SetText("")
    talents.ask:SetText(L["Answer the question on the Level tab first."])
    talents.ask:Show()
    screen.asked = true
    roadList:finish()
    return
  end
  talents.ask:Hide()
  talents.tree.frame:Show()
  talents.slider:Show()
  ns.tree.draw(talents.tree, snap, class, b, r.road, looking and shown or nil, r.mode == "own")
  screen.tree = talents.tree.model
  -- the road's order on the left
  local steps, nextStep = G.steps(b, snap, r.road)
  screen.road = {}
  for i, st in ipairs(steps) do
    local o = st.options[1]
    local name = o.info and o.info.name or spellName(o.spell)
    if #st.options > 1 then name = L["One of %d talents"]:format(#st.options) end
    local from, to = st.step.level[1], st.step.level[2]
    local when = from == to and tostring(from) or ("%d-%d"):format(from, to)
    local under = ("%s %d/%d"):format(name, st.rank, st.step.rank)
    local here = i == nextStep and not looking and r.mode ~= "own"
    local entry = roadList:add("level", L["Level %s"]:format(when), here and L["Next pick"] or nil, under)
    entry:SetScript("OnClick", function()
      view.looking = from ~= own and from or nil
      ns.page()
    end)
    if st.state == "done" then entry.text:SetTextColor(unpack(T.soft)) end
    if shown >= from and shown <= to then roadList:pick(entry) end
    table.insert(
      screen.road,
      { from = from, to = to, under = under, state = st.state, here = here, selected = shown >= from and shown <= to }
    )
  end
  roadList:finish()
  -- the slider is a view, never a state
  talents.slider.syncing = true
  talents.slider:SetMinMaxValues(G.FIRST_POINT_LEVEL, math.max(G.MAX_LEVEL, own))
  talents.slider:SetValue(math.max(shown, G.FIRST_POINT_LEVEL))
  talents.slider.syncing = false
  local points = math.max(0, math.min(shown, G.MAX_LEVEL) - G.FIRST_POINT_LEVEL + 1)
  talents.sliderText:SetText(
    looking and L["The road at level %d: %d points."]:format(shown, points)
      or L["Level %d: the points you have."]:format(own)
  )
  talents.looking:SetShown(looking)
  talents.back:SetShown(looking)
  if looking then talents.looking:SetText(L["Looking at level %d."]:format(shown)) end
  screen.back = looking and function()
    view.looking = nil
    ns.page()
  end or nil
  talents.back.click = screen.back
  local sentence = sentenceFor(snap, r)
  talents.road:SetText(sentence)
  screen.road_sentence, screen.looking, screen.slider = sentence, looking, shown
end

-- The guide could not draw this page: said plainly, no stack, kept for /primer debug.
local function broken(title, text)
  pcall(function()
    local say = text
      or L["This page would not draw. Close the window and open it again. If it keeps happening, /primer debug says what it was."]
    if book.frame.selectedTab == TAB.talents and talents then
      -- (the Talents tab says it in its own words, with nothing of the trees left on screen)
      talents.tree.frame:Hide()
      talents.slider:Hide()
      talents.looking:Hide()
      talents.back:Hide()
      talents.sliderText:SetText("")
      talents.road:SetText("")
      talents.ask:SetText((title or L["Something went wrong"]) .. "\n\n" .. say)
      talents.ask:Show()
    elseif page then
      page:start(title or L["Something went wrong"], "")
      hideRows()
      page:paragraph(say)
      page:finish()
    end
    ns.screen =
      { tab = book.frame.selectedTab, broken = title or L["Something went wrong"], brokenText = say, text = {} }
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
  local f = book.frame
  if not (f and f:IsShown() and (f.selectedTab == TAB.level or f.selectedTab == TAB.talents)) then return end
  local snap = ns.reader.snapshot()
  if not snap then
    -- (a fight: nothing is read, the window looks again in a moment)
    f.count:SetText(L["In combat. The guide waits."])
    if not waiting then
      waiting = true
      C_Timer.After(2, function()
        waiting = false
        book:refresh()
      end)
    end
    return
  end
  snap.className = snap.className or L["Unknown class"]
  local tab = f.selectedTab
  ns.screen = { tab = tab, text = {} }
  local kind, class = G.page(snap)
  if kind ~= "guide" then return (tab == TAB.talents and emptyTalents or empty)(kind, snap) end
  local choice = ns.choice(snap.group)
  local r = model(snap, class, G.resolve(snap, class, choice))
  ns.draws = (ns.draws or 0) + 1 -- (for the tests: one draw for a burst of events)
  setFacts(snap, class, r)
  if tab == TAB.talents then
    drawTalents(snap, class, r, choice)
  else
    drawLevel(snap, class, r, choice)
    page:finish(view.keep)
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
-- stays), "page" (the player went to another level: the page from its top),
-- "choice" (the player chose: what the page is for is worked out again).
local function refresh(mode)
  view.mode = mode
  if mode == "choice" then view.subjects = nil end
  view.keep = mode == "event"
  local ok, err = pcall(draw)
  if not ok then
    ns.fault("window", err)
    broken()
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

-- The other talent group is the one in use now: the window follows it.
function ns.groupChanged() ns.changed() end

-- ── the book ─────────────────────────────────────────────────────────────────
book = K.book({
  name = "PrimerFrame",
  title = "Primer",
  place = function()
    PrimerSettings = PrimerSettings or {}
    return K.place(PrimerSettings, "window")
  end,
  art = ns.ICON,
  titles = { L["Level"], L["Talents"], L["Class"] },
  first = TAB.level,
  search = "PrimerSearch",
  settle = 0.3,
})

book:add(TAB.level, {
  build = function(f)
    list = K.list(f.left, spineStyle, spine, false, "PrimerSpine")
    page = K.page(f.sheet, "PrimerLevelPage", { pairs = {} })
  end,
  show = function(n)
    local here = n == TAB.level
    list:SetShown(here)
    page:SetShown(here)
    -- (the family's search box finds nothing in a spine of levels)
    if here then book.frame.search:Hide() end
  end,
  refresh = function() refresh("page") end,
})
book:add(TAB.talents, {
  build = function(f)
    roadList = K.list(f.left, spineStyle, ns.roadRows, false, "PrimerRoad")
    local t = CreateFrame("Frame", nil, f.sheet)
    t:SetPoint("TOPLEFT", f.sheet, "TOPLEFT", 16, -16)
    t:SetPoint("BOTTOMRIGHT", f.sheet, "BOTTOMRIGHT", -16, 12)
    talents = t
    ns.talentsTab = t -- (for the tests)
    t.tree = ns.tree.new(t)
    t.tree.frame:SetPoint("TOPLEFT", 0, 0)
    local below = ns.TREE_H + 20
    t.slider = CreateFrame("Slider", nil, t)
    t.slider:SetOrientation("HORIZONTAL")
    t.slider:EnableMouse(true) -- (a bare slider takes no mouse: the game's template turns it on)
    t.slider:SetHitRectInsets(0, 0, -10, -10)
    t.slider:SetSize(260, 16)
    t.slider:SetPoint("TOPLEFT", t, "TOPLEFT", 10, -below)
    local track = t.slider:CreateTexture(nil, "BACKGROUND")
    track:SetColorTexture(T.rule[1], T.rule[2], T.rule[3], 1)
    track:SetPoint("LEFT", 0, 0)
    track:SetPoint("RIGHT", 0, 0)
    track:SetHeight(3)
    t.slider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
    t.slider:SetMinMaxValues(G.FIRST_POINT_LEVEL, G.MAX_LEVEL)
    t.slider:SetValueStep(1)
    t.slider:SetObeyStepOnDrag(true)
    local thumb = t.slider:GetThumbTexture()
    if thumb then thumb:SetSize(32, 32) end
    t.slider:SetScript("OnValueChanged", function(self, value)
      if self.syncing then return end
      local level = math.floor(value + 0.5)
      local snap = ns.reader.snapshot()
      view.looking = (snap and level == snap.level) and nil or level
      ns.page()
    end)
    t.sliderText = K.label(t, K.BODY_FONT, 12, T.soft)
    t.sliderText:SetPoint("LEFT", t.slider, "RIGHT", 14, 0)
    t.sliderText:SetWidth(ns.TREES_W - 284)
    t.looking = K.label(t, K.BODY_FONT, 13, T.gold)
    t.looking:SetPoint("TOPLEFT", t, "TOPLEFT", 0, -(below + 34))
    t.back = K.button(t, L["Back to my level"], 130)
    t.back:SetPoint("TOPRIGHT", t, "TOPLEFT", ns.TREES_W, -(below + 28))
    t.back:SetScript("OnClick", function(self)
      if self.click then self.click() end
    end)
    t.road = K.label(t, K.BODY_FONT, 12, T.soft)
    t.road:SetPoint("TOPLEFT", t, "TOPLEFT", 0, -(below + 66))
    t.road:SetWidth(ns.TREES_W)
    t.road:SetSpacing(2)
    t.ask = K.label(t, K.BODY_FONT, 13, T.text)
    t.ask:SetPoint("TOPLEFT", t, "TOPLEFT", 0, 0)
    t.ask:SetWidth(ns.TREES_W)
    t.ask:SetSpacing(3)
    t.ask:Hide()
  end,
  show = function(n)
    local here = n == TAB.talents
    roadList:SetShown(here)
    talents:SetShown(here)
    if here then book.frame.search:Hide() end
  end,
  refresh = function() refresh("page") end,
})
book:add(TAB.class, placeholder(TAB.class, L["Class"]))

function ns.window()
  local f = book:window()
  if not f.primerHooked then
    f.primerHooked = true
    -- (what the page was for is worked out again when the window is opened again, and a call that failed is tried again)
    f:HookScript("OnHide", function()
      ns.reader.reset()
      view.subjects, view.changing, view.looking = nil, nil, nil
    end)
  end
  return f
end
function ns.toggle()
  ns.window()
  book:toggle()
end
function ns.open(tab)
  ns.window()
  book:open(tab or TAB.level)
end

-- ── /primer fit: every text of the open window that the client cut ───────────
-- Walks the open window's texts and lists any whose text does not fit (IsTruncated, the client's own word for an
-- ellipsis). Nothing may be cut: a line that does not fit is shortened in the content.
function ns.fit()
  local out = {}
  local f = book.frame
  if not (f and f:IsShown()) then return out, false end
  local function walk(frame)
    if not frame:IsShown() then return end
    for _, region in ipairs({ frame:GetRegions() }) do
      if
        region.GetObjectType
        and region:GetObjectType() == "FontString"
        and region:IsVisible()
        and region.IsTruncated
      then
        local ok, cut = pcall(region.IsTruncated, region)
        if ok and cut then table.insert(out, region:GetText() or "") end
      end
    end
    for _, child in ipairs({ frame:GetChildren() }) do
      walk(child)
    end
  end
  walk(f)
  return out, true
end
