# Primer

A World of Warcraft addon: a class guide to read out of combat, in a window of
its own. For the character's class and build it gives the talents to pick, in
order and with the reason, what to press at the level it has reached, and what
the build is for, in the words of one narrator (the trainer who has watched you
fail). It is a book, not a tracker: it reads nothing in combat. Planned in
`../ideas/class-guide.md` (3 November 2026, every call the user's), its first
slice on paper in `../ideas/class-guide-warrior.md`. Set up 3 November 2026
(milestone M2, the repository). On GitHub (salty-max/primer, public, 3 November 2026, empty until
the first push), not released. Classic Era (11509) and Forever (16001), one
package, English only for now. **Forever first, Classic Era frozen** (5 November
2026, the user's call): new work is Forever's, Era keeps its three built guides
and gets fixes only (`../ideas/class-guide.md`, "Forever first"). Read the family's CLAUDE.md (`../CLAUDE.md`) first.

## Where things are

| What | Where |
|---|---|
| The addon file by file: the package, Core, Window, Tree, Settings, Minimap, the tests, the languages | `docs/architecture.md` |
| The guide's data, `content/<game>/<class>.json`, its shape and the facts check (`scripts/guide.ts`) | `docs/data.md` |
| What every class needs: one build per spec and role, 28 a game, how many are written | `docs/data.md`, the table in `../ideas/class-guide-coverage.md` |
| Which build a character is (feasibility, never the tree with most points) | `docs/inference.md` |
| Where each build's facts were read, and what the research changed | `docs/sources.md` |
| The voice's rules: the narrator, the class cards, what is the game's and what is ours | `docs/voices.md` |
| The tests: the strict game, the matrix, the secret values, what they cannot see, the checklist for the game | `docs/testing.md` |
| The plan, the milestones, what is open | `../ideas/class-guide.md`, `../ideas/class-guide-warrior.md` |
| The game's tables the facts come from | `../wow-data/docs/class-guide.md` |

## Commands

```bash
bun run check        # kit, saved ids, the guide's facts, the API tables, languages, lint, the battery on both games (sim, strict game, matrix, secret values), TOCs
bun run battery      # only the battery (about 20 seconds), docs/testing.md
bun run check:ci     # what CI and the release gate run: no family folder (the kit, the saved ids and the guide's facts aside)
bun run guide        # the Guide_*.lua and GuideText.lua again, after a content/ edit or wow-data's change (--check is in `check`)
bun scripts/guide.ts --stamp <game> <build|all>   # after reading a moved fact (the facts lock, docs/data.md)
bun run roads <game> <class> <tree> --from <research.md>   # a draft path from a research table (never writes over a file)
bun run ids          # every table saved-ids.json lists keeps the ids it had at the fork point from origin/main
bun scripts/root.ts --run addon-kit/q.ts check -- bun run check   # the same, quiet, stamping the tree for the push
bun run package      # dist/Primer-<version>.zip for a test in the game
bun run kit:sync     # after a change to the kit (Kit.lua, Media, scripts/root.ts)
bun run locales      # after a new L["..."] (then --keys for i18n/words.json)
scripts/release.sh --version X.Y.Z [--hold] NOTES.md   # check, tag, push; Actions publish
```

## Hard rules

- The rules come from the plan, as the design changed four of them (4 November
  2026, the user's go, `../ideas/primer-design.md` section 9): a row the
  character cannot press yet is shown grey in its place, with what it needs,
  so the plan never changes under the player's eyes. Every line has its
  reason, printed under it, wrapped and never truncated (changed 4 November
  2026 after the second game test, which reversed "one toggle away"), so a plan
  reads as a plan and not a wall: few steps, an opening of at most 5 and a loop
  of at most 6, the loop's rarest lines in a Rarely section of rows. A build is
  a way and not the way, yet each role has one recommended road, the other
  roads are kept as "also works", and the Overview says the price of the
  other. A stage is a level bracket and a job and never an optimum, and **the
  voice never changes the instruction** (`docs/voices.md`).
- **Meta-agnostic** (5 November 2026, the user's call): a Forever build's words
  claim no optimum and name no source or community. The talent order is "the
  common choice" with its price, never "the best". One list of banned words and
  names in `scripts/meta-lib.ts`, checked by `scripts/guide.ts` and
  `scripts/meta.test.ts` (`docs/voices.md`, Meta-agnostic). Era is frozen.
- The game's facts come from wow-data's databases only (`scripts/guide.ts`
  through `scripts/root.ts`, the kit's copy). Names of spells and talents are
  the game's, by id, never typed. Generated files (`Guide_*.lua`,
  `GuideText.lua`, `Text_*.lua`) are never edited by hand: `--check` fails a
  stale one. A fact the tables lack (a stance, a situation, a cost, a
  cooldown) is written as ours and marked, or left out.
- A build's id never changes and is never reused: characters keep it
  (`saved-ids.json`, `bun run ids` in the check). An id leaves only with the
  user's go, under `removed`.
- **Nothing in combat.** No combat event, no unit query in combat, no hook on a Blizzard
  frame. The window is our own, opened by `/primer`, the minimap button or
  Keyring's (a call to `ns.toggle`, never a hook). One exception: the
  optional Era talent-window overlay (`hooksecurefunc` only, every step in
  `pcall`, off in combat, built last, failing silently, and never on Forever
  until a probe has been read).
- English only for now (3 November 2026): French, German and Spanish are not
  worked on. Every word still goes through `L` (`i18n/words.json`) or `ns.say`
  (the guide), so a language can be added later. `HIDDEN_LOCALES` changes
  nothing here (`docs/architecture.md`, Languages).
- Text in plain ASCII, British English, no semicolons, no exclamation marks.
- `Kit.lua`, `Media/Ring.tga`, `scripts/root.ts`, `scripts/locales-lib.ts`,
  `scripts/package-lib.ts`, `scripts/battery-lib.ts`, `i18n/kit/`, `wow.yml`, `stylua.toml` and
  `addon/test/wowmock.lua`, `strict.lua`, `secrets.lua`, `battery.lua`, `strict_test.lua` are the kit's copies: edit addon-kit, then `bun run
  kit:sync`. The addon's own globals for selene are `primer.yml`.
- The minimap button's place is the kit's (`K.MINIMAP_ANGLES.Primer`, 90
  degrees), clear of the others and of Classic Era's zoom buttons.
- Blizzard's UI only through `bun ../wow-data/bin/ui.ts`. The icon is our
  logo, `Media/Logo.tga` (`ns.ICON`, 5 November 2026, the user's own).
- No other addon's API, even optional. Stepping aside for a rival is fine.
- Conventional Commits, lowercase subjects, no AI trailers. Commit locally;
  ask before any push, release or deploy. The pre-push hook wants a check
  stamp on the tree (q), which `release.sh` makes after the version bump.
