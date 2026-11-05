/**
 * Primer's tests in the test game, all at once (they are independent, so the wall time is the slowest one's):
 *
 *   sim.lua          a login, the window, the rules and the pages, per game
 *   strict_test.lua  the strict game refuses what the client refuses (a bad call must fail here)
 *   matrix.lua       every class, level, tab and state, hovered and clicked, per game
 *   matrix.lua secrets  Forever: the game's answers are secret values, the page shows nothing rather than raise
 *
 * docs/testing.md says how to run one alone and what none of them can see.
 *   bun scripts/battery.ts              all of them
 *   bun scripts/battery.ts matrix       the ones whose name has "matrix" in it
 */
import { resolve } from "node:path";

const ADDON = resolve(import.meta.dir, "..");
type Job = { name: string; forever: boolean; args: string[] };
const jobs: Job[] = [];
for (const forever of [false, true]) {
  jobs.push({ name: "sim", forever, args: ["addon/test/sim.lua"] });
  jobs.push({ name: "strict", forever, args: ["addon/test/strict_test.lua"] });
  jobs.push({ name: "matrix", forever, args: ["addon/test/matrix.lua"] });
}
jobs.push({ name: "matrix secrets", forever: true, args: ["addon/test/matrix.lua", "secrets"] });

const only = process.argv[2];
const started = Date.now();
const runs = jobs
  .filter((j) => !only || j.name.includes(only))
  .map(async (job) => {
    const proc = Bun.spawn(["luajit", ...job.args], {
      cwd: ADDON,
      env: { ...process.env, FOREVER: job.forever ? "1" : "0" },
      stdout: "pipe",
      stderr: "pipe",
    });
    const [out, err] = await Promise.all([new Response(proc.stdout).text(), new Response(proc.stderr).text()]);
    const code = await proc.exited;
    return { job, code, out: out.trim(), err: err.trim() };
  });

let failed = false;
for (const r of await Promise.all(runs)) {
  const label = `${r.job.name} (${r.job.forever ? "Forever" : "Classic Era"})`;
  if (r.code === 0) {
    // (the verdict line: the last one that starts with a tick)
    const verdict = r.out.split("\n").filter((l) => l.startsWith("✓")).pop() ?? r.out.split("\n").pop();
    console.log(`${verdict}`);
  } else {
    failed = true;
    console.log(`✗ ${label} failed`);
    console.log([r.out, r.err].filter(Boolean).join("\n").split("\n").slice(-40).join("\n"));
  }
}
console.log(`${failed ? "✗" : "✓"} battery: ${((Date.now() - started) / 1000).toFixed(1)}s`);
process.exit(failed ? 1 : 0);
