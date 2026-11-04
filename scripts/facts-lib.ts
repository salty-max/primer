/**
 * The facts lock's shape and its comparison (scripts/guide.ts holds the file,
 * facts.lock.json): per game and build, every fact the build read, as a key the
 * reader can say ("spell 116 level") and the value it had when a person last
 * stamped the build. Pure, so a test can change a fact and expect the red.
 */
export type Entry = { build: string; stamped?: string; facts: Record<string, string> };
export type Lock = Record<"classic" | "forever", Record<string, Entry>>;

/** What moved between two readings of a build's facts, one sentence each (empty: nothing). */
export function diffFacts(was: Record<string, string>, now: Record<string, string>): string[] {
  const out: string[] = [];
  const name = (facts: Record<string, string>, key: string) => {
    const m = /^(spell|talent) (\d+) /.exec(key);
    const n = m && (facts[`spell ${m[2]} name`] ?? null);
    return n && n !== "none" ? ` (${n})` : "";
  };
  for (const key of Object.keys(was).sort()) {
    const sentence = key.replace(/^(spell|talent) (\d+)/, (_, kind, id) => `${kind} ${id}${name({ ...now, ...was }, key)}`);
    if (!(key in now)) out.push(`${sentence} is no longer read`);
    else if (was[key] !== now[key]) out.push(`${sentence}: ${was[key]} became ${now[key]}`);
  }
  for (const key of Object.keys(now).sort()) if (!(key in was)) out.push(`${key} is read now and was not locked`);
  return out;
}
