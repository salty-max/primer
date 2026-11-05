-- The talent trees as the game draws them, with the road drawn on them: the
-- class's three trees (the data's `cells`: tree, row, column, ranks, the
-- points a row asks, prerequisites) as the kit's slots, each talent the road
-- takes numbered in the order it first takes it, what is taken lit, the next
-- pick ringed, the row gates at the left, a straight line for a prerequisite.
-- The numbers belong to the road and never move: a point spent changes a ring
-- and a count. The tooltip is the game's own for the talent (SetTalent) and
-- one line of ours (Era's SetTalent takes the talent's id: its own window calls it so. Forever's takes other arguments, see ns.talentTip). Drawn once, set in place on every look.
local _, ns = ...
local K, L = ns.kit, ns.kit.L
local T = K.T
local G = ns.rules

local CELL, GAP, COLS, ROWS = 38, 12, 4, 7 -- (the whole width of the book: 38 pixels a cell, the game's own are 37)
local VGAP = 8
local HP, VP = CELL + GAP, CELL + VGAP
local MARGIN = 28 -- (each tree's own gutter for the gates' numbers, two digits wide with room to spare)
local BETWEEN = 30 -- (between two trees)
local TREE_W = MARGIN + COLS * CELL + (COLS - 1) * GAP
local HEAD = 20 -- (the tree's name)
ns.TREE_W, ns.TREE_H = TREE_W, HEAD + ROWS * VP - VGAP
ns.TREE_GUTTER = MARGIN
ns.TREES_W = 3 * TREE_W + 2 * BETWEEN

local GOLD = { 1, 0.82, 0.2 }
local BLUE = { 0.45, 0.7, 0.95 }
local EDGE = "Interface\\Buttons\\UI-ActionButton-Border"

local Tree = {}
ns.tree = Tree

-- the cells of a class, by the game's talent id, and its trees' ids in the order the window lists them
local function cellsOf(class)
  local out, byId, tabs = {}, {}, {}
  local seen = {}
  for _, c in ipairs(ns.data.cells or {}) do
    if c.class == class then
      table.insert(out, c)
      byId[c.id] = c
      if not seen[c.tab] then
        seen[c.tab] = true
        table.insert(tabs, c.tab)
      end
    end
  end
  table.sort(tabs)
  return out, byId, tabs
end

-- The game's own talent tooltip, which knows the rank, for a cell or the footer's slot (Era only). Forever's
-- GameTooltip:SetTalent is (talentID, isInspect, groupIndex): called in Era's order it raised "bad argument #3"
-- from inside Blizzard's tooltip code, which pcall cannot hide, so there the spell's tooltip is the one shown.
function ns.talentTip(slot)
  if ns.forever then return false end
  return slot.talent
    and GameTooltip.SetTalent
    and pcall(GameTooltip.SetTalent, GameTooltip, slot.talent, false, false, slot.group)
end

local function tooltip(self)
  if not GameTooltip then return end
  local ok, err = pcall(function()
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    -- (the game's own talent tooltip, called as its own talent window calls it: by the talent's id; the spell's
    -- when the call is refused)
    local shown = ns.talentTip(self)
    if not shown and self.spell then GameTooltip:SetSpellByID(self.spell) end
    if self.line then GameTooltip:AddLine(self.line, T.accent[1], T.accent[2], T.accent[3], true) end
    GameTooltip:Show()
  end)
  if not ok then ns.fault("tooltip", err) end
end

local function cell(tree, row, col)
  local key = row * COLS + col
  local s = tree.cells[key]
  if s then return s end
  s = K.slot(tree.frame, CELL)
  s.edge = s:CreateTexture(nil, "OVERLAY")
  s.edge:SetTexture(EDGE)
  s.edge:SetBlendMode("ADD")
  s.edge:SetPoint("CENTER")
  s.edge:SetSize(CELL * 1.8, CELL * 1.8)
  s.mark = K.label(s, K.BODY_FONT, 10, GOLD)
  s.mark:SetPoint("TOPLEFT", 2, -2)
  s.rankText = K.label(s, K.BODY_FONT, 10, T.text)
  s.rankText:SetPoint("BOTTOMRIGHT", -2, 2)
  s:SetPoint("TOPLEFT", tree.frame, "TOPLEFT", MARGIN + col * HP, -(HEAD + row * VP))
  s:SetScript("OnEnter", tooltip)
  s:SetScript("OnLeave", function()
    if GameTooltip then GameTooltip:Hide() end
  end)
  tree.cells[key] = s
  return s
end

local function bar(tree, i)
  local t = tree.lines[i]
  if not t then
    t = tree.frame:CreateTexture(nil, "BACKGROUND")
    tree.lines[i] = t
  end
  return t
end

function Tree.new(parent)
  local t = { frame = CreateFrame("Frame", nil, parent), trees = {}, model = {} }
  t.frame:SetSize(3 * TREE_W + 2 * BETWEEN, ns.TREE_H)
  for i = 1, 3 do
    local f = CreateFrame("Frame", nil, t.frame)
    f:SetSize(TREE_W, ns.TREE_H)
    f:SetPoint("TOPLEFT", t.frame, "TOPLEFT", (i - 1) * (TREE_W + BETWEEN), 0)
    local tree = { frame = f, cells = {}, lines = {}, gates = {} }
    tree.name = K.label(f, K.TITLE_FONT, 14, T.gold)
    tree.name:SetPoint("TOPLEFT", MARGIN, 0)
    t.trees[i] = tree
  end
  return t
end

-- Set the trees for a class: snap (the character, or nil: no talents read), build and road (the road drawn), level
-- (nil: what the character has taken; a number: what the road has by then), who (the pick to ring).
-- t.model lists every cell as drawn, for the tests: { spell, window, row, col, rank, max, mark, state }.
function Tree.draw(t, snap, class, build, road, level, quiet)
  local cells, _, tabs = cellsOf(class)
  local marks = G.marks(build, road)
  local at = level and G.ranksAt(build, road, level)
  local pick = not level and not quiet and G.nextPick(snap, build, road)
  local why = {}
  for _, step in ipairs(G.roads(build)[road or 1].path) do
    for _, spell in ipairs(step.any or { step.talent }) do
      why[spell] = why[spell] or { level = step.level[1], text = ns.say(step.why) }
    end
  end
  -- the window's order of the trees: the game's, found from a talent of each; else by tree id
  local order = {}
  for _, tab in ipairs(tabs) do
    local at1
    for _, c in ipairs(cells) do
      local info = c.tab == tab and snap.talents.byId[c.id]
      if info then
        at1 = info.tab
        break
      end
    end
    if at1 and not order[at1] then order[at1] = tab end
  end
  for _, tab in ipairs(tabs) do
    local placed = false
    for _, v in pairs(order) do
      if v == tab then placed = true end
    end
    if not placed then
      for i = 1, 3 do
        if not order[i] then
          order[i] = tab
          break
        end
      end
    end
  end
  t.model = {}
  for i = 1, 3 do
    local tree = t.trees[i]
    for _, s in pairs(tree.cells) do
      s:Hide()
    end
    for _, l in pairs(tree.lines) do
      l:Hide()
    end
    for _, g in pairs(tree.gates) do
      g:Hide()
    end
    local tab = order[i]
    tree.frame:SetShown(tab ~= nil)
    if tab then
      tree.name:SetText(snap.talents.names[i] or L["Tree %d"]:format(i))
      local gates, at2 = {}, {}
      for _, c in ipairs(cells) do
        if c.tab == tab then
          local info = snap.talents.byId[c.id]
          local mark = marks[c.spell]
          local rank = level and (at[c.spell] or 0) or (info and info.rank or 0)
          local state = "off"
          if rank > 0 then
            state = "taken"
          elseif mark then
            state = "road"
          end
          -- (the next pick, or any option of the choice it is)
          for _, o in ipairs(pick and pick.step.options or {}) do
            if o.spell == c.spell then state = "next" end
          end
          local s = cell(tree, c.row, c.col)
          s.spell, s.talent, s.group = c.spell, c.id, snap.group
          local icon = info and info.icon
          if not icon then
            local _, ic = ns.reader.spell(c.spell)
            icon = ic
          end
          K.setSlot(s, icon or K.QUESTION)
          -- (the game's look for a talent that cannot be had, Vanilla/TalentFrameBase.lua:131 SetItemButtonDesaturated(button, 1, 0.65, 0.65, 0.65), here for a talent off the road; the road's in full colour)
          s.icon:SetDesaturated(state == "off")
          local v = state == "off" and 0.65 or 1
          s.icon:SetVertexColor(v, v, v)
          s.rankText:SetText(rank > 0 and ("%d/%d"):format(rank, c.max) or (c.max > 1 and ("0/%d"):format(c.max) or ""))
          s.mark:SetText(mark and tostring(mark) or "")
          local edge = state == "next" and GOLD or state == "taken" and GOLD or state == "road" and BLUE or nil
          s.edge:SetShown(edge ~= nil)
          if edge then
            s.edge:SetVertexColor(edge[1], edge[2], edge[3])
            s.edge:SetAlpha(state == "next" and 1 or state == "taken" and 0.55 or 0.7)
          end
          local w = why[c.spell]
          s.line = state == "next"
              and pick
              and L["Primer: next pick, level %d."]:format(pick.level) .. (w and (" " .. ns.stop(w.text)) or "")
            or w and L["Primer: pick %d on this road, from level %d."]:format(mark, w.level) .. " " .. ns.stop(w.text)
            or L["Primer: not on this road."]
          s:Show()
          at2[c.id] = { row = c.row, col = c.col }
          gates[c.row] = math.min(gates[c.row] or 99, c.req)
          table.insert(t.model, {
            spell = c.spell,
            window = i,
            row = c.row,
            col = c.col,
            rank = rank,
            max = c.max,
            mark = mark,
            state = state,
            frame = s,
          })
        end
      end
      -- the points a row asks (the game's rule), at the left of its first cell
      for row, need in pairs(gates) do
        if row > 0 and need > 0 then
          local g = tree.gates[row]
          if not g then
            g = K.label(tree.frame, K.BODY_FONT, 10, T.soft)
            g:SetWidth(MARGIN - 4)
            g:SetJustifyH("RIGHT")
            g:SetWordWrap(false)
            tree.gates[row] = g
          end
          g:ClearAllPoints()
          g:SetPoint("TOPLEFT", 0, -(HEAD + row * VP + CELL / 2 - 5))
          g:SetText(tostring(need))
          g:Show()
        end
      end
      -- straight prerequisite lines (the two diagonal ones the game draws bent are left out)
      local n = 0
      for _, c in ipairs(cells) do
        if c.tab == tab and c.pre then
          local to = at2[c.id]
          for _, p in ipairs(c.pre) do
            local from = at2[p.id]
            if from and to and (from.col == to.col or from.row == to.row) then
              n = n + 1
              local l = bar(tree, n)
              l:ClearAllPoints()
              local x = MARGIN + from.col * HP
              local y = HEAD + from.row * VP
              if from.col == to.col then
                local top, bottom = math.min(from.row, to.row), math.max(from.row, to.row)
                l:SetSize(4, (bottom - top) * VP - CELL + 2 * VGAP)
                l:SetPoint("TOPLEFT", tree.frame, "TOPLEFT", x + CELL / 2 - 2, -(HEAD + top * VP + CELL - VGAP))
              else
                local left, right = math.min(from.col, to.col), math.max(from.col, to.col)
                l:SetSize((right - left) * HP - CELL + 2 * GAP, 4)
                l:SetPoint("TOPLEFT", tree.frame, "TOPLEFT", MARGIN + left * HP + CELL - GAP, -(y + CELL / 2 - 2))
              end
              local taken = not level and snap.talents.byId[p.id] and snap.talents.byId[p.id].rank > 0
              local c1 = taken and GOLD or T.rule
              l:SetColorTexture(c1[1], c1[2], c1[3], taken and 0.8 or 0.9)
              l:Show()
            end
          end
        end
      end
    end
  end
end
