# CardFi Stake Pool Production Track — Verification Record

Verified at: 2026-08-08 Asia/Taipei  
Branch: `codex/stake-pool-production`

## Baseline artifact

Command:

```powershell
Get-FileHash artifacts/stake-pool-production/original-stake-pool.zip -Algorithm SHA256
```

Literal result, exit `0`:

```text
b8b7c0512daf757e8800fa066e143adc504265fbdbd2b1835a4c1407e5fd08d5  original-stake-pool.zip
```

The archive was reopened with `System.IO.Compression.ZipFile::OpenRead`; it contains the original metadata, two topology files, two systemd units, registration script, verifier, environment example and README. It contains no signing key.

## Modified artifact verification

Command:

```powershell
npm.cmd run stake-pool:verify
```

Literal result, exit `0`:

```text
OK: 16 Bash scripts pass syntax validation
OK: 24 stake-pool templates present
OK: JSON documents parse successfully
OK: ticker and description constraints pass
OK: no signing-key artifacts present
OK: block producer topology remains private
```

Command:

```powershell
npm.cmd test
npm.cmd run build
npm.cmd run contracts:check
npm.cmd run deploy:manifest:check
```

Literal result summary, every command exit `0`:

```text
Test Files  3 passed (3)
Tests       8 passed (8)
vite: 1794 modules transformed; production build completed
Aiken: total=27 passed=27 failed=0
OK: 4 validator manifests match the CIP-57 blueprint
PUBLIC_METADATA_OK ticker=CFI homepage=https://doki03164.github.io/CARDFI/
```

The Vite build was reopened and `dist/pool.json` parsed successfully.

The modified `cardfi-stake-pool-production.tar.gz` was reopened into a new directory and its packaged verifier was executed. Literal result, exit `0`:

```text
OK: 16 Bash scripts pass syntax validation
OK: 24 stake-pool templates present
OK: JSON documents parse successfully
OK: ticker and description constraints pass
OK: no signing-key artifacts present
OK: block producer topology remains private
MODIFIED_ARCHIVE_EXECUTED exit=0
```

## Official Preprod input verification

Input base URL:

```text
https://book.world.dev.cardano.org/environments/preprod
```

Each file was downloaded, hashed, then parsed with Node `JSON.parse`. Literal results, exit `0`:

```text
REMOTE_CONFIG_OK file=config.json sha256=6b2da527ab5ce7cfc6c02cf74a04f512fa845b870f9fdda25d26edcd5814e2c8
REMOTE_CONFIG_OK file=topology.json sha256=bd18a5adaeaa926c0eeb5ae5cbc8f70c6f18e702b6cb079cfdee58d1206fc25c
REMOTE_CONFIG_OK file=peer-snapshot.json sha256=e57179665f4854f46b4a5171a65869c2dbd7f515fb083dcffa76f364c41b9d7b
REMOTE_CONFIG_OK file=byron-genesis.json sha256=d88fbffdf78daaccfaddf504e95840c73ce527c06fa4140aefb55d3f91c00cef
REMOTE_CONFIG_OK file=shelley-genesis.json sha256=4b9d32c09159c2948e4386ba1f59db5a249a89b43b84dfd8368f465e650095de
REMOTE_CONFIG_OK file=alonzo-genesis.json sha256=7333bfafe311589fa09e8bf59a47ec0d85a1959f00748cc0800591d2c7646408
REMOTE_CONFIG_OK file=conway-genesis.json sha256=c196814fe2e8f36ad1910e5c287184970339657729e7ad4fc354c34e149be3f8
JSON_PARSE_OK file=alonzo-genesis.json
JSON_PARSE_OK file=byron-genesis.json
JSON_PARSE_OK file=config.json
JSON_PARSE_OK file=conway-genesis.json
JSON_PARSE_OK file=peer-snapshot.json
JSON_PARSE_OK file=shelley-genesis.json
JSON_PARSE_OK file=topology.json
```

Pinned node release HEAD verification, exit `0`:

```text
NODE_RELEASE_OK status=200 length=217353603 url=https://github.com/IntersectMBO/cardano-node/releases/download/11.0.1/cardano-node-11.0.1-linux-amd64.tar.gz
```

## Preflight and firewall behavior

Synthetic input used reserved documentation CIDRs, public resolvable DNS names and `https://example.com`; no wallet or key material was involved.

Commands:

```bash
bash infra/stake-pool/scripts/preflight.sh synthetic.env
bash infra/stake-pool/scripts/firewall-plan.sh synthetic.env plan
```

Literal result, exit `0`:

```text
PREFLIGHT_OK network=preprod ticker=CFI relays=one.one.one.one,cloudflare-dns.com metadata_length=19
FIREWALL_PLAN role=block-producer
  ufw default deny incoming
  ufw default allow outgoing
  ufw allow from 192.0.2.10/32 to any port 22 proto tcp
  ufw allow from 10.0.1.10/32 to any port 6000 proto tcp
  ufw allow from 10.0.2.10/32 to any port 6000 proto tcp
  ufw logging low
  ufw --force enable
```

## Patch and rollback

Commands:

```powershell
git apply --cached --reverse --check artifacts/stake-pool-production/stake-pool-production.patch
powershell.exe -NoProfile -ExecutionPolicy Bypass -File artifacts/stake-pool-production/rollback.ps1
```

Literal results, exits `0` / `0`:

```text
PATCH_INDEX_REVERSE_CHECK_EXIT=0
ROLLBACK_VERIFIED archive=b8b7c0512daf757e8800fa066e143adc504265fbdbd2b1835a4c1407e5fd08d5 target=C:\Users\andre\OneDrive\文件\ChatGPT\CardFi\infra\stake-pool apply=false
ROLLBACK_VERIFY_EXIT=0
```

`rollback.ps1` defaults to verification-only. `-Apply` first moves the modified tree to a timestamped backup, verifies the original archive hash, then restores the baseline.

## Verified behavior boundary

- Baseline behavior: 8-template SPO scaffold, reproducibly preserved by SHA-256 archive.
- Modified behavior: 24-file production track with 16 syntax-valid Bash tools, pinned node checksums, official Preprod inputs, separated online/offline registration, private BP topology, monitoring, backup and rollback.
- External state still pending: provisioned Linux hosts, operator DNS/IP values, offline key ceremony, node sync, funded Preprod wallet and on-chain pool registration. `deployment/preprod-manifest.json` records these gates as `false`; no chain submission is claimed.
