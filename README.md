# Deploy and Host AionUi on Railway

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/aionui?utm_medium=integration&utm_source=button&utm_campaign=aionui)

[AionUi](https://github.com/iOfficeAI/AionUi) is a free, open-source (Apache-2.0) "cowork" app for AI agents. You chat with an agent that can run commands, write files and work on projects, then review what it did in a files and changes panel. It can also run scheduled tasks and teams of agents. This template runs AionUi's WebUI as an always-on, password-protected web app on Railway, with all data kept on a volume.

## About Hosting AionUi

One service, one volume at `/data`.

The image runs the upstream AionUi web runtime and its Rust backend (AionCore), built from the upstream release tag. AionUi's own remote mode starts the backend with authentication switched off. This build turns authentication on and adds the CSRF handling the web client does not send yet. The changes are in `build/remote-auth.patch`. Every API call and WebSocket needs a login session, and requests from other sites are rejected.

The admin password comes from a Railway variable and is applied on every boot. Claude Code, Codex, Gemini CLI and OpenCode are installed on the volume and updated to their latest versions on every boot, so AionUi can use them as agents. Conversations, settings, provider keys (encrypted at rest), skills and agent workspaces live on the volume.

## Common Use Cases

- A browser-based AI agent workspace you can use from any device, with any model: OpenRouter, DeepSeek, OpenAI, Anthropic, Gemini, Kimi, Qwen or any OpenAI-compatible API
- Scheduled agent jobs such as daily reports, file clean-ups or monitoring, which keep running while your laptop is off
- Agent teams: several assistants with different roles working on one task
- A shared sandbox where the agent can run shell commands, Python and git on a server instead of your machine

## Dependencies for AionUi Hosting

- An API key for at least one LLM provider (OpenRouter gives access to most models with one key), or a Claude, ChatGPT or Google account for the agent CLIs. OpenCode's free models need no key at all.

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

**Agent CLIs:** pick an agent above the message box. Each one signs in its own way:

- **OpenCode** works right away with its free models, no key needed.
- **Claude Code:** run `claude setup-token` on your own computer to use your Claude Pro/Max plan, and paste the token into `CLAUDE_CODE_OAUTH_TOKEN`. Or set `ANTHROPIC_API_KEY`.
- **Codex:** set `OPENAI_API_KEY`. To use a ChatGPT plan instead, open a shell with `railway ssh` and run `codex login --device-auth`.
- **Gemini CLI:** set `GEMINI_API_KEY` (Google AI Studio has a free tier).

`AIONUI_AGENTS` picks which CLIs are installed: any of `claude`, `codex`, `gemini`, `opencode` and `qwen`, or any npm package name, comma-separated. Set it to `none` to install none. Claude Code and Codex still ask in AionUi before they run a command.

**Changing the password:** edit `AIONUI_ADMIN_PASSWORD` and redeploy. This also signs out every existing session. A redeploy that leaves the password unchanged keeps you logged in. The in-app WebUI password controls are not available on this build: they are local-only endpoints that stay locked when authentication is on.

Notes and limits:

- AionUi itself is light, at about 75 MB of RAM idle. Each running agent CLI session adds about 200–250 MB, so give it more memory if you run several at once or agents run heavy builds.
- The four agent CLIs take about 1.1 GB of the volume and add a few seconds to each boot while they update. If one reports that it is newer than the version AionUi verified, that is expected and it still works.
- Codex defaults to full access here, because its own sandbox cannot run inside a container. The container is the sandbox, and AionUi still asks before commands run.
- The agent's commands run inside the container as root. Anything outside `/data` resets on redeploy.
- Upgrades come through this template's repository, which rebuilds each new AionUi release with the authentication patch.

## Why Deploy AionUi on Railway?

Railway is a singular platform to deploy your infrastructure stack. Railway will host your infrastructure so you don't have to deal with configuration, while allowing you to vertically and horizontally scale it.

By deploying AionUi on Railway, you are one step closer to supporting a complete full-stack application with minimal burden. Host your servers, databases, AI agents, and more on Railway.
