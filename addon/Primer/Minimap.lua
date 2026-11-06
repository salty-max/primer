-- The guide's button on the minimap (the kit's: Kit.lua): click to open the
-- window, drag to move it around the minimap. Its place (and whether it shows)
-- is kept with this character's settings (Settings.lua). Keyring finds it by
-- its name, PrimerMinimapButton.
local _, ns = ...
local K, L = ns.kit, ns.kit.L

local M

function ns.createMinimapButton()
  if M then return end
  M = K.minimapButton({
    name = "PrimerMinimapButton",
    icon = ns.ICON,
    crop = true,
    title = "Primer",
    lines = function() return { L["A class guide to read out of combat."] } end,
    click = function() ns.toggle() end,
    rightClick = function() ns.openSettings() end,
    get = ns.option,
    set = ns.setOption,
  })
end

function ns.updateMinimapButton()
  if M then M:update() end
end

-- The key binding (the kit's K.binding, Bindings.xml): one key or pad button opens and closes the window as the
-- minimap button's click does.
-- Not in a fight: the guide reads nothing in combat, so a press then says so and opens nothing.
ns.kit.binding({
  key = "PRIMER",
  name = "Primer",
  global = "PrimerBinding",
  toggle = function() ns.toggle() end,
  outOfCombat = true,
  prefix = ns.PREFIX,
})
