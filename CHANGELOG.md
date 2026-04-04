# Changelog / 更新日志

All notable changes to this project will be documented in this file.
本文件记录本项目的重要变更。

## 2026-04-04

### Changed / 变更
- Updated project naming in documentation from `JackProAi-claudecode3.0` to `JackProAi-claudecode3.1`.
- 文档中的项目命名已从 `JackProAi-claudecode3.0` 更新为 `JackProAi-claudecode3.1`。
- Performed wording cleanup to avoid "official release" misunderstanding and added explicit non-affiliation language.
- 新增并统一了“非官方/无隶属关系”的措辞，降低“官方版本”误解风险。
- Added compliance file `COMPLIANCE.md` and linked it from both README files.
- 新增 `COMPLIANCE.md` 合规说明文件，并在中英文 README 中加入入口链接。

### Fixed / 修复
- Fixed garbled Chinese text when copying from the alt-screen (black box) area on Windows.
- Switched clipboard write path to PowerShell `Set-Clipboard` with explicit UTF-8 base64 decode.
- Kept `clip` as a fallback when PowerShell clipboard write fails.
- Fixed startup crash caused by a syntax issue in `package/cli.js` during this patch cycle.
- 修复了 Windows 下从全屏黑框区域复制中文后粘贴乱码的问题。
- 复制写入剪贴板改为 PowerShell `Set-Clipboard`，并显式使用 UTF-8 base64 解码。
- 当 PowerShell 失败时保留 `clip` 作为回退方案。
- 修复了本次补丁过程中 `package/cli.js` 语法问题导致的启动报错。

### Changed (Implementation Files) / 变更（实现文件）
- Updated runtime file `package/cli.js`.
- Updated restored source file `restored-src/src/ink/termio/osc.ts`.
- 更新了运行时文件 `package/cli.js`。
- 更新了还原源码文件 `restored-src/src/ink/termio/osc.ts`。
