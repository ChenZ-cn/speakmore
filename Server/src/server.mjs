import http from "node:http";
import { pathToFileURL } from "node:url";

import { consumeQuota, getQuotaStatus } from "./quota.mjs";
import { defaultQuotaStorePath, loadQuotaStore, saveQuotaStore } from "./fileQuotaStore.mjs";

const DEFAULT_TEXT_ENDPOINT = "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions";
const DEFAULT_ALIYUN_REALTIME_ENDPOINT =
  "wss://dashscope.aliyuncs.com/api-ws/v1/realtime?model=qwen3-asr-flash-realtime-2026-02-10";
const DEFAULT_OPENAI_REALTIME_ENDPOINT = "wss://api.openai.com/v1/realtime?intent=transcription";

export async function createSpeakMoreServer(options = {}) {
  const env = options.env ?? process.env;
  const storePath = options.storePath ?? env.SPEAKMORE_TRIAL_STORE ?? defaultQuotaStorePath();
  const store = options.store ?? await loadQuotaStore(storePath);
  const persist = async () => {
    if (!options.store) {
      await saveQuotaStore(store, storePath);
    }
  };

  const context = { env, store, persist };
  const server = http.createServer((request, response) => {
    handleHttpRequest(request, response, context).catch((error) => {
      writeJson(response, 500, { error: "server_error", message: error.message });
    });
  });

  if (options.enableRealtimeProxy !== false) {
    await attachRealtimeProxy(server, context);
  }

  return server;
}

async function handleHttpRequest(request, response, context) {
  const url = new URL(request.url ?? "/", `http://${request.headers.host ?? "localhost"}`);

  if (request.method === "GET" && url.pathname === "/health") {
    return writeJson(response, 200, { ok: true });
  }

  if (request.method === "GET" && url.pathname === "/v1/trial/status") {
    const deviceId = deviceIdFromRequest(request, url);
    return writeJson(response, 200, getQuotaStatus(context.store, deviceId));
  }

  if (request.method === "POST" && url.pathname === "/v1/trial/consume") {
    const body = await readJson(request);
    const deviceId = body.device_id ?? deviceIdFromRequest(request, url);
    const status = consumeQuota(context.store, deviceId, {
      outputChars: body.output_chars,
      speechSeconds: body.speech_seconds
    });
    await context.persist();
    return writeJson(response, 200, status);
  }

  if (request.method === "POST" && url.pathname === "/v1/chat/completions") {
    return proxyTextCompletion(request, response, url, context);
  }

  writeJson(response, 404, { error: "not_found" });
}

async function proxyTextCompletion(request, response, url, context) {
  const deviceId = deviceIdFromRequest(request, url);
  const status = getQuotaStatus(context.store, deviceId);
  if (status.exhausted) {
    return writeJson(response, 402, {
      error: "trial_quota_exceeded",
      message: "Trial quota is exhausted. Ask the user to enter their own API key.",
      status
    });
  }

  const apiKey = firstNonEmpty(
    context.env.SPEAKMORE_TEXT_API_KEY,
    context.env.ALIYUN_BAILIAN_API_KEY,
    context.env.ALIYUN_API_KEY
  );
  if (!apiKey) {
    return writeJson(response, 503, { error: "missing_text_api_key" });
  }

  const endpoint = context.env.SPEAKMORE_TEXT_ENDPOINT ?? DEFAULT_TEXT_ENDPOINT;
  const body = await readRawBody(request);
  const upstreamResponse = await fetch(endpoint, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${apiKey}`,
      "Content-Type": request.headers["content-type"] ?? "application/json"
    },
    body
  });
  const data = Buffer.from(await upstreamResponse.arrayBuffer());

  if (upstreamResponse.ok) {
    const outputChars = Math.min(extractOutputChars(data), status.remaining.outputChars);
    if (outputChars > 0) {
      consumeQuota(context.store, deviceId, { outputChars, speechSeconds: 0 });
      await context.persist();
    }
  }

  response.writeHead(upstreamResponse.status, {
    "Content-Type": upstreamResponse.headers.get("content-type") ?? "application/json"
  });
  response.end(data);
}

async function attachRealtimeProxy(server, context) {
  const { WebSocketServer, WebSocket } = await import("ws");
  const websocketServer = new WebSocketServer({ noServer: true });

  server.on("upgrade", (request, socket, head) => {
    const url = new URL(request.url ?? "/", `http://${request.headers.host ?? "localhost"}`);
    if (url.pathname !== "/v1/realtime") {
      return socket.destroy();
    }

    websocketServer.handleUpgrade(request, socket, head, (client) => {
      websocketServer.emit("connection", client, request);
    });
  });

  websocketServer.on("connection", (client, request) => {
    handleRealtimeConnection(WebSocket, client, request, context).catch((error) => {
      client.close(1011, error.message.slice(0, 120));
    });
  });
}

async function handleRealtimeConnection(WebSocket, client, request, context) {
  const url = new URL(request.url ?? "/", `http://${request.headers.host ?? "localhost"}`);
  const deviceId = deviceIdFromRequest(request, url);
  let status = getQuotaStatus(context.store, deviceId);
  if (status.exhausted) {
    client.close(4008, "trial quota exceeded");
    return;
  }

  const provider = (url.searchParams.get("provider") ?? context.env.SPEAKMORE_SPEECH_PROVIDER ?? "aliyun").toLowerCase();
  const upstreamUrl = realtimeEndpointFor(provider, context.env);
  const speechApiKey = realtimeApiKeyFor(provider, context.env);
  if (!speechApiKey) {
    client.close(1011, "missing speech api key");
    return;
  }

  let sampleRate = provider === "openai" ? 24_000 : 16_000;
  let estimatedSpeechSeconds = 0;
  let finalized = false;
  let upstreamOpen = false;
  const pendingMessages = [];

  const upstream = new WebSocket(upstreamUrl, {
    headers: realtimeHeadersFor(provider, speechApiKey)
  });

  upstream.on("open", () => {
    upstreamOpen = true;
    for (const pending of pendingMessages.splice(0)) {
      upstream.send(pending.data, { binary: pending.isBinary });
    }
  });

  upstream.on("message", (data, isBinary) => {
    if (client.readyState === WebSocket.OPEN) {
      client.send(data, { binary: isBinary });
    }
  });

  upstream.on("close", (code, reason) => {
    finalizeSpeechUsage().finally(() => {
      if (client.readyState === WebSocket.OPEN || client.readyState === WebSocket.CONNECTING) {
        client.close(code, reason);
      }
    });
  });

  upstream.on("error", () => {
    if (client.readyState === WebSocket.OPEN || client.readyState === WebSocket.CONNECTING) {
      client.close(1011, "upstream realtime error");
    }
  });

  client.on("message", (data, isBinary) => {
    const audioUpdate = estimateAudioSeconds(data, isBinary, sampleRate);
    sampleRate = audioUpdate.sampleRate;
    estimatedSpeechSeconds += audioUpdate.seconds;

    if (estimatedSpeechSeconds > status.remaining.speechSeconds) {
      client.close(4008, "trial quota exceeded");
      upstream.close();
      return;
    }

    if (upstreamOpen) {
      upstream.send(data, { binary: isBinary });
    } else {
      pendingMessages.push({ data, isBinary });
    }
  });

  client.on("close", () => {
    finalizeSpeechUsage().finally(() => upstream.close());
  });

  async function finalizeSpeechUsage() {
    if (finalized) {
      return;
    }
    finalized = true;

    const speechSeconds = Math.min(Math.ceil(estimatedSpeechSeconds), status.remaining.speechSeconds);
    if (speechSeconds > 0) {
      status = consumeQuota(context.store, deviceId, { outputChars: 0, speechSeconds });
      await context.persist();
    }
  }
}

function estimateAudioSeconds(data, isBinary, currentSampleRate) {
  if (isBinary) {
    return { sampleRate: currentSampleRate, seconds: 0 };
  }

  try {
    const event = JSON.parse(data.toString("utf8"));
    const sampleRate =
      event?.session?.sample_rate ??
      event?.session?.audio?.input?.format?.rate ??
      currentSampleRate;
    const audio = typeof event.audio === "string" ? event.audio : "";
    const bytes = audio ? Buffer.byteLength(audio, "base64") : 0;
    return {
      sampleRate,
      seconds: bytes > 0 ? bytes / 2 / sampleRate : 0
    };
  } catch {
    return { sampleRate: currentSampleRate, seconds: 0 };
  }
}

function realtimeEndpointFor(provider, env) {
  if (provider === "openai") {
    return env.SPEAKMORE_SPEECH_ENDPOINT ?? DEFAULT_OPENAI_REALTIME_ENDPOINT;
  }
  return env.SPEAKMORE_SPEECH_ENDPOINT ?? DEFAULT_ALIYUN_REALTIME_ENDPOINT;
}

function realtimeApiKeyFor(provider, env) {
  if (provider === "openai") {
    return firstNonEmpty(env.SPEAKMORE_SPEECH_API_KEY, env.OPENAI_API_KEY);
  }
  return firstNonEmpty(env.SPEAKMORE_SPEECH_API_KEY, env.ALIYUN_BAILIAN_API_KEY, env.ALIYUN_API_KEY);
}

function realtimeHeadersFor(provider, apiKey) {
  const headers = { "Authorization": `Bearer ${apiKey}` };
  if (provider !== "openai") {
    headers["OpenAI-Beta"] = "realtime=v1";
  }
  return headers;
}

async function readJson(request) {
  const raw = await readRawBody(request);
  if (!raw.length) {
    return {};
  }
  return JSON.parse(raw.toString("utf8"));
}

async function readRawBody(request) {
  const chunks = [];
  for await (const chunk of request) {
    chunks.push(chunk);
  }
  return Buffer.concat(chunks);
}

function writeJson(response, statusCode, payload) {
  response.writeHead(statusCode, { "Content-Type": "application/json; charset=utf-8" });
  response.end(JSON.stringify(payload));
}

function deviceIdFromRequest(request, url) {
  return url.searchParams.get("device_id") ?? request.headers["x-speakmore-device-id"];
}

function extractOutputChars(data) {
  try {
    const json = JSON.parse(data.toString("utf8"));
    const text = json?.choices?.[0]?.message?.content ?? "";
    return [...String(text)].length;
  } catch {
    return 0;
  }
}

function firstNonEmpty(...values) {
  return values.find((value) => typeof value === "string" && value.trim())?.trim();
}

if (import.meta.url === pathToFileURL(process.argv[1]).href) {
  const port = Number(process.env.SPEAKMORE_PORT ?? 8787);
  const server = await createSpeakMoreServer();
  server.listen(port, () => {
    console.log(`SpeakMore proxy listening on http://localhost:${port}`);
  });
}
