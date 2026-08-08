#!/usr/bin/env bash
set -euo pipefail

# Run on the designated transaction-build host after an offline key ceremony.
# No signing key should be stored in this repository.

ENV_FILE="${1:-../pool.env}"
source "$ENV_FILE"

required=(POOL_TICKER POOL_METADATA_URL POOL_PLEDGE_LOVELACE POOL_MARGIN RELAY_1_DNS RELAY_2_DNS PAYMENT_ADDR_FILE STAKE_VKEY_FILE)
for name in "${required[@]}"; do
  value="${!name:-}"
  if [[ -z "$value" || "$value" == *TARGET* || "$value" == HOST_* ]]; then
    echo "Missing concrete value: $name" >&2
    exit 2
  fi
done

NETWORK_ARGS=(--testnet-magic "$CARDANO_NODE_NETWORK_ID")
if [[ "$NETWORK" == "mainnet" ]]; then NETWORK_ARGS=(--mainnet); fi

mkdir -p build
cardano-cli latest query protocol-parameters "${NETWORK_ARGS[@]}" --out-file build/protocol.json
MIN_POOL_COST=$(jq -r '.minPoolCost' build/protocol.json)
POOL_COST="${POOL_COST_LOVELACE/QUERY_MIN_POOL_COST/$MIN_POOL_COST}"

curl --fail --silent --show-error "$POOL_METADATA_URL" -o build/poolMetaData.json
cardano-cli latest stake-pool metadata-hash --pool-metadata-file build/poolMetaData.json > build/poolMetaDataHash.txt

cardano-cli latest stake-pool registration-certificate \
  --cold-verification-key-file "$POOL_KEYS_DIR/cold.vkey" \
  --vrf-verification-key-file "$POOL_KEYS_DIR/vrf.vkey" \
  --pool-pledge "$POOL_PLEDGE_LOVELACE" \
  --pool-cost "$POOL_COST" \
  --pool-margin "$POOL_MARGIN" \
  --pool-reward-account-verification-key-file "$STAKE_VKEY_FILE" \
  --pool-owner-stake-verification-key-file "$STAKE_VKEY_FILE" \
  --single-host-pool-relay "$RELAY_1_DNS" --pool-relay-port "$RELAY_PORT" \
  --single-host-pool-relay "$RELAY_2_DNS" --pool-relay-port "$RELAY_PORT" \
  --metadata-url "$POOL_METADATA_URL" \
  --metadata-hash "$(cat build/poolMetaDataHash.txt)" \
  --out-file build/pool.cert

cardano-cli latest stake-address stake-delegation-certificate \
  --stake-verification-key-file "$STAKE_VKEY_FILE" \
  --cold-verification-key-file "$POOL_KEYS_DIR/cold.vkey" \
  --out-file build/deleg.cert

echo "Generated build/pool.cert and build/deleg.cert."
echo "Review all values, then build and sign the registration transaction using the isolated payment/stake signing workflow."
