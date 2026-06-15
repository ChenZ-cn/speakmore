# Security Policy

## Secrets

Never commit API keys, access tokens, signing certificates, provisioning profiles,
`.env` files, or local application-support data.

SpeakMore stores user API keys outside the repository. The optional server proxy
expects provider keys to be supplied through deployment environment variables.

## Reporting

If you find a security issue, email `zhangchen.more@gmail.com` with a concise
description and reproduction steps.

Please do not publish exploitable details before there is a fix or mitigation.
