#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"
load_env "$1"
CONTEXT="${2:?usage: register-pool.sh ENV_FILE CONTEXT_DIR AIRGAP_KEYS_DIR OUTPUT_DIR}"
KEYS="${3:?air-gapped key directory is required}"
OUT="${4:?output directory is required}"
assert_not_git_tree "$KEYS"
for name in POOL_METADATA_URL POOL_PLEDGE_LOVELACE POOL_MARGIN RELAY_1_DNS RELAY_2_DNS RELAY_PORT; do reject_placeholder "$name"; done
for file in protocol.json poolMetaDataHash.txt context.sha256; do require_file "$CONTEXT/$file"; done
(cd "$CONTEXT" && sha256sum --check --strict context.sha256)
for file in cold.vkey cold.skey vrf.vkey stake.vkey; do require_file "$KEYS/$file"; done
ensure_empty_private_dir "$OUT"
MIN_POOL_COST="$(jq -r '.minPoolCost' "$CONTEXT/protocol.json")"
POOL_COST="${POOL_COST_LOVELACE:-$MIN_POOL_COST}"
[[ "$POOL_COST" != QUERY_MIN_POOL_COST ]] || POOL_COST="$MIN_POOL_COST"
(( POOL_COST >= MIN_POOL_COST )) || die "pool cost $POOL_COST is below ledger minimum $MIN_POOL_COST"

cardano-cli latest stake-pool registration-certificate \
  --cold-verification-key-file "$KEYS/cold.vkey" --vrf-verification-key-file "$KEYS/vrf.vkey" \
  --pool-pledge "$POOL_PLEDGE_LOVELACE" --pool-cost "$POOL_COST" --pool-margin "$POOL_MARGIN" \
  --pool-reward-account-verification-key-file "$KEYS/stake.vkey" --pool-owner-stake-verification-key-file "$KEYS/stake.vkey" \
  --single-host-pool-relay "$RELAY_1_DNS" --pool-relay-port "$RELAY_PORT" \
  --single-host-pool-relay "$RELAY_2_DNS" --pool-relay-port "$RELAY_PORT" \
  --metadata-url "$POOL_METADATA_URL" --metadata-hash "$(cat "$CONTEXT/poolMetaDataHash.txt")" --out-file "$OUT/pool.cert"
cardano-cli latest stake-address stake-delegation-certificate --stake-verification-key-file "$KEYS/stake.vkey" --cold-verification-key-file "$KEYS/cold.vkey" --out-file "$OUT/deleg.cert"
if [[ "${STAKE_ALREADY_REGISTERED:-NO}" != YES ]]; then
  STAKE_DEPOSIT="$(jq -r '.stakeAddressDeposit' "$CONTEXT/protocol.json")"
  [[ "$STAKE_DEPOSIT" =~ ^[0-9]+$ ]] || die 'protocol parameters contain no numeric stakeAddressDeposit'
  cardano-cli latest stake-address registration-certificate --stake-verification-key-file "$KEYS/stake.vkey" --key-reg-deposit-amt "$STAKE_DEPOSIT" --out-file "$OUT/stake.cert"
fi
(cd "$OUT" && sha256sum ./*.cert > certificates.sha256)
info "offline certificates generated: $OUT"
