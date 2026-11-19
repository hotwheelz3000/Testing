// Shared helpers for building the catalog addons.
import { readJson, writeJson } from "./lib-io.mjs";
import { tmdbArt, saveTmdbCache } from "./tmdb.mjs";
export { readJson, writeJson };

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


// ---- IMDb matching through Cinemeta, cached between runs ----
const CACHE_PATH = "_cache/imdb.json"; // underscore folder: GitHub Pages doesn't serve it
let cache = null;
let cacheLoading = null;
const norm = s => String(s || "").toLowerCase().replace(/[^a-z0-9]/g, "");

export async function imdbMatch(type, title, year = "") {
  cache ??= await (cacheLoading ??= readJson(CACHE_PATH, {}));
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
let imgLoading = null;

async function imageOk(url) {
  if (!url || !/^https?:\/\//.test(url) || url.endsWith("/")) return false; // e.g. TMDB ".../bestv2/" = no image
  imgCache ??= await (imgLoading ??= readJson(IMG_CACHE_PATH, {}));
  if (imgCache[url] || url.startsWith("https://image.tmdb.org/t/p/w")) return true;
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

// ---- backup artwork when the usual sources have none ----
const nm = x => String(x || "").toLowerCase().replace(/[^a-z0-9]/g, "");

// Rotten Tomatoes search: exact name (and year when known), skipping RT's blank default poster.
async function rtPoster(m) {
  try {
    const html = await get(`https://www.rottentomatoes.com/search?search=${encodeURIComponent(m.name)}`, "text");
    for (const [, row] of html.matchAll(/<search-page-media-row([\s\S]*?)<\/search-page-media-row>/g)) {
      const name = row.match(/<img[^>]*?alt="([^"]*)"/)?.[1]?.replace(/&amp;/g, "&").replace(/&#39;/g, "'");
      const src = row.match(/<img[^>]*?src="([^"]+)"/)?.[1];
      const year = row.match(/(?:release|start)-year="(\d{4})"/)?.[1];
      if (!src || nm(name) !== nm(m.name)) continue;
      if (m.releaseInfo && year && !String(m.releaseInfo).includes(year)) continue;
      const full = src.split("/v2/")[1] || src;            // drop the 80px thumbnail resize
      if (!full.includes("/ems.")) continue;               // RT's placeholder isn't an "ems" image
      if (await imageOk(full)) return full;
    }
  } catch {}
  return null;
}

// TVmaze: shows only, exact name match.
async function tvmazePoster(m) {
  if (m.type !== "series") return null;
  try {
    const j = await get(`https://api.tvmaze.com/singlesearch/shows?q=${encodeURIComponent(m.name)}`);
    return nm(j?.name) === nm(m.name) && (await imageOk(j.image?.original)) ? j.image.original : null;
  } catch { return null; }
}

async function backupPoster(m) {
  // Posters only: a wide image is never used as a poster.
  for (const find of [rtPoster, tvmazePoster]) {
    const url = await find(m);
    if (url) { console.log(`  backup art (${find.name}): ${m.name}`); return url; }
  }
  return null;
}

// Makes sure every item has a working poster and background; drops items with no poster at all.
// Order: logo and background from TMDB first (official), poster from the list first.
export async function fixArt(metas) {
  const fixed = [];
  const queue = metas.map((m, i) => [m, i]);
  const worker = async () => {
    for (let job; (job = queue.shift()); ) {
      const [m, i] = job;
      const a = art(m.id);
      const t = await tmdbArt(m).catch(e => { console.log(`  tmdb: ${e.message}`); return {}; });
      const first = async (...urls) => { for (const u of urls) if (await imageOk(u)) return u; return null; };
      const poster = (await first(m.poster, a.poster, t.poster)) || (await backupPoster(m));
      if (!poster) { console.log(`  no poster, dropped: ${m.name}`); continue; }
      const background = (await first(t.background, m.background, a.background)) || poster;
      const logo = (await first(t.logo, m.logo)) || undefined;
      fixed[i] = { ...m, poster, background, logo };
    }
  };
  await Promise.all(Array.from({ length: 16 }, worker));
  return fixed.filter(Boolean);
}

export const saveCache = async () => {
  await saveTmdbCache();
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
