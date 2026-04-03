param(
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$CliArgs
)

$ErrorActionPreference = "Stop"

$RootDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$DefaultRuntimeDir = if ($env:CLAUDE_LOCAL_RUNTIME_DIR) { $env:CLAUDE_LOCAL_RUNTIME_DIR } else { Join-Path $RootDir ".claude-local-runtime" }
$RuntimeDir = $DefaultRuntimeDir
$RootEnvFile = if ($env:CLAUDE_LOCAL_ENV_FILE) { $env:CLAUDE_LOCAL_ENV_FILE } else { Join-Path $RootDir "claude-local.env" }
$RuntimeEnvFile = Join-Path $DefaultRuntimeDir "env"
$LegacyEnvFile = Join-Path $RootDir ".ccsmap-runtime\\env"
$SelectedEnvFile = $null

function Write-DefaultEnv {
  $content = @"
# Claude Local API configuration
#
# File to edit:
#   claude-local.env
#
# Kimi example:
CLAUDE_LOCAL_PROVIDER=kimi
ANTHROPIC_AUTH_TOKEN=paste_your_api_key_here
#
# Optional advanced overrides:
ANTHROPIC_BASE_URL=
ANTHROPIC_MODEL=
ANTHROPIC_SMALL_FAST_MODEL=
"@
  Write-TextNoBom -Path $RootEnvFile -Content $content
}

function Import-EnvFile {
  param([Parameter(Mandatory = $true)][string]$Path)

  Get-Content -Path $Path | ForEach-Object {
    $line = $_.Trim()
    if ([string]::IsNullOrWhiteSpace($line)) { return }
    if ($line.StartsWith("#")) { return }

    if ($line -match "^([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)$") {
      $name = $matches[1]
      $value = $matches[2].Trim()
      if (
        ($value.StartsWith('"') -and $value.EndsWith('"')) -or
        ($value.StartsWith("'") -and $value.EndsWith("'"))
      ) {
        $value = $value.Substring(1, $value.Length - 2)
      }
      $value = [Environment]::ExpandEnvironmentVariables($value)
      [Environment]::SetEnvironmentVariable($name, $value, "Process")
    }
  }
}

function Resolve-RuntimeDir {
  param([Parameter(Mandatory = $true)][string]$PathValue)

  $expanded = [Environment]::ExpandEnvironmentVariables($PathValue)
  if ([System.IO.Path]::IsPathRooted($expanded)) {
    return $expanded
  }
  return Join-Path $RootDir $expanded
}

function Read-JsonHashtable {
  param([Parameter(Mandatory = $true)][string]$Path)

  if (-not (Test-Path -LiteralPath $Path)) {
    return @{}
  }

  try {
    return (Get-Content -Raw -Path $Path | ConvertFrom-Json -AsHashtable)
  } catch {
    return @{}
  }
}

function Write-TextNoBom {
  param(
    [Parameter(Mandatory = $true)][string]$Path,
    [Parameter(Mandatory = $true)][string]$Content
  )

  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($Path, $Content, $utf8NoBom)
}

function Write-JsonNoBom {
  param(
    [Parameter(Mandatory = $true)][string]$Path,
    [Parameter(Mandatory = $true)]$Object,
    [int]$Depth = 8
  )

  Write-TextNoBom -Path $Path -Content ($Object | ConvertTo-Json -Depth $Depth)
}

function Ensure-CodexRuntimeState {
  param(
    [Parameter(Mandatory = $true)][string]$RuntimePath,
    [Parameter(Mandatory = $true)][string]$SeedRuntimePath
  )

  $runtimePlugins = Join-Path $RuntimePath "home\\plugins"
  $seedPlugins = Join-Path $SeedRuntimePath "home\\plugins"
  $runtimeHome = Join-Path $RuntimePath "home"
  $seedHome = Join-Path $SeedRuntimePath "home"

  if ($RuntimePath -ne $SeedRuntimePath -and (Test-Path -LiteralPath $seedPlugins)) {
    $seedMarketplace = Join-Path $seedPlugins "marketplaces\\openai-codex"
    $seedCache = Join-Path $seedPlugins "cache\\openai-codex"
    $seedKnown = Join-Path $seedPlugins "known_marketplaces.json"
    $runtimeMarketplace = Join-Path $runtimePlugins "marketplaces\\openai-codex"
    $runtimeCache = Join-Path $runtimePlugins "cache\\openai-codex"
    $runtimeKnown = Join-Path $runtimePlugins "known_marketplaces.json"

    if ((Test-Path -LiteralPath $seedMarketplace) -and -not (Test-Path -LiteralPath $runtimeMarketplace)) {
      New-Item -ItemType Directory -Force -Path (Join-Path $runtimePlugins "marketplaces") | Out-Null
      Copy-Item -Recurse -Force -Path $seedMarketplace -Destination $runtimeMarketplace
    }

    if ((Test-Path -LiteralPath $seedCache) -and -not (Test-Path -LiteralPath $runtimeCache)) {
      New-Item -ItemType Directory -Force -Path (Join-Path $runtimePlugins "cache") | Out-Null
      Copy-Item -Recurse -Force -Path $seedCache -Destination $runtimeCache
    }

    if ((Test-Path -LiteralPath $seedKnown) -and -not (Test-Path -LiteralPath $runtimeKnown)) {
      Copy-Item -Force -Path $seedKnown -Destination $runtimeKnown
    }

    $seedSettings = Join-Path $seedHome "settings.json"
    $runtimeSettings = Join-Path $runtimeHome "settings.json"
    if ((Test-Path -LiteralPath $seedSettings) -and -not (Test-Path -LiteralPath $runtimeSettings)) {
      Copy-Item -Force -Path $seedSettings -Destination $runtimeSettings
    }
  }

  $pluginVersion = $null
  $pluginVersionRoot = Join-Path $runtimePlugins "cache\\openai-codex\\codex"
  if (Test-Path -LiteralPath $pluginVersionRoot) {
    $pluginVersion = (Get-ChildItem -LiteralPath $pluginVersionRoot -Directory -ErrorAction SilentlyContinue |
      Sort-Object LastWriteTime -Descending |
      Select-Object -First 1 -ExpandProperty Name)
  }

  if ([string]::IsNullOrWhiteSpace($pluginVersion)) {
    return
  }

  $knownPath = Join-Path $runtimePlugins "known_marketplaces.json"
  $known = Read-JsonHashtable -Path $knownPath
  if (-not $known.ContainsKey("openai-codex")) {
    $known["openai-codex"] = @{
      source = @{
        source = "github"
        repo = "openai/codex-plugin-cc"
      }
      installLocation = (Join-Path $runtimePlugins "marketplaces\\openai-codex")
      lastUpdated = (Get-Date).ToUniversalTime().ToString("o")
    }
    Write-JsonNoBom -Path $knownPath -Object $known -Depth 8
  }

  $installedPath = Join-Path $runtimePlugins "installed_plugins.json"
  $installed = Read-JsonHashtable -Path $installedPath
  if (-not $installed.ContainsKey("version")) {
    $installed["version"] = 2
  }
  if (-not $installed.ContainsKey("plugins")) {
    $installed["plugins"] = @{}
  }

  $pluginId = "codex@openai-codex"
  $installPath = Join-Path $runtimePlugins ("cache\\openai-codex\\codex\\" + $pluginVersion)
  $now = (Get-Date).ToUniversalTime().ToString("o")
  $existingInstalledAt = $now
  if ($installed["plugins"].ContainsKey($pluginId) -and $installed["plugins"][$pluginId].Count -gt 0) {
    $existingInstalledAt = $installed["plugins"][$pluginId][0]["installedAt"]
    if ([string]::IsNullOrWhiteSpace($existingInstalledAt)) {
      $existingInstalledAt = $now
    }
  }
  $installed["plugins"][$pluginId] = @(
    @{
      scope = "user"
      installPath = $installPath
      version = $pluginVersion
      installedAt = $existingInstalledAt
      lastUpdated = $now
    }
  )
  Write-JsonNoBom -Path $installedPath -Object $installed -Depth 8

  $settingsPath = Join-Path $runtimeHome "settings.json"
  $settings = Read-JsonHashtable -Path $settingsPath
  if (-not $settings.ContainsKey("enabledPlugins")) {
    $settings["enabledPlugins"] = @{}
  }
  $settings["enabledPlugins"][$pluginId] = $true
  if (-not $settings.ContainsKey("extraKnownMarketplaces")) {
    $settings["extraKnownMarketplaces"] = @{}
  }
  $settings["extraKnownMarketplaces"]["openai-codex"] = @{
    source = @{
      source = "github"
      repo = "openai/codex-plugin-cc"
    }
  }
  Write-JsonNoBom -Path $settingsPath -Object $settings -Depth 8
}

if ($CliArgs.Count -gt 0 -and $CliArgs[0] -eq "--init-env") {
  if (Test-Path -LiteralPath $RootEnvFile) {
    Write-Output "Already exists: $RootEnvFile"
  } else {
    Write-DefaultEnv
    Write-Output "Created: $RootEnvFile"
    Write-Output "Open this file and replace ANTHROPIC_AUTH_TOKEN with your real API key."
  }
  exit 0
}

if (Test-Path -LiteralPath $RootEnvFile) {
  $SelectedEnvFile = $RootEnvFile
  Import-EnvFile -Path $RootEnvFile
} elseif (Test-Path -LiteralPath $RuntimeEnvFile) {
  $SelectedEnvFile = $RuntimeEnvFile
  Import-EnvFile -Path $RuntimeEnvFile
} elseif (Test-Path -LiteralPath $LegacyEnvFile) {
  $SelectedEnvFile = $LegacyEnvFile
  Import-EnvFile -Path $LegacyEnvFile
}

if (-not $SelectedEnvFile) {
  Write-DefaultEnv
  Write-Error @"
Created API config file:
  $RootEnvFile

Open this file and replace:
  ANTHROPIC_AUTH_TOKEN=paste_your_api_key_here

Then run:
  .\claude-local.ps1 --bare
"@
  exit 1
}

$RuntimeDir = if ([string]::IsNullOrWhiteSpace($env:CLAUDE_LOCAL_RUNTIME_DIR)) {
  Join-Path $RootDir ".claude-local-runtime"
} else {
  Resolve-RuntimeDir -PathValue $env:CLAUDE_LOCAL_RUNTIME_DIR
}

@("home", "xdg-config", "xdg-data", "xdg-state", "tmp") | ForEach-Object {
  New-Item -ItemType Directory -Force -Path (Join-Path $RuntimeDir $_) | Out-Null
}

[Environment]::SetEnvironmentVariable("HOME", (Join-Path $RuntimeDir "home"), "Process")
[Environment]::SetEnvironmentVariable("XDG_CONFIG_HOME", (Join-Path $RuntimeDir "xdg-config"), "Process")
[Environment]::SetEnvironmentVariable("XDG_DATA_HOME", (Join-Path $RuntimeDir "xdg-data"), "Process")
[Environment]::SetEnvironmentVariable("XDG_STATE_HOME", (Join-Path $RuntimeDir "xdg-state"), "Process")
[Environment]::SetEnvironmentVariable("TMPDIR", (Join-Path $RuntimeDir "tmp"), "Process")
[Environment]::SetEnvironmentVariable("CLAUDE_CONFIG_DIR", (Join-Path $RuntimeDir "home"), "Process")
[Environment]::SetEnvironmentVariable("CLAUDE_CODE_PLUGIN_CACHE_DIR", (Join-Path $RuntimeDir "home\\plugins"), "Process")
if ([string]::IsNullOrWhiteSpace($env:CLAUDE_CODE_USE_COWORK_PLUGINS)) {
  [Environment]::SetEnvironmentVariable("CLAUDE_CODE_USE_COWORK_PLUGINS", "0", "Process")
}
# Enable fullscreen/alt-screen rendering by default to avoid duplicated redraw
# blocks in scrollback during window resize on some terminals.
if ([string]::IsNullOrWhiteSpace($env:CLAUDE_CODE_NO_FLICKER)) {
  [Environment]::SetEnvironmentVariable("CLAUDE_CODE_NO_FLICKER", "1", "Process")
}

Ensure-CodexRuntimeState -RuntimePath $RuntimeDir -SeedRuntimePath (Join-Path $RootDir ".claude-local-runtime")

if ([string]::IsNullOrWhiteSpace($env:ANTHROPIC_AUTH_TOKEN) -and -not [string]::IsNullOrWhiteSpace($env:ANTHROPIC_API_KEY)) {
  [Environment]::SetEnvironmentVariable("ANTHROPIC_AUTH_TOKEN", $env:ANTHROPIC_API_KEY, "Process")
}

switch -Regex ($env:CLAUDE_LOCAL_PROVIDER) {
  "^(kimi|moonshot)$" {
    if ([string]::IsNullOrWhiteSpace($env:ANTHROPIC_BASE_URL)) {
      [Environment]::SetEnvironmentVariable("ANTHROPIC_BASE_URL", "https://api.moonshot.cn/anthropic", "Process")
    }
    if ([string]::IsNullOrWhiteSpace($env:ANTHROPIC_MODEL)) {
      [Environment]::SetEnvironmentVariable("ANTHROPIC_MODEL", "kimi-k2-0905-preview", "Process")
    }
    if ([string]::IsNullOrWhiteSpace($env:ANTHROPIC_SMALL_FAST_MODEL)) {
      [Environment]::SetEnvironmentVariable("ANTHROPIC_SMALL_FAST_MODEL", "kimi-k2-turbo-preview", "Process")
    }
  }
}

if ([string]::IsNullOrWhiteSpace($env:ANTHROPIC_AUTH_TOKEN)) {
  Write-Error @"
Missing ANTHROPIC_AUTH_TOKEN in $SelectedEnvFile

Example:
  CLAUDE_LOCAL_PROVIDER=kimi
  ANTHROPIC_AUTH_TOKEN=your_token_here
"@
  exit 1
}

if ($env:ANTHROPIC_AUTH_TOKEN -eq "paste_your_api_key_here") {
  Write-Error @"
Edit this file first:
  $SelectedEnvFile

Replace:
  ANTHROPIC_AUTH_TOKEN=paste_your_api_key_here

With your real API key, then run .\claude-local.ps1 --bare again.
"@
  exit 1
}

$NodePath = $null
try {
  $NodePath = (Get-Command node -ErrorAction Stop).Source
} catch {
  $KnownNodePath = "C:\Program Files\nodejs\node.exe"
  if (Test-Path -LiteralPath $KnownNodePath) {
    $NodePath = $KnownNodePath
  }
}

if (-not $NodePath) {
  Write-Error "Node.js is required (v18+). Install Node.js and run again."
  exit 1
}

$EffectiveCliArgs = @($CliArgs)
$hasThinkingFlag = $false
foreach ($arg in $EffectiveCliArgs) {
  if ($arg -eq "--thinking" -or $arg.StartsWith("--thinking=")) {
    $hasThinkingFlag = $true
    break
  }
}

$provider = if ($env:CLAUDE_LOCAL_PROVIDER) { $env:CLAUDE_LOCAL_PROVIDER.ToLowerInvariant() } else { "" }
$baseUrl = if ($env:ANTHROPIC_BASE_URL) { $env:ANTHROPIC_BASE_URL.ToLowerInvariant() } else { "" }
$useSiliconFlow = ($provider -eq "siliconflow") -or $baseUrl.Contains("siliconflow.cn")

if ($useSiliconFlow -and -not $hasThinkingFlag) {
  $EffectiveCliArgs += @("--thinking", "disabled")
}

& $NodePath (Join-Path $RootDir "package\\cli.js") @EffectiveCliArgs
exit $LASTEXITCODE
