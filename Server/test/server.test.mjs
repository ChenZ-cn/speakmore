import assert from "node:assert/strict";
import test from "node:test";

import { createMemoryQuotaStore, consumeQuota } from "../src/quota.mjs";
import { createSpeakMoreServer } from "../src/server.mjs";

test("status endpoint returns remaining quota for a device", async () => {
  const store = createMemoryQuotaStore();
  const { server, baseUrl } = await startTestServer(store);
  try {
    const response = await fetch(`${baseUrl}/v1/trial/status?device_id=device-a`);
    const body = await response.json();

    assert.equal(response.status, 200);
    assert.equal(body.remaining.outputChars, 2000);
    assert.equal(body.remaining.speechSeconds, 600);
  } finally {
    await closeServer(server);
  }
});

test("text proxy refuses hidden default key usage after trial exhaustion", async () => {
  const store = createMemoryQuotaStore();
  consumeQuota(store, "device-a", { outputChars: 2000, speechSeconds: 600 });
  const { server, baseUrl } = await startTestServer(store);
  try {
    const response = await fetch(`${baseUrl}/v1/chat/completions?device_id=device-a`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ messages: [] })
    });
    const body = await response.json();

    assert.equal(response.status, 402);
    assert.equal(body.error, "trial_quota_exceeded");
  } finally {
    await closeServer(server);
  }
});

async function startTestServer(store) {
  const server = await createSpeakMoreServer({
    store,
    enableRealtimeProxy: false,
    env: {}
  });

  await new Promise((resolve) => server.listen(0, "127.0.0.1", resolve));
  const address = server.address();
  return {
    server,
    baseUrl: `http://127.0.0.1:${address.port}`
  };
}

async function closeServer(server) {
  await new Promise((resolve, reject) => {
    server.close((error) => error ? reject(error) : resolve());
  });
}
