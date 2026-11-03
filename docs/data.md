# Primer's data

The guide's rules and words, and the facts check. Written by hand:
`content/<class>.json` (one file a class). Generated, never edited:
`addon/Primer/Guide_Classic.lua`, `Guide_Forever.lua`, `GuideText.lua`
(`bun scripts/guide.ts`, `--check` in `bun run check`).

## content/<class>.json

```
class  = { id (ChrClasses), key, token, name, text (the class's page), card,
           advice (optional) = [ { role, say } ] }
build  = { id, key, name, role (damage, tank, heal), tree (a TalentTab id),
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
checked against Forever's tables (the plan: never inherited from Era). Only
`classic` is written so far: the Warrior's three builds, Arms (1), Fury (2) and
Protection (3). A build id never changes and is never reused: a character keeps
it (`saved-ids.json`, `bun run ids` in the check).

`when` is a closed list (`WHEN` in `scripts/guide.ts`): a situation the player
reads off the screen, shown as advice and never enforced. `stance` is written
from play: the tables do not carry it.

## Adding a class (what a new class's content is)

One file, `content/<key>.json` (lower-case class key: `paladin.json`, `mage.json`),
the same shape as `content/warrior.json`, which is the model to copy. Nothing
else is edited: the generator reads every file in `content/`, writes the class
into `Guide_Classic.lua` (and `Guide_Forever.lua` for a build whose `games`
names it), its words into `GuideText.lua`, and the window picks it up by the
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
a spell or a talent. A Forever talent's `node_id` is wow-data's inferred
mapping (its doc, "Where each source is weak"): not used until M6.

## What it found on the first run (3 November 2026)

The paper slice had two slips the check caught. A Sweeping Strikes row without
its talent mark, and the Protection path's Improved Charge, which asks 5 points
in Arms when only 3 were spent. The second one was changed to Deflection 2/5
(it opens the same row, and a tank wants the parry), the rest of the path as it
was: a prose change for the writer to confirm.

## What the generator adds for the window

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
