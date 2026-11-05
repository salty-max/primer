import { expect, test } from "bun:test";
import { existsSync, readdirSync, readFileSync } from "node:fs";
import { join } from "node:path";
import { ALLOWED, BANNED, metaClaims, sourceNames } from "./meta-lib";

test("every kind of claim the gate bans is caught", () => {
  const samples = [
    "Most guides take this first.",
    "The best point in the tree.",
    "It is the meta pick.",
    "Mobalytics takes it at 30.",
    "A must for tanking a pack.",
    "Everyone takes it.",
    "It is the only way to level.",
    "Never take it before 20.",
    "Taking this is wrong.",
    "A safer road.",
    "Most players skip it.",
    "The fastest Hunter to level.",
    "A top pick, the go-to of the community.",
    "Most Hunters take it.",
    "Icy Veins and icy veins and WoWhead.",
    "That is the wrong order.",
  ];
  for (const s of samples) expect(metaClaims(s).length).toBeGreaterThan(0);
});

test("plain mechanics and trade-offs pass", () => {
  const fine = [
    "Rend bleeds for more. It buys a longer bleed and costs a point you could put into Deflection.",
    "Use it when a fight goes wrong.",
    "You must stand still to use the wand.",
    "The common choice is Feral, and the price is gold for the respec.",
    "A method of drinking: sit down.",
    "Nobody has played past 30.",
    "It never misses a monster that is stunned.",
    
  ];
  for (const s of fine) expect(metaClaims(s)).toEqual([]);
});

test("an allowed use passes and gives its reason", () => {
  for (const a of ALLOWED) expect(a.why.length).toBeGreaterThan(10);
  // the mechanism itself: a banned phrase cleared only where it is allowed
  const own = [{ phrase: "a mage who never takes it", why: "an example for the test of the mechanism" }];
  expect(metaClaims("It is the best.", [], own).length).toBe(1);
  expect(metaClaims("A phrase: the best.", [], [{ phrase: "the best", why: "an example for the test" }])).toEqual([]);
});

test("a build's own sources add their names", () => {
  const names = sourceNames([{ label: "Mobalytics, Mage levelling (Kir, 2 November 2026)" }, { label: "Blizzard, Beta Development Notes of 2 November" }]);
  expect(names).toContain("Kir");
  expect(metaClaims("Kir takes it first.", names)).toEqual(['names a source: "Kir"']);
});

// The content itself (Forever's only: Era is frozen and not held to it)
const dir = join(import.meta.dir, "..", "content", "forever");
test("no Forever build says a meta claim", () => {
  const problems: string[] = [];
  const walk = (o: unknown, path: string, names: string[], at: string) => {
    if (typeof o === "string") {
      if (/need\.when\[/.test(path)) return; // a tag from the closed list (WHEN), its words are WHEN_WORDS
      for (const c of metaClaims(o, names)) problems.push(`${at} ${path}: ${c}`);
    } else if (Array.isArray(o)) o.forEach((x, i) => walk(x, `${path}[${i}]`, names, at));
    else if (o && typeof o === "object") for (const [k, v] of Object.entries(o)) if (k !== "sources") walk(v, path ? `${path}.${k}` : k, names, at);
  };
  if (!existsSync(dir)) return;
  for (const f of readdirSync(dir).filter((x) => x.endsWith(".json"))) {
    const c = JSON.parse(readFileSync(join(dir, f), "utf8"));
    walk(c.class, "class", [], f);
    for (const b of c.builds) walk(b, "", sourceNames(b.sources), `${f} ${b.key}`);
  }
  expect(problems).toEqual([]);
});
