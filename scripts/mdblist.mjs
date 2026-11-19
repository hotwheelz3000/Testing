// Builds a separate addon from public MDBList lists (no API key needed).
// LISTS: one per line, "user/slug|catalog id|display name|movie or series"
import { mkdir, writeFile } from "node:fs/promises";
const OUT = process.env.OUT || "genres";
const ADDON_NAME = process.env.ADDON_NAME || "Latest Genres";
const MAX = Number(process.env.MAX || 200);
const lists = (process.env.LISTS || "").split("\n").map(l => l.trim()).filter(Boolean)
  .map(l => { const [path, id, name, type] = l.split("|").map(s => s.trim()); return { path, id, name, type }; });

const catalogs = [];
for (const l of lists) {
  try {
    const r = await fetch(`https://mdblist.com/lists/${l.path}/json`, { headers: { "user-agent": "Mozilla/5.0" } });
    if (!r.ok) throw new Error(`HTTP ${r.status}`);
    const items = await r.json();
    const metas = [];
    for (const it of items) {
      if (!it.imdb_id?.startsWith("tt") || metas.some(m => m.id === it.imdb_id)) continue;
      metas.push({
        id: it.imdb_id, type: l.type, name: it.title, releaseInfo: String(it.release_year || ""),
        poster: `https://images.metahub.space/poster/medium/${it.imdb_id}/img`,
        background: `https://images.metahub.space/background/medium/${it.imdb_id}/img`,
        logo: `https://images.metahub.space/logo/medium/${it.imdb_id}/img`,
      });
      if (metas.length >= MAX) break;
    }
    await mkdir(`${OUT}/catalog/${l.type}`, { recursive: true });
    await writeFile(`${OUT}/catalog/${l.type}/${l.id}.json`, JSON.stringify({ metas }, null, 2));
    catalogs.push({ type: l.type, id: l.id, name: l.name });
    console.log(`${l.name}: ${metas.length}`);
  } catch (e) { console.log(`!! ${l.name} failed: ${e.message}`); }
}
if (!catalogs.length) process.exit(1);
await writeFile(`${OUT}/manifest.json`, JSON.stringify({
  id: `com.hotwheelz3000.${OUT}`, version: "1.0.0", name: ADDON_NAME,
  description: "Latest releases by genre, from snoak's MDBList lists",
  resources: ["catalog"], types: [...new Set(catalogs.map(c => c.type))],
  catalogs, idPrefixes: ["tt"],
}, null, 2));
