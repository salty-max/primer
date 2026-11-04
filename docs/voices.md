# Primer's voice

The rules the writer and every reader of the guide keep. From the paper slice
(`../ideas/class-guide-warrior.md`, section 2, judged good by the user on
3 November 2026) and the plan (`../ideas/class-guide.md`, section 3). The
guide's words are `content/<class>.json`, never the generated `GuideText.lua`.

## The narrator

One narrator for every class: **the trainer who has watched you fail and wants
you to stop**. Never named, never "I" and never "we", always speaking to "you".

- **The instruction first, the flavour second.** A line says what to press,
  then why. A dry remark, if there is one, comes after both and could be cut
  without changing what the line asks of you.
- **The voice never changes the instruction.** The same spell, the same order,
  the same reason, in every voice. If a joke needs the instruction bent, the
  joke goes.
- **Every line has its reason**, and says when it stops being true. A line
  without a reason is cut.
- **Dry and kind, not clever.** One dry remark per build at most. No praise
  and no blame: a pull that went wrong was a pull.
- **Short.** A priority line is one sentence of instruction and one of reason,
  under 30 words together.
- **Never lore.** No names of people or places, no history, no gods.
- **Words.** British English (armour, grey, levelling), plain ASCII, no
  semicolons, no exclamation marks. Digits for levels, ranks and counts.
  Spell, talent and form names typed exactly as the game spells them (the
  generator checks the row's spell id against the game's name for it, and the
  window shows the game's own name by id beside the line). No "OP", no "meta", no "pro tip", no "DPS" (say damage),
  no "rotation" in a heading (say opening and priority).
- **The family's used-up devices stay out:** "Not X. Y." fragments, "Here is",
  "plainly", announced confessions ("to be honest"), a trailing ", which ..."
  quip on every line, endings that all land on a quip.
- **A build is a way, not the way.** Where players split, the page names both
  roads, picks one and prices the other. The footer on every build says it is a
  sensible way to play, that cooldowns and procs in a real fight change the
  order, and which client and day it was checked against (`checked`, `build`).

`scripts/guide.ts` refuses non-ASCII, a semicolon, an exclamation mark and the
banned words in any line (it cannot judge the rest: the cold read does).

## A class card

Five lines in the class's data (`content/<class>.json`, `class.card`): **cares
about**, **vocabulary**, **sounds like**, **never says**, **the test**. It is
vocabulary and a never-list, not a voice of its own (the paper slice's finding:
the cards change the words around an instruction and little else). It changes
the words, never the instruction.

The Warrior's: cares about rage, stance, the next swing and who the monster is
hitting. Never says mana, cast, spell, channel or anything soft. The test:
could it be said in the time it takes to press the button?

## What is the game's and what is ours

- The game's: every spell's, talent's and form's name (the lines type it as
  the game spells it, the window shows the game's own by id), the level a spell is learned at, a talent's tree, row and rank.
- Ours: the order, the reasons, the stance a button is pressed in and the
  situation it is pressed in (`when`), because the pinned tables carry neither
  (the paper slice, section 6). A stance is therefore written from play and
  marked in the data as such: **it is unchecked until the game has been asked**.
- Not stated anywhere: costs, cooldowns, cast times, durations. The tables lack
  them, so no line says a number the game could contradict.

## Reading it cold

A class is read cold by the `prose-reader` before the user reads it, and the
user reads every class before it ships (the plan, section 4): the generator
checks ids, not judgement.

## A plan line

A rotation plan's step (`docs/data.md`, "The rotation plan") is three clauses
in one line: when it applies (`if`), what to do (`say`, only when the spell's
name is not enough), why (`why`). Plain and imperative, the condition first and
the reason last, each one short clause (at most 14 words, no full stop: the
window adds it), no semicolons, no exclamation marks. "Whenever it is ready. It
is most of your damage." is the model. The loop's last line has no condition:
it is what you do when nothing above applies. A line never states a figure the
game's tables cannot back, and never changes what the spell is for to make a
joke. The voice is in the choice of words, never in a changed instruction.

## Where the voice is heard in the window (4 November 2026)

After the first game test ("the voice is not really present"): the voice is the
narrator's register and the class card's words in every line a player reads,
never at the cost of the instruction. It is in the Overview (`class.overview`),
in each plan line (the card's vocabulary: a paladin line says what is on you
before what to press, a mage line says when to stand still and uses cast, bolt,
range, slow, freeze, sheep), in the build's one dry remark under the loop, in the
level-10 prompt ("Pick what you will do most. You can change it later, and a
respec costs gold."), and in the notes (drift, open builds, looking). The
window's own labels (tab names, headings, the header line) stay plain.
