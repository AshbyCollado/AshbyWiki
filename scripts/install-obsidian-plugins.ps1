[CmdletBinding()]
param(
  [string]$VaultPath,
  [switch]$Check
)

$ErrorActionPreference = "Stop"
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
if ([string]::IsNullOrWhiteSpace($VaultPath)) { $VaultPath = Join-Path $scriptRoot "..\content" }
$lockPath = Join-Path $scriptRoot "obsidian-plugins.lock.json"
$lock = Get-Content -LiteralPath $lockPath -Raw | ConvertFrom-Json
$vault = [IO.Path]::GetFullPath($VaultPath)
$pluginRoot = Join-Path $vault ".obsidian\plugins"

function Require-Command([string]$Name) {
  if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
    throw "Required command '$Name' was not found. Install it and retry."
  }
}

if (-not (Test-Path -LiteralPath $vault -PathType Container)) { throw "Vault directory does not exist: $vault" }
if ($Check) {
  Write-Host "Plugin lock manifest is valid for vault: $vault"
  foreach ($p in $lock.plugins) { Write-Host ("- {0} {1} ({2})" -f $p.id, $p.version, $p.repository) }
  exit 0
}

$run = Join-Path ([IO.Path]::GetTempPath()) ("ashby-plugins-" + [guid]::NewGuid().ToString("N"))
$stage = Join-Path $run "stage"
$backup = Join-Path $run "backup"
New-Item -ItemType Directory -Path $stage,$backup,$pluginRoot -Force | Out-Null
$moved = @()
$community = Join-Path $vault ".obsidian\community-plugins.json"
$communityStage = Join-Path $run "community-plugins.json"

function Download([string]$Uri, [string]$Destination) {
  Invoke-WebRequest -Uri $Uri -OutFile $Destination -UseBasicParsing
}

function Assert-Hash([string]$Path, $Expected, [string]$Label) {
  if ([string]::IsNullOrWhiteSpace([string]$Expected)) { return }
  $actual = (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash.ToLowerInvariant()
  if ($actual -ne ([string]$Expected).ToLowerInvariant()) { throw "SHA-256 mismatch for $Label (expected $Expected, got $actual)" }
}

try {
  foreach ($p in $lock.plugins) {
    $pluginStage = Join-Path $stage $p.id
    New-Item -ItemType Directory -Path $pluginStage -Force | Out-Null
    foreach ($asset in $p.assets) {
      $target = Join-Path $run ($p.id + "-" + $asset.name)
      Download $asset.url $target
      Assert-Hash $target $asset.sha256 ("$($p.id)/$($asset.name)")
      Copy-Item -LiteralPath $target -Destination (Join-Path $pluginStage $asset.name)
    }
    $manifestPath = Join-Path $pluginStage "manifest.json"
    if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) { throw "Release for $($p.id) did not contain manifest.json." }
    $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
    if ($manifest.id -ne $p.id -or $manifest.version -ne $p.version) {
      throw "Manifest mismatch for $($p.id): got id '$($manifest.id)' version '$($manifest.version)'."
    }
    foreach ($required in @("main.js", "manifest.json", "styles.css")) {
      if (-not (Test-Path -LiteralPath (Join-Path $pluginStage $required) -PathType Leaf)) { throw "Release for $($p.id) is missing $required." }
    }
  }

  $existing = @()
  if (Test-Path -LiteralPath $community -PathType Leaf) {
    $existing = @(Get-Content -LiteralPath $community -Raw | ConvertFrom-Json)
  }
  $ids = [Collections.Generic.List[string]]::new()
  foreach ($id in $existing) { if ($id -is [string] -and -not $ids.Contains($id)) { $ids.Add($id) } }
  foreach ($p in $lock.plugins) { if (-not $ids.Contains($p.id)) { $ids.Add($p.id) } }
  $ids | ConvertTo-Json | Set-Content -LiteralPath $communityStage -Encoding UTF8

  foreach ($p in $lock.plugins) {
    $destination = Join-Path $pluginRoot $p.id
    if (Test-Path -LiteralPath $destination) { $b = Join-Path $backup $p.id; Move-Item -LiteralPath $destination -Destination $b; $moved += $p.id }
    Move-Item -LiteralPath (Join-Path $stage $p.id) -Destination $destination
  }
  if (Test-Path -LiteralPath $community) { Move-Item -LiteralPath $community -Destination (Join-Path $backup "community-plugins.json") }
  Move-Item -LiteralPath $communityStage -Destination $community
  Write-Host "Installed and verified $($lock.plugins.Count) pinned Obsidian plugins in $pluginRoot"
} catch {
  foreach ($p in $lock.plugins) {
    $destination = Join-Path $pluginRoot $p.id
    if (Test-Path -LiteralPath $destination) { Remove-Item -LiteralPath $destination -Recurse -Force }
    $b = Join-Path $backup $p.id
    if (Test-Path -LiteralPath $b) { Move-Item -LiteralPath $b -Destination $destination }
  }
  $oldCommunity = Join-Path $backup "community-plugins.json"
  if (Test-Path -LiteralPath $oldCommunity) {
    if (Test-Path -LiteralPath $community) { Remove-Item -LiteralPath $community -Force }
    Move-Item -LiteralPath $oldCommunity -Destination $community
  }
  throw
} finally {
  if (Test-Path -LiteralPath $run) { Remove-Item -LiteralPath $run -Recurse -Force -ErrorAction SilentlyContinue }
}
