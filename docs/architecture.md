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
- **Forever's talents (5 November 2026, `R.foreverTalents`)**: Forever has no
  per-tab `GetTalentInfo`, its talents are `C_Traits` nodes, read the way
  Blizzard's own frame does (`bun ../wow-data/bin/ui.ts find GetTreeNodes`):
  `C_ClassTalents.GetActiveConfigID`, `C_Traits.GetConfigInfo(config).treeIDs[1]`,
  `GetTreeNodes`, `GetNodeInfo` (`currentRank`, `ranksPurchased`,
  `activeEntry.entryID`), `GetEntryInfo` then `GetDefinitionInfo`, whose
  `spellID` is matched to the data's `cells` (rank 1's spell, the cell's id), so
  the rest of the guide sees the same `byId`, `points` and `total` as on Era.
  A tree's place is its order by id among the class's three. The points to
  spend are the tree currency's `quantity` (`C_Traits.GetTreeCurrencyInfo`),
  not the level's, so the cap does not matter; `G.budget()` (where the longest
  path ends) replaces Era's 51. Nothing in the documentation flags these
  returns secret, yet every value is checked and a node that raises is skipped
  (`safe`), so a page shows less and never an error. **Not tried in the game**:
  that `GetActiveConfigID` answers on a class with no specialisation, that a
  definition's spell is the cell's, that `treeIDs[1]` holds the three trees.
  No config at level 10 or more makes the reader blind (the page says it
  cannot read); below it the character just has nothing. `/primer debug` reads
  again and prints the config, the tree, the nodes, those with ranks, those
  matched to the guide, the points spent and to spend (`R.probe`).
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
- **Forever asks the spec (5 November 2026, the user's call)**: on Forever Blizzard
  says every spec is viable, so the choice at level 10 is the spec, and the role
  follows from it (Paladin: Holy heals, Protection tanks, Retribution deals damage;
  the Mage's three specs all deal damage). Specs and roles are different things, so
  the role is shown beside each spec and is never a second question. Era is frozen
  and asks the role exactly as before. On Forever a spec is a build (one build a
  tree), so nothing is renamed in the content and no build id moves.
  - *The question* (`G.specFirst()`, true when the data's game is Forever): with
    points to spend, none spent, no spec chosen and more than one build in the
    class, the Level page asks once "Which spec do you want to play?", one line a
    spec (its name, its role, and the build's own `line` from the content, never
    invented here) and a Not yet button, said once in chat like the role question
    (no pop-up, no glow). A spec chosen is `pickBuild`: it stores the build and its
    role, so the page follows it. A class with one build has nothing to ask.
  - *Once points are spent* the build follows the points (feasibility,
    `docs/inference.md`), a pick is kept, a drift is said. When the open specs
    span two roles and none was picked, the spec is asked (never the role), and
    "(yours)" is not put on a spec nobody chose.
  - *The Class tab* lists the specs as the choices, a row each (the spec's name,
    then its role, "(yours)" on the chosen one, and the build's line), and under
    them a button "Play <spec>" for each other spec once level 10 is reached, so
    the choice can be changed. The "Also works" roads stay a build's own and are
    not on this tab.
  - *The header and the Class tab* say the class until a spec is chosen or points
    are spent, then the spec (`hasBuildOf`: the one-role clause is Era's, as the
    Mage's three damage specs are three guides, not one).
  - *Change role* becomes *Change spec* on Forever, listing the other specs.
  - *A stored role* (`PrimerChar` from before): on Forever, a group with a stored
    `role` and no valid `pickedBuild` takes that role's recommended spec once
    (`G.migrate`, run when the page draws and when the welcome is asked, only
    before points are spent: after that the points decide, as for any role); the
    stored role is kept, never cleared, and no build id is touched.
  - *Two roles on one spec* (built 5 November 2026, the Feral Druid): the role at the level cap decides a build, so a spec that can serve two roles is two builds on its one tree, each with its own `role` and a `variant` ("cat", "bear") that `G.name` puts after the tree's name, so the spec question, the Class tab and the header read "Feral Combat (cat)" and "Feral Combat (bear)". The player picks the spec and the role follows, never a second question. The points cannot tell the two apart, so a Feral Druid with no pick has both open, they span two roles and the spec is asked. Nothing else changed: reachability is per tree and the pick is kept.
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
  page. Three tabs: **Level**, **Talents** and **Class**. The left list is the spine: the levels from the
  character's to 40 at which something arrives (a pick, or a spell the build's
  plans use), "You are here" at the character's own, the level shown picked
  out. The page is the selected level's: the **pick**, the **opening** (at most 5 steps), the **loop** (at most 6) and a "Rarely" section of the loop's rarest lines, rows like the others. Every step is a numbered row, its icon, its name and condition on one line and **its reason printed under it** in the dimmer body text, wrapped to the page, the row as tall as both, with room between rows and sections (`fillRow`). The page scrolls when they are longer than the window; nothing is cut. A row the character cannot press yet is grey in its place with what it needs, its own picture in grey at 0.85 of its brightness (`ns.DIM`, one place: a dark icon dimmed lower is a smudge). A row that stands for the best of a few spells (`best`) shows the one the character has. The facts are the count beside the portrait (the build, the level and
  the realm or the group: three at most) and the page's subtitle is how the road
  was chosen. Selecting a level is **looking**: "Looking at level 38." and "Back to
  my level", and nothing the page is for changes (`view.looking`); the level-10
  question, a drift or a role change is one block that replaces the page ("one idea
  a screen"), asked once (`view.putOff`). What the page is for (`view.subjects`, per
  talent group) is frozen while the window is open. A role chosen sets its
  recommended build (`G.recommend`). **Nothing is cut with an ellipsis**: a line
  that does not fit is shortened in the content (the check holds every plan line
  to 56 characters, a reason to 60, an opening to 5 steps and a loop to 6), rows
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
  fights, low mana and the big cooldowns are not on the page yet (a later pass).
- **The Talents tab** (4 November 2026): a tab over both panels (`whole`, a `K.panel` as the kit's deeds tabs make), no list: the three trees of `Tree.lua` take the whole width, and under them one block (`K.panel`, the width of the trees, `ns.FOOTER_H` high, a clear gap above it). On its left the stepper as one group (the kit's buttons `<` and `>` around "Level 17"), which steps one level at a time from the first point's level to the last the road has, back below the character's own too (the Level tab's list is capped at 40, this is not). On its right the next pick as a small card: the talent's icon (a `K.slot` of 36), a caption ("Next pick", or in gold "Looking at level N." with Back to my level at the card's right when looking), the talent and its rank ("Spiritual Focus, rank 3 of 5"), and the pick's own reason under it (its path step's `why`, wrapped, up to three lines, never the road's generic line). Stepping only looks (`view.looking`, shared with the Level tab); the pick and its reason follow the level looked at. A pending question (the level-10 role) is answered on the Level tab, the Talents tab says so. No talent-group switch yet (Era has one group).
- **The Class tab** (4 November 2026): a tab over both panels with one `K.page`: the class in the narrator's voice from the content's `overview` (who, good at, bad at, the resource, levelling: sentences, not lists, because that is what the content has; a class with no overview, the Warrior so far, shows its `text` alone), then "Builds": a row a role with the build advised for it (the one the page is on marked "(yours)"), the role's reason, and "Also works" in dim text for the role's other builds, and on a Hardcore realm the page's build's short Hardcore lines. It reads the frozen subject, so an event changes nothing it shows. The "at level 10" text of the overview is not on the page (the Level tab asks that question itself).
- **Tree.lua**: the class's three trees from the data's `cells` (row 0 to 6,
  column 0 to 3 as the game numbers them), `K.slot` cells of 38 pixels, 12 apart across and 8 down (each tree has its own 28 pixel gutter for the gates' numbers, three trees 30 apart are 708 pixels wide, the page holds about 724; the game's own cells are 37). A talent off the road is desaturated and dimmed to 0.65 (the value of Blizzard's Vanilla/TalentFrameBase.lua line 131 for a talent that cannot be had), one on the road or taken is in full colour, the road's
  numbers (the order it first takes each talent: they belong to the road), taken
  lit gold, on the road not yet blue, the next pick ringed, row gates at the
  left, straight prerequisite lines (the two diagonal ones are left out), the
  game's own tooltip (`GameTooltip:SetTalent(talentID, false, false, group)`,
  as Era's own talent window calls it) plus one line of ours. Forever has no
  tree window yet (F2 of the plan, the Forever-first order in `../ideas/class-guide.md`).
- **Minimap.lua**: the kit's `K.minimapButton`, named `PrimerMinimapButton`
  (Keyring finds the family's buttons by name), at `K.MINIMAP_ANGLES.Primer`
  (90 degrees, the top: at least 25 from every other place and clear of Classic
  Era's zoom buttons, which the kit's table says).
- **The logo** (5 November 2026): `addon/Primer/Media/Logo.tga`, 256 square,
  32-bit with rounded corners (alpha, as Yonder's), made from
  `assets/logo-1024.png` with magick. It is `ns.ICON` (the minimap button,
  cropped, the window's portrait, a spell's stand-in) and both TOCs'
  `IconTexture`. The PNG masters stay in `assets/`, never in the package.
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

`docs/testing.md` is the current account (the strict game, the matrix, the secret values, what
they cannot cover). What follows is the older sim.

`addon/test/game.lua` is the kit's game (`wowmock.lua`, a copy) plus the
registered events and what the guide reads (a spell book, the talent call as
the Era probe answered it, the season, names and pictures by id); `sim.lua`
plays a login, the slash command, the tabs, the button, the data (every key
has its word, every row its facts), the rules over characters (filters, stage,
role, build, steps, the per-game and season pages) and the three pages as the
window draws them, on Classic Era and with `FOREVER=1`. A game test (`wow-game-test`) shows what these cannot: the
look of the window, the portrait, the tabs under the frame, the button on the
real minimap.
