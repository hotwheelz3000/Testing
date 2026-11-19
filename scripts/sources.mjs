// Each source returns a list of catalog items: { id, type, name, poster?, background?, logo?, description?, releaseInfo? }
import { get, imdbMatch, art } from "./lib.mjs";

const MAX = 200;

// ---- Rotten Tomatoes browse pages (newest first, per streaming service) ----
async function rottenTomatoes({ service }, type) {
  const kind = type === "movie" ? "movies_at_home" : "tv_series_browse";
  const path = `${kind}/affiliates:${service}~sort:newest`;

  // Page 1 is in the page's JSON-LD block; later pages come from RT's own "Load more" endpoint.
  const html = await get(`https://www.rottentomatoes.com/browse/${path}`, "text");
  const items = [];
  for (const [, txt] of html.matchAll(/<script[^>]*application\/ld\+json[^>]*>([\s\S]*?)<\/script>/g)) {
    if (!txt.includes("ItemList")) continue;
    const j = JSON.parse(txt);
    const list = j.itemListElement?.itemListElement || j.itemListElement || [];
    items.push(...list.map(x => ({ title: x.name, poster: x.image, score: x.aggregateRating?.ratingValue })));
    break;
  }
  let after = Buffer.from(String(items.length - 1)).toString("base64");
  while (items.length && items.length < MAX) {
    const j = await get(`https://www.rottentomatoes.com/cnapi/browse/${path}?after=${encodeURIComponent(after)}`);
    const list = j.grid?.list || [];
    items.push(...list.map(x => ({ title: x.title, poster: x.posterUri, score: x.criticsScore?.scorePercent?.replace("%", "") })));
    if (!list.length || !j.pageInfo?.hasNextPage) break;
    after = j.pageInfo.endCursor;
  }

  const metas = [];
  for (const it of items.slice(0, MAX)) {
    const hit = await imdbMatch(type, it.title);
    if (!hit) { console.log(`  no match: ${it.title}`); continue; }
    metas.push({
      id: hit.id, type, name: it.title, ...art(hit.id),
      poster: it.poster || hit.poster,
      description: it.score ? `Tomatometer ${it.score}%` : hit.description || "",
    });
  }
  return metas;
}

// ---- Public MDBList lists (JSON export, no API key needed) ----
async function mdblist({ list }, type) {
  const items = await get(`https://mdblist.com/lists/${list}/json`);
  return items
    .filter(it => it.imdb_id?.startsWith("tt"))
    .slice(0, MAX)
    .map(it => ({ id: it.imdb_id, type, name: it.title, releaseInfo: String(it.release_year || ""), ...art(it.imdb_id) }));
}

// ---- Another Stremio addon's catalog (pages overlap, so keep only new items) ----
async function stremio({ url }, type) {
  const items = [];
  const seen = new Set();
  let misses = 0;
  while (items.length < MAX && misses < 3) {
    let list = [];
    try { list = (await get(items.length ? `${url}/skip=${items.length}.json` : `${url}.json`)).metas || []; }
    catch (e) { console.log(`  page error: ${e.message}`); }
    const fresh = list.filter(m => !seen.has(m.id));
    if (!fresh.length) { misses++; continue; }
    misses = 0;
    fresh.forEach(m => { seen.add(m.id); items.push(m); });
  }

  const metas = [];
  for (const m of items) {
    const hit = await imdbMatch(type, m.name, m.year);
    const id = hit?.id || m.id; // no IMDb match: keep the source id (e.g. tmdb:123)
    metas.push({
      id, type, name: m.name, ...art(id),
      poster: m.poster || hit?.poster, background: m.background || art(id).background,
      description: m.description || "", releaseInfo: m.year,
    });
  }
  return metas;
}

// ---- A subreddit's posts via the Arctic Shift Reddit archive ----
// Reads "Name (Year)" style post titles and matches them to IMDb. Newest first.
export function parsePostTitle(raw) {
  const t = String(raw || "").replace(/^title:\s*/i, "").trim();
  if (!t || t.includes("?") || /\b(anyone|where|help|request|question|looking for|eng dub)\b/i.test(t)) return null;
  let name, year = "";
  let m = t.match(/^(.*?)\s*[\(\[]((?:19|20)\d{2})[\)\]]/);              // Madden (2026)
  if (!m) m = t.match(/^(.*?)[\s._-]+((?:19|20)\d{2})(?=[\s._-]|$)/);       // Street.Fighter.2026.WEB...
  if (m) { name = m[1]; year = m[2]; }
  else if (t.split(/\s+/).length <= 6) name = t;                         // AVENGERS DOOMSDAY
  else return null;
  name = name.replace(/[._]/g, " ").replace(/\s*[\(\[][^)\]]*[\)\]]/g, "").replace(/\s+/g, " ").trim();
  return name.length > 1 ? { name, year } : null;
}

async function reddit({ subreddit, days = 60 }, type) {
  const since = Math.floor(Date.now() / 1000) - days * 86400;
  const posts = [];
  let before = "";
  for (let page = 0; page < 20; page++) {
    const url = `https://arctic-shift.photon-reddit.com/api/posts/search?subreddit=${subreddit}&after=${since}`
      + `${before ? `&before=${before}` : ""}&limit=100&sort=desc&fields=title,created_utc`;
    const { data } = await get(url);
    if (!data?.length) break;
    posts.push(...data);
    before = data[data.length - 1].created_utc;
    if (data.length < 100) break;
  }
  console.log(`  ${posts.length} posts`);

  const metas = [];
  const seen = new Set();
  for (const p of posts) {
    if (metas.length >= MAX) break;
    const parsed = parsePostTitle(p.title);
    if (!parsed) continue;
    const key = parsed.name.toLowerCase();
    if (seen.has(key)) continue;
    seen.add(key);
    const hit = await imdbMatch(type, parsed.name, parsed.year);
    if (!hit) { console.log(`  no match: ${p.title}`); continue; }
    if (metas.some(m => m.id === hit.id)) continue;
    metas.push({
      id: hit.id, type, name: hit.name || parsed.name, releaseInfo: parsed.year, ...art(hit.id),
      description: `Posted on r/${subreddit} ${new Date(p.created_utc * 1000).toISOString().slice(0, 10)}`,
    });
  }
  if (metas.length < 5) throw new Error(`only ${metas.length} movies found`);
  return metas;
}

export const sources = { rottentomatoes: rottenTomatoes, mdblist, stremio, reddit };
