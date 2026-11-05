-- Primer's settings, each character's own (its profile, "Name - Realm", the
-- kit's: Kit.lua), all kept in PrimerSettings so that one character can take
-- another's: chosen among this game's characters, or brought by a code
-- (/primer export, /primer import CODE). Their page in the game's Options
-- (AddOns tab): /primer settings, or a right-click on the minimap button; the
-- welcome page (Welcome.lua) offers them too. The window's place is kept
-- beside them (Window.lua).
--
--   PrimerSettings.profiles["Name - Realm"] = { minimapHidden, minimapAngle,
--     levelTenLine, welcomed }
--   PrimerSettings.places.window = { point, x, y }
local _, ns = ...
local K = ns.kit
local L = K.L

-- (levelTenLine: the one line in chat when a character reaches level 10 with a
-- point to spend; welcomed: never copied)
-- (minimapAngle: the button's place around the minimap, in degrees: the kit's
-- 90 at the top, 25 from Yours Truly's (115), clear of the Era zoom buttons)
local DEFAULTS = {
  minimapHidden = false,
  minimapAngle = K.MINIMAP_ANGLES.Primer,
  levelTenLine = true,
  welcomed = false,
}
local SHARED = { "minimapHidden", "minimapAngle", "levelTenLine" }

-- The profiles: a code "PR1:h0:a90:l1".
local P = K.profiles({
  saved = function()
    if type(PrimerSettings) ~= "table" then PrimerSettings = {} end
    return PrimerSettings
  end,
  defaults = DEFAULTS,
  shared = SHARED,
  letters = { minimapHidden = "h", minimapAngle = "a", levelTenLine = "l" },
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

-- The page in the game's Options (the kit's: K.options).
local O

function ns.createSettingsPanel()
  if O then return end
  O = K.options({
    title = "Primer",
    key = "PRIMER",
    get = ns.option,
    set = ns.setOption,
    defaults = DEFAULTS,
    profiles = P,
    slash = "/primer",
    prefix = ns.PREFIX,
  })
  O:check("minimapHidden", L["Minimap button"], L["The book by the minimap: click to open it, drag to move it."], true)
  O:check(
    "levelTenLine",
    L["A line in chat when a talent point waits"],
    L["Say once in chat when this character has a talent point to spend."]
  )
  O:copy()
  O:done()
end

function ns.openSettings() return O ~= nil and O:open() end
