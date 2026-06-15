import { mkdir, readFile, writeFile } from "node:fs/promises";
import path from "node:path";

import { createMemoryQuotaStore } from "./quota.mjs";

export function defaultQuotaStorePath() {
  return path.join(process.cwd(), ".data", "trial-usage.json");
}

export async function loadQuotaStore(filePath = defaultQuotaStorePath()) {
  try {
    const data = await readFile(filePath, "utf8");
    return createMemoryQuotaStore(JSON.parse(data));
  } catch (error) {
    if (error?.code === "ENOENT") {
      return createMemoryQuotaStore();
    }
    throw error;
  }
}

export async function saveQuotaStore(store, filePath = defaultQuotaStorePath()) {
  await mkdir(path.dirname(filePath), { recursive: true });
  const records = Object.fromEntries(store.records.entries());
  await writeFile(filePath, JSON.stringify(records, null, 2) + "\n", "utf8");
}
