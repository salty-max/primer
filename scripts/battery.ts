/**
 * Primer's tests in the test game, all at once (they are independent, so the wall time is the slowest one's):
 *
 *   sim.lua          a login, the window, the rules and the pages, per game
 *   strict_test.lua  the strict game refuses what the client refuses (a bad call must fail here)
 *   matrix.lua       every class, level, tab and state, hovered and clicked, per game
 *   matrix.lua secrets  Forever: the game's answers are secret values, the page shows nothing rather than raise
 *
 * The runner is the kit's (battery-lib.ts); docs/testing.md says how to run one alone and what none of them can see.
 *   bun scripts/battery.ts              all of them
 *   bun scripts/battery.ts matrix       the ones whose name has "matrix" in it
 */
import { type Job, runBattery } from "./battery-lib";

const jobs: Job[] = [];
for (const forever of [false, true]) {
  jobs.push({ name: "sim", forever, args: ["addon/test/sim.lua"] });
  jobs.push({ name: "strict", forever, args: ["addon/test/strict_test.lua"] });
  jobs.push({ name: "matrix", forever, args: ["addon/test/matrix.lua"] });
}
jobs.push({ name: "matrix secrets", forever: true, args: ["addon/test/matrix.lua", "secrets"] });

await runBattery(jobs);
