// Matches a title to its IMDb id through Cinemeta (Stremio's free catalog). Matches are cached.
import { get, norm, fileCache } from "./util.mjs";

const cache = fileCache("_cache/imdb.json");
export const saveImdbCache = cache.save;

export async function imdbMatch(type, title, year = "") {
  const saved = await cache.load();
  const key = `${type}|${norm(title)}|${year}`;
  if (saved[key]) return saved[key];
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
  if (!hit?.id?.startsWith("tt")) return null;
  return (saved[key] = { id: hit.id, name: hit.name, poster: hit.poster, description: hit.description });
}
