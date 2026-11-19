// Official artwork from TMDB (needs the TMDB_KEY secret; does nothing without it).
// Accepts either the v3 "API Key" or the v4 "Read Access Token".
import { fileCache } from "./util.mjs";

const KEY = (process.env.TMDB_KEY || "").trim();
export const tmdbEnabled = !!KEY;
const isToken = KEY.startsWith("eyJ");
const IMG = "https://image.tmdb.org/t/p";
const WEEK = 7 * 86400 * 1000;
const cache = fileCache("_cache/tmdb.json");
const imdbIds = fileCache("_cache/tmdb-imdb.json"); // TMDB id -> IMDb id never changes, kept forever

export async function api(path, params = {}) {
  const qs = new URLSearchParams(isToken ? params : { ...params, api_key: KEY });
  for (let attempt = 1; attempt <= 3; attempt++) {
    const r = await fetch(`https://api.themoviedb.org/3${path}?${qs}`, {
      headers: isToken ? { Authorization: `Bearer ${KEY}`, accept: "application/json" } : { accept: "application/json" },
    });
    if (r.ok) return r.json();
    if (r.status === 401) throw new Error("TMDB key rejected (check the TMDB_KEY secret)");
    if (r.status !== 429 && r.status < 500) return null;
    await new Promise(res => setTimeout(res, 1000 * attempt));
  }
  return null;
}

// Best image: highest rated in the preferred languages, in order.
function pick(list = [], langs) {
  for (const lang of langs) {
    const hits = list.filter(i => (i.iso_639_1 ?? null) === lang).sort((a, b) => b.vote_average - a.vote_average || b.vote_count - a.vote_count);
    if (hits.length) return hits[0].file_path;
  }
  return null;
}

// Returns { poster, background, logo } URLs (any may be null) for a catalog item.
export async function tmdbArt(m) {
  if (!KEY) return {};
  const saved = await cache.load();
  const key = `${m.type}|${m.id}`;
  const hit = saved[key];
  // Complete art is refreshed weekly; anything missing is rechecked every run.
  const complete = hit?.art?.poster && hit.art.logo && hit.art.background;
  if (hit && complete && Date.now() - hit.t < WEEK) return hit.art;

  let kind = m.type === "movie" ? "movie" : "tv";
  let id = m.id.match(/^tmdb:(\d+)$/)?.[1];
  if (!id && m.id.startsWith("tt")) {
    const found = await api(`/find/${m.id}`, { external_source: "imdb_id" });
    const res = found?.[`${kind}_results`]?.[0] || found?.movie_results?.[0] || found?.tv_results?.[0];
    if (res) { id = res.id; kind = res.media_type === "movie" || found?.movie_results?.[0] === res ? "movie" : "tv"; }
  }
  let art = {};
  if (id) {
    const imgs = await api(`/${kind}/${id}/images`, { include_image_language: "en,null" });
    const logo = pick(imgs?.logos, ["en"]);
    const backdrop = pick(imgs?.backdrops, [null, "en"]);   // prefer clean backgrounds without text
    const poster = pick(imgs?.posters, ["en", null]);
    art = {
      logo: logo && `${IMG}/w500${logo}`,
      background: backdrop && `${IMG}/w1280${backdrop}`,
      poster: poster && `${IMG}/w500${poster}`,
    };
  }
  saved[key] = { t: Date.now(), art };
  return art;
}

// IMDb id for a TMDB movie/show (null if TMDB doesn't know it).
export async function imdbIdFor(kind, id) {
  const saved = await imdbIds.load();
  const key = `${kind}:${id}`;
  if (key in saved) return saved[key];
  const ext = await api(`/${kind}/${id}/external_ids`);
  if (!ext) return null; // lookup failed: try again next run
  return (saved[key] = ext.imdb_id || null);
}

export const saveTmdbCache = async () => { await cache.save(); await imdbIds.save(); };
