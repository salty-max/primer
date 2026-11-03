/**
 * i18n/<locale>/ → addon/Primer/Text_<locale>.lua, one for every language the
 * game has (a stub where there is no translation yet, so the TOC never names
 * a missing file): each client loads its own, through Text_[TextLocale].lua in
 * the TOCs, and English stays wherever a translation says nothing (Locale.lua).
 * The family's core (scripts/locales-lib.ts, the kit's copy) reads the words,
 * merges the kit's own (i18n/kit/, translated once for every addon), checks
 * them and writes the files.
 *
 * Primer is English only for now (the user's call, 3 November 2026): there is
 * no i18n/<locale>/ yet, so every language but English is a stub of English
 * words, and HIDDEN_LOCALES (deDE, esES, esMX: held out of the family's zips)
 * changes nothing here. A language added later is i18n/<locale>/words.json
 * (and the guide's words in i18n/<locale>/guide.json, which this script will
 * then turn into Guide_<locale>.lua: the wow-translating skill).
 *
 *   bun scripts/locales.ts            write the Text files
 *   bun scripts/locales.ts --check    fail if one isn't up to date, a word has
 *                                     no translation, a translation drops or
 *                                     reorders a blank, or prose has a semicolon
 *   bun scripts/locales.ts --keys     write i18n/words.json, every word to translate
 */
import { join } from "node:path";
import { run } from "./locales-lib";

run({ root: join(import.meta.dir, ".."), addon: "addon/Primer" });
