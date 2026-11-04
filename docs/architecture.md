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
- **The phase flow (M3b)**, in Guide.lua and the strip of the window (rebuilt in M-B): a character's phase is its state (`untalented` before level
  10, `choose` with points to spend and none spent, `spent`), kept apart from
  the builds, which are content. At `choose` with no role stored the Play tab
  asks once what to play (a card a role, the build we advise, Use this, or Not
  yet) and says it once in chat, never a pop-up and no glow; a role chosen sets
  that role's recommended build. From `spent` the
  build is the player's pick, else the build the points leave open: a build is
  reachable while the points outside its tree are no more than 20 of the 51
  (feasibility, not the tree with most points, `docs/inference.md`). Several
  open: the page shows the build we advise for the role, and says so (it never asks which build).
  A pick the points can no longer reach is said once with three ways on (keep,
  follow, my own way); points that fit only another role's builds offer a
  switch, never silent; a dismissed note stays dismissed until the drift
  changes (`driftSeen`). Your own way (`freestyle`)
  has no picks and no notes. Change role in the header opens the strip with the other
  roles and says a respec costs gold. Saved per talent group: `role`, `pickedBuild`,
  `freestyle`, `driftSeen`, `driftWay`, `notYet`.
- **What the page is for (4 November 2026, after the first game test)**: a
  header on every tab says it in one line ("Retribution Paladin. Damage. Level
  12. A build you picked." and how it was chosen: a build you picked, following
  your points, your own way, not chosen yet). What the page is for (the role
  and build, `view.subject`) is fixed while the window is open and changes only
  on the player's own click or when the window is opened: a point spent, a
  level or a spell learned update the facts, the ticks and the notes in place,
  never the build or role. A picked build is never swapped for the nearest one:
  the drift is said and Follow is a button. A click on another build or role
  only looks (`view.look`): the page says so loudly with Use this build and
  Back, and nothing is chosen until Use. A refresh from an event keeps the
  scroll and the talent in view; a tab or a click starts at the top.
- **The Overview tab** (4 November 2026, the first tab): the class in
  general in the narrator's voice, from the class's `overview` in the data, the
  builds in a line each with their roles, and what to do at level 10 (`drawOverview`).
  (M-B: the card names the other builds as what also works.) **Roads** (`G.roads`,
  `G.pickRoad`): a build may have several orders for its points; the player never
  chooses one: the page advises the recommended road (the Hardcore road on a
  Hardcore realm), says why in a line, and recognises quietly a documented road
  the points follow, with no drift (`docs/inference.md`). A stage's plan may carry `alt`, another way to play it
  (a crowd, against one monster), under its own heading. `build.hardcore` lines
  show only on a Hardcore realm (`G.HARDCORE`).
- **The rotation plan** (`drawPlan`, `G.stepState`): a stage's `plan` shown as
  Opening, Loop, Between fights, Low mana and Big cooldowns (`docs/data.md`).
- **Window.lua** (rebuilt 4 November 2026 from `../ideas/primer-design.md`, direction A):
  `K.gameWindow` ("PrimerFrame") or `K.dialog`, `K.movable` (place in
  `PrimerSettings.places.window`, Escape closes), three `K.tabs`: **Overview**
  (the class in the narrator's voice, then a card: your road with the role's
  recommendation and its price, the other roles, what also works, the Hardcore
  lines), **Plan** (the stage's opening, the loop read from the top, between
  fights, low mana, big cooldowns: one line a row, `[n] icon name when`, the
  reason one toggle away ("Show the reasons", kept for the account) and in each
  row's tooltip; a row the character cannot press yet stays in its place, grey,
  with what it needs; at level 10 with no role, one card a role) and **Talents**
  (`Tree.lua`, the order beside the trees, a level slider, the next pick's reason).
  Over the tabs, on every one: a **header** (the build and class, role, level,
  Hardcore realm, talent group, one sentence on how the page was chosen, the
  next-pick chip) and a **strip** of fixed height for the one thing that needs the
  player (the level-10 question, Change role, a drift, a new stage), so nothing
  below it moves. What the page is for (`view.subjects`, per talent group) is
  frozen while the window is open: an event greys and lights the rows in place
  (the stage gives the list, never the character), moves a ring and a count, and
  swaps nothing. A role chosen sets its recommended build (`G.recommend`): the
  player is never asked which build. Scroll and tab survive an event. The
  events are the same as before (`PLAYER_ENTERING_WORLD`, `PLAYER_LEVEL_UP`,
  `SPELLS_CHANGED`, `LEARNED_SPELL_IN_SKILL_LINE`, `TRAINER_UPDATE`,
  `CHARACTER_POINTS_CHANGED`, `PLAYER_TALENT_UPDATE`, `TRAIT_CONFIG_UPDATED`,
  `ACTIVE_TALENT_GROUP_CHANGED`), each only asking for a look, a burst as one
  draw 0.3 seconds later. In a fight it reads nothing and says it waits. A
  draw is `pcall`-guarded (`broken`). One chat line at level 10, once a
  character (`PrimerChar.welcomed`), replaces the minimap glow. What each draw
  left is `ns.screen` (header, strip, plan lists, tree cells, overview): the
  sim reads that and presses the strip's buttons through it. `ns.toggle()`,
  `ns.open(tab)`.
- **Tree.lua**: the class's three trees from the data's `cells` (row 0 to 6,
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
