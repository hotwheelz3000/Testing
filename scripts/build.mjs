// Builds every addon listed in addons.json into the current folder (the Pages branch checkout).
// Usage: node build.mjs [addon folder ...]   (no arguments = build all)
import { readFile } from "node:fs/promises";
import { readJson, writeJson, writeCatalog, saveCache, SKIP_EXTRA } from "./lib.mjs";
import { sources } from "./sources.mjs";

const config = JSON.parse(await readFile(new URL("../addons.json", import.meta.url), "utf8"));
const only = process.argv.slice(2);
let failures = 0;

for (const addon of config.addons) {
  if (only.length && !only.includes(addon.folder)) continue;
  console.log(`\n=== ${addon.name} (${addon.folder})`);

  // One entry per catalog/type pair, in config order.
  const cats = addon.catalogs.flatMap(c => (c.types || [c.type]).map(type => ({ ...c, type })));
  const results = {};

  for (const c of cats) {
    const key = `${c.type}/${c.id}`;
    try {
      const metas = await sources[c.source](c, c.type);
      const unique = metas.filter((m, i) => metas.findIndex(x => x.id === m.id) === i);
      if (!unique.length) throw new Error("no items");
      results[key] = unique;
      console.log(`${c.name} (${c.type}): ${unique.length}`);
    } catch (e) {
      failures++;
      results[key] = (await readJson(`${addon.folder}/catalog/${key}.json`, { metas: [] })).metas;
      console.log(`!! ${c.name} (${c.type}) failed: ${e.message} — keeping last version (${results[key].length})`);
    }
  }

  // Shared titles appear under one catalog only: the priority catalog wins,
  // otherwise whichever catalog ranks the title highest (ties: config order).
  if (addon.dedupe) {
    for (const type of new Set(cats.map(c => c.type))) {
      const group = cats.filter(c => c.type === type);
      const owner = {};
      group.forEach((c, order) => results[`${type}/${c.id}`].forEach((m, rank) => {
        const score = c.id === addon.dedupe.priority ? [-1, -1] : [rank, order];
        const best = owner[m.id];
        if (!best || score[0] < best.score[0] || (score[0] === best.score[0] && score[1] < best.score[1])) owner[m.id] = { id: c.id, score };
      }));
      for (const c of group) {
        const key = `${type}/${c.id}`;
        const before = results[key].length;
        results[key] = results[key].filter(m => owner[m.id].id === c.id);
        if (before !== results[key].length) console.log(`dedupe ${c.name} (${type}): ${before} -> ${results[key].length}`);
      }
    }
  }

  for (const c of cats) await writeCatalog(`${addon.folder}/catalog/${c.type}/${c.id}`, results[`${c.type}/${c.id}`]);

  // Series catalogs first, then movies (stable within each type).
  const listed = [...cats].sort((a, b) => (a.type === "series" ? 0 : 1) - (b.type === "series" ? 0 : 1));
  await writeJson(`${addon.folder}/manifest.json`, {
    id: addon.id, version: addon.version, name: addon.name, description: addon.description,
    resources: ["catalog"],
    types: [...new Set(listed.map(c => c.type))],
    catalogs: listed.map(c => ({ type: c.type, id: c.id, name: c.name, extra: SKIP_EXTRA })),
    idPrefixes: addon.idPrefixes || ["tt"],
  });
}

await saveCache();
console.log(`\nDone. ${failures} catalog(s) failed.`);
