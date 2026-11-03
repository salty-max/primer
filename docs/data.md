# Primer's data

The guide's rules and words, and the facts check. Written by hand:
`content/<class>.json` (one file a class). Generated, never edited:
`addon/Primer/Guide_Classic.lua`, `Guide_Forever.lua`, `GuideText.lua`
(`bun scripts/guide.ts`, `--check` in `bun run check`).

## content/<class>.json

```
class  = { id (ChrClasses), key, token, name, text (the class's page), card }
build  = { id, key, name, role (damage, tank, heal), tree (a TalentTab id),
           games (["classic"]), checked (a date), intro, pathNote, split, dry,
           path = [step], stages = [stage] }
step   = { points [from, to], level [from, to], talent (rank 1's spell) or
           any ([spells], a choice), rank (it reaches), of (its ranks), why }
stage  = { from, to (levels), about, opening, rows = [row] }
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
