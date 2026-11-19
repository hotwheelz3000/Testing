// Copies the r/movieleaks addon's movie list into our addon as its own catalog.
import { mkdir, writeFile } from "node:fs/promises";
const OUT = process.env.LEAKS_OUT || "movieleaks";
const SRC = "https://e1fc7808b5de-stremio-r-movieleaks.baby-beamup.club/catalog/movie/movieleaks_movies";
const CAT_ID = "movieleaks";
const NAME = "r/movieleaks";

const items = [];
const seen = new Set();
for (let skip = 0; skip < 200; ) {
  const url = skip ? `${SRC}/skip=${skip}.json` : `${SRC}.json`;
  const r = await fetch(url);
  if (!r.ok) { console.log("source failed", r.status); break; }
  const list = (await r.json()).metas || [];
  const fresh = list.filter(m => !seen.has(m.id));
  if (!fresh.length) break;
  fresh.forEach(m => { seen.add(m.id); items.push(m); });
  skip += list.length;
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
  if (!hit?.id?.startsWith("tt")) { console.log("no match:", m.name); continue; }
  if (metas.some(x => x.id === hit.id)) continue;
  metas.push({ id: hit.id, type: "movie", name: m.name, poster: m.poster || hit.poster,
               background: m.background, description: m.description || "", releaseInfo: m.year });
}
console.log("matched:", metas.length);
if (!metas.length) process.exit(1);

await mkdir(`${OUT}/catalog/movie`, { recursive: true });
await writeFile(`${OUT}/catalog/movie/${CAT_ID}.json`, JSON.stringify({ metas }, null, 2));
const manifest = {
  id: "com.hotwheelz3000.movieleaks",
  version: "1.0.0",
  name: NAME,
  description: "Movies posted on r/movieleaks (copied from jcdc's addon every 6 hours)",
  resources: ["catalog"],
  types: ["movie"],
  catalogs: [{ type: "movie", id: CAT_ID, name: "Movies - r/movieleaks" }],
  idPrefixes: ["tt"],
};
await writeFile(`${OUT}/manifest.json`, JSON.stringify(manifest, null, 2));
