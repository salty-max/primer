/**
 * Primer's rules and words, from content/ (the writer's, by hand) and wow-data's
 * databases (../wow-data, its pinned sources), each game's own:
 *
 *   addon/Primer/Guide_Classic.lua, Guide_Forever.lua: the rules of every build
 *     written for that game (content/<class>.json: a build's `games`): its
 *     talent path (a step: the points, the level, the talent's id and the rank
 *     it reaches) and its stages (the level bracket, each priority row with the
 *     spell, the level it is learned at, its stance, its conditions and the
 *     key of its words). Ids and keys only, no word the player reads.
 *   addon/Primer/GuideText.lua: the words by key, English as the writer wrote
 *     them (a language added later comes as a file beside it, from i18n/).
 *
 * The facts are checked on every run, against each game's own tables:
 *   - every spell id of a row is in the game's data, in the class's book
 *     (class_spell), or a rank of a talent; the level the data gives is at or
 *     under the stage's top, and the level the writer gave (when one) is the
 *     data's; the spell's level in the file is the data's
 *   - every talent id is in the game's talent table, the build's tree holds its
 *     31 deepest points, the build's name is its tree's, the rank is at most its largest, the points of a step are the
 *     ranks it buys, the point N is taken at level N + 9, the tree holds the
 *     points the talent asks (req_points) and its prerequisite is at full rank
 *   - the stages follow each other and end at level 60
 *   - the words: plain ASCII, no semicolon, no exclamation mark
 * A patch that drops or moves a spell or a talent fails here, and so the daily
 * game-data job, before its pull request.
 *
 *   bun scripts/guide.ts           write them
 *   bun scripts/guide.ts --check   fail if one isn't up to date (the facts too)
 */
import type { Database } from "bun:sqlite";
import { existsSync, readdirSync, readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import type * as WowDb from "../../wow-data/src/db";
import { familyPath } from "./root";

// through the family folder, from a worktree too (scripts/root.ts)
const { openDb } = (await import(familyPath("wow-data", "src", "db.ts"))) as typeof WowDb;

const ROOT = join(import.meta.dir, "..");
const ADDON = join(ROOT, "addon", "Primer");
const CHECK = process.argv.includes("--check");
type Game = "classic" | "forever";
const GAMES: Game[] = ["classic", "forever"];
const FILE: Record<Game, string> = { classic: "Guide_Classic.lua", forever: "Guide_Forever.lua" };

const PHASES = ["untalented", "choose", "spent"];
const ROLES = ["damage", "tank", "heal"];
const STANCES = ["battle", "defensive", "berserker"];
// What a row's `when` may say: a situation the player reads off the screen
// (a state the page cannot see, shown as advice), never a rule it enforces.
const WHEN = ["ooc", "spare", "group", "dodge", "execute", "long", "shield", "hurt", "loose", "wrong", "brute", "lit", "rest", "lowmana", "undead", "pack", "flee", "humanoid", "caster"];
// The window's words for them (what the lines say, short: GuideText's `when.<key>`)
const WHEN_WORDS: Record<string, string> = {
  ooc: "before the pull",
  spare: "with rage to spare",
  group: "with a group",
  dodge: "after a dodge",
  execute: "when it is nearly dead",
  long: "in a long fight",
  shield: "with a shield",
  hurt: "when you are being hit",
  loose: "when a monster turns away",
  wrong: "when the pull goes wrong",
  brute: "against a hard hitter",
  lit: "when it lights up",
  rest: "between fights",
  lowmana: "when your mana is low",
  undead: "against undead and demons",
  pack: "against two or more",
  flee: "when a monster runs",
  humanoid: "against a humanoid",
  caster: "when a monster is casting",
};
// The client's form numbers less one (SpellShapeshiftForm 17, 18, 19: bits of the stance mask)
const STANCE_FORMS: Record<string, number> = { battle: 16, defensive: 17, berserker: 18 };
// The forms a row may be pressed in, by the spell that is the form (checked against the game's own names)
const STANCE_SPELLS: Record<string, [number, string]> = {
  battle: [2457, "Battle Stance"],
  defensive: [71, "Defensive Stance"],
  berserker: [2458, "Berserker Stance"],
};

type Row = {
  spell: number;
  say: string;
  name: string;
  talentSpell?: number;
  need: { level?: number; stance?: string[]; talents?: number[]; when?: string[] };
};
type Stage = { from: number; to: number; phase?: string; about?: string; opening?: string; rows: Row[] };
type Step = { points: [number, number]; level: [number, number]; talent?: number; any?: number[]; rank: number; of?: number; why: string };
type Build = {
  id: number;
  key: string;
  name: string;
  role: string;
  tree: number;
  games: Game[];
  checked: string;
  intro: string;
  pathNote: string;
  split?: string;
  dry?: string;
  path: Step[];
  stages: Stage[];
};
type Content = {
  class: { id: number; key: string; token: string; name: string; text: string; card: Record<string, string>; advice?: { role: string; say?: string }[] };
  builds: Build[];
};

const content: Content[] = readdirSync(join(ROOT, "content"))
  .filter((f) => f.endsWith(".json"))
  .sort()
  .map((f) => JSON.parse(readFileSync(join(ROOT, "content", f), "utf8")));

const filled = new Map<Row, string[]>(); // the stances the table gave a row, per run of a game (never written back to the content)
const unchecked = new Set<string>(); // stances written that the table cannot confirm
const problems: string[] = [];
const bad = (msg: string) => problems.push(msg);

// ── the words ────────────────────────────────────────────────────────────────
// Every string the player may read, by key. The keys are the data's (the Lua
// rules name them), the words the writer's.
const text: Record<string, string> = {};
function word(key: string, value: string | undefined) {
  if (value === undefined) return undefined;
  if (key in text && text[key] !== value) bad(`${key}: written twice, differently`);
  text[key] = value;
  if (/[^\x20-\x7e]/.test(value)) bad(`${key}: plain ASCII only`);
  if (value.includes(";")) bad(`${key}: a semicolon in what players read`);
  if (value.includes("!")) bad(`${key}: an exclamation mark`);
  if (/\b(DPS|OP|meta|pro tip)\b/.test(value)) bad(`${key}: a word the voice never uses (docs/voices.md)`);
  if (!value.trim()) bad(`${key}: empty`);
  return key;
}

// ── the facts, a game at a time ──────────────────────────────────────────────
type Tal = { id: number; tab_id: number; row: number; max_rank: number; spell_id: number; req_points: number; min_level: number };
class Facts {
  db: Database;
  tal = new Map<number, Tal>(); // by rank 1's spell
  prereq = new Map<number, { requires: number; rank: number }[]>(); // by talent id
  constructor(
    readonly game: Game,
    readonly classId: number,
  ) {
    this.db = openDb(game);
    for (const t of this.db.query("SELECT id, tab_id, row, max_rank, spell_id, req_points, min_level FROM talent WHERE class_id = ?").all(classId) as Tal[]) this.tal.set(t.spell_id, t);
    for (const p of this.db.query("SELECT talent_id, requires_id, rank FROM talent_prereq").all() as { talent_id: number; requires_id: number; rank: number }[]) {
      if (!this.prereq.has(p.talent_id)) this.prereq.set(p.talent_id, []);
      this.prereq.get(p.talent_id)!.push({ requires: p.requires_id, rank: p.rank });
    }
  }
  /** A spell's name in the game's data (null: no such spell). */
  name(spell: number): string | null {
    const r = this.db.query("SELECT name FROM name WHERE kind = 'spell' AND id = ? AND locale = 'enUS'").get(spell) as { name: string } | null;
    return r ? r.name : null;
  }
  /** The level a class learns a spell at: its book's (null: not in it, or no level). */
  level(spell: number): number | null | undefined {
    const r = this.db.query("SELECT level FROM class_spell WHERE class_id = ? AND spell_id = ?").get(this.classId, spell) as { level: number | null } | null;
    return r ? r.level : undefined;
  }
  /** The forms a spell can be pressed in, from the client's own table (SpellShapeshift): null when it asks for none. */
  stances(spell: number): string[] | null {
    const r = this.db.query("SELECT stance_mask, stance_exclude FROM spell_info WHERE spell_id = ?").get(spell) as { stance_mask: number | null; stance_exclude: number | null } | null;
    if (!r || !r.stance_mask) return null;
    const mine = Object.entries(STANCE_FORMS).filter(([, bit]) => (r.stance_mask! & (1 << bit)) !== 0 && ((r.stance_exclude ?? 0) & (1 << bit)) === 0);
    return mine.length ? mine.map(([k]) => k) : null;
  }
  pins(): string {
    const m = this.db.query("SELECT value FROM meta WHERE key = 'pins'").get() as { value: string };
    const p = JSON.parse(m.value).builds[this.game];
    return `${p.product} ${p.build}`;
  }
  build(): string {
    return this.pins().split(" ")[1];
  }
}

function checkBuild(b: Build, f: Facts) {
  const at = `${b.key} (${f.game})`;
  // the talent path: simulate the points
  const spent = new Map<number, number>(); // tab -> points
  const rank = new Map<number, number>(); // talent id -> rank
  const taken = new Map<number, number>(); // talent spell -> the level the path first takes it
  let point = 0;
  b.path.forEach((s, i) => {
    const where = `${at} path step ${i + 1}`;
    const n = s.points[1] - s.points[0] + 1;
    if (s.points[0] !== point + 1) bad(`${where}: starts at point ${s.points[0]}, the one after ${point}`);
    point = s.points[1];
    if (s.level[0] !== s.points[0] + 9 || s.level[1] !== s.points[1] + 9) bad(`${where}: point N is taken at level N + 9 (points ${s.points.join("-")}, levels ${s.level.join("-")})`);
    const ids = s.any ?? (s.talent === undefined ? [] : [s.talent]);
    if (!ids.length) return bad(`${where}: no talent`);
    const found = ids.map((id) => f.tal.get(id));
    ids.forEach((id, k) => !found[k] && bad(`${where}: spell ${id} is no talent of this class in ${f.game}'s data`));
    if (found.some((t) => !t)) return;
    const t = found[0]!;
    if (s.any) {
      if (n !== s.rank) bad(`${where}: a choice of ${n} points, rank ${s.rank}`);
      for (const o of found) if (o!.max_rank !== s.rank) bad(`${where}: ${f.name(o!.spell_id)} has ${o!.max_rank} ranks, the step reaches ${s.rank}`);
    }
    if (s.of !== undefined && s.of !== t.max_rank) bad(`${where}: ${f.name(t.spell_id)} is ${s.rank}/${s.of} in the content, ${t.max_rank} ranks in the data`);
    if (!s.any) {
      if (s.rank > t.max_rank) bad(`${where}: rank ${s.rank} of ${t.max_rank}`);
      const was = rank.get(t.id) ?? 0;
      if (s.rank - was !== n) bad(`${where}: ${f.name(t.spell_id)} goes ${was} to ${s.rank} with ${n} points`);
    }
    const before = spent.get(t.tab_id) ?? 0;
    for (const o of found as Tal[]) {
      if ((spent.get(o.tab_id) ?? 0) < o.req_points) bad(`${where}: ${f.name(o.spell_id)} asks ${o.req_points} points in its tree, ${spent.get(o.tab_id) ?? 0} are spent`);
      if (s.level[0] < o.min_level) bad(`${where}: ${f.name(o.spell_id)} is open from level ${o.min_level}, taken at ${s.level[0]}`);
      for (const p of f.prereq.get(o.id) ?? []) {
        if ((rank.get(p.requires) ?? 0) < p.rank) bad(`${where}: ${f.name(o.spell_id)} needs talent ${p.requires} at rank ${p.rank} first`);
      }
      taken.set(o.spell_id, s.level[0]);
    }
    rank.set(t.id, s.rank);
    spent.set(t.tab_id, before + n);
  });
  if (point > 51) bad(`${at}: ${point} points, 51 is the most`);
  if (point !== 51) bad(`${at}: the path spends ${point} points, a full one 51`);
  // the build's own tree reaches its deepest talent
  if ((spent.get(b.tree) ?? 0) < 31) bad(`${at}: the path puts ${spent.get(b.tree) ?? 0} points in tree ${b.tree}, its own tree takes at least 31`);
  const tab = f.db.query("SELECT name FROM name WHERE kind = 'talent_tab' AND id = ? AND locale = 'enUS'").get(b.tree) as { name: string } | null;
  if (!tab || tab.name !== b.name) bad(`${at}: the build is named ${b.name}, its tree ${b.tree} ${tab ? tab.name : "is no tree"}`);
  // the stages follow each other
  let next = b.stages[0]?.from ?? 1;
  for (const st of b.stages) {
    if (st.from !== next || st.to < st.from) bad(`${at}: stage ${st.from}-${st.to} doesn't follow the one before`);
    next = st.to + 1;
  }
  if (next !== 61) bad(`${at}: the stages end at level ${next - 1}, not 60`);
  const stances = new Map<number, string>(); // a spell's stances, one list a build
  b.stages.forEach((st, si) =>
    st.rows.forEach((r, ri) => {
      const where = `${at} stage ${st.from}-${st.to} row ${ri + 1} (${r.name})`;
      const sn = f.name(r.spell);
      if (sn === null) return bad(`${where}: spell ${r.spell} is not in ${f.game}'s data`);
      if (sn !== r.name) bad(`${where}: spell ${r.spell} is ${sn} in the data, ${r.name} in the content`);
      let level: number | null | undefined;
      if (r.talentSpell !== undefined) {
        const t = f.tal.get(r.talentSpell);
        if (!t) return bad(`${where}: spell ${r.talentSpell} is no talent of this class`);
        level = t.min_level;
      } else {
        level = f.level(r.spell);
        if (level === undefined) return bad(`${where}: spell ${r.spell} is not in the class's book`);
        if (level === null) return bad(`${where}: spell ${r.spell} has no level in the data`);
      }
      if (r.talentSpell === undefined && f.tal.has(r.spell)) bad(`${where}: spell ${r.spell} is a talent's rank 1, the row needs talentSpell`);
      if (level > st.to) bad(`${where}: learned at level ${level}, above the stage's ${st.to}`);
      if (r.need.level !== undefined && r.need.level !== level) bad(`${where}: the content says level ${r.need.level}, the data ${level}`);
      for (const s of r.need.stance ?? []) if (!STANCES.includes(s)) bad(`${where}: stance ${s}`);
      // The stance, against the client's own table: a form the spell cannot be pressed in is a
      // contradiction, and a spell the table limits to forms the writer left unsaid takes the table's
      // (the writer may narrow a spell that several forms allow, never widen it)
      filled.delete(r); // (this game's own)
      const allowed = f.stances(r.spell);
      if (allowed) {
        for (const s of r.need.stance ?? []) if (!allowed.includes(s)) bad(`${where}: the content presses it in ${s}, the data allows ${allowed.join(" or ")}`);
        if (!r.need.stance?.length) filled.set(r, allowed);
      } else if (r.need.stance?.length) {
        // (the table limits no form: the stance is the writer's alone, told, never failed)
        const once = `${f.game}:${r.spell}`;
        if (!unchecked.has(once)) {
          unchecked.add(once);
          console.log(`note: ${r.name} (${r.spell}) is pressed in ${r.need.stance.join(" or ")} by the content, the client's table limits no form`);
        }
      }
      for (const w of r.need.when ?? []) if (!WHEN.includes(w)) bad(`${where}: when ${w} is no condition of the vocabulary`);
      for (const tid of [...(r.need.talents ?? []), ...(r.talentSpell !== undefined ? [r.talentSpell] : [])]) {
        if (!f.tal.has(tid)) bad(`${where}: needs talent spell ${tid}, no talent of this class`);
        else if (!taken.has(tid)) bad(`${where}: needs talent ${f.name(tid)}, the path never takes it`);
        else if (taken.get(tid)! > st.to) bad(`${where}: needs talent ${f.name(tid)}, the path takes it at level ${taken.get(tid)}, after the stage's ${st.to}`);
      }
      const want = JSON.stringify(r.need.stance?.length ? r.need.stance : (filled.get(r) ?? []));
      const had = stances.get(r.spell);
      if (had !== undefined && had !== want) bad(`${where}: stance ${want}, another row of the build says ${had}: one list for a spell`);
      stances.set(r.spell, want);
      (r as Row & { learned: number }).learned = level;
    }),
  );
}

// ── the Lua ──────────────────────────────────────────────────────────────────
const q = (s: string) => `"${s.replace(/\\/g, "\\\\").replace(/"/g, '\\"')}"`;
const list = (a: (string | number)[]) => `{ ${a.join(", ")} }`;

function rowLua(r: Row & { learned: number }, key: string): string {
  const f = [`spell = ${r.spell}`, `level = ${r.learned}`];
  if (r.talentSpell !== undefined) f.push(`talent = ${r.talentSpell}`);
  if (r.need.talents?.length) f.push(`talents = ${list(r.need.talents)}`);
  const stance = r.need.stance?.length ? r.need.stance : filled.get(r);
  if (stance?.length) f.push(`stance = ${list(stance.map(q))}`);
  if (r.need.when?.length) f.push(`when = ${list(r.need.when.map(q))}`);
  f.push(`say = ${q(key)}`);
  return `{ ${f.join(", ")} }`;
}

function luaFor(game: Game): { lua: string; builds: number } {
  const lines: string[] = [];
  const classes: string[] = [];
  const builds: string[] = [];
  const used = new Map<number, Tal>(); // the talents the builds name, by rank 1's spell
  const advice: string[] = []; // the level-10 advice a class's content adds, by class and role
  let version = "";
  for (const c of content) {
    const mine = c.builds.filter((b) => b.games.includes(game));
    if (!mine.length) continue;
    const f = new Facts(game, c.class.id);
    version = f.pins();
    for (const [key, [id, name]] of Object.entries(STANCE_SPELLS)) {
      const n = f.name(id);
      if (n !== name) bad(`${c.class.key} (${game}): the ${key} stance is spell ${id}, ${n ?? "not in the data"}, not ${name}`);
    }
    const card = Object.entries(c.class.card).map(([k, v]) => `${k} = ${q(v)}`);
    classes.push(`    [${c.class.id}] = { token = ${q(c.class.token)}, key = ${q(c.class.key)}, text = ${q(word(`${c.class.key}`, c.class.text)!)}, builds = ${list(mine.map((b) => b.id))}, card = { ${card.join(", ")} } },`);
    const mineAdvice: string[] = [];
    for (const a of c.class.advice ?? []) {
      if (!ROLES.includes(a.role)) bad(`${c.class.key} advice: role ${a.role} is none of ${ROLES.join(", ")}`);
      else if (!mine.some((b) => b.role === a.role)) bad(`${c.class.key} advice: no ${a.role} build is written for ${game}`);
      else mineAdvice.push(`${a.role} = { say = ${a.say ? q(word(`${c.class.key}.advice.${a.role}`, a.say)!) : "false"} }`);
    }
    if (mineAdvice.length) advice.push(`    [${c.class.id}] = { ${mineAdvice.join(", ")} },`);
    for (const b of mine) {
      checkBuild(b, f);
      const k = b.key;
      const names = [...b.path.flatMap((s) => s.any ?? (s.talent === undefined ? [] : [s.talent])), ...b.stages.flatMap((st) => st.rows.flatMap((r) => [...(r.need.talents ?? []), ...(r.talentSpell !== undefined ? [r.talentSpell] : [])]))];
      for (const n of names) if (f.tal.has(n)) used.set(n, f.tal.get(n)!);
      const out: string[] = [];
      out.push(`    [${b.id}] = {`);
      out.push(`      key = ${q(k)}, class = ${c.class.id}, role = ${q(b.role)}, tree = ${b.tree}, name = ${q(b.name)},`);
      out.push(`      checked = ${q(b.checked)}, build = ${q(f.build())},`);
      out.push(`      intro = ${q(word(`${k}.intro`, b.intro)!)}, note = ${q(word(`${k}.note`, b.pathNote)!)},`);
      if (b.split) out.push(`      split = ${q(word(`${k}.split`, b.split)!)},`);
      if (b.dry) out.push(`      dry = ${q(word(`${k}.dry`, b.dry)!)},`);
      out.push("      path = {");
      b.path.forEach((s, i) => {
        const t = s.any ? `any = ${list(s.any)}` : `talent = ${s.talent}`;
        out.push(`        { points = ${list(s.points)}, level = ${list(s.level)}, ${t}, rank = ${s.rank}, why = ${q(word(`${k}.p${i + 1}`, s.why)!)} },`);
      });
      out.push("      },");
      out.push("      stages = {");
      b.stages.forEach((st, si) => {
        if (st.phase !== undefined && !PHASES.includes(st.phase)) bad(`${b.key} stage ${st.from}-${st.to}: phase ${st.phase} is none of ${PHASES.join(", ")}`);
        const phase = st.phase ? `, phase = ${q(st.phase)}` : "";
        const about = st.about ? `, about = ${q(word(`${k}.s${si + 1}`, st.about)!)}` : "";
        out.push(`        { from = ${st.from}, to = ${st.to}${phase}${about},`);
        if (st.opening) out.push(`          opening = ${q(word(`${k}.s${si + 1}.opening`, st.opening)!)},`);
        out.push("          rows = {");
        st.rows.forEach((r, ri) => out.push(`            ${rowLua(r as Row & { learned: number }, word(`${k}.s${si + 1}.r${ri + 1}`, r.say)!)},`));
        out.push("          },");
        out.push("        },");
      });
      out.push("      },");
      out.push("    },");
      builds.push(...out);
    }
  }
  lines.push(
    `-- Generated by scripts/guide.ts from content/ and wow-data's ${game}.db (client ${version || "none: no build written for this game yet"}):`,
    "-- edit those, never this file. The words are GuideText.lua's, by key.",
    "--   classes[id] = { token, key, text, builds (ids), card (the voice's vocabulary: not shown) }",
    "--   builds[id]  = { key, class, role, tree (a talent tab), name, checked, build (the client),",
    "--                   intro, note, split, dry (word keys), path, stages }",
    "--   path[n]     = { points = { from, to }, level = { from, to }, talent (rank 1's spell) or any (a choice),",
    "--                   rank (it reaches), why }",
    "--   stages[n]   = { from, to (levels), phase (untalented, choose or spent: the character's phase it serves, none: any), about, opening, rows }",
    "--   advice[class][role] = { say (a word key, or false): the writer's line for the level-10 advice, after the builds that fit and the first three picks of the first)",
    "--   rows[n]     = { spell (rank 1), level (it is learned), talent (a talent's spell), talents (taken first),",
    "--                   stance (stances it is pressed in: the writer's, else what the client's table allows), when (a situation), say }",
    "--   talents[spell] = { id (the talent's, as the game's talent call gives it), tab (its tree), max (its ranks) }, every talent the builds name",
    "--   stances[key]   = the spell that is the form (its name is the game's, by id)",
    "local _, ns = ...",
    "ns.data = {",
    `  game = ${q(game)},`,
    "  classes = {",
    ...classes,
    "  },",
    "  builds = {",
    ...builds,
    "  },",
    "  talents = {",
    ...[...used.keys()].sort((a, b) => a - b).map((sp) => `    [${sp}] = { id = ${used.get(sp)!.id}, tab = ${used.get(sp)!.tab_id}, max = ${used.get(sp)!.max_rank} },`),
    "  },",
    "  advice = {",
    ...advice,
    "  },",
    "  stances = {",
    ...(builds.length ? Object.entries(STANCE_SPELLS).map(([k, [id]]) => `    ${k} = ${id},`) : []),
    "  },",
    "}",
  );
  return { lua: lines.join("\n") + "\n", builds: builds.length };
}

for (const k of WHEN) word(`when.${k}`, WHEN_WORDS[k]);
const outputs: [string, string][] = [];
for (const g of GAMES) outputs.push([join(ADDON, FILE[g]), luaFor(g).lua]);
const sorted = Object.keys(text).sort();
outputs.push([
  join(ADDON, "GuideText.lua"),
  [
    "-- Generated by scripts/guide.ts from content/: edit those, never this file.",
    "-- The guide's words by key, English as the writer wrote them. A language added",
    "-- later comes as a file beside this one (ns.guideText), from i18n/.",
    "local _, ns = ...",
    "ns.guideText = {",
    ...sorted.map((k) => `  [${q(k)}] = ${q(text[k])},`),
    "}",
  ].join("\n") + "\n",
]);

if (problems.length) {
  console.error(`✗ ${problems.length} fact${problems.length > 1 ? "s" : ""} wrong:`);
  for (const p of problems) console.error(`  ${p}`);
  process.exit(1);
}
let stale = false;
for (const [file, lua] of outputs) {
  const now = existsSync(file) ? readFileSync(file, "utf8") : "";
  if (now === lua) continue;
  if (CHECK) {
    console.error(`✗ ${file.replace(ROOT + "/", "")} is out of date: bun scripts/guide.ts`);
    stale = true;
  } else writeFileSync(file, lua);
}
if (stale) process.exit(1);
console.log(`✓ the guide: ${content.reduce((n, c) => n + c.builds.length, 0)} builds, ${sorted.length} words, the facts checked in ${GAMES.filter((g) => content.some((c) => c.builds.some((b) => b.games.includes(g)))).join(" and ")}`);
