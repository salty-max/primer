-- The guide's window: the family's (the kit's K.gameWindow: portrait, title
-- bar) with its tabs under the bottom edge, Play, Talents and Role. At this
-- milestone each tab is an empty page that says what it will hold; the pages'
-- content is the next one (docs/architecture.md). Opened by /primer and the
-- minimap button; it reads nothing, in combat or out.
local _, ns = ...
local K, L = ns.kit, ns.kit.L
local T = K.T

local WIDTH, HEIGHT = 560, 420
local TABS = { play = 1, talents = 2, role = 3 }
ns.TAB = TABS

local frame
local pages = {}

-- What each page will hold, in one plain sentence.
local function sentences()
  return {
    [TABS.play] = L["The Play page will give you the opening and the order to press your spells in, for your level and your build."],
    [TABS.talents] = L["The Talents page will give you the next talent points to take, in order, with the reason for each."],
    [TABS.role] = L["The Role page will say what your build is for, and let you choose between damage, tanking and healing."],
  }
end

local function show(n)
  frame.selectedTab = n
  K.selectTab(frame, n)
  for i, page in pairs(pages) do
    page:SetShown(i == n)
  end
end

local function build()
  local window = K.gameWindow("PrimerFrame", "Primer", ns.ICON)
  frame = window or K.dialog("PrimerFrame", "Primer")
  PrimerSettings = PrimerSettings or {}
  K.movable(frame, WIDTH, HEIGHT, K.place(PrimerSettings, "window"))
  local edge = window and 8 or 14
  local body = K.panel(frame, true)
  body:SetPoint("TOPLEFT", edge, -58)
  body:SetPoint("BOTTOMRIGHT", -edge, edge)
  local words = sentences()
  for n in ipairs(words) do
    local page = CreateFrame("Frame", nil, body)
    page:SetAllPoints()
    local text = K.label(page, K.BODY_FONT, 14, T.text)
    text:SetPoint("TOPLEFT", 24, -24)
    text:SetPoint("TOPRIGHT", -24, -24)
    text:SetJustifyV("TOP")
    text:SetText(words[n])
    pages[n] = page
  end
  frame.selectedTab = TABS.play
  frame:SetScript("OnShow", function() show(frame.selectedTab) end)
  K.tabs(frame, { L["Play"], L["Talents"], L["Role"] }, show)
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
