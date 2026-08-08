#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"
load_env "${1:-$ROOT/pool.env}"
for name in POOL_TICKER POOL_METADATA_URL POOL_PLEDGE_LOVELACE POOL_MARGIN RELAY_1_DNS RELAY_2_DNS RELAY_PORT BP_PORT CARDANO_NODE_VERSION CARDANO_NODE_SHA256_AMD64 CARDANO_NODE_SHA256_ARM64 CARDANO_CONFIG_BASE_URL; do reject_placeholder "$name"; done
[[ "$POOL_TICKER" =~ ^[A-Z0-9]{3,9}$ ]] || die 'POOL_TICKER must be 3-9 uppercase alphanumeric characters'
(( ${#POOL_METADATA_URL} <= 64 )) || die 'POOL_METADATA_URL exceeds the 64-character ledger limit'
[[ "$POOL_MARGIN" =~ ^0(\.[0-9]+)?$|^1(\.0+)?$ ]] || die 'POOL_MARGIN must be between 0 and 1'
[[ "$POOL_PLEDGE_LOVELACE" =~ ^[0-9]+$ ]] || die 'POOL_PLEDGE_LOVELACE must be an integer'
[[ "$RELAY_PORT" =~ ^[0-9]+$ && "$BP_PORT" =~ ^[0-9]+$ ]] || die 'ports must be integers'
resolve_host "$RELAY_1_DNS" || die "cannot resolve $RELAY_1_DNS"
resolve_host "$RELAY_2_DNS" || die "cannot resolve $RELAY_2_DNS"
curl --proto '=https' --tlsv1.2 --fail --silent --show-error --head "$POOL_METADATA_URL" >/dev/null
printf 'PREFLIGHT_OK network=%s ticker=%s relays=%s,%s metadata_length=%s\n' "$NETWORK" "$POOL_TICKER" "$RELAY_1_DNS" "$RELAY_2_DNS" "${#POOL_METADATA_URL}"
