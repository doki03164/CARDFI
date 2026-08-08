$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$required = @(
  'pool.env.example',
  'metadata/poolMetaData.json',
  'topology/block-producer-topology.json',
  'topology/relay-topology.json',
  'systemd/cardano-node-block-producer.service',
  'systemd/cardano-node-relay.service',
  'scripts/lib.sh',
  'scripts/render-config.sh',
  'scripts/install-host.sh',
  'scripts/preflight.sh',
  'scripts/airgap-key-ceremony.sh',
  'scripts/issue-op-cert.sh',
  'scripts/install-hot-credentials.sh',
  'scripts/firewall-plan.sh',
  'scripts/prepare-registration-online.sh',
  'scripts/register-pool.sh',
  'scripts/build-registration-tx.sh',
  'scripts/airgap-sign-registration.sh',
  'scripts/submit-registration.sh',
  'scripts/verify-onchain.sh',
  'scripts/health-check.sh',
  'scripts/backup-cold-keys.sh',
  'monitoring/prometheus-alerts.yml',
  'deployment/preprod-manifest.json'
)

foreach ($relative in $required) {
  $path = Join-Path $root $relative
  if (-not (Test-Path -LiteralPath $path)) { throw "Missing template: $relative" }
}

Get-Content (Join-Path $root 'metadata/poolMetaData.json') -Raw | ConvertFrom-Json | Out-Null
Get-Content (Join-Path $root 'topology/block-producer-topology.json') -Raw | ConvertFrom-Json | Out-Null
Get-Content (Join-Path $root 'topology/relay-topology.json') -Raw | ConvertFrom-Json | Out-Null
Get-Content (Join-Path $root 'deployment/preprod-manifest.json') -Raw | ConvertFrom-Json | Out-Null

$metadata = Get-Content (Join-Path $root 'metadata/poolMetaData.json') -Raw | ConvertFrom-Json
if ($metadata.ticker -notmatch '^[A-Z0-9]{3,9}$') { throw 'Ticker must be 3-9 uppercase alphanumeric characters.' }
if ($metadata.description.Length -gt 255) { throw 'Metadata description exceeds 255 characters.' }
if ($metadata.homepage -notmatch '^https://') { throw 'Metadata homepage must use HTTPS.' }
$publicMetadataPath = Join-Path (Split-Path -Parent (Split-Path -Parent $root)) 'public/pool.json'
if (-not (Test-Path $publicMetadataPath)) { throw 'Missing Vite-public pool metadata.' }
$publicMetadata = Get-Content $publicMetadataPath -Raw | ConvertFrom-Json
if (($metadata | ConvertTo-Json -Compress) -ne ($publicMetadata | ConvertTo-Json -Compress)) { throw 'Infrastructure and public pool metadata differ.' }

$trackedSecrets = Get-ChildItem -Path $root -Recurse -File | Where-Object { $_.Extension -in '.skey', '.mnemonic', '.age' }
if ($trackedSecrets) { throw "Secret-like artifact found under repository infrastructure tree: $($trackedSecrets.FullName -join ', ')" }

$bp = Get-Content (Join-Path $root 'topology/block-producer-topology.json') -Raw
if ($bp -notmatch '"useLedgerAfterSlot"\s*:\s*-1') { throw 'Block producer must disable ledger peer discovery.' }
if ($bp -notmatch '"bootstrapPeers"\s*:\s*null') { throw 'Block producer must not configure bootstrap peers.' }

$bashPath = if (Test-Path 'C:\Program Files\Git\bin\bash.exe') { 'C:\Program Files\Git\bin\bash.exe' } else { (Get-Command bash -ErrorAction SilentlyContinue).Source }
if ($bashPath) {
  $scripts = Get-ChildItem (Join-Path $root 'scripts') -Filter '*.sh'
  foreach ($script in $scripts) {
    & $bashPath -n $script.FullName
    if ($LASTEXITCODE -ne 0) { throw "Bash syntax validation failed: $($script.Name)" }
  }
  Write-Output "OK: $($scripts.Count) Bash scripts pass syntax validation"
}

Write-Output "OK: $($required.Count) stake-pool templates present"
Write-Output "OK: JSON documents parse successfully"
Write-Output "OK: ticker and description constraints pass"
Write-Output "OK: no signing-key artifacts present"
Write-Output "OK: block producer topology remains private"
