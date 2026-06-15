# SpeakMore 多说有益

SpeakMore（多说有益）is a macOS menu bar voice input tool. It listens from a shortcut, shows live transcription, cleans, translates, polishes, or answers selected text with a configurable AI provider, then writes the final text back into the active app.

This repository contains the open-source macOS MVP: the Swift app, tests, local build scripts, a lightweight server-proxy skeleton, and public documentation. It does not include private API keys, local user settings, raw audio, packaged apps generated during local builds, or internal test records.

## Download

- Download the current macOS DMG: [downloads/SpeakMore-macOS.dmg](downloads/SpeakMore-macOS.dmg)
- Read the public guide: [https://chenz-cn.github.io/speakmore/](https://chenz-cn.github.io/speakmore/)

## Features

- Long-press or custom shortcut voice input.
- Modes for auto cleanup, direct dictation, translation, polishing, and asking about selected text.
- macOS Accessibility based selected-text reading with clipboard fallback.
- Live floating input panel with audio quality indicators.
- Configurable interface language, models, endpoints, and shortcuts.
- Local API key storage outside the repository.
- Optional server proxy for trial quota and default-provider keys.

## Requirements

- macOS 14 or later.
- Xcode command line tools with Swift Package Manager.
- A speech recognition API key and a text AI API key, unless you connect the app to your own proxy.
- Microphone permission and Accessibility permission for global shortcut and paste automation.

## Run In Development

```bash
swift run SpeakMore
```

## Build Local App Bundle

```bash
Scripts/build_app.sh
open "build/SpeakMore-多说有益.app"
```

## Build Local DMG

```bash
Scripts/build_dmg.sh
open dist
```

Generated app bundles and DMG files are intentionally ignored by git.

## First Setup

1. Open SpeakMore from the menu bar.
2. Choose `Settings / Models...`.
3. Add your Speech Recognition API key and Text AI API key, then save.
4. Allow microphone permission when macOS asks.
5. Enable Accessibility permission for SpeakMore in System Settings.

API keys are stored in the user's local application support directory, not in source control.

## Default Providers

The app currently defaults to Alibaba Bailian for both speech recognition and text AI:

- Speech recognition: `qwen3-asr-flash-realtime-2026-02-10`
- Text AI: `qwen3.6-flash`

Settings also expose OpenAI, DeepSeek, SiliconFlow, and custom OpenAI-compatible endpoints where supported.

## Server Proxy

The optional server in `Server/` keeps default provider keys off the client and meters a small trial quota by device ID.

```bash
cd Server
npm install
cp .env.example .env
npm start
```

Set real secrets in your deployment environment, not in git. See [Server/README.md](Server/README.md).

## Privacy Defaults

- SpeakMore does not store raw audio.
- Text history is off by default.
- API keys must stay in local user storage or trusted server environment variables.
- Speech and text are sent only to the providers configured by the user or proxy operator.

## Security

Do not commit API keys, `.env` files, provisioning profiles, signing certificates, or local application-support data. See [SECURITY.md](SECURITY.md).

## License

MIT

## Contact

For questions, feedback, or collaboration, email `zhangchen.more@gmail.com`.
