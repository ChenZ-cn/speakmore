# SpeakMore Server Proxy

This service keeps default provider API keys on the server and meters the free trial by device ID.

Trial limits:

- 2000 output characters
- 600 seconds of realtime speech recognition

## Run locally

```bash
cd Server
npm install
SPEAKMORE_TEXT_API_KEY=... \
SPEAKMORE_SPEECH_API_KEY=... \
npm start
```

The server listens on `http://localhost:8787` by default.

## Required secrets

Do not put these in the macOS app or in git. Set them as deployment environment variables:

- `SPEAKMORE_TEXT_API_KEY`: default Text AI key used by `/v1/chat/completions`
- `SPEAKMORE_SPEECH_API_KEY`: default realtime ASR key used by `/v1/realtime`

Optional:

- `SPEAKMORE_TEXT_ENDPOINT`: OpenAI-compatible chat completions endpoint
- `SPEAKMORE_SPEECH_PROVIDER`: `aliyun` or `openai`
- `SPEAKMORE_SPEECH_ENDPOINT`: realtime WebSocket endpoint
- `SPEAKMORE_TRIAL_STORE`: local JSON store path for trial usage
- `SPEAKMORE_PORT`: HTTP port

## API

`GET /v1/trial/status?device_id=DEVICE_ID`

Returns remaining trial quota for a device.

`POST /v1/chat/completions?device_id=DEVICE_ID`

Proxies an OpenAI-compatible text request and decrements output-character quota.

`WS /v1/realtime?device_id=DEVICE_ID&provider=aliyun`

Relays the existing realtime WebSocket protocol to the upstream provider and decrements speech-seconds quota from appended PCM audio.

## Deployment note

The local JSON file is for development only. A production deployment should replace it with a durable store such as Postgres, Redis, Cloudflare KV/D1, or another managed database.
