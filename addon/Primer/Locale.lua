-- The reader's language. The client loads its own Text_<locale>.lua next (the
-- TOCs name Text_[TextLocale].lua; scripts/locales.ts writes them from
-- i18n/), which hands its words to ns.translate: English stays wherever it
-- says nothing. Primer is English only for now, so every language's file is a
-- stub and the words are the addon's own. The guide's words are GuideText.lua's,
-- by key (a language added later comes as a file beside it). A spell's or a
-- talent's name is the game's, by id, in the client's language: never ours.
local _, ns = ...
local K = ns.kit

-- (the kit's: the language's plural rule, every word through it; which game
-- this is the kit says too, ns.forever)
function ns.translate(t) K.translate(t) end

-- A guide's word by its key (GuideText.lua), else the key itself: a missing
-- word shows as what it is, never as nothing.
function ns.say(key) return (ns.guideText and ns.guideText[key]) or key end
