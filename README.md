# Testing

## Catalog addons

Three Stremio/Nuvio catalog addons, rebuilt every 6 hours by the **Build addons** workflow and served by GitHub Pages from the `claude/maid-hotel-game-kga08a` branch (next to the hotel game site).

| Addon | Install link |
|---|---|
| Latest Streaming (TV: TMDB network lists + Rotten Tomatoes; movies: TMDB Discover + Rotten Tomatoes) | `stremio://hotwheelz3000.github.io/Testing/rt/manifest.json` |
| r/movieleaks (Reddit posts via Arctic Shift, jcdc's addon as backup) | `stremio://hotwheelz3000.github.io/Testing/movieleaks/manifest.json` |
| Latest Genres (MDBList) | `stremio://hotwheelz3000.github.io/Testing/genres/manifest.json` |

For apps that want a plain URL, swap `stremio://` for `https://`.

### Files

- `addons.json`: every addon and catalog. **Edit this to add or remove lists.**
- `scripts/build.mjs`: builds the addons in `addons.json` (load each catalog, fix artwork, remove shared titles, write files).
- `scripts/sources.mjs`: where titles come from (`rottentomatoes`, `mdblist`, `stremio`, `reddit`, `tmdb`).
- `scripts/artwork.mjs`: posters, backgrounds and logos, with backups (see Notes).
- `scripts/tmdb.mjs`: official TMDB artwork (uses the `TMDB_KEY` secret).
- `scripts/imdb.mjs`: matches titles to IMDb ids through Cinemeta.
- `scripts/catalog.mjs`: writes catalog files (with See All paging) and manifests.
- `scripts/util.mjs`: downloads with retries, JSON files, caches, name matching.
- `.github/workflows/rt.yml`: the "Build addons" schedule. **Run workflow** can build just one addon (e.g. `genres`).

### Adding a list

Add one line to the addon's `catalogs` in `addons.json`, then run the workflow.

- MDBList: `{ "source": "mdblist", "list": "snoak/latest-horror-movies", "id": "mdb-horror", "name": "Latest Horror", "type": "movie" }`
- Rotten Tomatoes service: `{ "source": "rottentomatoes", "service": "max", "id": "rt-max", "name": "Latest Max", "types": ["series", "movie"] }`
- Subreddit posts: `{ "source": "reddit", "subreddit": "movieleaks", "days": 60, "id": "…", "name": "…", "type": "movie" }`
- Another addon's catalog: `{ "source": "stremio", "url": "https://…/catalog/movie/<catalog id>", "id": "…", "name": "…", "type": "movie" }`

Keep existing `id`s unchanged: Nuvio folders point at them.

### Cover images

Images listed in `covers.json` are downloaded once into `covers/` on the Pages branch and served at `https://hotwheelz3000.github.io/Testing/covers/<file>` (handy for Nuvio folder covers).

### Notes

- Latest Streaming shows each title under one service only. Hulu wins shared titles; otherwise the service where Rotten Tomatoes ranks it highest.
- TV lists come from journey.co.il's TMDB network catalogs (`/stremio/catalog/network/<TMDB network id>.json`, 100 newest, no key). Network ids: Netflix 213, Hulu 453, Apple TV+ 2552, Prime 1024, Disney+ 2739, Paramount+ 4330.
- TV catalogs use `merge`: the TMDB network list first, then Rotten Tomatoes titles not already listed (no duplicates, max 200). Movie catalogs merge TMDB Discover (newest released movies streaming on the service in the US; provider ids Netflix 8, Hulu 15, Apple TV+ 350, Prime 9, Disney+ 337, Paramount+ 531|582|1853|2303|2616) with Rotten Tomatoes "newest".
- A catalog can have a `fallback` source, used when its main source fails. If both fail, the last good version is kept.
- After changing names or catalogs, remove and re-add the addon in Nuvio; it caches manifests.
