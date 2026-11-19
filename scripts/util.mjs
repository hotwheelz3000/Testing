// Basic helpers shared by every script: JSON files, downloads with retries, name matching.
import { mkdir, readFile, writeFile } from "node:fs/promises";
import { dirname } from "node:path";

export const UA = { "user-agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 Safari/605.1.15" };
export const sleep = ms => new Promise(r => setTimeout(r, ms));

// "The Body!" and "the body" compare equal.
export const norm = s => String(s || "").toLowerCase().replace(/[^a-z0-9]/g, "");

export async function readJson(path, fallback) {
  try { return JSON.parse(await readFile(path, "utf8")); } catch { return fallback; }
}

export async function writeJson(path, data, pretty = true) {
  await mkdir(dirname(path), { recursive: true });
  await writeFile(path, JSON.stringify(data, null, pretty ? 2 : 0));
}

// A JSON cache file under _cache/ (GitHub Pages doesn't serve underscore folders).
// Loaded once even when many workers ask at the same time.
export function fileCache(path) {
  let data = null, loading = null;
  return {
    load: async () => (data ??= await (loading ??= readJson(path, {}))),
    save: async () => { if (data) await writeJson(path, data, false); },
  };
}

// fetch with a browser user agent; retries on network errors, 422 (Arctic Shift timeout), 429 and 5xx.
export async function get(url, as = "json") {
  for (let attempt = 1; attempt <= 3; attempt++) {
    try {
      const r = await fetch(url, { headers: UA });
      if (r.ok) return as === "text" ? r.text() : r.json();
      if (![422, 429].includes(r.status) && r.status < 500) throw new Error(`HTTP ${r.status}`);
      console.log(`  retry ${attempt} (${r.status}) ${url}`);
    } catch (e) {
      if (attempt === 3 || /HTTP 4/.test(e.message)) throw e;
    }
    await sleep(1500 * attempt);
  }
  throw new Error(`gave up on ${url}`);
}
