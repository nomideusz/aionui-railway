# Deploy and Host AionUi on Railway

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/aionui?utm_medium=integration&utm_source=button&utm_campaign=aionui)

[AionUi](https://github.com/iOfficeAI/AionUi) is a free, open-source (Apache-2.0) "cowork" app for AI agents. You chat with an agent that can run commands, write files and work on projects, then review what it did in a files and changes panel. It can also run scheduled tasks and teams of agents. This template runs AionUi's WebUI as an always-on, password-protected web app on Railway, with all data kept on a volume.

## About Hosting AionUi

One service, one volume at `/data`.

The image runs the upstream AionUi web runtime and its Rust backend (AionCore), built from the upstream release tag. AionUi's own remote mode starts the backend with authentication switched off. This build turns authentication on and adds the CSRF handling the web client does not send yet. The changes are in `build/remote-auth.patch`. Every API call and WebSocket needs a login session, and requests from other sites are rejected.

The admin password comes from a Railway variable and is applied on every boot. Conversations, settings, provider keys (encrypted at rest), skills and agent workspaces live on the volume.

## Common Use Cases

- A browser-based AI agent workspace you can use from any device, with any model: OpenRouter, DeepSeek, OpenAI, Anthropic, Gemini, Kimi, Qwen or any OpenAI-compatible API
- Scheduled agent jobs such as daily reports, file clean-ups or monitoring, which keep running while your laptop is off
- Agent teams: several assistants with different roles working on one task
- A shared sandbox where the agent can run shell commands, Python and git on a server instead of your machine

## Dependencies for AionUi Hosting

- An API key for at least one LLM provider (OpenRouter gives access to most models with one key)

### Deployment Dependencies

- [AionUi on GitHub](https://github.com/iOfficeAI/AionUi)
- [AionUi LLM configuration guide](https://github.com/iOfficeAI/AionUi/wiki/LLM-Configuration)
- [OpenRouter API keys](https://openrouter.ai/keys)

### Implementation Details

**First login:** open your Railway domain and sign in as `admin` with `AIONUI_ADMIN_PASSWORD` from the service's Variables tab.

**Connect a model:**

1. Go to **Settings → Model → Add Model → Add manually**.
2. Pick the platform, paste your API key and choose models.
3. Back in chat, select the model under the message box.

**Using the agent:** the built-in **Aion CLI** agent asks before it runs a command or writes a file. Pick "allow once" or "allow always", or change the permission mode under the message box. Files it creates appear in the side panel, and each conversation gets its own workspace on the volume.

**Changing the password:** edit `AIONUI_ADMIN_PASSWORD` and redeploy. This also signs out every existing session. A redeploy that leaves the password unchanged keeps you logged in. The in-app WebUI password controls are not available on this build: they are local-only endpoints that stay locked when authentication is on.

Notes and limits:

- Aion CLI is built in. The other agents in the list (Claude Code, Codex, Gemini CLI and more) are only detected when their CLI is installed, and this image does not ship them.
- It is very light: about 75 MB of RAM idle and roughly 220 MB of disk on first boot, mostly the bundled Node runtime. Give it more memory if agents run heavy builds.
- The agent's commands run inside the container as root. Anything outside `/data` resets on redeploy.
- Upgrades come through this template's repository, which rebuilds each new AionUi release with the authentication patch.

## Why Deploy AionUi on Railway?

Railway is a singular platform to deploy your infrastructure stack. Railway will host your infrastructure so you don't have to deal with configuration, while allowing you to vertically and horizontally scale it.

By deploying AionUi on Railway, you are one step closer to supporting a complete full-stack application with minimal burden. Host your servers, databases, AI agents, and more on Railway.
