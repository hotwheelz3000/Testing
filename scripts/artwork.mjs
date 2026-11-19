// Makes sure every catalog item has a working poster, background and (when possible) logo.
//   logo:       TMDB official -> list's own / metahub fan art
//   background: TMDB official -> list's own -> metahub -> poster
//   poster:     list's own -> metahub -> TMDB -> Rotten Tomatoes search -> TVmaze; none -> item dropped
// Wide images are never used as posters.
import { UA, get, norm, fileCache } from "./util.mjs";
import { tmdbArt, saveTmdbCache } from "./tmdb.mjs";

// metahub (Stremio's image service) artwork for IMDb ids.
export const metahub = id => id.startsWith("tt") ? {
  poster: `https://images.metahub.space/poster/medium/${id}/img`,
  background: `https://images.metahub.space/background/medium/${id}/img`,
  logo: `https://images.metahub.space/logo/medium/${id}/img`,
} : {};

// ---- image checks (working images are remembered; missing ones are retried next run) ----
const working = fileCache("_cache/images.json");

async function imageOk(url) {
  if (!url || !/^https?:\/\//.test(url) || url.endsWith("/")) return false; // e.g. TMDB ".../bestv2/" = no image
  const saved = await working.load();
  if (saved[url] || url.startsWith("https://image.tmdb.org/t/p/w")) return true;
  for (const method of ["HEAD", "GET"]) {
    try {
      const r = await fetch(url, { method, headers: UA, redirect: "follow" });
      if (method === "GET") r.body?.cancel();
      if (r.ok && (r.headers.get("content-type") || "image").startsWith("image")) return (saved[url] = true);
      if (r.status !== 405) break; // HEAD not allowed -> try GET
    } catch {}
  }
  return false;
}

const firstWorking = async (...urls) => { for (const u of urls) if (await imageOk(u)) return u; return null; };

// ---- backup posters ----
// Rotten Tomatoes search: exact name (and year when known), skipping RT's blank default poster.
async function rtPoster(m) {
  try {
    const html = await get(`https://www.rottentomatoes.com/search?search=${encodeURIComponent(m.name)}`, "text");
    for (const [, row] of html.matchAll(/<search-page-media-row([\s\S]*?)<\/search-page-media-row>/g)) {
      const name = row.match(/<img[^>]*?alt="([^"]*)"/)?.[1]?.replace(/&amp;/g, "&").replace(/&#39;/g, "'");
      const src = row.match(/<img[^>]*?src="([^"]+)"/)?.[1];
      const year = row.match(/(?:release|start)-year="(\d{4})"/)?.[1];
      if (!src || norm(name) !== norm(m.name)) continue;
      if (m.releaseInfo && year && !String(m.releaseInfo).includes(year)) continue;
      const full = src.split("/v2/")[1] || src;  // drop the 80px thumbnail resize
      if (!full.includes("/ems.")) continue;     // RT's placeholder isn't an "ems" image
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
    return norm(j?.name) === norm(m.name) && (await imageOk(j.image?.original)) ? j.image.original : null;
  } catch { return null; }
}

async function backupPoster(m) {
  for (const find of [rtPoster, tvmazePoster]) {
    const url = await find(m);
    if (url) { console.log(`  backup art (${find.name}): ${m.name}`); return url; }
  }
  return null;
}

// ---- main ----
export async function fixArt(metas) {
  const fixed = [];
  const queue = metas.map((m, i) => [m, i]);
  const worker = async () => {
    for (let job; (job = queue.shift()); ) {
      const [m, i] = job;
      const hub = metahub(m.id);
      const t = await tmdbArt(m).catch(e => { console.log(`  tmdb: ${e.message}`); return {}; });
      const poster = (await firstWorking(m.poster, hub.poster, t.poster)) || (await backupPoster(m));
      if (!poster) { console.log(`  no poster, dropped: ${m.name}`); continue; }
      const background = (await firstWorking(t.background, m.background, hub.background)) || poster;
      const logo = (await firstWorking(t.logo, m.logo)) || undefined;
      fixed[i] = { ...m, poster, background, logo };
    }
  };
  await Promise.all(Array.from({ length: 16 }, worker));
  return fixed.filter(Boolean);
}

export async function saveArtCache() {
  await saveTmdbCache();
  await working.save();
}
