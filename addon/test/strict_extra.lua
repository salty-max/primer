-- Primer's own cases for the strict game (the kit's strict_test.lua runs them): the calls that went wrong here.
-- Today's failure (5 November 2026): GameTooltip:SetTalent(talent, false, false, group).
return function(G, refused, accepted)
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

  -- the talent tooltip
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
    refused(
      "Era's talent tooltip with one argument",
      function() GameTooltip:SetTalent(5) end,
      "called with 1 arguments"
    )
  end
end
