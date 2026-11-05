-- The welcome (the kit's, Kit.lua): once per character, a few seconds after
-- its first login (out of combat; /primer welcome shows it again), laid out
-- as the book's window: on the left what Primer is; on the right this
-- character's choices (Settings.lua: the minimap button, the line at level
-- 10), then another character's to take, chosen among this game's or brought
-- by a code (/primer export there). Closing it, however, is enough to have
-- seen it. It offers no sharing: Primer collects nothing.
local _, ns = ...
local K = ns.kit
local L = K.L

local W = K.welcome({
  name = "PrimerWelcome",
  title = L["Welcome to Primer"],
  art = ns.ICON,
  logo = ns.ICON,
  heading = "Primer",
  tagline = L["A class guide to read out of combat."],
  intro = function()
    -- (the question at level 10 is the game's: Forever's players pick a spec, Era's a role)
    local asks = ns.data
        and ns.data.game == "forever"
        and L["At level 10 it asks which spec you want to play. You can change it later, and a respec costs gold."]
      or L["At level 10 it asks which role you want to play. You can change it later, and a respec costs gold."]
    return L["Primer says which talents to pick and what to press at your level, with the reason printed under every line."]
      .. "\n\n"
      .. asks
      .. "\n\n"
      .. L["Open it with /primer or the minimap button, before the pull and not during one. It reads your talents and spells only out of combat, and it sends nothing anywhere."]
  end,
  profiles = ns.profiles,
  choices = function()
    return {
      K.minimapChoice(ns.option, ns.setOption),
      {
        text = L["A line in chat when a talent point waits"],
        hint = L["Once, when you have a talent point to spend."],
        get = function() return ns.option("levelTenLine") end,
        set = function(v) ns.setOption("levelTenLine", v and true or false) end,
      },
    }
  end,
  footnote = L["Change them any time: %s, or a right-click on the minimap button."]:format("/primer settings")
    .. " "
    .. L["/primer opens the book."],
  open = { text = L["Open the book"], click = function() ns.toggle() end },
  exportHint = L["Copy it (Ctrl+C), then on another character: Use a code, or /primer import CODE."],
  importHint = L["Paste the code (/primer export on the other character), then press Enter."],
  refused = L["That isn't a Primer settings code."],
})

ns.welcome = W -- (its frame, rows, picker and code: for the tests)
function ns.showWelcome(mode) W:Show(mode) end

K.welcomeOnce(W, ns.profiles, function() return ns.book() ~= nil end)
