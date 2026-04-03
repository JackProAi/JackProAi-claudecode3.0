# JackProAi-claudecode3.0（本地部署版，非官方）

> 基于 `2026-03-31` 泄露包与 Source Map 还原整理的 Claude Code 本地部署版本（非官方）。

> 如需远程安装或定制功能，可加博主微信：`JACKPROAI`（注明来意，有偿）。

[Read English Documentation](./README.md)

## 免责声明
- 本仓库**不是** Anthropic 官方发布版本。
- 仅用于本地部署实践与架构研究学习，请自行评估使用风险。

## 当前仓库内容（已按目录核对）
- 启动入口：
  - `claude-local.ps1`（Windows PowerShell）
  - `claude-local`（Bash）
  - `start-claude-local.ps1` / `start-claude-local.bat`（Windows 推荐）
- 核心程序：`package/cli.js`
- 版本说明：`node package/cli.js --version` 显示 `2.1.90`。
- 还原源码目录：`restored-src/`
- 环境模板：`claude-local.env.example`

## 环境要求
- Node.js 18+
- Windows PowerShell（若在 Windows 下使用仓库内脚本）
- 以下二选一：
  - Anthropic 兼容云 API
  - 本地 OpenAI 兼容接口（例如 LM Studio）

## 快速开始（Windows）
```powershell
# 从 GitHub 拉取（仓库名是 2.0，但内容已是 3.0 版本）
git clone https://github.com/JackProAi/JackProAi-claudecode2.0.git JackProAi-claudecode3.0
cd JackProAi-claudecode3.0

# 首次执行脚本可能需要放开策略
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

# 方式 A：自动生成 claude-local.env（文件不存在时）
.\claude-local.ps1 --init-env

# 方式 B：从模板复制
Copy-Item ".\claude-local.env.example" ".\claude-local.env" -Force
```

编辑 `claude-local.env` 后，推荐用启动器进入（带会话处理）：
```powershell
.\start-claude-local.bat
# 或
.\start-claude-local.ps1
```

启动器行为说明：
- 会优先读取当前项目历史并尝试续接会话；找不到可用历史时自动新开会话。
- 默认追加系统提示：优先使用简体中文回复（除非你主动要求其他语言）。
- 默认传入 `--thinking disabled`，减少部分兼容模型下的思考模式问题。
- 若恢复旧会话失败，会自动降级为新会话启动。

也可直接调用底层入口（不走启动器）：
```powershell
.\claude-local.ps1 --bare
```

## `.env` 文件说明
当前目录里与配置相关的文件：
- `claude-local.env`：实际生效配置（默认读取）
- `claude-local.env.example`：模板文件
- `claude-local - API.env`：云 API 示例配置

切换到云 API 示例可用：
```powershell
Copy-Item ".\claude-local - API.env" ".\claude-local.env" -Force
```

## 配置示例

### 1）本地模型（LM Studio 示例）
```env
CLAUDE_LOCAL_PROVIDER=lmstudio
ANTHROPIC_AUTH_TOKEN=lmstudio
ANTHROPIC_BASE_URL=http://127.0.0.1:1234
ANTHROPIC_MODEL=qwen3.5-9b
ANTHROPIC_SMALL_FAST_MODEL=qwen3.5-9b
CLAUDE_LOCAL_RUNTIME_DIR=.claude-local-runtime
```

### 2）云 API（SiliconFlow 示例）
```env
CLAUDE_LOCAL_PROVIDER=siliconflow
ANTHROPIC_AUTH_TOKEN=your_api_key
ANTHROPIC_BASE_URL=https://api.siliconflow.cn/
ANTHROPIC_MODEL=moonshotai/Kimi-K2-Instruct-0905
ANTHROPIC_SMALL_FAST_MODEL=moonshotai/Kimi-K2-Instruct-0905
CLAUDE_LOCAL_RUNTIME_DIR=.claude-local-runtime
```

注意：
- `claude-local.ps1` / `claude-local` 默认都读取 `claude-local.env`。
- 不要把真实 API Key 提交到仓库。
- LM Studio 场景建议提高上下文窗口（如 25k+），减少上下文不足报错。

## 常用启动命令
```powershell
# 查看版本
node .\package\cli.js --version

# 进入 REPL
.\claude-local --bare

# 单次调用
.\claude-local -p "只回复：hello" --bare --output-format text
```

macOS/Linux 可用：
```bash
./claude-local --version
./claude-local --bare
```

## CODEX 插件说明
- 本发布目录默认包含可用的 Codex 插件运行时数据（位于 `.claude-local-runtime/home/plugins/`）。
- `claude-local.ps1` 启动时会自动补齐/修复 Codex 插件状态（`known_marketplaces.json`、`installed_plugins.json`、`settings.json` 的 `enabledPlugins`）。
- 若你重新初始化了 runtime 或插件命令未出现，可手动执行下面流程：

```text
/plugin marketplace add openai/codex-plugin-cc
/plugin install codex@openai-codex
/reload-plugins
/codex:setup
```

常用命令：
```text
/codex:review
/codex:adversarial-review
/codex:rescue
/codex:status
/codex:result
/codex:cancel
```

## 项目结构
```text
JackProAi-claudecode3.0
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

## 备注
- 运行态数据默认写入 `.claude-local-runtime/`。
- 脚本默认启用 `CLAUDE_CODE_NO_FLICKER=1`，用于减少终端重绘闪烁问题。
- 如终端出现乱码或异常，优先使用 `start-claude-local.bat` 或 `start-claude-local.ps1` 启动。
- 如需远程安装或定制功能，可加博主微信：`JACKPROAI`（注明来意，有偿）。
