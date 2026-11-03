-- Primer's settings, each character's own (its profile, "Name - Realm", the
-- kit's: Kit.lua), all kept in PrimerSettings so that one character can take
-- another's. Only the minimap button for now; the window's place is kept
-- beside them (Window.lua).
--
--   PrimerSettings.profiles["Name - Realm"] = { minimapHidden, minimapAngle }
--   PrimerSettings.places.window = { point, x, y }
local _, ns = ...
local K = ns.kit

-- (minimapAngle: the button's place around the minimap, in degrees: the kit's
-- 90 at the top, 25 from Yours Truly's (115), clear of the Era zoom buttons)
local DEFAULTS = {
  minimapHidden = false,
  minimapAngle = K.MINIMAP_ANGLES.Primer,
}

-- The profiles: a code "PR1:h0:a90".
local P = K.profiles({
  saved = function()
    if type(PrimerSettings) ~= "table" then PrimerSettings = {} end
    return PrimerSettings
  end,
  defaults = DEFAULTS,
  shared = { "minimapHidden", "minimapAngle" },
  letters = { minimapHidden = "h", minimapAngle = "a" },
  tag = "PR1",
  changed = function(key)
    if key == "minimapHidden" or key == "minimapAngle" then
      if ns.updateMinimapButton then ns.updateMinimapButton() end
    end
  end,
})
ns.profiles = P

function ns.loadProfile() P:load() end
function ns.option(key) return P:get(key) end
function ns.setOption(key, value) P:set(key, value) end
