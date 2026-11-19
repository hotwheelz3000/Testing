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
      if (![422, 429].includes(r.status) && r.status < 500) throw new Error(`HTTP ${r.status}`); // 422 = Arctic Shift timeout
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
    const sameYear = m => year && String(m.releaseInfo || "").startsWith(String(year));
    hit = same.find(sameYear) || same[0]
      // "Rolling Loud" (2026) -> "Rolling Loud: The Movie" (2026): prefix match only when the year agrees
      || metas.find(m => sameYear(m) && norm(m.name).startsWith(norm(title)))
      || (type === "series" ? metas[0] : null);
  } catch (e) { console.log(`  cinemeta error for "${title}": ${e.message}`); }
  if (hit?.id?.startsWith("tt")) {
    cache[key] = { id: hit.id, name: hit.name, poster: hit.poster, description: hit.description };
    return cache[key];
  }
  return null;
}

// ---- image checks (working images are remembered between runs) ----
const IMG_CACHE_PATH = "_cache/images.json";
let imgCache = null;

async function imageOk(url) {
  if (!url || !/^https?:\/\//.test(url) || url.endsWith("/")) return false; // e.g. TMDB ".../bestv2/" = no image
  imgCache ??= await readJson(IMG_CACHE_PATH, {});
  if (imgCache[url]) return true;
  for (const method of ["HEAD", "GET"]) {
    try {
      const r = await fetch(url, { method, headers: UA, redirect: "follow" });
      if (method === "GET") r.body?.cancel();
      if (r.ok && (r.headers.get("content-type") || "image").startsWith("image")) return (imgCache[url] = true);
      if (r.status !== 405) break; // HEAD not allowed -> try GET
    } catch {}
  }
  return false;
}

// Makes sure every item has a working poster and background; drops items with no poster at all.
export async function fixArt(metas) {
  const fixed = [];
  const queue = metas.map((m, i) => [m, i]);
  const worker = async () => {
    for (let job; (job = queue.shift()); ) {
      const [m, i] = job;
      const a = art(m.id);
      const poster = (await imageOk(m.poster)) ? m.poster : (await imageOk(a.poster)) ? a.poster : null;
      if (!poster) { console.log(`  no poster, dropped: ${m.name}`); continue; }
      const background = (await imageOk(m.background)) ? m.background : (await imageOk(a.background)) ? a.background : poster;
      const logo = (await imageOk(m.logo)) ? m.logo : undefined;
      fixed[i] = { ...m, poster, background, logo };
    }
  };
  await Promise.all(Array.from({ length: 16 }, worker));
  return fixed.filter(Boolean);
}

export const saveCache = async () => {
  if (cache) await writeJson(CACHE_PATH, cache, false);
  if (imgCache) await writeJson(IMG_CACHE_PATH, imgCache, false);
};

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
