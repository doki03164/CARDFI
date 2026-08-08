param(
  [switch]$Apply,
  [string]$WorkspaceRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
)
$ErrorActionPreference = 'Stop'
$zip = Join-Path $PSScriptRoot 'original-stake-pool.zip'
$manifest = Join-Path $PSScriptRoot 'original.sha256'
$expected = ((Get-Content -LiteralPath $manifest -Raw).Trim() -split '\s+')[0]
$actual = (Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash.ToLowerInvariant()
if ($actual -ne $expected) { throw "Original archive hash mismatch: $actual" }
$target = [System.IO.Path]::GetFullPath((Join-Path $WorkspaceRoot 'infra\stake-pool'))
$root = [System.IO.Path]::GetFullPath($WorkspaceRoot)
if (-not $target.StartsWith($root, [System.StringComparison]::OrdinalIgnoreCase)) { throw 'Rollback target escaped workspace' }
if (-not $Apply) { Write-Output "ROLLBACK_VERIFIED archive=$actual target=$target apply=false"; exit 0 }
$backup = "$target.before-rollback-$(Get-Date -Format yyyyMMddHHmmss)"
Move-Item -LiteralPath $target -Destination $backup
New-Item -ItemType Directory -Path $target | Out-Null
Expand-Archive -LiteralPath $zip -DestinationPath $target
Write-Output "ROLLBACK_APPLIED restored=$target previous=$backup archive=$actual"
