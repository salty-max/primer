/**
 * The meta gate (5 November 2026, the user's call): a Forever build's words state what a spell or a talent
 * does and what a pick buys and costs, and never claim an optimum or lean on a community's authority.
 * The order of the talents is volatile (a patch or a month of play moves it), so it is "the common choice"
 * with its price, never "the best". docs/voices.md ("Meta-agnostic") has the rule in prose.
 *
 * One list, here: BANNED is what a build's text may not say, ALLOWED the uses that are fine with the reason
 * each is fine. scripts/guide.ts runs `metaClaims` on every word of a Forever build, scripts/meta.test.ts
 * runs it on the content files and on this list's own examples. Era's content is frozen and not held to it.
 */

/** Sites, writers and handles the content once cited. A build's own `sources` labels are added by the caller. */
export const AUTHORITIES = [
  "Mobalytics", "Icy Veins", "Maxroll", "Warcraft Tavern", "Wowhead", "Method", "timesaver", "wow.gg", "WOWTBC",
  "wowforeverbuilds", "talentsforever", "Conquest Capped", "Kami Labs", "Zockify", "mmonster", "patchbot",
  "BirraGzeeZ", "DoubleZug", "Rycn", "Luxrah", "Vareion", "Kargoz", "Crix", "Nicktew", "Celz", "Meyra", "Fouren",
  "Feor", "Jampanos", "Ruse_Cruize", "Ahlaundoh", "Djexde", "DonTheCrown", "Sellin", "Seliathan", "Tiqqle",
  "Wordup", "Seksixeny", "Asuna", "Nescalz", "Feyo", "Teloril", "Nevermore", "Babyhoof",
];

export type Ban = { re: RegExp; why: string };

export const BANNED: Ban[] = [
  { re: /\b(guides?|walkthroughs?|tier lists?)\b/i, why: "leans on what guides say" },
  { re: /\b(most|many|every|all|some|other) (players|people|users)\b/i, why: "leans on what players do" },
  { re: /\b(fastest|quickest|easiest|smoothest|slowest (\w+ )?(way|to level))\b/i, why: "ranks the specs by levelling speed" },
  { re: /\b(community|bis|best-in-slot|top (pick|choice|spec|build)|go-to|no-brainer|highest-rated|highest rated)\b/i, why: "leans on a ranking or a community" },
  { re: /\b(most|nearly all|almost all|nearly everyone|almost everyone) (hunters|warriors|rogues|mages|priests|paladins|shamans|warlocks|druids|casters|healers|tanks)\b|\bplayers? (take|pick|skip|choose|go|start|level|prefer|favour|favor)\b/i, why: "leans on what players do" },
  { re: /\b(best|optimal|optimum|optimally|ideal|perfect|strongest|top-tier|top tier|S-tier|meta|tier)\b/i, why: "claims an optimum" },
  { re: /\b(mandatory|required|essential|must-have|must have|a must)\b/i, why: "calls a pick compulsory" },
  { re: /\b(everyone|everybody) (takes|picks|plays|agrees|uses|skips|levels)\b|\b(standard|consensus|popular|proven)\b/i, why: "leans on what everyone does" },
  { re: /\bthe (only|right|correct|proper|best|one) way\b/i, why: "a build is a way, not the way" },
  { re: /\b(always|never) (take|pick|skip|put|choose|level|spend|start)\b/i, why: "an order given as a law" },
  { re: /(?<!goes |gone |went |go |going )\bwrong\b/i, why: "calls a road wrong" },
  { re: /\b(safer|safest)\b/i, why: "ranks the roads" },
  { re: /\brecommend(ed|s|ation)?\b/i, why: "recommendation is the page's, said as advises" },
];

/** Uses that are fine, each with its reason. A phrase here is cleared wherever it appears. */
export const ALLOWED: { phrase: string; why: string }[] = [
  // none today. An entry is a phrase cleared wherever it appears, with the reason it is a mechanic of the game and no claim.
];

/** Every claim in a text, as "reason: matched text". `names` are the build's own sources (sites and writers). */
export function metaClaims(value: string, names: string[] = [], allowed = ALLOWED): string[] {
  let t = value;
  for (const a of allowed) t = t.split(a.phrase).join(" ");
  const out: string[] = [];
  for (const b of BANNED) {
    const m = t.match(b.re);
    if (m) out.push(`${b.why}: "${m[0]}"`);
  }
  for (const n of [...AUTHORITIES, ...names]) {
    if (n.length < 3) continue;
    const esc = n.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
    // matched in any case ("icy veins"), except Method, a plain word that is a site only in a capital
    if (new RegExp(`(?<![A-Za-z])${esc}(?![A-Za-z])`, n === "Method" ? "" : "i").test(t)) out.push(`names a source: "${n}"`);
  }
  return out;
}

/** The sites and writers a build's `sources` labels name: "Mobalytics, Mage levelling (Kir, 2 November)" gives Mobalytics and Kir. */
export function sourceNames(sources: { label: string }[] = []): string[] {
  const names: string[] = [];
  for (const s of sources) {
    const site = s.label.split(",")[0].trim();
    // Blizzard is the developer and a spell's name (Blizzard, the Mage's), no community authority to hide
    if (site && site !== "Blizzard") names.push(site);
    const who = s.label.match(/\(([^,)]+)/)?.[1]?.trim();
    if (who && /^[A-Za-z_][A-Za-z_ ]*$/.test(who) && !/^(updated|read|beta|counted|dated|via|forever|classic|launch|era)/i.test(who)) names.push(who);
  }
  return names;
}
