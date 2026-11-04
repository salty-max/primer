/**
 * The road importer, a DRAFT MAKER: it reads one order table of a research file
 * (ideas/class-guide-research/<class>-<build>.md: Levels | Points | Talent) and
 * proposes a build's `path` for content/<game>/<class>.json, with every `why` empty.
 * It never writes into authored content: the draft goes to stdout, or to --out when
 * that file does not exist yet, and a person reads it against the research, fills
 * the `why`s and pastes it in. The generator then checks the draft as it checks any path.
 *
 *   bun scripts/roads.ts <game> <class key> <tree name> --from <research.md> [--table N] [--out draft.json]
 *
 * Every name is resolved to one talent of the class in that game's data (a name that
 * matches none or two fails, never a guess; an id written beside it must be that talent's
 * rank 1 spell). A table that does not make 51 points in sequence, a rank above the
 * talent's, a gate the order breaks or a point the tree's own rule forbids is listed,
 * and a table with no levels is refused ("no levels": write the order by hand).
 */
import { existsSync, readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import type * as WowDb from "../../wow-data/src/db";
import { familyPath } from "./root";

const { openDb } = (await import(familyPath("wow-data", "src", "db.ts"))) as typeof WowDb;
const ROOT = join(import.meta.dir, "..");
const arg = (name: string) => {
  const i = process.argv.indexOf(name);
  return i < 0 ? undefined : process.argv[i + 1];
};
const [game, classKey, treeName] = process.argv.slice(2).filter((a, i, all) => !a.startsWith("--") && !all[i - 1]?.startsWith("--"));
const from = arg("--from");
if (!["classic", "forever"].includes(game ?? "") || !classKey || !treeName || !from) {
  console.error("bun scripts/roads.ts <classic|forever> <class key> <tree name> --from <research.md> [--table N] [--out draft.json]");
  process.exit(2);
}
const db = openDb(game as "classic" | "forever");
// the class id from the game's own ChrClasses (a class with no content file yet is the importer's reason to exist)
const classRow = db.query("SELECT ID FROM client_ChrClasses WHERE Filename = ?").get(classKey!.toUpperCase()) as { ID: number } | null;
if (!classRow) {
  console.error(`no class ${classKey} in ${game}'s data`);
  process.exit(2);
}
const content = { class: { id: classRow.ID } };

type Tal = { id: number; tab_id: number; max_rank: number; spell_id: number; req_points: number; min_level: number; name: string };
const talents = db
  .query("SELECT t.id, t.tab_id, t.max_rank, t.spell_id, t.req_points, t.min_level, n.name FROM talent t JOIN name n ON n.kind = 'spell' AND n.id = t.spell_id AND n.locale = 'enUS' WHERE t.class_id = ?")
  .all(content.class.id) as Tal[];
const prereq = new Map<number, { requires: number; rank: number | null }[]>();
for (const p of db.query("SELECT talent_id, requires_id, rank FROM talent_prereq").all() as { talent_id: number; requires_id: number; rank: number | null }[]) {
  prereq.set(p.talent_id, [...(prereq.get(p.talent_id) ?? []), { requires: p.requires_id, rank: p.rank }]);
}
const tab = db.query("SELECT id FROM name WHERE kind = 'talent_tab' AND name = ? AND locale = 'enUS'").all(treeName) as { id: number }[];
const own = talents.filter((t) => tab.some((x) => x.id === t.tab_id));
const treeId = own[0]?.tab_id;

const problems: string[] = [];
const bad = (m: string) => problems.push(m);
if (!treeId) bad(`no tree named ${treeName} for this class in ${game}'s data`);

// the tables of the file: the lines from a header that starts "| Levels | Points" to the first line that is no row
const lines = readFileSync(from!, "utf8").split("\n");
const tables: string[][] = [];
for (let i = 0; i < lines.length; i++) {
  if (/^\|\s*Levels\s*\|\s*Points\s*\|\s*Talent/.test(lines[i])) {
    const rows: string[] = [];
    for (let j = i + 2; j < lines.length && lines[j].startsWith("|"); j++) rows.push(lines[j]);
    tables.push(rows);
  }
}
const n = Number(arg("--table") ?? 1);
const rows = tables[n - 1];
if (!rows) {
  console.error(`${from}: ${tables.length} order tables, no table ${n}`);
  process.exit(2);
}

type Step = { points: [number, number]; level: [number, number]; talent: number; rank: number; of: number; why: string };
const steps: Step[] = [];
const rank = new Map<number, number>();
const spent = new Map<number, number>();
let point = 0;
for (const line of rows) {
  const cells = line.split("|").slice(1, -1).map((c) => c.trim());
  const [lv, pts, raw] = cells;
  const m = /^(\d+)(?:-(\d+))?$/.exec(lv);
  const count = Number(pts);
  if (!m || !Number.isInteger(count)) {
    bad(`"${line}": no levels or no points ("no levels": write this order by hand)`);
    continue;
  }
  const lo = Number(m[1]);
  const hi = Number(m[2] ?? m[1]);
  // (the notes beside a name: its id, "(5/5)", "(now 5/5)", or the tree it is in, whatever it is called)
  const written = raw.replace(/\s*\((?:[^()]*,\s*)?(\d+)\)\s*$/, "").replace(/\s*\((?:now\s+)?\d+\/\d+\)\s*$/, "").replace(/\s*\([^()]*\)\s*$/, "").trim();
  const id = /\((?:[^()]*,\s*)?(\d{4,})\)/.exec(raw)?.[1];
  const found = talents.filter((t) => t.name.toLowerCase() === written.toLowerCase());
  if (found.length !== 1) {
    bad(`"${written}": ${found.length ? "matches " + found.length + " talents" : "matches no talent"} of this class in ${game}'s data`);
    continue;
  }
  const t = found[0];
  if (id && Number(id) !== t.spell_id) bad(`"${written}": the research gives ${id}, the data ${t.spell_id}`);
  if (hi - lo + 1 !== count) bad(`"${line}": levels ${lo}-${hi} are ${hi - lo + 1} points, the table says ${count}`);
  if (lo !== point + 10) bad(`"${line}": starts at level ${lo}, the point after ${point} comes at level ${point + 10}`);
  if ((spent.get(t.tab_id) ?? 0) < t.req_points) bad(`"${written}" at level ${lo}: asks ${t.req_points} points in its tree, ${spent.get(t.tab_id) ?? 0} are spent`);
  for (const p of prereq.get(t.id) ?? []) if ((rank.get(p.requires) ?? 0) < (p.rank ?? 1)) bad(`"${written}" at level ${lo}: its prerequisite is not at full rank yet`);
  const r = (rank.get(t.id) ?? 0) + count;
  if (r > t.max_rank) bad(`"${written}": rank ${r} of ${t.max_rank}`);
  rank.set(t.id, r);
  spent.set(t.tab_id, (spent.get(t.tab_id) ?? 0) + count);
  steps.push({ points: [point + 1, point + count], level: [lo, hi], talent: t.spell_id, rank: r, of: t.max_rank, why: "" });
  point += count;
}
if (point !== 51) bad(`${point} points, a full order is 51`);
if (treeId && (spent.get(treeId) ?? 0) < 31) bad(`${spent.get(treeId) ?? 0} points in ${treeName}, a build takes at least 31`);

const draft = "[\n" + steps.map((x) => " " + JSON.stringify(x)).join(",\n") + "\n]";
if (problems.length) {
  console.error(`${problems.length} to settle by hand before this draft is a path:`);
  for (const p of problems) console.error(`  ${p}`);
}
const out = arg("--out");
if (out) {
  if (existsSync(out)) {
    console.error(`${out} exists: the importer never writes over a file`);
    process.exit(1);
  }
  writeFileSync(out, draft + "\n");
  console.log(`draft: ${steps.length} steps, ${point} points -> ${out}`);
} else console.log(draft);
process.exit(problems.length ? 1 : 0);
