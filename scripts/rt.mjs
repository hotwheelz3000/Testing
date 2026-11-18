// Builds a manifest + catalog JSON from a Rotten Tomatoes browse page.
import { mkdir, writeFile } from "node:fs/promises";

const RT_URL = process.env.RT_URL;
const PAGES = Number(process.env.RT_PAGES || 3);
const UA = { "user-agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 Safari/605.1.15" };

const path = new URL(RT_URL).pathname.replace(/^\/browse\//, "");
const isMovie = path.startsWith("movies");
const type = isMovie ? "movie" : "series";

async function rtItems() {
  const out = [];
  let after = "";
  for (let p = 0; p < PAGES; p++) {
    const api = `https://www.rottentomatoes.com/napi/browse/${path}${after ? `?after=${encodeURIComponent(after)}` : ""}`;
    const r = await fetch(api, { headers: UA });
    if (!r.ok) { console.log("napi failed", r.status); break; }
    const j = await r.json();
    out.push(...(j.grid?.list || []));
    if (!j.pageInfo?.hasNextPage) break;
    after = j.pageInfo.endCursor;
  }
  if (out.length) return out;
  // Fallback: parse the HTML page
  const html = await (await fetch(RT_URL, { headers: UA })).text();
  const re = /<span[^>]*data-qa="discovery-media-list-item-title"[^>]*>\s*([^<]+?)\s*<\/span>/g;
  let m; while ((m = re.exec(html))) out.push({ title: m[1] });
  return out;
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
