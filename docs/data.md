# Primer's data

The guide's rules and words, and the facts check. Written by hand:
`content/<game>/<class>.json` (one file a class a game: `content/classic/paladin.json`, `content/forever/warrior.json`, Forever's first, written 5 November 2026: F0 to F3 of `../ideas/class-guide.md`, `content/forever/mage.json`, its second, F4, `content/forever/rogue.json`, its third, `content/forever/warlock.json`, its fourth, ids 15 to 17, and `content/forever/shaman.json`, its fifth, ids 18 to 20, and `content/forever/hunter.json`, its sixth, ids 21 to 23, and `content/forever/priest.json`, its seventh, ids 24 to 26, and `content/forever/paladin.json`, its eighth, ids 6 to 8, the same as Era's Paladin so a character keeps its pick, and `content/forever/druid.json`, its ninth and last class, ids 27 to 30: Feral as a cat, Feral as a bear, Balance and Restoration, 5 November 2026). Generated, never edited:
`addon/Primer/Guide_Classic.lua`, `Guide_Forever.lua`, `GuideText.lua`
(`bun scripts/guide.ts`, `--check` in `bun run check`).

## content/<game>/<class>.json

`variant` is for two builds on one tree (a Feral Druid as a cat or as a bear, Forever 5 November 2026): both are named as the game names the tree, so the one word after it ("cat", "bear") tells them apart wherever a build is named (`G.name`: "Feral Combat (cat)"). A class with one build a tree has none.

A game's own file: Era's advice and Forever's never share a line, so a build has no `games` list, the folder is the game. `class.roles` gives the one build the page advises for each role the class has (`{ "damage": { "build": "paladin-retribution", "reason": "..." } }`, a reason of 30 words at most, a role with several builds names the one, the others are "also works"). Every plan line holds to the line budget (4 November 2026 rework, enforced for every build): name and condition together at most 56 characters, a reason at most 60, what one line of the window holds and the client never cuts. A stage's opening has at most 5 steps and its loop at most 6, each printed with its reason under it; the loop's rarest lines go to `plan.rarely` (steps like a loop's, each with a condition, drawn as a Rarely section, rows like the loop's).

```
class  = { id (ChrClasses), key, token, name, text (the class's page), card,
           advice (optional) = [ { role, say } ] }
build  = { id, key, name, variant (optional), role (damage, tank, heal), tree (a TalentTab id),
           games (["classic"]), checked (a date), intro, pathNote, split, dry,
           path = [step], stages = [stage] }
step   = { points [from, to], level [from, to], talent (rank 1's spell) or
           any ([spells], a choice), rank (it reaches), of (its ranks), why }
stage  = { from, to (levels), phase (untalented, choose, spent: optional), about,
           opening, rows = [row] }
row    = { spell (rank 1), name, talentSpell (the row is a talent),
           need = { level, stance [..], talents [spell ids taken first],
                    when [..] }, say }
```

A build's `games` says where it is written: a Forever build is its own text,
checked against Forever's tables (the plan: never inherited from Era). Classic is written for
the Warrior, Paladin and Mage (nine builds, Warrior Arms 1, Fury 2, Protection 3), Forever for the
Warrior, the Mage, the Rogue, the Warlock, the Shaman, the Hunter, the Priest and the Paladin (Era has no Rogue, Warlock, Shaman, Hunter or Priest file: the Warrior's, Mage's and Paladin's ids and keys are the same in their own files, so a character keeps its pick across the
two games' separate guides). A build id never changes and is never reused: a character keeps
it (`saved-ids.json`, `bun run ids` in the check).

`when` is a closed list (`WHEN` in `scripts/guide.ts`): a situation the player
reads off the screen, shown as advice and never enforced. `stance` is written
from play: the tables do not carry it.

## Adding a class (what a new class's content is)

One file, `content/classic/<key>.json` (lower-case class key: `paladin.json`, `mage.json`),
the same shape as `content/classic/warrior.json`, which is the model to copy. Nothing
else is edited: the generator reads every file in `content/<game>/`, writes the class
into `Guide_Classic.lua` or `Guide_Forever.lua`, whichever folder it is in, its words into `GuideText.lua`, and the window picks it up by the
class token. No per-class code anywhere. In the file:

- `class`: `id` (ChrClasses: Warrior 1, Paladin 2, Hunter 3, Rogue 4, Priest 5,
  Shaman 7, Mage 8, Warlock 9, Druid 11), `key`, `token` (`PALADIN`, as
  `UnitClass` returns it), `name`, `text` (the class's page), `card` (the five
  voice lines), and optionally `advice`: `[ { "role": "damage", "say": "..." } ]`,
  one line a role added to the level-10 advice (without it the advice is the
  role's builds and the first three picks of its first build, each with the
  writer's own reason).
- `builds`: each `id` (never changed or reused, `saved-ids.json`), `key`
  (`paladin-retribution`), `name` (the tree's English name, checked against the
  game's), `role`, `tree` (the TalentTab id), `games` (`["classic"]`),
  `checked`, `intro`, `pathNote`, optional `split` (the rest of a sentence that
  follows "Where players split:") and `dry`, `path` and `stages`.
- `path`: steps covering points 1 to 51 in order (point N at level N + 9, so
  `level` is `points` plus 9), each `talent` (rank 1's spell id) or `any` (a
  choice among spells of the same tree, one rank count), `rank` it reaches,
  `why`. The build's own tree holds at least 31 of the 51. A path that crosses
  trees is a hybrid and is recognised from the path itself: the window reads
  the points a build would have in each tree from it, so nothing is declared
  twice.
- `stages`: level brackets one after the other to level 60 (a build may start
  late), each `about`, `opening`, optional `phase`, `rows`. A row is `spell`
  (rank 1's id), `name` (the game's name, checked), `say` (instruction then
  reason, under 30 words) and `need`: `level` (the data's, checked), optional
  `stance` (from `STANCES`, narrowing what the client's table allows),
  `talents` (talent spell ids taken first) and `when` (from `WHEN`).
- A closed list grows in `scripts/guide.ts` with its words: a new `when` key is
  added to `WHEN` and to `WHEN_WORDS` (its plain phrase), a new form to
  `STANCES`, `STANCE_FORMS` (the client's form number less one) and
  `STANCE_SPELLS` (the spell that is the form), so the check and the window
  know it. Facts are checked per game on every run (`bun run guide`).

Paladin (6, 7, 8) and Mage (9, 10, 11) are written (4 November 2026, from
`../ideas/class-guide-paladin-mage.md`, which is the paper the content is read
from). Each build opens with a stage 1 to 9 with `phase: "untalented"`, the
class's kit, the same in its three builds. A wand's Shoot is no spell of the
class's book, so no row carries it. The Mage has one `advice` line, for damage.

## The rotation plan (a stage's `plan`)

A stage shows either its priority `rows` (the first format, the Warrior's builds
until they are re-authored) or a `plan`, which is what a player reads to know
what to press and in which order. Retribution and Frost are written in it
(4 November 2026, the user's call after the first game test: "what to do in each
order, not just a list of spells and their explanation").

```
stage.plan = {
  opening: [step],           -- numbered, in order, before the pull
  loop:    [step],           -- numbered, read from the top: the first line that applies, then again
  between: [step],           -- between fights
  low:     [step],           -- when the resource runs low
  big:     { spells: [{ spell, name }], say }   -- the big cooldowns, one line on when
}
step = { spell, name }  or  { text },   -- a spell (rank 1's id, its name checked) or a line of text alone
       if,    -- when it applies, a clause ("whenever it is ready"): none on the last line of the loop
       say,   -- what to do, only when the spell's name is not enough
       why,   -- one short clause
       need:  { level, talents, stance },  talentSpell    -- as a row's
```

What the window does with it: the lists in that order under "Opening", "Loop",
"Between fights", "Low mana" and "Big cooldowns"; each step the game's own
icon and name by id, then one line (`if`, `say`, `why`, each a clause, each
with its full stop added). The last line of the loop reads "If nothing above
applies". A step the character cannot press yet stays in its place, grey, and
says why on its line: the level it comes at, the talent it needs, or that it is
not in the book yet. So the plan grows as the character levels and never shows
a step as ready that is not.

What the check holds a plan to (`scripts/guide.ts`, `checkPlan`):

- every spell is checked as a row's is (the game's name, the class's book or a
  talent's rank 1 with `talentSpell`, the level the data gives and at or under
  the stage's top, the form against the client's table, the talents on the path);
  `Attack` (6603) is the one spell every character has that no book lists, its
  picture the action bar's `Ability_MeleeDamage` (the client's own icon for it
  is a developer's photo)
- an `opening` and a `loop` exist, the last line of the loop has no `if` and every
  other line of the loop, of `between` and of `low` has one, every step has a `why`
- an `if`, a `say` or a `why` is a clause: no full stop at its end, at most 14 words
- the words are plain ASCII with no semicolon and no exclamation mark
- figures: a cost, a cooldown or a duration is written only where the data backs
  it (the tables give a figure per spell, and a rank or a talent can change it:
  the first two builds state none). A stance comes from the client's table.

House voice for a plan line (`docs/voices.md` holds the rest): plain, imperative,
the condition first and the reason last, one short clause each, no semicolons,
digits for numbers, never lore, never a figure the tables cannot back. The
instruction is the spell's name, so `say` is for what the name does not tell.

## The class overview, roads, the other way to play, Hardcore, sources

- `class.overview = { who, good, bad, resource, levelling, ten }`: the Overview
  tab, the class in general in the narrator's voice (who it is and how it plays,
  what it is good and bad at, its resource in plain words, levelling in two or
  three sentences, what to do at level 10). One screen, short. Optional: a class
  without one shows its `text` and its builds. Each build adds `line`, one line
  for the overview (none: the first sentence of its `intro`).
- `build.roads`: another order of the same points for the same build (the same
  role and tree). `path` is the first road (`roadId`; `roadName` and `roads[].name` are optional and shown nowhere yet); `roads` holds the
  others, each `{ id, name, path }` with its own whys. Each path is checked whole
  (51 points, point N at level N + 9, the tree's rows, prerequisites, the own tree's
  31). A row's talents must be taken by every road by the stage's top. The player
  never chooses a road: **we recommend one** (`recommended`, a road id), from the
  research (`ideas/class-guide-research/`: which roads most guides prefer for the
  current Era patch; where guides split about evenly, the safer or more reliable
  one), and `roadReason` says why and the price of the other in one plain sentence
  ("Most guides take this road. The other road trades X for Y."). `hardcoreRoad`
  and `hardcoreReason` give the road for a Hardcore realm (`Enum.SeasonID.Hardcore`)
  where the research gives one: used without asking and named in the header
  ("Hardcore realm: this is the safer road."). The other roads (`alsoRecognised`, by
  default every other road) stay in the data only to be recognised: when the points
  clearly follow one, the page says quietly "These points follow the other way to
  this build. It reaches the same place." and keeps advising along that road's path
  from where the character is, with no drift and no nag. The road in view is fixed
  while the window is open, like the build.
- `stage.plan.alt = { name, say, opening?, loop, between?, low? }`: another way to
  play the same stage with its own lists, shown under its name ("A crowd of
  monsters"), `say` one clause on when it is for.
- `build.hardcore = [line]`: lines for a Hardcore realm (Enum.SeasonID.Hardcore,
  `C_Seasons`), shown under "Hardcore" after the plan and nowhere else.
- `build.sources = [{ label, url, read }]`: where its facts were read, never
  shown, listed in `docs/sources.md`.

## The facts check (every run of scripts/guide.ts)

Against each game's own database (wow-data's `classic.db` / `forever.db`, the
`talent`, `talent_prereq`, `class_spell` (its `level` is `spell_level`'s) and `name` tables:
`../wow-data/docs/class-guide.md` says what they hold and where they are weak):

- every row's spell is in the game's data, with the name the content gives, in
  the class's book (or a talent's rank 1) and with a level, at or under the
  stage's top; the level the content gives is the data's, and the file carries
  the data's
- every talent id is in the talent table for that class, the rank is at most its
  ranks, the points of a step are the ranks it buys, point N is at level N + 9,
  the tree holds the points the talent asks and its prerequisite is at full
  rank, the path spends 51 points, the build's tree holds at least 31 of them and
  is named as the game names it, a talent a row needs is on the path by the
  stage's top, a spell has one list of stances in a build, the stages follow each
  other (a build may start late: Protection at 10) and end at 60
- every line is plain ASCII with no semicolon and no exclamation mark

It fails the daily `game-data.yml` before its pull request when a patch moves
a spell or a talent.

Both games share one `GuideText.lua`, so Forever's words are keyed under `forever.` (`KEYNS` in
`scripts/guide.ts`: `forever.warrior-arms.p1`), Classic's keys unchanged. The path check reads a talent taken
in several steps (Deflection, Improved Slam) as taken at its first point.

## The facts lock (facts.lock.json)

Per game and build, every fact the build read: a spell's name, level, forms and family, a talent's
cell (tree, row, column), ranks, points asked, first level and prerequisites, a tree's
name. The run compares what it reads with the lock and **fails naming the build and the
fact** ("classic mage-frost: spell 116 (Frostbolt) level: 6 became 4"), in `--check` and in
the daily job's plain run alike. A build with no entry fails too. Only a person clears it:
read the fact, then `bun scripts/guide.ts --stamp <game> <build key | all>`, which writes
that build's entry again (with the day, and the client build it was read at), saying each fact it accepts and still failing on a build it does not stamp. Every class's whole trees are locked too (`cells:<class>`), since the Talents tab draws each cell. The Lua still carries the current pin's build and the content's `checked`, not the lock's stamp: showing the stamp in the Plan's footer is M-B. A lock that
never fails would mean the check is wrong: `scripts/facts.test.ts` changes a fact and
expects the red (`bun test scripts`, in `check:ci`).

## The road importer (scripts/roads.ts)

A draft maker, never a pipeline: `bun scripts/roads.ts classic paladin Retribution --from
../ideas/class-guide-research/paladin-retribution.md [--table N] [--out draft.json]` reads one
order table of a research file (Levels, Points, Talent) and prints a `path` with every `why`
empty. Each name is resolved to one talent of the class in that game's data (no match, two
matches, or an id beside it that is not that talent: listed, not guessed), and the order is
walked as the generator walks a path (51 points in sequence, point N at level N + 9, ranks,
the tree's gates, prerequisites, 31 in the build's tree). It never writes over a file (`--out`
refuses an existing one) and never reads or writes authored content: a person reads the draft
against the research once, fills the `why`s and pastes it in. Era's Retribution Icy Veins table
comes out identical to the authored path. A table with no levels (Wowhead's tier-by-tier prose)
is refused: that order is written by hand and marked `source: prose`. A Forever talent's `node_id` is wow-data's inferred
mapping (its doc, "Where each source is weak"): not used until M6.

## What it found on the first run (3 November 2026)

The paper slice had two slips the check caught. A Sweeping Strikes row without
its talent mark, and the Protection path's Improved Charge, which asks 5 points
in Arms when only 3 were spent. The second one was changed to Deflection 2/5
(it opens the same row, and a tank wants the parry), the rest of the path as it
was: a prose change for the writer to confirm.

## What the generator adds for the window

`cells` in `Guide_<game>.lua`: every talent of the classes written, cell by cell (class, spell, id, tab, row 0 to 6 and col 0 to 3 as the game numbers them, max, req, pre), which the Talents tab draws the trees from. Forever's file says `inferred = true` (its rows, columns and prerequisites are inferred from the trait engine). `roles` on a class: the recommended build of each role (`build` id, `why` a word key).

The stances are checked against the client's own `spell_info` (its shapeshift mask): a form the spell cannot be pressed in fails the check, and a spell the table limits to forms the writer left unsaid takes the table's (Hamstring, Sweeping Strikes). The writer may narrow a spell several forms allow, never widen it. A stance the writer gives a spell the table limits to no form is the writer's alone: the generator prints a `note:` line for it and keeps it (Death Wish says Berserker, the table says any form).

Per game: `talents[spell] = { id, tab, max }` for every talent a build names (the
window finds a talent through the game's talent call by its id), `stances[key]`
(the spell that is the form, its name checked against the game's) and the
(both in `Guide_<game>.lua`) and the words `when.<key>` (the situation each tag
stands for, in `GuideText.lua`).

## The rules' shape for the window (M3, built in Guide.lua)

A row shows if its facts are true now: the character's level is at least
`level`, `talent` and `talents` are taken (`C_SpecializationInfo` on Era, the
probe's open question), `stance` is the form it is pressed in. `when` is only
text. The page for a level 12 warrior is shorter, never wrong.

A step may be a line of text alone where one line stands for several spells (the opening's "A seal": Command with a slow weapon, else Righteousness). It has no icon of its own and no grey state, so use it only where the loop below names the spells by id.

A stage still written as rows (the older form: Warrior, and the stages of other builds not yet re-authored as a plan) is drawn as a loop with its reasons under it but is not held to the step budget or the 56 characters: it is exempt until its pass (M-C), and the sim says so (`screen.legacy`).

Every spell of a step or row carries `family = { ids }` when the class's book holds more than one id under its name (the game gives each rank its own id and may report only the highest learned): the window counts the spell known when any of them is in the book (`Reader.known`). Season of Discovery runes are left out.

Every step of a talent path (a build's `path` and each of its `roads`) has a `why` of its own: what this talent does for this build, one or two sentences in the narrator's voice, at most 170 characters (three lines of the Talents tab's card), never empty and never about "this road". `scripts/guide.ts` fails on any that is, and the sim reads every road.

A step may stand for the best of a few spells (an armour that gets better): `spell` is the one every character has, `best` lists the ids best first and ends on that spell (`{ "spell": 168, "name": "Frost Armor", "best": [7302, 168], ... }`). The window shows the best one the character has now, its own icon and name, and the reason says the alternative. A spell the class is given with no trainer and no class-book row (Shoot, the wand, 5019, as Attack is) goes in `COMMON_SPELLS` in `scripts/guide.ts`: it counts as granted, always ready, with its icon named there. The check fails a step whose spell has no picture in the data, and prints a `note:` for the plan lines that name no spell (Sit and drink, Keep swinging: actions, not spells) so none is a family of alternatives by accident. A pick's `why` fits any of the ranks the step covers (it is read at each of them), so it says nothing about "the first" or "two points".
