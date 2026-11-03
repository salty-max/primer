/**
 * The addon's package: the family's (scripts/package-lib.ts, the kit's copy):
 * addon/Primer as it is, one zip for every game, each game loading its own
 * TOC; its TOCs checked.
 *
 *   bun scripts/package.ts           dist/Primer and dist/Primer-<version>.zip
 *   bun scripts/package.ts --no-zip  the folder only (to copy into a game)
 *   bun scripts/package.ts --check   the TOCs only
 */
import { join } from "node:path";
import { run } from "./package-lib";

// (each game's own files: its guide's rules)
run({ root: join(import.meta.dir, ".."), name: "Primer", games: { classic: ["Guide_Classic.lua"], forever: ["Guide_Forever.lua"] } });
