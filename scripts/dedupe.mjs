// Each title appears in only one service's list: the one where it ranks highest.
// Ties go to the service listed first in the manifest.
import { readFile, writeFile } from "node:fs/promises";
const OUT = process.env.OUT || "rt";
const manifest = JSON.parse(await readFile(`${OUT}/manifest.json`, "utf8"));
for (const type of manifest.types) {
  const cats = manifest.catalogs.filter(c => c.type === type);
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
  for (const c of cats) {
    if (!lists[c.id]) continue;
    const kept = lists[c.id].filter(m => best[m.id][2] === c.id);
    console.log(`${type} ${c.name}: ${lists[c.id].length} -> ${kept.length}`);
    await writeFile(`${OUT}/catalog/${type}/${c.id}.json`, JSON.stringify({ metas: kept }, null, 2));
  }
}
