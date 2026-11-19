// Writes catalog files and the addon manifest.
import { rm } from "node:fs/promises";
import { writeJson } from "./util.mjs";

// Declaring "skip" makes apps show a See All arrow and page through the list.
export const SKIP_EXTRA = [{ name: "skip", isRequired: false }];

// <dir>.json holds the whole list; <dir>/skip=N.json holds the rest after N items.
// Old page files are cleared first so a shorter list leaves nothing stale behind.
export async function writeCatalog(dir, metas) {
  await rm(dir, { recursive: true, force: true });
  await writeJson(`${dir}.json`, { metas });
  const skips = new Set([metas.length]);
  for (let k = 10; k < metas.length; k += 10) skips.add(k);
  for (const k of skips) await writeJson(`${dir}/skip=${k}.json`, { metas: metas.slice(k) }, false);
}

export async function writeManifest(addon, cats) {
  // Series catalogs first, then movies (stable within each type).
  const listed = [...cats].sort((a, b) => (a.type === "series" ? 0 : 1) - (b.type === "series" ? 0 : 1));
  await writeJson(`${addon.folder}/manifest.json`, {
    id: addon.id, version: addon.version, name: addon.name, description: addon.description,
    resources: ["catalog"],
    types: [...new Set(listed.map(c => c.type))],
    catalogs: listed.map(c => ({ type: c.type, id: c.id, name: c.name, extra: SKIP_EXTRA })),
    idPrefixes: addon.idPrefixes || ["tt"],
  });
}
