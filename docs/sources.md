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
