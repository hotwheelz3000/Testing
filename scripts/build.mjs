// Builds every addon listed in addons.json into the current folder (the Pages branch checkout).
// Usage: node build.mjs [addon folder ...]   (no arguments = build all)
import { readFile } from "node:fs/promises";
import { readJson, norm } from "./util.mjs";
import { sources } from "./sources.mjs";
import { tmdbEnabled, tmdbGenres } from "./tmdb.mjs";
import { fixArt, saveArtCache } from "./artwork.mjs";
import { saveImdbCache } from "./imdb.mjs";
import { writeCatalog, writeManifest } from "./catalog.mjs";

const MAX = 200;
const config = JSON.parse(await readFile(new URL("../addons.json", import.meta.url), "utf8"));
const only = process.argv.slice(2);
let failures = 0;

// One catalog's items from its source(s). A list cut short by a source hiccup is
// topped up with the previous run's titles (not already listed) so it doesn't shrink.
async function loadCatalog(c, previousPath) {
  const metas = await loadSources(c);
  if (!metas.partial) return metas;
  const seen = new Set(metas.flatMap(m => [m.id, norm(m.name)]));
  const previous = (await readJson(previousPath, { metas: [] })).metas.filter(m => !seen.has(m.id) && !seen.has(norm(m.name)));
  console.log(`  partial list (${metas.length}), topped up with ${Math.min(previous.length, MAX - metas.length)} from last run`);
  return [...metas, ...previous].slice(0, MAX);
}

async function loadSources(c) {
  if (c.merge) {
    // Several sources in order; later ones only add titles not already listed (by id or name).
    const metas = [];
    const seen = new Set();
    for (const part of c.merge) {
      try {
        const got = await sources[part.source](part, c.type);
        if (got.partial) metas.partial = true;
        const added = got.filter(m => !seen.has(m.id) && !seen.has(norm(m.name)));
        added.forEach(m => { metas.push(m); seen.add(m.id); seen.add(norm(m.name)); });
        console.log(`  ${part.source}: ${got.length} found, ${added.length} added`);
      } catch (e) { console.log(`  ${part.source} failed: ${e.message}`); }
    }
    const out = metas.slice(0, MAX);
    out.partial = metas.partial;
    return out;
  }
  try { return await sources[c.source](c, c.type); }
  catch (e) {
    if (!c.fallback) throw e;
    console.log(`  ${c.source} failed (${e.message}), using fallback ${c.fallback.source}`);
    return sources[c.fallback.source](c.fallback, c.type);
  }
}

// Shared titles stay in one catalog only: the priority catalog wins,
// otherwise whichever catalog ranks the title highest (ties: config order).
function removeSharedTitles(cats, results, priority) {
  for (const type of new Set(cats.map(c => c.type))) {
    const group = cats.filter(c => c.type === type);
    const owner = {};
    group.forEach((c, order) => results[`${type}/${c.id}`].forEach((m, rank) => {
      const score = c.id === priority ? [-1, -1] : [rank, order];
      const best = owner[m.id];
      if (!best || score[0] < best.score[0] || (score[0] === best.score[0] && score[1] < best.score[1])) owner[m.id] = { id: c.id, score };
    }));
    for (const c of group) {
      const key = `${type}/${c.id}`;
      const before = results[key].length;
      results[key] = results[key].filter(m => owner[m.id].id === c.id);
      if (before !== results[key].length) console.log(`shared titles removed from ${c.name} (${type}): ${before} -> ${results[key].length}`);
    }
  }
}

// "excludeGenres": ["Horror"] on a catalog drops titles TMDB tags with that genre.
const GENRE_IDS = { Horror: 27 };
async function dropGenres(c, metas) {
  if (!c.excludeGenres?.length) return metas;
  if (!tmdbEnabled) { console.log("  genre filter skipped (needs TMDB_KEY)"); return metas; }
  const banned = c.excludeGenres.map(g => GENRE_IDS[g]).filter(Boolean);
  const kept = [];
  for (const m of metas) {
    const genres = await tmdbGenres(m);
    if (genres?.some(id => banned.includes(id))) { console.log(`  ${c.excludeGenres.join("/")} removed: ${m.name}`); continue; }
    kept.push(m);
  }
  return kept;
}

console.log(tmdbEnabled ? "TMDB artwork: on" : "TMDB artwork: off (no TMDB_KEY secret)");

for (const addon of config.addons) {
  if (only.length && !only.includes(addon.folder)) continue;
  console.log(`\n=== ${addon.name} (${addon.folder})`);

  // One entry per catalog/type pair, in config order.
  const cats = addon.catalogs.flatMap(c => (c.types || [c.type]).map(type => ({ ...c, type })));
  const results = {};

  for (const c of cats) {
    const key = `${c.type}/${c.id}`;
    try {
      const metas = await dropGenres(c, await loadCatalog(c, `${addon.folder}/catalog/${key}.json`));
      const unique = await fixArt(metas.filter((m, i) => metas.findIndex(x => x.id === m.id) === i));
      if (!unique.length) throw new Error("no items");
      results[key] = unique;
      console.log(`${c.name} (${c.type}): ${unique.length}`);
    } catch (e) {
      failures++;
      results[key] = (await readJson(`${addon.folder}/catalog/${key}.json`, { metas: [] })).metas;
      console.log(`!! ${c.name} (${c.type}) failed: ${e.message} — keeping last version (${results[key].length})`);
    }
  }

  if (addon.dedupe) removeSharedTitles(cats, results, addon.dedupe.priority);
  for (const c of cats) await writeCatalog(`${addon.folder}/catalog/${c.type}/${c.id}`, results[`${c.type}/${c.id}`]);
  await writeManifest(addon, cats);
}

await saveImdbCache();
await saveArtCache();
console.log(`\nDone. ${failures} catalog(s) failed.`);
