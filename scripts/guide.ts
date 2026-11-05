/**
 * Primer's rules and words, from content/ (the writer's, by hand) and wow-data's
 * databases (../wow-data, its pinned sources), each game's own:
 *
 *   addon/Primer/Guide_Classic.lua, Guide_Forever.lua: the rules of every build
 *     written for that game (content/<game>/<class>.json, one file a class a game): its
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
 *   - the words: plain ASCII, no semicolon, no exclamation mark, and for Forever no meta claim
 *     (an optimum, a community's authority, a named source: scripts/meta-lib.ts)
 * A patch that drops or moves a spell or a talent fails here, and so the daily
 * game-data job, before its pull request.
 *
 * facts.lock.json holds, per game and build, every fact the build read (a spell's
 * name, level and forms, a talent's cell, ranks and prerequisites, a tree's name).
 * A fact that moved fails the run and names it. Only a person clears it, by reading
 * the fact and stamping the build again (--stamp). A build with no entry fails too.
 *
 *   bun scripts/guide.ts                     write them
 *   bun scripts/guide.ts --check             fail if one isn't up to date (the facts too)
 *   bun scripts/guide.ts --stamp <game> <build key | all>   write the lock's entry again
 */
import type { Database } from "bun:sqlite";
import { existsSync, readdirSync, readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { metaClaims, sourceNames } from "./meta-lib";
import type * as WowDb from "../../wow-data/src/db";
import { familyPath } from "./root";
import { diffFacts, type Lock } from "./facts-lib";

// through the family folder, from a worktree too (scripts/root.ts)
const { openDb } = (await import(familyPath("wow-data", "src", "db.ts"))) as typeof WowDb;

const ROOT = join(import.meta.dir, "..");
const ADDON = join(ROOT, "addon", "Primer");
const CHECK = process.argv.includes("--check");
const STAMP = process.argv.includes("--stamp") ? process.argv.slice(process.argv.indexOf("--stamp") + 1) : null;
const LOCK_FILE = process.env.PRIMER_LOCK ?? join(ROOT, "facts.lock.json"); // (the test points it at a copy)
const BUDGET_LINE = 56; // a plan row's name and condition together, in characters (one line of the window)
const BUDGET_WHY = 60; // a reason, printed under its step
const BUDGET_PICK_WHY = 170; // a pick's reason: three lines of the Talents tab's card
const BUDGET_OPENING = 5; // a stage's opening, a numbered step each with its reason under it
const BUDGET_LOOP = 6; // a stage's loop, a numbered step each with its reason under it: the rest of the loop goes to `rarely`
type Game = "classic" | "forever";
const GAMES: Game[] = ["classic", "forever"];
const FILE: Record<Game, string> = { classic: "Guide_Classic.lua", forever: "Guide_Forever.lua" };

const PHASES = ["untalented", "choose", "spent"];
// What a class's overview says, in the order the page reads it (who the class is, what it is good and bad at,
// its resource, levelling, and what to do at level 10)
const OVERVIEW = ["who", "good", "bad", "resource", "levelling", "ten"];
// Spells every character has that no class book lists (the plan's "Attack"), by id and the game's name
// (and the picture the game's action bar gives it: the client's own icon for the spell is a developer's photo)
const COMMON_SPELLS: Record<number, [string, string]> = {
  6603: ["Attack", "Interface\\Icons\\Ability_MeleeDamage"],
  // Shoot (the wand): every wand-user has it from level 1 and no class book lists it, so the facts check takes it as granted
  5019: ["Shoot", "Interface\\Icons\\Ability_ShootWand"],
};
const PLAN_LISTS = ["opening", "loop", "rarely", "between", "low"] as const;
const CLAUSE_WORDS = 14;
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
// A step of a rotation plan: a spell (its name checked against the game's, level and stance as a row's)
// or a line of text alone, when it applies (`if`, a clause: none on the last line of the loop), what to do
// (`say`, only when the spell's name is not enough) and why (one short clause).
type PlanStep = { spell?: number; best?: number[]; name?: string; text?: string; if?: string; say?: string; why: string; talentSpell?: number; need?: Row["need"] };
type Plan = {
  opening: PlanStep[];
  loop: PlanStep[];
  rarely?: PlanStep[]; // the loop's lowest-priority lines, a quiet note under it
  between?: PlanStep[];
  low?: PlanStep[];
  big?: { spells: PlanStep[]; say: string };
  // another way to play the same stage with its own lists (a style: single target or a crowd): a name, one line on when
  // it is for, and its own opening and loop
  alt?: { name: string; say: string; opening?: PlanStep[]; loop: PlanStep[]; between?: PlanStep[]; low?: PlanStep[] };
};
type Stage = { from: number; to: number; phase?: string; about?: string; opening?: string; rows?: Row[]; plan?: Plan };
type Step = { points: [number, number]; level: [number, number]; talent?: number; any?: number[]; rank: number; of?: number; why: string };
type Build = {
  id: number;
  key: string;
  name: string;
  role: string;
  tree: number;
  checked: string;
  intro: string;
  line?: string; // one line for the class's overview (none: the first sentence of the intro)
  variant?: string; // when two builds share a tree (a Feral Druid as a cat or a bear): the word after the tree's name, "cat"
  pathNote: string;
  hardcore?: string[]; // lines for a Hardcore realm, after the plan (the season check in the window)
  sources?: { label: string; url: string; read: string }[]; // where the facts of the build were read (docs/sources.md): never shown
  split?: string;
  dry?: string;
  path: Step[];
  roadName?: string; // the first road's plain name, when the build has several ("Retribution first")
  roadId?: string; // and its id
  roads?: { id: string; name?: string; path: Step[] }[]; // the other roads of the same build: the same role and tree, another order of the points
  recommended?: string; // the road the page advises: ours, from the research (docs/sources.md), never the player's choice
  alsoRecognised?: string[]; // roads kept only to be recognised: points that follow one are no drift, the page advises along it
  hardcoreRoad?: string; // the road on a Hardcore realm, where the research gives one
  roadReason?: string; // why the recommended road, and the price of the other, in plain words
  hardcoreReason?: string; // the same for the Hardcore road
  stages: Stage[];
};
type Content = {
  class: {
    id: number;
    key: string;
    token: string;
    name: string;
    text: string;
    card: Record<string, string>;
    advice?: { role: string; say?: string }[];
    overview?: Record<string, string>;
    roles?: Record<string, { build: string; reason: string }>; // the one build the page advises for a role, and why
  };
  builds: Build[];
};

// content/<game>/<class>.json: a game's own file for a class, never one game's line on the other
const content: Record<Game, Content[]> = { classic: [], forever: [] };
for (const g of GAMES) {
  const dir = join(ROOT, "content", g);
  if (!existsSync(dir)) continue;
  content[g] = readdirSync(dir)
    .filter((f) => f.endsWith(".json"))
    .sort()
    .map((f) => JSON.parse(readFileSync(join(dir, f), "utf8")));
}

// the sites and writers Forever's builds list as sources: none of them may be named in what a player reads (scripts/meta-lib.ts)
const SOURCE_NAMES = [...new Set(content.forever.flatMap((c) => c.builds.flatMap((b) => sourceNames(b.sources))))];

const filled = new Map<Row, string[]>(); // the stances the table gave a row, per run of a game (never written back to the content)
const unchecked = new Set<string>(); // stances written that the table cannot confirm
const problems: string[] = [];
const bad = (msg: string) => problems.push(msg);

// ── the words ────────────────────────────────────────────────────────────────
// Every string the player may read, by key. The keys are the data's (the Lua
// rules name them), the words the writer's.
const text: Record<string, string> = {};
// One GuideText.lua serves both games, so a game's own words are keyed under its name (Forever's advice never
// shares a key with Era's): "" for Classic, so its keys stay byte for byte as they were.
let KEYNS = "";
function word(key: string, value: string | undefined) {
  if (value === undefined) return undefined;
  if (!key.startsWith("when.")) key = KEYNS + key;
  if (key in text && text[key] !== value) bad(`${key}: written twice, differently`);
  text[key] = value;
  if (/[^\x20-\x7e]/.test(value)) bad(`${key}: plain ASCII only`);
  if (value.includes(";")) bad(`${key}: a semicolon in what players read`);
  if (value.includes("!")) bad(`${key}: an exclamation mark`);
  if (/\b(DPS|OP|meta|pro tip)\b/.test(value)) bad(`${key}: a word the voice never uses (docs/voices.md)`);
  if (!value.trim()) bad(`${key}: empty`);
  // Forever's words claim no optimum and lean on no community (docs/voices.md, "Meta-agnostic"); Era is frozen and not held to it
  if (KEYNS === "forever.") for (const claim of metaClaims(value, SOURCE_NAMES)) bad(`${key}: ${claim} (docs/voices.md, Meta-agnostic)`);
  return key;
}

// ── the facts, a game at a time ──────────────────────────────────────────────
type Tal = { id: number; tab_id: number; row: number; col: number; max_rank: number; spell_id: number; req_points: number; min_level: number };
class Facts {
  db: Database;
  seen = new Map<string, string>(); // every fact read since the last reset, for the lock ("spell 116 name": "Frostbolt")
  tal = new Map<number, Tal>(); // by rank 1's spell
  prereq = new Map<number, { requires: number; rank: number }[]>(); // by talent id
  constructor(
    readonly game: Game,
    readonly classId: number,
  ) {
    this.db = openDb(game);
    for (const t of this.db.query("SELECT id, tab_id, row, col, max_rank, spell_id, req_points, min_level FROM talent WHERE class_id = ?").all(classId) as Tal[]) this.tal.set(t.spell_id, t);
    for (const p of this.db.query("SELECT talent_id, requires_id, rank FROM talent_prereq").all() as { talent_id: number; requires_id: number; rank: number }[]) {
      if (!this.prereq.has(p.talent_id)) this.prereq.set(p.talent_id, []);
      this.prereq.get(p.talent_id)!.push({ requires: p.requires_id, rank: p.rank });
    }
  }
  /** A spell's name in the game's data (null: no such spell). */
  name(spell: number): string | null {
    const r = this.db.query("SELECT name FROM name WHERE kind = 'spell' AND id = ? AND locale = 'enUS'").get(spell) as { name: string } | null;
    this.seen.set(`spell ${spell} name`, r ? r.name : "none");
    return r ? r.name : null;
  }
  /** The level a class learns a spell at: its book's (null: not in it, or no level). */
  level(spell: number): number | null | undefined {
    const r = this.db.query("SELECT level FROM class_spell WHERE class_id = ? AND spell_id = ?").get(this.classId, spell) as { level: number | null } | null;
    this.seen.set(`spell ${spell} level`, r ? String(r.level) : "none");
    return r ? r.level : undefined;
  }
  /** Every rank of a spell in the class's book: the spells that share its name (the game gives each rank its own id,
   * and a character with a higher rank may no longer report the lower one). The spell's own id first. */
  family(spell: number): number[] {
    const rows = this.db
      .query(
        "SELECT cs.spell_id AS id FROM class_spell cs JOIN name n ON n.kind = 'spell' AND n.id = cs.spell_id AND n.locale = 'enUS' WHERE cs.class_id = ? AND cs.kind <> 'rune' AND n.name = (SELECT name FROM name WHERE kind = 'spell' AND id = ? AND locale = 'enUS') ORDER BY cs.spell_id",
      )
      .all(this.classId, spell) as { id: number }[];
    const ids = [spell, ...rows.map((r) => r.id).filter((id) => id !== spell)];
    this.seen.set(`spell ${spell} family`, ids.join(","));
    return ids;
  }
  /** A spell's picture in the data (null: none, the row would show a blank). */
  icon(spell: number): string | null {
    const r = this.db.query("SELECT icon_path FROM spell_info WHERE spell_id = ?").get(spell) as { icon_path: string | null } | null;
    this.seen.set(`spell ${spell} icon`, r?.icon_path ?? "none");
    return r?.icon_path ?? null;
  }
  /** The forms a spell can be pressed in, from the client's own table (SpellShapeshift): null when it asks for none. */
  stances(spell: number): string[] | null {
    const r = this.db.query("SELECT stance_mask, stance_exclude FROM spell_info WHERE spell_id = ?").get(spell) as { stance_mask: number | null; stance_exclude: number | null } | null;
    this.seen.set(`spell ${spell} forms`, r?.stance_mask ? `${r.stance_mask}/${r.stance_exclude ?? 0}` : "none");
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
  // the talent path (and each road's): simulate the points
  const simulate = (steps: Step[], label: string) => {
    const spent = new Map<number, number>(); // tab -> points
    const rank = new Map<number, number>(); // talent id -> rank
    const taken = new Map<number, number>(); // talent spell -> the level the path first takes it
    let point = 0;
    steps.forEach((s, i) => {
      const where = `${at} ${label} ${i + 1}`;
      const n = s.points[1] - s.points[0] + 1;
      // every pick has a reason of its own, what this talent does for this build: never empty, never about "this road",
      // and short enough for the three lines the Talents tab gives it
      if (!s.why?.trim()) bad(`${where}: a pick has its own reason`);
      else if (/\broad\b/i.test(s.why)) bad(`${where}: the reason is about the road, not what the talent does ("${s.why}")`);
      else if (s.why.length > BUDGET_PICK_WHY) bad(`${where}: the reason is over ${BUDGET_PICK_WHY} characters`);
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
        if (!taken.has(o.spell_id)) taken.set(o.spell_id, s.level[0]); // the first point in it is the level it works from
      }
      rank.set(t.id, s.rank);
      spent.set(t.tab_id, before + n);
    });
    if (point > 51) bad(`${at} ${label}s: ${point} points, 51 is the most`);
    if (point !== 51) bad(`${at} ${label}s: spend ${point} points, a full path 51`);
    // the build's own tree reaches its deepest talent
    if ((spent.get(b.tree) ?? 0) < 31) bad(`${at} ${label}s: put ${spent.get(b.tree) ?? 0} points in tree ${b.tree}, its own tree takes at least 31`);
    return { taken, spent };
  };
  const takens = [simulate(b.path, "path step").taken];
  for (const [i, road] of (b.roads ?? []).entries()) takens.push(simulate(road.path, `road ${i + 2} step`).taken);
  const tab = f.db.query("SELECT name FROM name WHERE kind = 'talent_tab' AND id = ? AND locale = 'enUS'").get(b.tree) as { name: string } | null;
  f.seen.set(`tree ${b.tree} name`, tab ? tab.name : "none");
  if (!tab || tab.name !== b.name) bad(`${at}: the build is named ${b.name}, its tree ${b.tree} ${tab ? tab.name : "is no tree"}`);
  // the stages follow each other
  let next = b.stages[0]?.from ?? 1;
  for (const st of b.stages) {
    if (st.from !== next || st.to < st.from) bad(`${at}: stage ${st.from}-${st.to} doesn't follow the one before`);
    next = st.to + 1;
  }
  if (next !== 61) bad(`${at}: the stages end at level ${next - 1}, not 60`);
  const stances = new Map<number, string>(); // a spell's stances, one list a build
  // A row's or a plan step's spell: in the game's data and the class's book (or a talent's rank 1, or a spell
  // every character has), its level the data's, its forms checked against the client's table, its talents on the path
  const checkRow = (r: Row, where: string, st: Stage) => {
    {
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
        else
          takens.forEach((taken, road) => {
            const via = road === 0 ? "the path" : `road ${road + 1}`;
            if (!taken.has(tid)) bad(`${where}: needs talent ${f.name(tid)}, ${via} never takes it`);
            else if (taken.get(tid)! > st.to) bad(`${where}: needs talent ${f.name(tid)}, ${via} takes it at level ${taken.get(tid)}, after the stage's ${st.to}`);
          });
      }
      const want = JSON.stringify(r.need.stance?.length ? r.need.stance : (filled.get(r) ?? []));
      const had = stances.get(r.spell);
      if (had !== undefined && had !== want) bad(`${where}: stance ${want}, another row of the build says ${had}: one list for a spell`);
      stances.set(r.spell, want);
      (r as Row & { learned: number }).learned = level;
      (r as Row & { family?: number[] }).family = f.family(r.spell);
    }
  };
  // A rotation plan (the stage's opening, loop, between fights, low resource and big cooldowns): every
  // spell checked as a row is, every line a clause with its reason, the loop's last line the one that applies
  // when nothing above does (so it has no condition and every other line of the loop has one)
  const checkPlan = (plan: Plan, where: string, st: Stage, alt = false) => {
    const clause = (text: string | undefined, at: string, what: string) => {
      if (text === undefined) return;
      if (/[.!?;:]$/.test(text.trim())) bad(`${at}: ${what} is a clause, with no full stop at its end`);
      if (text.trim().split(/\s+/).length > CLAUSE_WORDS) bad(`${at}: ${what} is over ${CLAUSE_WORDS} words, a plan line is one short clause`);
    };
    const step = (x: PlanStep, at: string, needWhy = true) => {
      if (x.spell !== undefined) {
        if (!x.name) return bad(`${at}: a spell with no name`);
        x.need ??= {};
        if (COMMON_SPELLS[x.spell] !== undefined) {
          if (COMMON_SPELLS[x.spell][0] !== x.name) bad(`${at}: spell ${x.spell} is ${COMMON_SPELLS[x.spell][0]}, ${x.name} in the content`);
          const n = f.name(x.spell);
          if (n !== x.name) bad(`${at}: spell ${x.spell} is ${n ?? "not in the data"} in ${f.game}'s data, ${x.name} in the content`);
          (x as Row & { learned: number }).learned = 1;
        } else {
          checkRow(x as Row, at, st);
        }
        // a picture for every spell: a row never shows a blank
        if (COMMON_SPELLS[x.spell] === undefined && f.icon(x.spell) === null) bad(`${at}: spell ${x.spell} has no picture in the data`);
        // a row that stands for the best of a few spells (an armour, a seal): the best first, the baseline the row's own spell
        if (x.best) {
          const infos: { spell: number; level: number; family: number[] }[] = [];
          for (const id of x.best) {
            const lv = f.level(id);
            if (f.name(id) === null || lv === undefined || lv === null) bad(`${at}: best spell ${id} is not in the class's book`);
            else infos.push({ spell: id, level: lv, family: f.family(id) });
            if (f.icon(id) === null) bad(`${at}: best spell ${id} has no picture in the data`);
          }
          if (infos.some((b, i) => i > 0 && b.level > infos[i - 1].level)) bad(`${at}: best runs best first, a later spell is learned at a higher level than an earlier one`);
          if (x.best[x.best.length - 1] !== x.spell) bad(`${at}: the last of best is the row's own spell (the one every character has)`);
          (x as { bestInfo?: typeof infos }).bestInfo = infos;
        }
      } else if (!x.text) bad(`${at}: neither a spell nor a text`);
      else {
        const k = `${b.key} (${f.game})`;
        noSpell.set(k, [...(noSpell.get(k) ?? []), x.text]);
      }
      if (needWhy && !x.why) bad(`${at}: no reason`);
      const over = (x.name ?? x.text ?? "").length + (x.if ? 1 + x.if.length : 0) > BUDGET_LINE || (x.why?.length ?? 0) > BUDGET_WHY;
      if (over) bad(`${at}: over the line budget (name and condition ${BUDGET_LINE} characters, reason ${BUDGET_WHY})`);
      clause(x.if, at, "its condition");
      clause(x.why, at, "its reason");
      clause(x.say, at, "its instruction");
    };
    if ((plan.opening?.length ?? 0) > BUDGET_OPENING) bad(`${where}: an opening of more than ${BUDGET_OPENING} steps`);
    if ((plan.loop?.length ?? 0) > BUDGET_LOOP) bad(`${where}: a loop of more than ${BUDGET_LOOP} lines`);
    for (const name of PLAN_LISTS) {
      const steps = plan[name] ?? [];
      if ((name === "loop" || (name === "opening" && !alt)) && !steps.length) bad(`${where}: a plan has ${name === "loop" ? "a" : "an"} ${name}`);
      steps.forEach((x, i) => {
        const at = `${where} plan ${name} ${i + 1}${x.name ? ` (${x.name})` : ""}`;
        step(x, at);
        const last = name === "loop" && i === steps.length - 1;
        if (last && x.if) bad(`${at}: the last line of the loop is the one that applies when nothing above does, it has no condition`);
        if (!last && (name === "loop" || name === "rarely" || name === "between" || name === "low") && !x.if) bad(`${at}: a line of the ${name} says when it applies`);
      });
    }
    if (plan.alt) {
      if (!plan.alt.name || !plan.alt.say) bad(`${where} plan alt: a name and a line on when it is for`);
      clause(plan.alt.say, `${where} plan alt`, "its line");
      checkPlan({ ...plan.alt, opening: plan.alt.opening ?? [] } as Plan, `${where} alt`, st, true);
    }
    if (plan.big) {
      if (!plan.big.say) bad(`${where} plan big: a line that says when`);
      clause(plan.big.say, `${where} plan big`, "its line");
      plan.big.spells.forEach((x, i) => step(x, `${where} plan big ${i + 1}${x.name ? ` (${x.name})` : ""}`, false));
    }
  };
  b.stages.forEach((st) => {
    const where = `${at} stage ${st.from}-${st.to}`;
    if (!st.rows && !st.plan) bad(`${where}: neither rows nor a plan`);
    (st.rows ?? []).forEach((r, ri) => checkRow(r, `${where} row ${ri + 1} (${r.name})`, st));
    if (st.plan) checkPlan(st.plan, where, st);
  });
}

// ── the Lua ──────────────────────────────────────────────────────────────────
const q = (s: string) => `"${s.replace(/\\/g, "\\\\").replace(/"/g, '\\"')}"`;
const list = (a: (string | number)[]) => `{ ${a.join(", ")} }`;

function rowLua(r: Row & { learned: number }, key: string): string {
  const f = [`spell = ${r.spell}`, `level = ${r.learned}`];
  const fam = (r as Row & { family?: number[] }).family;
  if (fam && fam.length > 1) f.push(`family = ${list(fam)}`);
  if (r.talentSpell !== undefined) f.push(`talent = ${r.talentSpell}`);
  if (r.need.talents?.length) f.push(`talents = ${list(r.need.talents)}`);
  const stance = r.need.stance?.length ? r.need.stance : filled.get(r);
  if (stance?.length) f.push(`stance = ${list(stance.map(q))}`);
  if (r.need.when?.length) f.push(`when = ${list(r.need.when.map(q))}`);
  f.push(`say = ${q(key)}`);
  return `{ ${f.join(", ")} }`;
}

// Every spell line of a stage, its priority rows and its plan's steps
function stepsOf(st: Stage): (Row | PlanStep)[] {
  const plan = st.plan ? [...PLAN_LISTS.flatMap((n) => [...(st.plan![n] ?? []), ...(st.plan!.alt?.[n] ?? [])]), ...(st.plan.big?.spells ?? [])] : [];
  return [...(st.rows ?? []), ...plan];
}

// A plan step as Lua: its spell (or its text), the level it is learned at, its talents and forms, and the keys of
// its words (cond: when it applies, say: what to do, why: the reason)
function stepLua(x: PlanStep & { learned?: number }, key: string, bare = false): string {
  const f: string[] = [];
  if (x.spell !== undefined) {
    f.push(`spell = ${x.spell}`, `level = ${x.learned}`);
    const fam = (x as { family?: number[] }).family;
    if (fam && fam.length > 1) f.push(`family = ${list(fam)}`);
    const bi = (x as { bestInfo?: { spell: number; level: number; family: number[] }[] }).bestInfo;
    if (bi) f.push(`best = { ${bi.map((b) => `{ spell = ${b.spell}, level = ${b.level}${b.family.length > 1 ? `, family = ${list(b.family)}` : ""} }`).join(", ")} }`);
    if (COMMON_SPELLS[x.spell] !== undefined) f.push("common = true", `icon = ${q(COMMON_SPELLS[x.spell][1])}`);
    if (x.talentSpell !== undefined) f.push(`talent = ${x.talentSpell}`);
    if (x.need?.talents?.length) f.push(`talents = ${list(x.need.talents)}`);
    const stance = x.need?.stance?.length ? x.need.stance : filled.get(x as unknown as Row);
    if (stance?.length) f.push(`stance = ${list(stance.map(q))}`);
  } else f.push(`text = ${q(word(`${key}.text`, x.text)!)}`);
  if (!bare) {
    if (x.if) f.push(`cond = ${q(word(`${key}.if`, x.if)!)}`);
    if (x.say) f.push(`say = ${q(word(`${key}.say`, x.say)!)}`);
    if (x.why) f.push(`why = ${q(word(`${key}.why`, x.why)!)}`);
  }
  return `{ ${f.join(", ")} }`;
}

const noSpell = new Map<string, string[]>(); // build (game): the plan lines that name no spell, so show no picture
const lockNow: Lock = { classic: {}, forever: {} }; // what each build read this run, for the lock

function luaFor(game: Game): { lua: string; builds: number } {
  KEYNS = game === "forever" ? "forever." : "";
  const lines: string[] = [];
  const classes: string[] = [];
  const builds: string[] = [];
  const used = new Map<number, Tal>(); // the talents the builds name, by rank 1's spell
  const advice: string[] = []; // the level-10 advice a class's content adds, by class and role
  const cells: string[] = []; // every talent of the classes written, cell by cell (the window draws the trees from them)
  let version = "";
  for (const c of content[game]) {
    const mine = c.builds;
    if (!mine.length) continue;
    const f = new Facts(game, c.class.id);
    version = f.pins();
    for (const [key, [id, name]] of Object.entries(STANCE_SPELLS)) {
      const n = f.name(id);
      if (n !== name) bad(`${c.class.key} (${game}): the ${key} stance is spell ${id}, ${n ?? "not in the data"}, not ${name}`);
    }
    const card = Object.entries(c.class.card).map(([k, v]) => `${k} = ${q(v)}`);
    const ov = c.class.overview;
    if (ov) for (const k of Object.keys(ov)) if (!OVERVIEW.includes(k)) bad(`${c.class.key} overview: ${k} is none of ${OVERVIEW.join(", ")}`);
    const overview = ov ? `, overview = { ${OVERVIEW.filter((k) => ov[k] !== undefined).map((k) => `${k} = ${q(word(`${c.class.key}.ov.${k}`, ov[k])!)}`).join(", ")} }` : "";
    classes.push(`    [${c.class.id}] = { token = ${q(c.class.token)}, key = ${q(c.class.key)}, text = ${q(word(`${c.class.key}`, c.class.text)!)}, builds = ${list(mine.map((b) => b.id))}, card = { ${card.join(", ")} }${overview} },`);
    const mineAdvice: string[] = [];
    for (const a of c.class.advice ?? []) {
      if (!ROLES.includes(a.role)) bad(`${c.class.key} advice: role ${a.role} is none of ${ROLES.join(", ")}`);
      else if (!mine.some((b) => b.role === a.role)) bad(`${c.class.key} advice: no ${a.role} build is written for ${game}`);
      else mineAdvice.push(`${a.role} = { say = ${a.say ? q(word(`${c.class.key}.advice.${a.role}`, a.say)!) : "false"} }`);
    }
    if (mineAdvice.length) advice.push(`    [${c.class.id}] = { ${mineAdvice.join(", ")} },`);
    // one recommended build a role, with its reason (the page never asks which: docs/data.md)
    const roles: string[] = [];
    for (const role of new Set(mine.map((b) => b.role))) {
      const r = c.class.roles?.[role];
      if (!r) {
        bad(`${c.class.key} (${game}): the ${role} role has no recommended build (class.roles.${role})`);
        continue;
      }
      const chosen = mine.find((b) => b.key === r.build);
      if (!chosen || chosen.role !== role) bad(`${c.class.key} (${game}): roles.${role} names ${r.build}, no ${role} build of the class`);
      if (!r.reason || r.reason.trim().split(/\s+/).length > 30) bad(`${c.class.key} (${game}): roles.${role} gives a reason of 30 words at most`);
      else roles.push(`${role} = { build = ${chosen?.id ?? 0}, why = ${q(word(`${c.class.key}.role.${role}`, r.reason)!)} }`);
    }
    for (const role of Object.keys(c.class.roles ?? {})) if (!mine.some((b) => b.role === role)) bad(`${c.class.key} (${game}): roles.${role}, but no ${role} build is written for ${game}`);
    if (roles.length) classes[classes.length - 1] = classes[classes.length - 1].replace(/ \},$/, `, roles = { ${roles.join(", ")} } },`);
    const all = [...f.tal.values()].sort((a, b) => a.tab_id - b.tab_id || a.row - b.row || a.col - b.col);
    // the class's whole trees are locked too: the Talents tab draws every cell, so one that moves must be read
    const treeFacts: Record<string, string> = {};
    for (const t of all) treeFacts[`cell ${t.spell_id}`] = `tree ${t.tab_id} row ${t.row} column ${t.col}, ${t.max_rank} ranks, ${t.req_points} points asked, needs ${(f.prereq.get(t.id) ?? []).map((p) => `${p.requires} at ${p.rank ?? 0}`).sort().join(", ") || "none"}`;
    lockNow[game][`cells:${c.class.key}`] = { build: f.build(), facts: treeFacts };
    for (const t of all) {
      const pre = (f.prereq.get(t.id) ?? []).map((p) => `{ id = ${p.requires}, rank = ${p.rank ?? 0} }`);
      cells.push(`    { class = ${c.class.id}, spell = ${t.spell_id}, id = ${t.id}, tab = ${t.tab_id}, row = ${t.row}, col = ${t.col}, max = ${t.max_rank}, req = ${t.req_points}${pre.length ? `, pre = { ${pre.join(", ")} }` : ""} },`);
    }
    for (const b of mine) {
      f.seen = new Map();
      checkBuild(b, f);
      const k = b.key;
      const names = [...[b.path, ...(b.roads ?? []).map((r) => r.path)].flat().flatMap((s) => s.any ?? (s.talent === undefined ? [] : [s.talent])), ...b.stages.flatMap((st) => stepsOf(st).flatMap((r) => [...(r.need?.talents ?? []), ...(r.talentSpell !== undefined ? [r.talentSpell] : [])]))];
      for (const n of names) if (f.tal.has(n)) used.set(n, f.tal.get(n)!);
      for (const n of new Set(names)) {
        const t = f.tal.get(n);
        if (!t) continue;
        f.seen.set(`talent ${n} cell`, `tree ${t.tab_id} row ${t.row} column ${t.col}, id ${t.id}`);
        f.seen.set(`talent ${n} ranks`, String(t.max_rank));
        f.seen.set(`talent ${n} points asked`, String(t.req_points));
        f.seen.set(`talent ${n} first level`, String(t.min_level));
        f.seen.set(`talent ${n} needs`, (f.prereq.get(t.id) ?? []).map((p) => `${p.requires} at ${p.rank ?? 0}`).sort().join(", ") || "none");
      }
      lockNow[game][b.key] = { build: f.build(), facts: Object.fromEntries([...f.seen].sort(([a], [b]) => (a < b ? -1 : 1))) };
      const out: string[] = [];
      out.push(`    [${b.id}] = {`);
      out.push(`      key = ${q(k)}, class = ${c.class.id}, role = ${q(b.role)}, tree = ${b.tree}, name = ${q(b.name)},`);
      out.push(`      checked = ${q(b.checked)}, build = ${q(f.build())},`);
      out.push(`      intro = ${q(word(`${k}.intro`, b.intro)!)}, note = ${q(word(`${k}.note`, b.pathNote)!)},`);
      out.push(`      line = ${q(word(`${k}.line`, b.line ?? b.intro.split(/(?<=\.)\s/)[0])!)},`);
      if (b.hardcore?.length) out.push(`      hardcore = ${list(b.hardcore.map((t, i) => q(word(`${k}.hc${i + 1}`, t)!)))},`);
      for (const src of b.sources ?? []) if (!src.label || !/^https?:\/\//.test(src.url) || !/^\d{4}-\d{2}-\d{2}$/.test(src.read)) bad(`${k}: a source is a label, a url and the day it was read (YYYY-MM-DD)`);
      if (b.variant) out.push(`      variant = ${q(word(`${k}.variant`, b.variant)!)},`);
      if (b.split) out.push(`      split = ${q(word(`${k}.split`, b.split)!)},`);
      if (b.dry) out.push(`      dry = ${q(word(`${k}.dry`, b.dry)!)},`);
      const pathLua = (steps: Step[], key: string, pad: string) =>
        steps.map((s, i) => {
          const t = s.any ? `any = ${list(s.any)}` : `talent = ${s.talent}`;
          return `${pad}{ points = ${list(s.points)}, level = ${list(s.level)}, ${t}, rank = ${s.rank}, why = ${q(word(`${key}.p${i + 1}`, s.why)!)} },`;
        });
      out.push("      path = {");
      out.push(...pathLua(b.path, k, "        "));
      out.push("      },");
      if (b.roads?.length) {
        const ids = [b.roadId ?? "", ...b.roads.map((r) => r.id)];
        if (ids.some((id) => !id) || new Set(ids).size !== ids.length) bad(`${k}: every road has its own id (roadId, roads[].id)`);
        const at = (id: string | undefined, what: string) => {
          const n = ids.indexOf(id ?? "");
          if (n < 0) bad(`${k}: ${what} ${id} is no road of the build (${ids.join(", ")})`);
          return n + 1;
        };
        const rec = at(b.recommended, "recommended");
        for (const id of b.alsoRecognised ?? []) if (id === b.recommended) bad(`${k}: the recommended road is not also only recognised`);
        const also = (b.alsoRecognised ?? ids.filter((id) => id !== b.recommended)).map((id) => at(id, "alsoRecognised"));
        if (!b.roadReason) bad(`${k}: a recommendation says why, and the price of the other road (roadReason)`);
        const hc = b.hardcoreRoad !== undefined ? at(b.hardcoreRoad, "hardcoreRoad") : undefined;
        if (hc !== undefined && !b.hardcoreReason) bad(`${k}: a Hardcore road says why (hardcoreReason)`);
        out.push(`      recommended = ${rec}, recognised = ${list(also)}${hc !== undefined ? `, hardcoreRoad = ${hc}` : ""},`);
        out.push(`      roadWhy = ${q(word(`${k}.roadwhy`, b.roadReason ?? "")!)}${b.hardcoreReason ? `, hardcoreWhy = ${q(word(`${k}.hcwhy`, b.hardcoreReason)!)}` : ""},`);
        out.push("      roads = {");
        out.push(`        { ${b.roadName ? `name = ${q(word(`${k}.road1`, b.roadName)!)}` : ""} },`);
        b.roads.forEach((road, ri) => {
          out.push(`        { ${road.name ? `name = ${q(word(`${k}.road${ri + 2}`, road.name)!)}, ` : ""}path = {`);
          out.push(...pathLua(road.path, `${k}.r${ri + 2}`, "          "));
          out.push("        } },");
        });
        out.push("      },");
      }
      out.push("      stages = {");
      b.stages.forEach((st, si) => {
        if (st.phase !== undefined && !PHASES.includes(st.phase)) bad(`${b.key} stage ${st.from}-${st.to}: phase ${st.phase} is none of ${PHASES.join(", ")}`);
        const phase = st.phase ? `, phase = ${q(st.phase)}` : "";
        const about = st.about ? `, about = ${q(word(`${k}.s${si + 1}`, st.about)!)}` : "";
        out.push(`        { from = ${st.from}, to = ${st.to}${phase}${about},`);
        if (st.opening) out.push(`          opening = ${q(word(`${k}.s${si + 1}.opening`, st.opening)!)},`);
        if (st.rows?.length) {
          out.push("          rows = {");
          st.rows.forEach((r, ri) => out.push(`            ${rowLua(r as Row & { learned: number }, word(`${k}.s${si + 1}.r${ri + 1}`, r.say)!)},`));
          out.push("          },");
        }
        if (st.plan) {
          out.push("          plan = {");
          const lists = (plan: Plan | NonNullable<Plan["alt"]>, key: string, pad: string) => {
            for (const name of PLAN_LISTS) {
              const steps = (plan as Plan)[name] ?? [];
              if (!steps.length) continue;
              out.push(`${pad}${name} = {`);
              steps.forEach((x, i) => out.push(`${pad}  ${stepLua(x as PlanStep & { learned?: number }, `${key}.${name}${i + 1}`)},`));
              out.push(`${pad}},`);
            }
          };
          lists(st.plan, `${k}.s${si + 1}`, "            ");
          if (st.plan.alt) {
            const alt = st.plan.alt;
            out.push(`            alt = { name = ${q(word(`${k}.s${si + 1}.alt.name`, alt.name)!)}, say = ${q(word(`${k}.s${si + 1}.alt.say`, alt.say)!)},`);
            lists(alt, `${k}.s${si + 1}.alt`, "              ");
            out.push("            },");
          }
          if (st.plan.big) {
            const big = st.plan.big;
            out.push(`            big = { say = ${q(word(`${k}.s${si + 1}.big`, big.say)!)}, spells = {`);
            big.spells.forEach((x, i) => out.push(`              ${stepLua(x as PlanStep & { learned?: number }, `${k}.s${si + 1}.big${i + 1}`, true)},`));
            out.push("            } },");
          }
          out.push("          },");
        }
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
    "--   classes[id].overview = { who, good, bad, resource, levelling, ten (word keys): the class in general, optional }",
    "--   builds[id]  = { key, class, role, tree (a talent tab), name, checked, build (the client), line (one line for the overview), variant (a word after the tree name, when two builds share it),",
    "--                   intro, note, split, dry (word keys), path, stages }",
    "--   roads[n]    = { name (a word key), path (the others; the first is `path`) }: another order of the points for the same build",
    "--   recommended (a road's number: ours, from the research), recognised (the numbers kept only to be recognised), hardcoreRoad (on a Hardcore realm), roadWhy and hardcoreWhy (word keys: why, and the price of the other)",
    "--   path[n]     = { points = { from, to }, level = { from, to }, talent (rank 1's spell) or any (a choice),",
    "--                   rank (it reaches), why }",
    "--   stages[n]   = { from, to (levels), phase (untalented, choose or spent: the character's phase it serves, none: any), about, opening, rows }",
    "--   advice[class][role] = { say (a word key, or false): the writer's line for the level-10 advice, after the builds that fit and the first three picks of the first)",
    "--   rows[n]     = { spell (rank 1), level (it is learned), talent (a talent's spell), talents (taken first),",
    "--                   stance (stances it is pressed in: the writer's, else what the client's table allows), when (a situation), say }",
    "--   talents[spell] = { id (the talent's, as the game's talent call gives it), tab (its tree), max (its ranks), req (points in its tree it asks) }, every talent the builds name",
    "--   cells[n]       = { class, spell (rank 1), id, tab, row, col, max (ranks), req (points the tree asks), pre = { { id, rank } } }, every talent of the classes written:",
    "--                    the trees as the game draws them" + (game === "forever" ? " (Forever's rows, columns and prerequisites are inferred, docs/data.md)" : ""),
    "--   stances[key]   = the spell that is the form (its name is the game's, by id)",
    "--   roles on a class = { [role] = { build (id), why (word key) } }: the one build the page advises for the role",
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
    ...[...used.keys()].sort((a, b) => a - b).map((sp) => `    [${sp}] = { id = ${used.get(sp)!.id}, tab = ${used.get(sp)!.tab_id}, max = ${used.get(sp)!.max_rank}, req = ${used.get(sp)!.req_points} },`),
    "  },",
    "  advice = {",
    ...advice,
    "  },",
    ...(game === "forever" ? ["  inferred = true,"] : []),
    "  cells = {",
    ...cells,
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

// ── the lock: the facts each build read, as they were when a person last stamped it ──
const lock: Lock = existsSync(LOCK_FILE) ? JSON.parse(readFileSync(LOCK_FILE, "utf8")) : { classic: {}, forever: {} };
let lockOut: Lock | null = null;
if (STAMP) {
  const [game, which] = STAMP;
  if (!GAMES.includes(game as Game) || !which) bad("--stamp <classic|forever> <build key | all>");
  else if (which !== "all" && !lockNow[game as Game][which] && !lock[game as Game]?.[which]) bad(`--stamp: no build ${which} written for ${game}`);
  else {
    lockOut = structuredClone(lock);
    for (const [key, entry] of Object.entries(lockNow[game as Game])) {
      if (which === "all" || which === key) {
        // what the stamp accepts, said out loud
        for (const m of diffFacts(lock[game as Game]?.[key]?.facts ?? {}, entry.facts)) console.log(`stamping ${game} ${key}: ${m}`);
        lockOut[game as Game][key] = { ...entry, stamped: new Date().toISOString().slice(0, 10) };
      } else {
        const was = lock[game as Game]?.[key];
        if (!was) bad(`${game} ${key}: not in facts.lock.json, stamp it as well`);
        else for (const m of diffFacts(was.facts, entry.facts)) bad(`${game} ${key}: ${m} (not stamped: this run stamps ${which})`);
      }
    }
    for (const key of Object.keys(lockOut[game as Game])) {
      if (lockNow[game as Game][key] || (which !== "all" && which !== key)) continue;
      console.log(`stamping ${game} ${key}: dropped, no such build is written any more`);
      delete lockOut[game as Game][key];
    }
  }
} else {
  for (const g of GAMES) {
    for (const [key, now] of Object.entries(lockNow[g])) {
      const was = lock[g]?.[key];
      if (!was) bad(`${g} ${key}: not in facts.lock.json, read its facts then bun scripts/guide.ts --stamp ${g} ${key}`);
      else for (const m of diffFacts(was.facts, now.facts)) bad(`${g} ${key}: ${m} (read it, then bun scripts/guide.ts --stamp ${g} ${key})`);
    }
    for (const key of Object.keys(lock[g] ?? {})) if (!lockNow[g][key]) bad(`${g} ${key}: in facts.lock.json, but no such build is written any more (bun scripts/guide.ts --stamp ${g} ${key} drops it)`);
  }
}
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
if (lockOut) writeFileSync(LOCK_FILE, JSON.stringify(lockOut, null, 1) + "\n");
for (const [file, lua] of outputs) {
  const now = existsSync(file) ? readFileSync(file, "utf8") : "";
  if (now === lua) continue;
  if (CHECK) {
    console.error(`✗ ${file.replace(ROOT + "/", "")} is out of date: bun scripts/guide.ts`);
    stale = true;
  } else writeFileSync(file, lua);
}
if (stale) process.exit(1);
for (const [k, texts] of noSpell) console.log(`note: ${k}: plan lines that name no spell and show no picture (${[...new Set(texts)].join(", ")})`);
console.log(`✓ the guide: ${GAMES.reduce((n, g) => n + content[g].reduce((m, c) => m + c.builds.length, 0), 0)} builds, ${sorted.length} words, the facts checked and locked in ${GAMES.filter((g) => content[g].length).join(" and ")}`);
