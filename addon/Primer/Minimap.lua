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
    get = ns.option,
    set = ns.setOption,
  })
end

function ns.updateMinimapButton()
  if M then M:update() end
end
