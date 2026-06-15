import assert from "node:assert/strict";
import test from "node:test";

import { createMemoryQuotaStore, getQuotaStatus, consumeQuota } from "../src/quota.mjs";

test("new devices receive the default trial quota", () => {
  const store = createMemoryQuotaStore();
  const status = getQuotaStatus(store, "device-a");

  assert.equal(status.limits.outputChars, 2000);
  assert.equal(status.limits.speechSeconds, 600);
  assert.equal(status.remaining.outputChars, 2000);
  assert.equal(status.remaining.speechSeconds, 600);
  assert.equal(status.exhausted, false);
});

test("usage is bound to the device id", () => {
  const store = createMemoryQuotaStore();

  consumeQuota(store, "device-a", { outputChars: 120, speechSeconds: 15 });

  assert.equal(getQuotaStatus(store, "device-a").remaining.outputChars, 1880);
  assert.equal(getQuotaStatus(store, "device-a").remaining.speechSeconds, 585);
  assert.equal(getQuotaStatus(store, "device-b").remaining.outputChars, 2000);
  assert.equal(getQuotaStatus(store, "device-b").remaining.speechSeconds, 600);
});

test("quota exhaustion is reported before hidden default keys are used again", () => {
  const store = createMemoryQuotaStore();

  consumeQuota(store, "device-a", { outputChars: 2000, speechSeconds: 600 });

  const status = getQuotaStatus(store, "device-a");
  assert.equal(status.remaining.outputChars, 0);
  assert.equal(status.remaining.speechSeconds, 0);
  assert.equal(status.exhausted, true);
  assert.throws(
    () => consumeQuota(store, "device-a", { outputChars: 1, speechSeconds: 0 }),
    /trial quota exceeded/
  );
});
