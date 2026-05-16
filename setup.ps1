<#
obsidian-wiki setup for Windows.

Usage:
  powershell -ExecutionPolicy Bypass -File .\setup.ps1
  powershell -ExecutionPolicy Bypass -File .\setup.ps1 -VaultPath "C:\path\to\vault"

What it does:
  1. Creates .env from .env.example when needed
  2. Writes %USERPROFILE%\.obsidian-wiki\config so skills work from any project
  3. Links or copies .skills\* into each supported agent skills directory
  4. Bootstraps AGENTS.md aliases
#>

[CmdletBinding()]
param(
  [string]$VaultPath = "C:\Users\84981\iCloudDrive\iCloud~md~obsidian\tannin-obsidian-wiki"
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$SkillsDir = Join-Path $ScriptDir ".skills"

function Write-Status {
  param([string]$Message)
  Write-Host "[obsidian-wiki] $Message"
}

function Get-RelativeDisplayPath {
  param([string]$Path)
  if ($Path.StartsWith($ScriptDir, [System.StringComparison]::OrdinalIgnoreCase)) {
    return $Path.Substring($ScriptDir.Length).TrimStart("\")
  }
  return $Path
}

function Remove-LinkLikeItem {
  param([string]$Path)

  if (-not (Test-Path -LiteralPath $Path)) {
    return $true
  }

  $item = Get-Item -LiteralPath $Path -Force
  $isReparsePoint = (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0)

  if ($isReparsePoint) {
    if ($item.PSIsContainer) {
      [System.IO.Directory]::Delete($item.FullName)
    }
    else {
      [System.IO.File]::Delete($item.FullName)
    }
    return $true
  }

  return $false
}

function New-DirectoryLinkOrCopy {
  param(
    [string]$Source,
    [string]$Target
  )

  if (-not (Remove-LinkLikeItem -Path $Target)) {
    Write-Host "  ! $Target is a real directory or file, skipping"
    return
  }

  $parent = Split-Path -Parent $Target
  New-Item -ItemType Directory -Path $parent -Force | Out-Null

  try {
    New-Item -ItemType Junction -Path $Target -Target $Source -Force | Out-Null
  }
  catch {
    try {
      New-Item -ItemType SymbolicLink -Path $Target -Target $Source -Force | Out-Null
    }
    catch {
      Copy-Item -Path $Source -Destination $Target -Recurse -Force
      Write-Host "  ! Linked copy fallback used for $Target"
    }
  }
}

function New-FileLinkOrCopy {
  param(
    [string]$Source,
    [string]$Target,
    [switch]$ReplaceRegularFile
  )

  if (-not (Remove-LinkLikeItem -Path $Target)) {
    if ($ReplaceRegularFile) {
      Remove-Item -LiteralPath $Target -Force
    }
    else {
      Write-Host "  ! $Target is a real file, leaving it in place"
      return
    }
  }

  $parent = Split-Path -Parent $Target
  New-Item -ItemType Directory -Path $parent -Force | Out-Null

  try {
    New-Item -ItemType SymbolicLink -Path $Target -Target $Source -Force | Out-Null
  }
  catch {
    Copy-Item -Path $Source -Destination $Target -Force
    Write-Host "  ! File copy fallback used for $Target"
  }
}

function Install-Skills {
  param(
    [string]$TargetDir,
    [string]$Label,
    [string[]]$SkillNames = @()
  )

  New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null

  if ($SkillNames.Count -eq 0) {
    $skills = Get-ChildItem -LiteralPath $SkillsDir -Directory
  }
  else {
    $skills = foreach ($skillName in $SkillNames) {
      Get-Item -LiteralPath (Join-Path $SkillsDir $skillName)
    }
  }

  foreach ($skill in $skills) {
    $target = Join-Path $TargetDir $skill.Name
    New-DirectoryLinkOrCopy -Source $skill.FullName -Target $target
  }

  Write-Status "Installed skills -> $Label"
}

Write-Host ""
Write-Host "obsidian-wiki - Windows setup"
Write-Host ""

if (-not (Test-Path -LiteralPath $SkillsDir)) {
  throw "Cannot find .skills at $SkillsDir"
}

$envPath = Join-Path $ScriptDir ".env"
$envExamplePath = Join-Path $ScriptDir ".env.example"

if (-not (Test-Path -LiteralPath $envPath)) {
  Copy-Item -Path $envExamplePath -Destination $envPath
  Write-Status "Created .env from .env.example"
}
else {
  Write-Status ".env already exists"
}

$envContent = Get-Content -LiteralPath $envPath
$quotedVaultPath = '"' + $VaultPath.Replace('"', '\"') + '"'
$updatedEnv = $false
$envContent = $envContent | ForEach-Object {
  if ($_ -match '^OBSIDIAN_VAULT_PATH=') {
    $updatedEnv = $true
    "OBSIDIAN_VAULT_PATH=$quotedVaultPath"
  }
  else {
    $_
  }
}
if (-not $updatedEnv) {
  $envContent += "OBSIDIAN_VAULT_PATH=$quotedVaultPath"
}
Set-Content -LiteralPath $envPath -Value $envContent -Encoding UTF8
Write-Status "Set .env OBSIDIAN_VAULT_PATH=$VaultPath"

$globalConfigDir = Join-Path $HOME ".obsidian-wiki"
$globalConfigPath = Join-Path $globalConfigDir "config"
New-Item -ItemType Directory -Path $globalConfigDir -Force | Out-Null
@(
  "OBSIDIAN_VAULT_PATH=$quotedVaultPath"
  'OBSIDIAN_WIKI_REPO="' + $ScriptDir.Replace('"', '\"') + '"'
) | Set-Content -LiteralPath $globalConfigPath -Encoding UTF8
Write-Status "Global config written to $globalConfigPath"

if (-not (Test-Path -LiteralPath $VaultPath)) {
  New-Item -ItemType Directory -Path $VaultPath -Force | Out-Null
  Write-Status "Created vault directory $VaultPath"
}

$hermesBootstrap = Join-Path $ScriptDir ".hermes.md"
if (
  (Test-Path -LiteralPath $hermesBootstrap) -and
  -not (((Get-Item -LiteralPath $hermesBootstrap -Force).Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) -and
  ((Get-Content -LiteralPath $hermesBootstrap -Raw).Trim() -eq "AGENTS.md")
) {
  Write-Status ".hermes.md already points to AGENTS.md"
}
else {
  New-FileLinkOrCopy -Source (Join-Path $ScriptDir "AGENTS.md") -Target $hermesBootstrap -ReplaceRegularFile
  Write-Status ".hermes.md -> AGENTS.md"
}

$projectAgentDirs = @(
  ".claude\skills",
  ".cursor\skills",
  ".windsurf\skills",
  ".agents\skills",
  ".kiro\skills"
)
foreach ($agentDir in $projectAgentDirs) {
  Install-Skills -TargetDir (Join-Path $ScriptDir $agentDir) -Label "$agentDir\"
}

Install-Skills -TargetDir (Join-Path $HOME ".claude\skills") -Label "$HOME\.claude\skills\ (wiki-update, wiki-query)" -SkillNames @("wiki-update", "wiki-query")

$globalAgentDirs = @(
  ".gemini\skills",
  ".gemini\antigravity\skills",
  ".codex\skills",
  ".hermes\skills",
  ".openclaw\skills",
  ".copilot\skills",
  ".trae\skills",
  ".trae-cn\skills",
  ".kiro\skills",
  ".agents\skills"
)
foreach ($agentDir in $globalAgentDirs) {
  Install-Skills -TargetDir (Join-Path $HOME $agentDir) -Label "$HOME\$agentDir\"
}

$skillCount = (Get-ChildItem -LiteralPath $SkillsDir -Directory).Count

Write-Host ""
Write-Host "Setup complete."
Write-Host "Skills found: $skillCount"
Write-Host "Vault path:   $VaultPath"
Write-Host "Config file:  $globalConfigPath"
Write-Host ""
Write-Host "From any project:"
Write-Host "  /wiki-update"
Write-Host "  /wiki-query"
Write-Host ""
