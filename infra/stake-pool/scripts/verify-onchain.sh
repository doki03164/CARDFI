#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"
load_env "$1"
COLD_VKEY="${2:?usage: verify-onchain.sh ENV_FILE COLD_VKEY STAKE_ADDRESS_FILE}"
STAKE_ADDR_FILE="${3:?stake address file is required}"
require_file "$COLD_VKEY"; require_file "$STAKE_ADDR_FILE"
mapfile -t NET < <(network_args)
POOL_ID="$(cardano-cli latest stake-pool id --cold-verification-key-file "$COLD_VKEY" --output-format hex)"
SNAPSHOT="$(cardano-cli latest query stake-snapshot "${NET[@]}" --stake-pool-id "$POOL_ID")"
STAKE_INFO="$(cardano-cli latest query stake-address-info "${NET[@]}" --address "$(cat "$STAKE_ADDR_FILE")")"
jq -e 'type == "object"' <<<"$SNAPSHOT" >/dev/null
jq -e 'type == "array" and length > 0' <<<"$STAKE_INFO" >/dev/null
printf 'ONCHAIN_OK network=%s pool_id=%s stake_address_registered=true\n' "$NETWORK" "$POOL_ID"
