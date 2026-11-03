-- Primer played through: a login, /primer opening the window with its three
-- tabs (each an empty page that says what it will hold), the minimap button,
-- the guide's rules and words (every key has its text), and nothing asked of
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
  check(#b.stages == 3 or id == 3, "its stages: " .. b.key)
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
  check(builds == 3 and D.builds[1] and D.builds[2] and D.builds[3], "Classic Era: the Warrior's three builds")
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
  check(not event:find("COMBAT") and not event:find("^UNIT_") and not event:find("SPELL"), "no combat event: " .. event)
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

-- ── the minimap command ──────────────────────────────────────────────────────
SlashCmdList.PRIMER("minimap")
check(ns.option("minimapHidden") == true, "/primer minimap hides the button")
SlashCmdList.PRIMER("minimap")
check(ns.option("minimapHidden") == false, "and shows it again")

io.write(("✓ Primer: %d checks (%s)"):format(count, G.FOREVER and "Forever" or "Classic Era"), "\n")
