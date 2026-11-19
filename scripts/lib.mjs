// Shared helpers for building the catalog addons.
import { mkdir, readFile, writeFile } from "node:fs/promises";
import { dirname } from "node:path";

const UA = { "user-agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 Safari/605.1.15" };
const sleep = ms => new Promise(r => setTimeout(r, ms));

// fetch with a browser user agent and a few retries on errors / 429 / 5xx.
export async function get(url, as = "json") {
  for (let attempt = 1; attempt <= 3; attempt++) {
    try {
      const r = await fetch(url, { headers: UA });
      if (r.ok) return as === "text" ? r.text() : r.json();
      if (r.status !== 429 && r.status < 500) throw new Error(`HTTP ${r.status}`);
      console.log(`  retry ${attempt} (${r.status}) ${url}`);
    } catch (e) {
      if (attempt === 3 || /HTTP 4/.test(e.message)) throw e;
    }
    await sleep(1500 * attempt);
  }
  throw new Error(`gave up on ${url}`);
}

export async function readJson(path, fallback) {
  try { return JSON.parse(await readFile(path, "utf8")); } catch { return fallback; }
}

export async function writeJson(path, data, pretty = true) {
  await mkdir(dirname(path), { recursive: true });
  await writeFile(path, JSON.stringify(data, null, pretty ? 2 : 0));
}

// ---- IMDb matching through Cinemeta, cached between runs ----
const CACHE_PATH = "_cache/imdb.json"; // underscore folder: GitHub Pages doesn't serve it
let cache = null;
const norm = s => String(s || "").toLowerCase().replace(/[^a-z0-9]/g, "");

export async function imdbMatch(type, title, year = "") {
  cache ??= await readJson(CACHE_PATH, {});
  const key = `${type}|${norm(title)}|${year}`;
  if (cache[key]) return cache[key];
  let hit = null;
  try {
    const { metas = [] } = await get(`https://v3-cinemeta.strem.io/catalog/${type}/top/search=${encodeURIComponent(title)}.json`);
    const same = metas.filter(m => norm(m.name) === norm(title));
    hit = (year && same.find(m => String(m.releaseInfo || "").startsWith(String(year)))) || same[0] || (type === "series" ? metas[0] : null);
  } catch (e) { console.log(`  cinemeta error for "${title}": ${e.message}`); }
  if (hit?.id?.startsWith("tt")) {
    cache[key] = { id: hit.id, poster: hit.poster, description: hit.description };
    return cache[key];
  }
  return null;
}

export const saveCache = () => cache && writeJson(CACHE_PATH, cache, false);

// ---- artwork ----
export const art = id => id.startsWith("tt") ? {
  poster: `https://images.metahub.space/poster/medium/${id}/img`,
  background: `https://images.metahub.space/background/medium/${id}/img`,
  logo: `https://images.metahub.space/logo/medium/${id}/img`,
} : {};

// ---- catalog files ----
// Writes <dir>.json plus <dir>/skip=N.json pages, so apps show a See All arrow and can page.
export async function writeCatalog(dir, metas) {
  await writeJson(`${dir}.json`, { metas });
  const skips = new Set([metas.length]);
  for (let k = 10; k < metas.length; k += 10) skips.add(k);
  for (const k of skips) await writeJson(`${dir}/skip=${k}.json`, { metas: metas.slice(k) }, false);
}

export const SKIP_EXTRA = [{ name: "skip", isRequired: false }];
