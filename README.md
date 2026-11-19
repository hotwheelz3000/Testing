# Testing

## Catalog addons

Three Stremio/Nuvio catalog addons, rebuilt every 6 hours by the **Build addons** workflow and served by GitHub Pages from the `claude/maid-hotel-game-kga08a` branch (next to the hotel game site).

| Addon | Install link |
|---|---|
| Latest Streaming (Rotten Tomatoes, per service) | `stremio://hotwheelz3000.github.io/Testing/rt/manifest.json` |
| r/movieleaks | `stremio://hotwheelz3000.github.io/Testing/movieleaks/manifest.json` |
| Latest Genres (MDBList) | `stremio://hotwheelz3000.github.io/Testing/genres/manifest.json` |

For apps that want a plain URL, swap `stremio://` for `https://`.

### Files

- `addons.json`: every addon and catalog. **Edit this to add or remove lists.**
- `scripts/build.mjs`: builds the addons listed in `addons.json`.
- `scripts/sources.mjs`: where items come from (`rottentomatoes`, `mdblist`, `stremio`).
- `scripts/lib.mjs`: shared helpers (requests with retries, IMDb matching with a cache, artwork, catalog paging).
- `.github/workflows/rt.yml`: the schedule. **Run workflow** can build just one addon (e.g. `genres`).

### Adding a list

Add one line to the addon's `catalogs` in `addons.json`, then run the workflow.

- MDBList: `{ "source": "mdblist", "list": "snoak/latest-horror-movies", "id": "mdb-horror", "name": "Latest Horror", "type": "movie" }`
- Rotten Tomatoes service: `{ "source": "rottentomatoes", "service": "max", "id": "rt-max", "name": "Latest Max", "types": ["series", "movie"] }`
- Another addon's catalog: `{ "source": "stremio", "url": "https://…/catalog/movie/<catalog id>", "id": "…", "name": "…", "type": "movie" }`

Keep existing `id`s unchanged: Nuvio folders point at them.

### Notes

- Latest Streaming shows each title under one service only. Hulu wins shared titles; otherwise the service where Rotten Tomatoes ranks it highest.
- Rotten Tomatoes "newest" sorts by latest episode, so network shows with old seasons on Netflix (NCIS, St. Denis Medical) can appear in Latest Netflix.
- If a source fails, the last good version of that catalog is kept.
- After changing names or catalogs, remove and re-add the addon in Nuvio; it caches manifests.
