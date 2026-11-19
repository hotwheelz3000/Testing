// Builds a manifest + catalog JSON from a Rotten Tomatoes browse page.
import { mkdir, writeFile } from "node:fs/promises";

const RT_URL = process.env.RT_URL;
const OUT = process.env.OUT || "rt";
const NAME = process.env.NAME || "Rotten Tomatoes";
const CAT_ID = process.env.CAT_ID || "rt-list";
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
    id: hit.id, type, logo: `https://images.metahub.space/logo/medium/${hit.id}/img`, name: it.title,
    poster: it.posterUri || hit.poster,
    description: score || hit.description || "",
  });
}
console.log(`RT items: ${items.length}, matched: ${metas.length}`);
if (!metas.length) { console.log("Nothing matched — keeping old files"); process.exit(1); }

// Merge into one manifest so several lists (series + movie) share one addon
import { readFile } from "node:fs/promises";
let manifest = {
  id: `com.hotwheelz3000.${OUT}`,
  version: "1.1.0",
  name: process.env.ADDON_NAME || NAME,
  description: "Newest titles per streaming service, from Rotten Tomatoes",
  resources: ["catalog"],
  types: [],
  catalogs: [],
  idPrefixes: ["tt"],
};
try {
  const old = JSON.parse(await readFile(`${OUT}/manifest.json`, "utf8"));
  manifest.catalogs = (old.catalogs || []).filter(c => !(c.type === type && c.id === CAT_ID));
} catch {}
manifest.catalogs.push({ type, id: CAT_ID, name: NAME });
manifest.catalogs.sort((x, y) => (x.type === "series" ? -1 : 1) - (y.type === "series" ? -1 : 1));
manifest.types = [...new Set(manifest.catalogs.map(c => c.type))];
await mkdir(`${OUT}/catalog/${type}`, { recursive: true });
await writeFile(`${OUT}/manifest.json`, JSON.stringify(manifest, null, 2));
await writeFile(`${OUT}/catalog/${type}/${CAT_ID}.json`, JSON.stringify({ metas }, null, 2));
