$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$required = @(
  'pool.env.example',
  'metadata/poolMetaData.json',
  'topology/block-producer-topology.json',
  'topology/relay-topology.json',
  'systemd/cardano-node-block-producer.service',
  'systemd/cardano-node-relay.service',
  'scripts/register-pool.sh'
)

foreach ($relative in $required) {
  $path = Join-Path $root $relative
  if (-not (Test-Path -LiteralPath $path)) { throw "Missing template: $relative" }
}

Get-Content (Join-Path $root 'metadata/poolMetaData.json') -Raw | ConvertFrom-Json | Out-Null
Get-Content (Join-Path $root 'topology/block-producer-topology.json') -Raw | ConvertFrom-Json | Out-Null
Get-Content (Join-Path $root 'topology/relay-topology.json') -Raw | ConvertFrom-Json | Out-Null

$metadata = Get-Content (Join-Path $root 'metadata/poolMetaData.json') -Raw | ConvertFrom-Json
if ($metadata.ticker -notmatch '^[A-Z0-9]{3,9}$') { throw 'Ticker must be 3-9 uppercase alphanumeric characters.' }
if ($metadata.description.Length -gt 255) { throw 'Metadata description exceeds 255 characters.' }

Write-Output "OK: $($required.Count) stake-pool templates present"
Write-Output "OK: JSON documents parse successfully"
Write-Output "OK: ticker and description constraints pass"
