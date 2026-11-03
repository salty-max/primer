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
    lines = function()
      local lines = { L["A class guide to read out of combat."] }
      if ns.glowing then table.insert(lines, L["You have talent points to spend."]) end
      return lines
    end,
    click = function() ns.toggle() end,
    get = ns.option,
    set = ns.setOption,
  })
end

-- A soft glow on the button while the level-10 question waits (the game's own
-- highlight of its minimap buttons, always on): never a pop-up.
local glow
function ns.setGlow(on)
  ns.glowing = on and true or false
  if not (M and M.button) then return end
  if not glow then
    glow = M.button:CreateTexture(nil, "OVERLAY")
    glow:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    glow:SetBlendMode("ADD")
    glow:SetAllPoints()
  end
  glow:SetShown(ns.glowing)
end

function ns.updateMinimapButton()
  if M then M:update() end
end
