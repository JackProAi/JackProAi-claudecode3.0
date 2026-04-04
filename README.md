# JackProAi-claudecode3.1 (Local Deployment Edition, Unofficial)

> Third-party local deployment adaptation for compatibility testing and architecture study, organized from archived package files and restored source maps.

> If you need remote installation or custom feature development, add the author on WeChat: <font color="#22c55e">JACKPROAI</font> (state your purpose; paid service).
>
> **Douyin/Bilibili/Xiaohongshu: <font color="#22c55e">JACK的AI视界</font>. WeChat Official Account: <font color="#22c55e">JACK带你玩AI</font>.**

[中文文档](./README.zh-CN.md)
[Changelog](./CHANGELOG.md)
[Compliance / 合规说明](./COMPLIANCE.md)

## Disclaimer
- This repository is **not** an official Anthropic release.
- This repository is **not affiliated with, endorsed by, or operated by** Anthropic.
- "Claude" and "Anthropic" are trademarks of their respective owners and are used only for compatibility description.
- It is for local deployment practice and architecture research only. Please evaluate the risks yourself.
- Keep upstream legal files (for example `package/LICENSE.md`) when redistributing this project.
- Some files under `package/` are upstream originals kept for compatibility and legal traceability.

## Current Repository Contents (Verified Against This Folder)
- Launch entrypoints:
  - `claude-local.ps1` (Windows PowerShell)
  - `claude-local` (Bash)
  - `start-claude-local.ps1` / `start-claude-local.bat` (recommended on Windows)
- Core program: `package/cli.js`
- Version note: `node package/cli.js --version` is `2.1.90`.
- Restored source directory: `restored-src/`
- Environment template: `claude-local.env.example`

## Requirements
- Node.js 18+
- Windows PowerShell (if using the provided Windows scripts)
- One of the following:
  - Anthropic-compatible cloud API
  - Local OpenAI-compatible endpoint (for example, LM Studio)

## Quick Start (Windows)
```powershell
# Clone from GitHub
git clone https://github.com/JackProAi/JackProAi-claudecode3.1.git
cd JackProAi-claudecode3.1

# If script execution is blocked, run once:
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

# Option A: auto-create claude-local.env (when missing)
.\claude-local.ps1 --init-env

# Option B: copy from template
Copy-Item ".\claude-local.env.example" ".\claude-local.env" -Force
```

After editing `claude-local.env`, it is recommended to start via the launcher (with session handling):
```powershell
.\start-claude-local.bat
# or
.\start-claude-local.ps1
```

Launcher behavior:
- It tries to resume the latest session for the current project; if no valid history exists, it starts a new session.
- It appends a system prompt to prefer Simplified Chinese responses unless you explicitly request another language.
- It passes `--thinking disabled` by default for better compatibility with some models.
- If resume fails, it automatically falls back to a new session.

You can also call the low-level entry directly (without launcher logic):
```powershell
.\claude-local.ps1 --bare
```

## `.env` Files
Configuration-related files in this directory:
- `claude-local.env`: active runtime config (default file loaded)
- `claude-local.env.example`: template
- `claude-local - API.env`: cloud API sample profile

To switch to the API sample profile:
```powershell
Copy-Item ".\claude-local - API.env" ".\claude-local.env" -Force
```

## Config Examples

### 1) Local model (LM Studio example)
```env
CLAUDE_LOCAL_PROVIDER=lmstudio
ANTHROPIC_AUTH_TOKEN=lmstudio
ANTHROPIC_BASE_URL=http://127.0.0.1:1234
ANTHROPIC_MODEL=qwen3.5-9b
ANTHROPIC_SMALL_FAST_MODEL=qwen3.5-9b
CLAUDE_LOCAL_RUNTIME_DIR=.claude-local-runtime
```

### 2) Cloud API (SiliconFlow example)
```env
CLAUDE_LOCAL_PROVIDER=siliconflow
ANTHROPIC_AUTH_TOKEN=your_api_key
ANTHROPIC_BASE_URL=https://api.siliconflow.cn/
ANTHROPIC_MODEL=moonshotai/Kimi-K2-Instruct-0905
ANTHROPIC_SMALL_FAST_MODEL=moonshotai/Kimi-K2-Instruct-0905
CLAUDE_LOCAL_RUNTIME_DIR=.claude-local-runtime
```

Notes:
- `claude-local.ps1` and `claude-local` both load `claude-local.env` by default.
- Do not commit real API keys to this repository.
- For LM Studio, a larger context window (for example 25k+) helps avoid context-limit errors.

## Common Launch Commands
```powershell
# version
node .\package\cli.js --version

# REPL mode
.\claude-local --bare

# one-shot prompt
.\claude-local -p "Only reply: hello" --bare --output-format text
```

For macOS/Linux:
```bash
./claude-local --version
./claude-local --bare
```

## CODEX Plugin Notes
- This release directory includes usable Codex plugin runtime data by default (under `.claude-local-runtime/home/plugins/`).
- On startup, `claude-local.ps1` auto-repairs Codex plugin state (`known_marketplaces.json`, `installed_plugins.json`, and `enabledPlugins` in `settings.json`).
- If you reinitialize runtime or plugin commands are missing, run:

```text
/plugin marketplace add openai/codex-plugin-cc
/plugin install codex@openai-codex
/reload-plugins
/codex:setup
```

Common commands:
```text
/codex:review
/codex:adversarial-review
/codex:rescue
/codex:status
/codex:result
/codex:cancel
```

## Project Structure
```text
JackProAi-claudecode3.1
├── claude-local
├── claude-local.ps1
├── start-claude-local.bat
├── start-claude-local.ps1
├── claude-local.env
├── claude-local.env.example
├── claude-local - API.env
├── package/
│   ├── cli.js
│   ├── package.json
│   └── vendor/
├── restored-src/
│   ├── src/
│   └── vendor/
├── extract-sources.js
├── README.md
└── README.zh-CN.md
```

## Notes
- Runtime data is stored under `.claude-local-runtime/` by default.
- Scripts enable `CLAUDE_CODE_NO_FLICKER=1` by default to reduce redraw/flicker issues.
- If terminal output appears garbled, start with `start-claude-local.bat` or `start-claude-local.ps1` first.
- This project must not be described or published as an official product release.
- For remote installation or custom feature development, add the author on WeChat: <font color="#22c55e">JACKPROAI</font> (state your purpose; paid service).
