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
- **The phase flow (M3b)**, in Guide.lua and the top of the Play, Talents
  and Role pages: a character's phase is its state (`untalented` before level
  10, `choose` with points to spend and none spent, `spent`), kept apart from
  the builds, which are content. At `choose` with no role stored the Play tab
  asks once what to play (Damage, Tank, Heal, whichever the class has, or Not
  yet) in a quiet block and the minimap button glows, never a pop-up; a role
  chosen shows the builds that fit and the first three picks. From `spent` the
  build is the player's pick, else the build the points leave open: a build is
  reachable while the points outside its tree are no more than 20 of the 51
  (feasibility, not the tree with most points, `docs/inference.md`). Several
  open and no role chosen: the page asks which role, and says it is guessing.
  A pick the points can no longer reach is said once with three ways on (keep,
  follow, my own way); points that fit only another role's builds offer a
  switch, never silent; a dismissed note stays dismissed until the drift
  changes (`driftSeen`). Your own way (`freestyle`)
  has no picks and no notes. A role change on the Role tab re-filters at once
  and counts the points off the nearest build of the new role, and says a
  respec costs gold. Saved per talent group: `role`, `pickedBuild`,
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
  A click on a build there looks at it on the Role tab. **Roads** (`G.roads`,
  `G.pickRoad`): a build may have several orders for its points; the player never
  chooses one: the page advises the recommended road (the Hardcore road on a
  Hardcore realm), says why in a line, and recognises quietly a documented road
  the points follow, with no drift (`docs/inference.md`). A stage's plan may carry `alt`, another way to play it
  (a crowd, against one monster), under its own heading. `build.hardcore` lines
  show only on a Hardcore realm (`G.HARDCORE`).
- **The rotation plan** (`drawPlan`, `G.stepState`): a stage's `plan` shown as
  Opening, Loop, Between fights, Low mana and Big cooldowns (`docs/data.md`).
- **Window.lua**: `K.gameWindow` ("PrimerFrame") or `K.dialog`, the kit's book
  geometry (`K.BOOK_W` x `K.BOOK_H`, the builds on the left, the page on the
  right, no search), `K.movable` (place in `PrimerSettings.places.window`,
  Escape closes), `K.tabs` for **Play** (the stage's opening and priority: the
  game's slot for each spell, its name by id, the form and the moment, the
  reason, then the footer with the date it was checked), **Talents** (the
  build's talents in order with their real pictures, `rank/target`, the next
  pick and the points to spend) and **Role** (the player's switch, damage,
  tank or heal, for the roles the class has a build for, and what the build is
  for). Each page for the character as it is when it draws: on show, a click,
  a level up, a spell learned, a point spent or a change of talent group
  (`PLAYER_ENTERING_WORLD`, `PLAYER_LEVEL_UP`, `SPELLS_CHANGED`,
  `LEARNED_SPELL_IN_SKILL_LINE`, `TRAINER_UPDATE`, `CHARACTER_POINTS_CHANGED`,
  `PLAYER_TALENT_UPDATE`, `TRAIT_CONFIG_UPDATED`, `ACTIVE_TALENT_GROUP_CHANGED`:
  each only asks the window to look again, a burst as one draw 0.3 seconds
  later, an event a client lacks skipped and never raised). In a fight it reads
  nothing and says it waits, then draws. **Talent groups**: Era has one in
  practice, Forever two, asked of the game (`GetNumSpecGroups`,
  `GetActiveSpecGroup`: a client without them has one). What a character chose
  is kept per group (`PrimerChar.groups[n] = { build, role }`, `ns.choice(n)`).
  Play and Role follow the group in use (`ACTIVE_TALENT_GROUP_CHANGED` makes
  the window follow it), the Talents tab has a switch to look at the other
  group's talents and choose its build, absent with one group. The empty pages (Season of Discovery,
  no guide for the game, no guide for the class) are the house voice and never
  another game's or class's text. `ns.toggle()`, `ns.open(tab)`.
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
