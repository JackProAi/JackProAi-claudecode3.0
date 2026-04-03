param()

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location -LiteralPath $scriptDir

$configHome = $env:CLAUDE_CONFIG_DIR
if ([string]::IsNullOrWhiteSpace($configHome)) {
  $configHome = Join-Path $scriptDir ".claude-local-runtime\home"
  $env:CLAUDE_CONFIG_DIR = $configHome
}

$historyPath = Join-Path $configHome "history.jsonl"
$projectsRoot = Join-Path $configHome "projects"
$currentProject = (Get-Location).Path
$resumeSessionId = $null

function Test-SessionTranscriptExists {
  param(
    [Parameter(Mandatory = $true)][string]$SessionId,
    [Parameter(Mandatory = $true)][string]$ProjectsDir
  )

  if ([string]::IsNullOrWhiteSpace($SessionId)) {
    return $false
  }
  if (-not (Test-Path -LiteralPath $ProjectsDir)) {
    return $false
  }

  $match = Get-ChildItem -Path $ProjectsDir -Recurse -File -Filter "$SessionId.jsonl" -ErrorAction SilentlyContinue |
    Select-Object -First 1
  return $null -ne $match
}

if (Test-Path -LiteralPath $historyPath) {
  $entries = @()
  Get-Content -Path $historyPath | ForEach-Object {
    if ([string]::IsNullOrWhiteSpace($_)) { return }
    try {
      $entries += ($_ | ConvertFrom-Json)
    } catch {
      # Ignore malformed lines.
    }
  }

  $projectEntries = $entries |
    Where-Object {
      $_.sessionId -and $_.timestamp -and $_.project -and
      $_.project.ToLowerInvariant() -eq $currentProject.ToLowerInvariant()
    } |
    Sort-Object timestamp -Descending

  $latestEntry = $projectEntries | Select-Object -First 1
  if ($latestEntry) {
    $lastDisplay = [string]$latestEntry.display
    $lastDisplayLower = $lastDisplay.ToLowerInvariant()
    $clearIntent =
      $lastDisplayLower -eq "/clear" -or
      $lastDisplayLower -eq "clear" -or
      $lastDisplay.Contains("清空聊天记录")

    if (-not $clearIntent) {
      foreach ($candidate in $projectEntries) {
        $candidateSessionId = [string]$candidate.sessionId
        if (Test-SessionTranscriptExists -SessionId $candidateSessionId -ProjectsDir $projectsRoot) {
          $resumeSessionId = $candidateSessionId
          break
        }
      }

      if (-not $resumeSessionId) {
        Write-Host "Found previous session IDs, but transcripts are missing locally. Starting a new session."
      }
    } else {
      Write-Host "Last action was clear. Starting a new session instead of resuming."
    }
  }
}

$langPrompt = "Always reply in Simplified Chinese unless I explicitly ask for another language."
$args = @("--thinking", "disabled", "--append-system-prompt", $langPrompt)

Write-Host "Project: $currentProject"
if ($resumeSessionId) {
  Write-Host "Resuming session: $resumeSessionId"
  $args += @("--resume", $resumeSessionId)
} else {
  Write-Host "No previous session found for this project. Starting a new session."
}

& (Join-Path $scriptDir "claude-local.ps1") -CliArgs $args
$exitCode = $LASTEXITCODE

if ($exitCode -ne 0 -and $resumeSessionId) {
  Write-Host ""
  Write-Host "Resume failed. Starting a new session..."
  & (Join-Path $scriptDir "claude-local.ps1") -CliArgs @("--thinking", "disabled", "--append-system-prompt", $langPrompt)
  $exitCode = $LASTEXITCODE
}

if ($exitCode -ne 0) {
  Write-Host ""
  Write-Host "Claude Local failed to start. Exit code: $exitCode"
}

exit $exitCode
