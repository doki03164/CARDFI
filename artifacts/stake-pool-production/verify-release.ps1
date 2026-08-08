$ErrorActionPreference = 'Stop'
$manifestPath = Join-Path $PSScriptRoot 'release-manifest.sha256'
foreach ($line in Get-Content -LiteralPath $manifestPath) {
  if ([string]::IsNullOrWhiteSpace($line)) { continue }
  $parts = $line -split '\s+', 2
  $expected = $parts[0].ToLowerInvariant()
  $path = Join-Path $PSScriptRoot $parts[1]
  $actual = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()
  if ($actual -ne $expected) { throw "Hash mismatch for $($parts[1]): $actual" }
  Write-Output "ARTIFACT_OK file=$($parts[1]) sha256=$actual"
}
& (Join-Path $PSScriptRoot 'rollback.ps1')
