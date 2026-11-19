// Each title appears in only one service's list: the one where it ranks highest.
// Titles on the PRIORITY list (Hulu by default) always stay there.
// Ties go to the service listed first in the manifest.
import { readFile, writeFile } from "node:fs/promises";
import { writeCatalog } from "./catalog-files.mjs";
const OUT = process.env.OUT || "rt";
const PRIORITY = process.env.PRIORITY || "rt-list";
const manifest = JSON.parse(await readFile(`${OUT}/manifest.json`, "utf8"));
for (const type of manifest.types) {
  const cats = manifest.catalogs.filter(c => c.type === type && c.id.startsWith("rt-"));
  const lists = {};
  for (const c of cats) {
    try { lists[c.id] = JSON.parse(await readFile(`${OUT}/catalog/${type}/${c.id}.json`, "utf8")).metas; }
    catch { lists[c.id] = null; }
  }
  const best = {}; // imdb id -> [rank, order, catalog id]
  cats.forEach((c, order) => (lists[c.id] || []).forEach((m, rank) => {
    const b = best[m.id];
    if (!b || rank < b[0] || (rank === b[0] && order < b[1])) best[m.id] = [rank, order, c.id];
  }));
  for (const m of lists[PRIORITY] || []) best[m.id] = [-1, -1, PRIORITY];
  for (const c of cats) {
    if (!lists[c.id]) continue;
    const kept = lists[c.id].filter(m => best[m.id][2] === c.id);
    console.log(`${type} ${c.name}: ${lists[c.id].length} -> ${kept.length}`);
    await writeCatalog(`${OUT}/catalog/${type}/${c.id}`, kept);
  }
}
