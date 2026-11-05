import { expect, test } from "bun:test";
import { diffFacts } from "./facts-lib";

const was = { "spell 116 name": "Frostbolt", "spell 116 level": "4", "talent 11170 cell": "tree 61 row 4 column 2, id 7" };

test("a lock that sees nothing move stays quiet", () => {
  expect(diffFacts(was, { ...was })).toEqual([]);
});

test("a fact that moved is named, with the spell's name", () => {
  expect(diffFacts(was, { ...was, "spell 116 level": "6" })).toEqual(["spell 116 (Frostbolt) level: 4 became 6"]);
});

test("a fact that is gone, and one that is new, both fail", () => {
  const now: Record<string, string> = { ...was, "spell 99 name": "Other" };
  delete now["talent 11170 cell"];
  expect(diffFacts(was, now)).toEqual(["talent 11170 cell is no longer read", "spell 99 name is read now and was not locked"]);
});

// The whole path: guide.ts against a copy of the lock with one fact edited must fail, naming it
// (only where the family's databases are, so not in CI's plain check)
import { existsSync, mkdtempSync, readFileSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

const have = (() => {
  try {
    return existsSync(join(import.meta.dir, "..", "..", "wow-data", "src", "db.ts"));
  } catch {
    return false;
  }
})();

test.skipIf(!have)("guide.ts fails on a lock whose fact moved, and on one whose cell moved", () => {
  const root = join(import.meta.dir, "..");
  const text = readFileSync(join(root, "facts.lock.json"), "utf8");
  const run = (lock: string) => {
    const f = join(mkdtempSync(join(tmpdir(), "primer-lock-")), "facts.lock.json");
    writeFileSync(f, lock);
    return Bun.spawnSync(["bun", join(root, "scripts", "guide.ts"), "--check"], { env: { ...process.env, PRIMER_LOCK: f }, stdout: "pipe", stderr: "pipe" });
  };
  expect(run(text).exitCode).toBe(0);
  const level = run(text.replace('"spell 116 level": "4"', '"spell 116 level": "6"'));
  expect(level.exitCode).toBe(1);
  expect(level.stderr.toString()).toContain("spell 116 (Frostbolt) level: 6 became 4");
  const cell = run(text.replace(/("cell \d+": "tree \d+ row )(\d)/, (_, a, b) => a + (Number(b) + 1)));
  expect(cell.exitCode).toBe(1);
  expect(cell.stderr.toString()).toContain("cell ");
}, 60000); // three runs of guide.ts: past bun's 5 second default once the guide held 33 builds
