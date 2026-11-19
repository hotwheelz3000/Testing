// Writes a catalog plus "skip" pages so apps show a See All arrow and can page.
import { mkdir, writeFile } from "node:fs/promises";
export async function writeCatalog(dir, metas) {
  await mkdir(dir, { recursive: true });
  await writeFile(`${dir}.json`, JSON.stringify({ metas }, null, 2));
  const skips = new Set([metas.length]);
  for (let k = 10; k < metas.length; k += 10) skips.add(k);
  for (const k of skips) await writeFile(`${dir}/skip=${k}.json`, JSON.stringify({ metas: metas.slice(k) }));
}
export const SKIP_EXTRA = [{ name: "skip", isRequired: false }];
