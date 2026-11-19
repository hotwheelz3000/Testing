// Copies the r/movieleaks addon's movie list into its own addon.
import { writeFile } from "node:fs/promises";
import { writeCatalog, SKIP_EXTRA } from "./catalog-files.mjs";
const OUT = process.env.LEAKS_OUT || "movieleaks";
const SRC = "https://e1fc7808b5de-stremio-r-movieleaks.baby-beamup.club/catalog/movie/movieleaks_movies";
const CAT_ID = "movieleaks";
const NAME = "r/movieleaks";
const MAX = 200;

// The source pages overlap, so ask for skip = items collected so far and keep only new ones.
const items = [];
const seen = new Set();
let misses = 0;
while (items.length < MAX && misses < 3) {
  const url = items.length ? `${SRC}/skip=${items.length}.json` : `${SRC}.json`;
  let list = [];
  try {
    const r = await fetch(url, { headers: { "user-agent": "Mozilla/5.0" } });
    if (r.ok) list = (await r.json()).metas || []; else console.log("source", r.status, url);
  } catch (e) { console.log("source error", e.message); }
  const fresh = list.filter(m => !seen.has(m.id));
  console.log(`page skip=${items.length}: ${list.length} items, ${fresh.length} new`);
  if (!fresh.length) { misses++; continue; }
  misses = 0;
  fresh.forEach(m => { seen.add(m.id); items.push(m); });
}
console.log("source items:", items.length);

async function imdbFor(m) {
  const u = `https://v3-cinemeta.strem.io/catalog/movie/top/search=${encodeURIComponent(m.name)}.json`;
  try {
    const metas = (await (await fetch(u)).json()).metas || [];
    const norm = s => String(s).toLowerCase().replace(/[^a-z0-9]/g, "");
    return metas.find(x => norm(x.name) === norm(m.name) && String(x.releaseInfo || "").startsWith(String(m.year || "")))
        || metas.find(x => norm(x.name) === norm(m.name));
  } catch { return null; }
}

const metas = [];
for (const m of items) {
  const hit = await imdbFor(m);
  // No IMDb match: keep the original TMDB id so the movie still shows up.
  const id = hit?.id?.startsWith("tt") ? hit.id : m.id;
  if (metas.some(x => x.id === id)) continue;
  metas.push({
    id, type: "movie", name: m.name, poster: m.poster || hit?.poster, background: m.background,
    logo: id.startsWith("tt") ? `https://images.metahub.space/logo/medium/${id}/img` : undefined,
    description: m.description || "", releaseInfo: m.year,
  });
}
console.log("kept:", metas.length, "imdb matched:", metas.filter(m => m.id.startsWith("tt")).length);
if (!metas.length) process.exit(1);

await writeCatalog(`${OUT}/catalog/movie/${CAT_ID}`, metas);
await writeFile(`${OUT}/manifest.json`, JSON.stringify({
  id: "com.hotwheelz3000.movieleaks", version: "1.1.0", name: NAME,
  description: "Movies posted on r/movieleaks (copied from jcdc's addon every 6 hours)",
  resources: ["catalog"], types: ["movie"],
  catalogs: [{ type: "movie", id: CAT_ID, name: "Movies - r/movieleaks", extra: SKIP_EXTRA }],
  idPrefixes: ["tt", "tmdb"],
}, null, 2));
