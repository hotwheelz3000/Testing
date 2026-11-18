// Builds a manifest + catalog JSON from a Rotten Tomatoes browse page.
import { mkdir, writeFile } from "node:fs/promises";

const RT_URL = process.env.RT_URL;
const PAGES = Number(process.env.RT_PAGES || 3);
const UA = { "user-agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 Safari/605.1.15" };

const path = new URL(RT_URL).pathname.replace(/^\/browse\//, "");
const isMovie = path.startsWith("movies");
const type = isMovie ? "movie" : "series";

async function rtItems() {
  const r = await fetch(RT_URL, { headers: UA });
  console.log("RT page status", r.status);
  const html = await r.text();
  const blocks = [...html.matchAll(/<script[^>]*application\/ld\+json[^>]*>([\s\S]*?)<\/script>/g)];
  for (const [, txt] of blocks) {
    if (!txt.includes("ItemList")) continue;
    try {
      const j = JSON.parse(txt);
      const list = j.itemListElement?.itemListElement || j.itemListElement || [];
      return list.map(x => ({
        title: x.name,
        posterUri: x.image,
        criticsScore: { score: x.aggregateRating?.ratingValue },
      }));
    } catch (e) { console.log("JSON-LD parse failed", e.message); }
  }
  return [];
}

async function imdbFor(title) {
  const u = `https://v3-cinemeta.strem.io/catalog/${type}/top/search=${encodeURIComponent(title)}.json`;
  try {
    const j = await (await fetch(u)).json();
    const norm = s => s.toLowerCase().replace(/[^a-z0-9]/g, "");
    const exact = (j.metas || []).find(x => norm(x.name) === norm(title));
    return exact || (j.metas || [])[0];
  } catch { return null; }
}

const items = await rtItems();
const metas = [];
for (const it of items) {
  const hit = await imdbFor(it.title);
  if (!hit?.id?.startsWith("tt")) { console.log("no match:", it.title); continue; }
  if (metas.some(x => x.id === hit.id)) continue;
  const score = it.criticsScore?.score ? `Tomatometer ${it.criticsScore.score}%` : "";
  metas.push({
    id: hit.id, type, name: it.title,
    poster: it.posterUri || hit.poster,
    description: score || hit.description || "",
  });
}
console.log(`RT items: ${items.length}, matched: ${metas.length}`);
if (!metas.length) { console.log("Nothing matched — keeping old files"); process.exit(1); }

const manifest = {
  id: "com.hotwheelz3000.rt",
  version: "1.0.0",
  name: "Rotten Tomatoes",
  description: `Catalog from ${RT_URL}`,
  resources: ["catalog"],
  types: [type],
  catalogs: [{ type, id: "rt-list", name: "Rotten Tomatoes" }],
  idPrefixes: ["tt"],
};
await mkdir(`rt/catalog/${type}`, { recursive: true });
await writeFile("rt/manifest.json", JSON.stringify(manifest, null, 2));
await writeFile(`rt/catalog/${type}/rt-list.json`, JSON.stringify({ metas }, null, 2));
