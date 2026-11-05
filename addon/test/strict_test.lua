-- The strict game refuses what the client refuses (addon/test/strict.lua): each bad call below is a call that
-- raised, or would have, in the player's game. If one of these passes, the net has a hole.
-- FOREVER=1 for Forever's client. Today's failure (5 November 2026): GameTooltip:SetTalent(talent, false, false, group).
local G = dofile("addon/test/game.lua")
local S = G.strict
assert(S, "the strict game is on (STRICT=0 turns it off)")
local count = 0
local function refused(what, fn, pattern)
  local before = #S.violations
  local ok, err = pcall(fn)
  assert(not ok, "✗ the strict game accepted: " .. what)
  assert(tostring(err):find(pattern, 1, true), ("✗ %s: wrong refusal: %s"):format(what, tostring(err)))
  assert(#S.violations == before + 1, "✗ the refusal was not kept for the check: " .. what)
  S.violations[#S.violations] = nil
  count = count + 1
end
local function accepted(what, fn)
  local ok, err = pcall(fn)
  assert(ok, ("✗ the strict game refused a good call: %s: %s"):format(what, tostring(err)))
  count = count + 1
end

local f = CreateFrame("Frame", nil, UIParent)
local t = f:CreateTexture()

-- the documented functions
if G.FOREVER then
  refused(
    "a node asked for without its config",
    function() C_Traits.GetNodeInfo(nil, 5) end,
    "bad argument #1 (configID)"
  )
  refused("a node id that is text", function() C_Traits.GetNodeInfo(7, {}) end, "bad argument #2 (nodeID)")
  refused("an extra argument", function() C_Traits.GetNodeInfo(7, 5, 1) end, "too many arguments")
  accepted("a node asked for", function() C_Traits.GetNodeInfo(7, 5) end)
end
refused(
  "a spec index of zero",
  function() C_SpecializationInfo.GetSpecializationInfo(0) end,
  "bad argument #1 (specializationIndex)"
)
accepted("a spec", function() C_SpecializationInfo.GetSpecializationInfo(1) end)
refused("a spell name asked of nothing", function() C_Spell.GetSpellInfo(nil) end, "bad argument #1")

-- the widgets' methods
refused("a size that is text", function() f:SetSize("wide", 20) end, "bad argument #2 (x)")
refused("a point that is not text", function() f:SetPoint(5) end, "bad argument #2 (point)")
refused("a texture path that is a frame", function() t:SetTexture({}) end, "bad argument")
accepted("a size", function() f:SetSize(10, 20) end)
accepted("the short form of a point", function() f:SetPoint("LEFT", 4, 0) end)
accepted("a point and nothing else", function() f:SetPoint("TOP") end)

-- the tooltip: the methods the documentation does not list are held to Blizzard's own call sites
refused("a method that exists in no game", function() GameTooltip:SetNothingAtAll(1) end, "SetNothingAtAll")
accepted("a spell tooltip", function() GameTooltip:SetSpellByID(100) end)
if G.FOREVER then
  refused(
    "Era's talent tooltip on Forever",
    function() GameTooltip:SetTalent(5, false, false, 1) end,
    "has no call in forever's own source"
  )
  refused(
    "and Forever's own order is not proven either",
    function() GameTooltip:SetTalent(5, false, 1) end,
    "has no call in forever's own source"
  )
else
  accepted("Era's talent tooltip on Era", function() GameTooltip:SetTalent(5, false, false, 1) end)
  refused("Era's talent tooltip with one argument", function() GameTooltip:SetTalent(5) end, "called with 1 arguments")
end
-- (an allowlisted method passes, and is said)
S.ALLOW["GameTooltip:SetNothingAtAll"] = "a test"
accepted("an allowlisted method", function() GameTooltip:SetNothingAtAll(1) end)
S.ALLOW["GameTooltip:SetNothingAtAll"] = nil

-- a refusal inside a pcall is kept all the same
S.violations = {}
pcall(function() f:SetSize("a", "b") end)
assert(#S.violations == 1, "✗ a pcall hid a refusal")
S.violations = {}
count = count + 1
io.write(
  ("✓ strict game: %d refusals and acceptances (%s)\n"):format(count, G.FOREVER and "Forever" or "Classic Era")
)
