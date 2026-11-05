# Where the guide's facts were read

Every priority line and talent step of a build can be traced to the pages below.
Written 4 November 2026 from `content/<class>.json` (`sources`, each a label, a
url and the day it was read) and the research in `../ideas/class-guide-research/`
(one file a build, with the disagreements and the names checked against
wow-data). Nothing is copied: the words are ours and only facts are used.
Era 1.15.x only; no Wrath, Cataclysm, retail or Season of Discovery page.

## paladin-retribution

- Icy Veins, Retribution Paladin levelling talents (Abide, updated 2026-07-18): <https://www.icy-veins.com/wow-classic/retribution-paladin-leveling-talent-build-from-1-to-60> (read 2026-11-04)
- Wowhead, Retribution Paladin levelling tips (Impakt, updated 2024-11-20): <https://www.wowhead.com/classic/guide/classes/paladin/retribution/leveling-tips> (read 2026-11-04)
- Wowhead, Hardcore Paladin (Calamityhc, updated 2024-11-20): the Holy-first road is its New Player build: <https://www.wowhead.com/classic/guide/classes/paladin/hardcore-leveling-tips> (read 2026-11-04)
- Warcraft Tavern, Paladin levelling: <https://www.warcrafttavern.com/wow-classic/guides/paladin-leveling-guide/> (read 2026-11-04)
- NoobToBoss, Paladin Retribution levelling: <https://noobtoboss.com/wow-classic-paladin-retribution-leveling-guide/> (read 2026-11-04)
- Icy Veins, Hardcore Paladin overview (Sellin, 2023-05-21): <https://www.icy-veins.com/wow-classic/hardcore-paladin-class-overview> (read 2026-11-04)
- Hardcore Helper, Paladin (updated 2026-07-27): <https://www.hardcorehelper.com/guides/paladin-wow-classic-hardcore> (read 2026-11-04)
- Blizzard forum, Paladin weapon speed (2019-09-28): <https://us.forums.blizzard.com/en/wow/t/paladin-weapon-speed/315363> (read 2026-11-04)

## mage-frost

- Icy Veins, single-target Frost Mage levelling talents (Farmerfarms, updated 2026-07-18): <https://www.icy-veins.com/wow-classic/single-target-frost-mage-leveling-talent-build-from-1-to-60> (read 2026-11-04)
- Icy Veins, AoE grinding Frost Mage (same author and date): <https://www.icy-veins.com/wow-classic/aoe-grinding-frost-mage-leveling-talent-build-from-1-to-60> (read 2026-11-04)
- Wowhead, Frost Mage levelling tips (Woah, updated 2024-11-18): <https://www.wowhead.com/classic/guide/classes/mage/frost/leveling-tips> (read 2026-11-04)
- Wowhead, Hardcore Mage (durtyrandy24, updated 2024-11-20): <https://www.wowhead.com/classic/guide/classes/mage/hardcore-leveling-tips> (read 2026-11-04)
- Blizzard forum, Frost single target against AoE (2024-11-28): <https://us.forums.blizzard.com/en/wow/t/frost-mage-single-target-vs-aoe-for-leveling/2019340> (read 2026-11-04)
- NoobToBoss, Frost Mage levelling: <https://noobtoboss.com/wow-classic-mage-frost-leveling-guide/> (read 2026-11-04)
- Warcraft Tavern, Mage levelling: <https://www.warcrafttavern.com/wow-classic/guides/mage-leveling-guide/> (read 2026-11-04)
- Icy Veins, Hardcore Mage overview (Abide, 2023-06-09): <https://www.icy-veins.com/wow-classic/hardcore-mage-class-overview> (read 2026-11-04)
- Hardcore Helper, Mage (updated 2026-07-27): <https://www.hardcorehelper.com/guides/mage-wow-classic-hardcore> (read 2026-11-04)

## What the research changed (4 November 2026)

- **Retribution has two roads for the first points** (`roads` in the data): Retribution first (Icy Veins) and Holy first (Wowhead's Hardcore New Player build: Divine Intellect 5, Spiritual Focus 5 by level 19, then about 30 in Retribution from 20, Seal of Command at 30, Protection last). Neither is a drift. The order of the Holy-first road is the author's own, read from the build's calculator link on 4 November 2026; no player's write-up of it was found. Its 51st point is free (Repentance is written).
- **Frost opens with Elemental Precision** (3 points at 10), then Improved Frostbolt, Frostbite, Ice Shards (in every single-target build), Improved Frost Nova, Shatter, Ice Block, Cold Snap, Frost Channeling, Arctic Reach, then the Arcane block (Focus 3, Concentration 5, Wand Specialization, Arcane Meditation). Magic Absorption and Improved Cone of Cold are gone: no single-target guide takes them. The path is Icy Veins' single-target order. Winter's Chill is a named disagreement (two guides take it, two do not), in the build's `split` line.
- **Frost's loop has the Shatter combo** (Frost Nova, then Frostbolt on the frozen monster) from the level Shatter is taken, and the crowd style (Frost Nova, Blizzard, Cone of Cold, Arcane Explosion) is its own list under "A crowd of monsters", for a player with Improved Blizzard, which the single-target road does not take.
- **The seal is chosen by weapon speed**: Seal of Command with a weapon slower than 3.5 seconds, Righteousness with a faster one (Icy Veins, Warcraft Tavern, the Blizzard forum agree on 3.5; Wowhead's pages say 3.2 and 3.8). One honest condition, the sources named here.
- **Hardcore lines** (`hardcore` in the data, shown only on a Hardcore realm): never five pulls without cooldowns, Divine Shield from 34 as the escape, a shield to run in, never out of mana in a fight; Frost: cast from range, Frost Nova then Blink before bandaging, Polymorph the second monster, Ice Block a last resort.
- **Seal of Command, Consecration, Sanctity Aura, Repentance, Ice Barrier, Ice Block and Cold Snap are talents** on Era: their steps carry `talentSpell`. Consecration is not in the plan: only the Retribution-first road takes it, at 51.
- **Names the weaker guides get wrong never enter the data**: Ice Floes (not an Era talent), Parry for Deflection, Frostbolt 5 for Improved Frostbolt, Cold Snap 2 (one rank), Ice Barrier ranks.
- Not applied: Mana Shield (guides disagree, left out of the big cooldowns), Dampen Magic (no step), the weapon list by dungeon (not a priority), professions.

## What is missing

- **Reddit and Discord were not reachable** from the research tools (refused or
  empty), so those voices are missing here. The Wowhead comment sections and the
  Blizzard forum threads stand in as the community's voice. No real player's
  write-up of the Holy-first order was found: its evidence is the author's own
  calculator link on Wowhead's Hardcore page.
- **Wowhead's Hardcore Experienced build** for the Retribution Paladin
  (Improved Blessing of Might 5 and Deflection 5 first, Seal of Command at 20,
  Vengeance 35 to 39, Repentance 40, Redoubt 41 to 45, Precision 46 to 48, Divine
  Intellect 49 to 53, Spiritual Focus 54 to 58) is not a road of its own here: its
  last two points are not in the link, and the first road covers the same shape
  (Retribution first). Seal of Command is taken at 20, 22 or 30 depending on the
  road: a range, and every plan line that needs it waits for the talent, not a level.
- **The two styles of Frost**: the single-target road is a full path; the crowd
  style is a list of lines, not a path (its talents are known only as an end state
  and by decade), so it is for a pack rooted with Frost Nova (Blizzard from level 20), with no talent the single-target road skips.

## Roads: what we recommend, and why (4 November 2026)

Only the Retribution Paladin has more than one documented road in the data.

| Build | Recommended | On a Hardcore realm | Why |
|---|---|---|---|
| paladin-retribution | Retribution first (Icy Veins' full order) | Holy first (Wowhead's Hardcore New Player build) | Icy Veins, Wowhead's general page and Wowhead's Hardcore Experienced build all go Retribution first, so most guides take it. Holy first is the same Hardcore guide's build for a first character: it trades damage in the first twenty levels for mana and heals a hit does not spoil, and a Hardcore realm asks for the safer one. Honest note: most Hardcore guides still go Retribution first (Wowhead's Hardcore Experienced build, Icy Veins' Hardcore page); only the New Player build is Holy first, so the Hardcore road is our safety call, and the page words it that way. |
| mage-frost | its one road (Icy Veins' single-target order) | the same | Every ordered guide (Icy Veins, Wowhead, Wowhead Hardcore, NoobToBoss, Warcraft Tavern) is single target, and Hardcore guidance calls it the safest. The crowd style is a list of lines, not a road. |

## Builds the research says are off (a content card to come)

Warrior, Holy, Protection, Fire and Arcane were written before the research and
each has one road in the data. Their research files say that road differs from
what most guides take, so no recommendation line is shown for them yet (a
recommendation would be a claim we cannot back):

- **warrior-arms**: three roads in the guides (Arms straight through, Cruelty first
  with a respec at 30 or 40, a Hardcore-safe Arms order); the path opens with
  Improved Heroic Strike, which no guide takes, and lacks Deflection before 20.
  Slam is in the plan ("when rage is high") and no guide supports it.
- **warrior-fury**: dual wield is the only road, the guides default to a two-hander.
- **warrior-protection**: Last Stand, Improved Bloodrage and One-Handed Weapon
  Specialization are not in the path; two documented roads.
- **paladin-holy**: Consecration is not in the path; the guides' tail is Retribution
  and Protection points, not Primer's Protection tail.
- **paladin-protection**: both guides start in Holy (Consecration at 20) and
  Protection from 21; the path starts in Protection and takes Consecration at 51.
- **mage-fire**: Elemental Precision first (three of three), and an Arcane tail in
  every guide, not Frost.
- **mage-arcane**: Arcane Power at 40 then Frost in every ordered guide; every
  Hardcore guide warns against it.

The Feral Druid is not in the data yet. The research files for these builds are in
`ideas/class-guide-research/` (section 7 of each).

## Forever: warrior-arms, warrior-fury, warrior-protection (5 November 2026)

Each build's `sources` lists the pages; the research is `../ideas/class-guide-research/forever/warrior-*.md`
(redone against build 1.60.1.70790, the launch build, with every tree cell checked against `card.ts talents Warrior --game forever`).
Every guide read is for the beta (level 30 cap) or written before launch, so levels 31 to 60 are paper.

- **Arms** follows Mobalytics' 4 November levelling order (Ahlaundoh), the newest, with the 70790 ranks (Bloodthrill 2, Improved Tactical Mastery 3 so not taken). Where Mobalytics' last points went to Fury it keeps them, and the Enrage pick is ours from its other guide's note. No second road yet: the Bloodthrill or Weaponmaster first split is in `split`.
- **Fury** follows Kargoz (2 November). Written for the 70755 tree, so three places changed: Raging Blows is now Improved Whirlwind (same spell id, other effect), Flurry stops at 3, Gore Drinker needs Blood Craze 3 (taken at 33). The 13 points after level 40 that Kargoz put in Arms (Improved Tactical Mastery 5, Anger Management, Deep Wounds) cannot be taken, so the tail is ours: Improved Whirlwind 2, Unbridled Wrath (Icy Veins, Warcraft Tavern), Reckless Swings, Improved Execute and Piercing Howl (Warcraft Tavern), and Kargoz's Deflection and Improved Rend. A guess, not a guide's order.
- **Protection** follows Icy Veins' order (21 October) to level 40 with Mobalytics' (Kargoz, 14 October) final picks. After 40 the sources disagree (Icy Veins: Fury 20, Kargoz: 40 Protection). The tail is ours: Icy Veins' Cruelty, Lingering Rage and Unbridled Wrath, then Improved Bloodrage (Kargoz, Method) and Anticipation.
- **Plans** (the rotation stages) are written from the spells' own text in `forever.db` and the guides' rotation sections (Kargoz, Maxroll, Mobalytics Arms, Icy Veins). Not sourced: stance of each line (taken from the client's table), when Execute is worth it (Mobalytics calls it often a trap), Whirlwind's rage floor in the Arms crowd plan (Mobalytics' end-game page).
- **Not verifiable without the game:** Reckless Swings' cost, Flurry's real percentages, Improved Whirlwind's per-rank effect, trainer levels (a copy of Classic's), and anything after 30.

## Forever: mage-frost, mage-fire, mage-arcane (5 November 2026)

Each build's `sources` lists the pages. The research is `../ideas/class-guide-research/forever/mage-*.md`, written against build 70755. The Mage trees did not change to 70790 (`wow-data/bin/tree-diff.ts`), only the text of Improved Frostbolt and Winter's Chill, which no longer names Frost Blast. Every talent a path or plan names was read in `card.ts talents Mage --game forever` at 70790, and the facts check holds its tree, row, ranks and gates. Every guide read is for the beta (level 30 cap) or written before launch, so levels 31 to 60 are paper.

- **Frost** follows Mobalytics' single-target order (3 November): Improved Frostbolt, Precision, Frostbite, Ice Lance at 20, Ice Shards, Ice Block, Shatter, Fingers of Frost, Cold Snap, Winter's Chill, Ice Barrier at 40, then an Arcane tail for mana. The order inside the Arcane tail (Improved Channeling, Missile Barrage, Arcane Subtlety, Arcane Concentration) is Mobalytics' table. The AoE Frost order (Precision, Permafrost, Improved Blizzard, Arctic Reach, no Frostbite) is not a second road: Blizzard was weakened and the guides disagree on its risk, so the pack-pulling plan is not written.
- **Fire** follows Mobalytics' only full Fire order. Warcraft Tavern's beta Fire leans on Improved Scorch, which Mobalytics skips, so Scorch is in no plan. The Fire plan lines come from Warcraft Tavern, Maxroll and the talents' own text (Heating Up stacks to 3, Fire Blast adds a stack on every hit).
- **Arcane** follows Mobalytics' Arcane order. Zockify would open with Wand Specialization, and Method says Arcane out-damages Frost solo. The loop (Arcane Missiles on Missile Barrage, Arcane Wrath, Arcane Blast to 4 stacks, a cheap spell between) is Warcraft Tavern's and Maxroll's, with Zockify's "skip Arcane Blast while Missile Barrage is active".
- **The recommended build is Frost** (six of eight sources: Mobalytics, Conquest Capped, Method, Icy Veins, Warcraft Tavern, wowforeverbuilds). One source makes Arcane the default (Zockify). The roles table holds one build, Frost, and the Overview says the price of the others.
- **Not sourced:** Presence of Mind's use (an Arcane Wrath you cannot stand still for) is ours, from Wrath's cast time. The stance-free armour choice (Ice Armor for Frost and Fire, Mage Armor for Arcane, Mage Armor under low mana for Frost) is Zockify's and Warcraft Tavern's loosely. "You must stand still to use the wand" is one source (Conquest Capped, 15 October beta). Frostfire Bolt is in no plan: no guide uses it.
- **Not verifiable without the game:** every cast time and mana cost (Arcane Blast is 1.5 seconds in the data and 2.5 in Blizzard's 7 October dive), Ice Lance sharing a cooldown with Fire Blast (Blizzard's 2 November notes, through an aggregator), the rank rule that a spell learned more than 12 levels below you triggers Frostbite and Fingers of Frost less often, trainer levels (a copy of Classic's), and anything after 30.

## Forever: rogue-assassination, rogue-combat, rogue-subtlety (5 November 2026)

Each build's `sources` lists the pages. The research is `../ideas/class-guide-research/forever/rogue-*.md`, redone on 5 November against build 1.60.1.70790 (the launch build): every talent a path or plan names was read in `card.ts talents Rogue --game forever`, and the facts check holds its tree, row, ranks and gates. The 70790 build moved about 25 Rogue nodes (Murder, Improved Distract, Quietus, Cutthroat and Thousand Cuts are gone). Shank (24 and 44) and Poised (18) are class spells the Rogue learns, not talents, and no path counts them. Every guide read is for the beta (level 30 cap) or written before launch, so levels 31 to 60 are paper.

- **Combat** follows DonTheCrown's order on Mobalytics (4 and 5 November): Efficient Strikes, Coup de Grace, Precision, Deflection, Riposte at 20, Endurance, Flawless Execution, Weapon Expertise, Aggression, Blade Flurry at 30, Dual Wield Specialization, Hack and Slash, Flash of Steel, Adrenaline Rush at 40, then Assassination for critical hits and poisons. Djexde's order on the same site is the same trees with Remorseless Attacks first and Riposte at 22, Blade Flurry at 32. Method would swap Lightning Reflexes and Endurance for Puncturing Wounds and a dagger.
- **Assassination** follows Djexde's order (Mobalytics, 4 November), the only full order read, with a Combat tail (Coup de Grace, Deflection, Precision, Riposte) and Opportunity and Vile Poisons last. The guide itself advises Combat. Icy Veins' order is in a slider that could not be read. Method, as read, prefers Assassination, but its page is a beta page.
- **Subtlety** follows Djexde's order (Mobalytics, 4 November), which agrees in shape with Icy Veins' text (Subtlety down to Hemorrhage, Death Mark, then Combat and Assassination). Warcraft Tavern's Subtlety page and Kami Labs' simulation still name talents removed before launch and were used for the plan's lines only.
- **The recommended build is Combat** (Mobalytics' three authors, Icy Veins, Maxroll, Conquest Capped, Warcraft Tavern). Method is the one source that leans Assassination. The roles table holds one build, Combat, and the Overview says the price of the others.
- **Plans** are written from the spells' own text in `forever.db` and the guides' rotation sections (Mobalytics, Icy Veins, Maxroll). No figure is stated except what the data backs.
- **Not sourced:** the poison line (Instant Poison on both weapons is Icy Veins', but the spell has no class-book row so it is a text line), Eviscerate's point count in the low levels (ours), and Rupture's place in Subtlety's plan (Icy Veins says it is the finisher on long fights, Mobalytics adds it to a longer list and Death Mark's "4 or 5 points" (no rotation names a count: Djexde says Slice and Dice at 2 or more, then Death Mark).
- **Not verifiable without the game:** every energy cost, Riposte's disarm length, the Boot Knife points (the talent text says 2, Shank's own text says 1), Hack and Slash's real numbers, whether Mutilate demands two daggers (Icy Veins says so, the data says dagger), trainer levels (a copy of Classic's), and anything after 30.
