// Builds a manifest + catalog JSON from a Rotten Tomatoes browse page.
import { mkdir, writeFile } from "node:fs/promises";

const RT_URL = process.env.RT_URL;
const OUT = process.env.OUT || "rt";
const NAME = process.env.NAME || "Rotten Tomatoes";
const UA = { "user-agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 Safari/605.1.15" };

const path = new URL(RT_URL).pathname.replace(/^\/browse\//, "");
const isMovie = path.startsWith("movies");
const type = isMovie ? "movie" : "series";

const MAX = Number(process.env.RT_MAX || 200);

async function firstPage() {
  const r = await fetch(RT_URL, { headers: UA });
  console.log("RT page status", r.status);
  const html = await r.text();
  const blocks = [...html.matchAll(/<script[^>]*application\/ld\+json[^>]*>([\s\S]*?)<\/script>/g)];
  for (const [, txt] of blocks) {
    if (!txt.includes("ItemList")) continue;
    try {
      const j = JSON.parse(txt);
      const list = j.itemListElement?.itemListElement || j.itemListElement || [];
      return list.map(x => ({ title: x.name, posterUri: x.image, score: x.aggregateRating?.ratingValue }));
    } catch (e) { console.log("JSON-LD parse failed", e.message); }
  }
  return [];
}

async function rtItems() {
  const out = await firstPage();
  let after = Buffer.from(String(out.length - 1)).toString("base64");
  while (out.length < MAX) {
    const api = `https://www.rottentomatoes.com/cnapi/browse/${path}?after=${encodeURIComponent(after)}`;
    const r = await fetch(api, { headers: UA });
    if (!r.ok) { console.log("cnapi failed", r.status); break; }
    const j = await r.json();
    const list = j.grid?.list || [];
    out.push(...list.map(x => ({ title: x.title, posterUri: x.posterUri, score: x.criticsScore?.scorePercent?.replace("%", "") })));
    if (!list.length || !j.pageInfo?.hasNextPage) break;
    after = j.pageInfo.endCursor;
  }
  return out.slice(0, MAX);
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
  const score = it.score ? `Tomatometer ${it.score}%` : "";
  metas.push({
    id: hit.id, type, name: it.title,
    poster: it.posterUri || hit.poster,
    description: score || hit.description || "",
  });
}
console.log(`RT items: ${items.length}, matched: ${metas.length}`);
if (!metas.length) { console.log("Nothing matched — keeping old files"); process.exit(1); }

const manifest = {
  id: `com.hotwheelz3000.${OUT}`,
  version: "1.0.0",
  name: NAME,
  description: `Catalog from ${RT_URL}`,
  resources: ["catalog"],
  types: [type],
  catalogs: [{ type, id: "rt-list", name: NAME }],
  idPrefixes: ["tt"],
};
await mkdir(`${OUT}/catalog/${type}`, { recursive: true });
await writeFile(`${OUT}/manifest.json`, JSON.stringify(manifest, null, 2));
await writeFile(`${OUT}/catalog/${type}/rt-list.json`, JSON.stringify({ metas }, null, 2));
