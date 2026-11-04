# Primer's architecture

The addon file by file (the map is CLAUDE.md). The guide's data and its checks:
`docs/data.md`. Milestone M2 of `../ideas/class-guide.md`: the repository and the
Warrior's rules in data. M3 (4 November 2026): the window, Classic Era first.

## The package

- `addon/Primer`: one package for every game (`Primer_Vanilla.toc`: Classic
  Era, 11509; `Primer_Camelot.toc`: Forever, 16001; no TBC Anniversary: the
  family dropped it), the same but for the interface and the game's rules
  (`Guide_Classic.lua`, `Guide_Forever.lua`). Loads that, `GuideText.lua` (the
  words by key), `Kit.lua` (the kit's copy, `bun run kit:sync`; never edit it),
  `Locale.lua`, `Text_[TextLocale].lua`, `Core.lua`, `Settings.lua`,
  `Reader.lua`, `Guide.lua`, `Window.lua`, `Minimap.lua` (the test game loads
  them from the TOC).

## The files

- **Core.lua**: the kit's theme (a cool blue-grey), `PrimerChar` (the guide of
  one character, by GUID: the chosen build and the role switch, both for M3),
  the events (the kit's `K.events`), `/primer` (the kit's `K.commands`: alone
  it toggles the window, `minimap` shows or hides the button, anything else the
  usage). It listens to no combat event and asks no unit: **Primer reads
  nothing in combat** (the test checks the events it registers).
- **Settings.lua**: the kit's profiles (a character's settings, takable by a
  code "PR1:h0:a90"): the minimap button's place and whether it shows. No
  Options page and no welcome yet.
- **Reader.lua**: every call goes through `try()`: a function the client
  documents can still raise ("API unsupported", `GetNumSpecGroups` on Classic
  Era, found in the first game test, 4 November 2026), so an error is kept once
  (`ns.faults`, this session only, `/primer debug` prints it), the call is
  skipped until the window is opened again, and the answer is the safe default
  (one group, no season). When the talents or the book are the calls that
  failed (`R.blind()`) the page says it cannot read the character and gives no
  advice from defaults. The whole draw is a `pcall`: a failing page is a calm
  "Something went wrong" page, never a Lua error. What it reads, out of combat: the
  class and level, `C_Seasons.GetActiveSeason`, `C_SpellBook` (a spell in the
  book), `C_Spell.GetSpellInfo` (a name and a picture, by id) and the talents
  (`C_SpecializationInfo.GetTalentInfo` over each tree's cells, found by the
  talent's id from the data: its spell is 0 at rank 0). `snapshot()` answers
  nil in combat. No old global (`GetTalentInfo`, `IsSpellKnown`) is used.
- **Guide.lua**: the rules, no frame and no game call, played over a snapshot:
  `page` (season, game, class or guide), `role` and `build` (the player's
  choice if the class has it, else the tree with the most points, else the
  first), `stage` (the level's), `rows` (a row shows if its level is reached,
  its talents taken and its spell in the book: the level-12 page is shorter,
  never wrong; a spell only waiting for the trainer is counted), `steps` (the
  path as the character stands: done, partly, later, and the next pick) and
  `unspent` (a point a level from 10).
- **The phase flow (M3b)**, in Guide.lua and the Level page: a character's phase is its state (`untalented` before level
  10, `choose` with points to spend and none spent, `spent`), kept apart from
  the builds, which are content. At `choose` with no role stored the Level page
  asks once what to play (a line a role and a button each, or Not yet) and says it once in chat, never a pop-up and no glow; a role chosen sets
  that role's recommended build. From `spent` the
  build is the player's pick, else the build the points leave open: a build is
  reachable while the points outside its tree are no more than 20 of the 51
  (feasibility, not the tree with most points, `docs/inference.md`). Several
  open: the page shows the build we advise for the role, and says so (it never asks which build).
  A pick the points can no longer reach is said once with three ways on (keep,
  follow, my own way); points that fit only another role's builds offer a
  switch, never silent; a dismissed note stays dismissed until the drift
  changes (`driftSeen`). Your own way (`freestyle`)
  has no picks and no notes. Change role, at the foot of the page, offers the other
  roles and says a respec costs gold. Saved per talent group: `role`, `pickedBuild`,
  `freestyle`, `driftSeen`, `driftWay`, `notYet`.
- **What the page is for (4 November 2026, after the first game test)**: the role
  and build (`view.subjects`) are fixed while the window is open and change only
  on the player's own click or when the window is opened: a point spent, a level or
  a spell learned update the page in place, never the build or role. A picked
  build is never swapped for the nearest one: the drift is said and Follow is a
  button. Looking at another level only looks (`view.looking`). **Roads**
  (`G.roads`, `G.pickRoad`): a build may have several orders for its points; the
  player never chooses one: the page advises the recommended road (the Hardcore
  road on a Hardcore realm) and recognises quietly a documented road the points
  follow (`docs/inference.md`). A stage's plan may carry `alt` and a build
  `hardcore` lines: neither is on the Level page yet.
- **The rotation plan** (`G.stepState`): a stage's `plan`, its opening and loop
  on the Level page (`docs/data.md`).
- **Window.lua** (rebuilt twice on 4 November 2026: direction A failed the user's
  game test, "no family vibe, the window does not use the kit", so it is direction B
  of `../ideas/primer-design.md` on the kit's book, the way Goodwill and Yours
  Truly are built): `K.book` ("PrimerFrame": the game's window, `K.list` on the
  left, `K.page` on the right, `K.tabs`), no frame of its own but the rows of the
  page. Three tabs: **Level** (written), **Talents** and **Class** (placeholders
  that say their name). The left list is the spine: the levels from the
  character's to 40 at which something arrives (a pick, or a spell the build's
  plans use), "You are here" at the character's own, the level shown picked
  out. The page is the selected level's, with at most about ten lines of text
  (`ns.BUDGET.lines`): the **pick** (next pick, or that level's, a "Why?" that opens
  its reason), the **opening** as one chain of names, the **loop** as numbered
  rows (`[n] icon name clause`, wrapping rather than clipping, the reason in the
  icon's tooltip, a row the character cannot press yet grey in its place with what
  it needs). The facts are the count beside the portrait (the build, the level and
  the realm or the group: three at most) and the page's subtitle is how the road
  was chosen. Selecting a level is **looking**: "Looking at level 38." and "Back to
  my level", and nothing the page is for changes (`view.looking`); the level-10
  question, a drift or a role change is one block that replaces the page ("one idea
  a screen"), asked once (`view.putOff`). What the page is for (`view.subjects`, per
  talent group) is frozen while the window is open. A role chosen sets its
  recommended build (`G.recommend`). **Nothing is cut with an ellipsis**: a line
  that does not fit is shortened in the content (the check holds every plan line
  to 56 characters, a reason to 60, an opening to 6 steps and a loop to 8), rows
  wrap, and `/primer fit` (`ns.fit`) walks the open window and names any text the
  client cut (`IsTruncated`). The events are the same as before
  (`PLAYER_ENTERING_WORLD`, `PLAYER_LEVEL_UP`, `SPELLS_CHANGED`,
  `LEARNED_SPELL_IN_SKILL_LINE`, `TRAINER_UPDATE`, `CHARACTER_POINTS_CHANGED`,
  `PLAYER_TALENT_UPDATE`, `TRAIT_CONFIG_UPDATED`, `ACTIVE_TALENT_GROUP_CHANGED`), each
  only asking for a look, a burst as one draw 0.3 seconds later. In a fight it
  reads nothing and says it waits. A draw is `pcall`-guarded (`broken`). One chat
  line at level 10, once a character (`PrimerChar.welcomed`). What each draw left
  is `ns.screen` (title, facts, spine, pick, opening, loop, question): the sim reads
  that and presses the buttons through it. `ns.toggle()`, `ns.open(tab)`. Between
  fights, low mana, the big cooldowns, the Hardcore notes and the Overview are
  not on the page yet (the Class tab and a later pass).
- **Tree.lua** (kept for the Talents tab, which is a placeholder: nothing calls it yet): the class's three trees from the data's `cells` (row 0 to 6,
  column 0 to 3 as the game numbers them), `K.slot` cells of 34 pixels, the road's
  numbers (the order it first takes each talent: they belong to the road), taken
  lit gold, on the road not yet blue, the next pick ringed, row gates at the
  left, straight prerequisite lines (the two diagonal ones are left out), the
  game's own tooltip (`GameTooltip:SetTalent(talentID, false, false, group)`,
  as Era's own talent window calls it) plus one line of ours. Forever has no
  tree yet (M-E).
- **Minimap.lua**: the kit's `K.minimapButton`, named `PrimerMinimapButton`
  (Keyring finds the family's buttons by name), at `K.MINIMAP_ANGLES.Primer`
  (90 degrees, the top: at least 25 from every other place and clear of Classic
  Era's zoom buttons, which the kit's table says).
- **Locale.lua**: `ns.translate` (the kit's) and `ns.say(key)`, a guide word by
  its key.
- **Guide_Classic.lua, Guide_Forever.lua, GuideText.lua**: generated by
  `scripts/guide.ts` (`docs/data.md`). Forever's has no build yet.
- **Text_<locale>.lua**: generated by `scripts/locales.ts`, a stub for each of
  the eleven client languages.

## Languages

English only for now (the user's call, 3 November 2026): every word still goes
through `L` and the guide's through `ns.say`, so a language can be added later
with the `wow-translating` skill, but there is no `i18n/<locale>/` yet and no
French, German or Spanish work. What that does to the family's lists:

- `HIDDEN_LOCALES` (deDE, esES, esMX, in addon-kit's `locales-lib.ts`) changes
  nothing that matters: with no translation, every language but English is a
  stub of English words (deDE, esES and esMX carry the held-back mark, the
  others read "no translation yet"), and a held-back language only differs once
  it has a translation. `addon/test/held.lua` is the family's guard for the day
  a `LOCALE=…` line is added to `check:ci`; the sim does not call it yet.
- The TOCs name no `Notes-<locale>`, and the store page (later) says English.
- The test plays an English client only. A language added means its
  `LOCALE=…` lines in `check:ci` as the siblings have them.

## The tests

`addon/test/game.lua` is the kit's game (`wowmock.lua`, a copy) plus the
registered events and what the guide reads (a spell book, the talent call as
the Era probe answered it, the season, names and pictures by id); `sim.lua`
plays a login, the slash command, the tabs, the button, the data (every key
has its word, every row its facts), the rules over characters (filters, stage,
role, build, steps, the per-game and season pages) and the three pages as the
window draws them, on Classic Era and with `FOREVER=1`. A game test (`wow-game-test`) shows what these cannot: the
look of the window, the portrait, the tabs under the frame, the button on the
real minimap.
