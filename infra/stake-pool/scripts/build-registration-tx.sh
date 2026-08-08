#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"
load_env "$1"
CERTS="${2:?usage: build-registration-tx.sh ENV_FILE CERT_DIR OUTPUT_DIR}"
OUT="${3:?output directory is required}"
for file in pool.cert deleg.cert certificates.sha256; do require_file "$CERTS/$file"; done
(cd "$CERTS" && sha256sum --check --strict certificates.sha256)
require_file "$PAYMENT_ADDR_FILE"
require_cmd cardano-cli; require_cmd jq
ensure_empty_private_dir "$OUT"
mapfile -t NET < <(network_args)
ADDRESS="$(cat "$PAYMENT_ADDR_FILE")"
cardano-cli latest query utxo "${NET[@]}" --address "$ADDRESS" --out-file "$OUT/utxo.json"
TX_IN="$(jq -r 'keys[0] // empty' "$OUT/utxo.json")"
[[ -n "$TX_IN" ]] || die 'payment address has no spendable UTxO'
TIP="$(cardano-cli latest query tip "${NET[@]}" | jq -r '.slot')"
[[ "$TIP" =~ ^[0-9]+$ ]] || die 'node tip has no numeric slot'
CERT_ARGS=()
if [[ "${STAKE_ALREADY_REGISTERED:-NO}" != YES ]]; then
  require_file "$CERTS/stake.cert"
  CERT_ARGS+=(--certificate-file "$CERTS/stake.cert")
fi
CERT_ARGS+=(--certificate-file "$CERTS/pool.cert" --certificate-file "$CERTS/deleg.cert")
cardano-cli conway transaction build "${NET[@]}" --tx-in "$TX_IN" --change-address "$ADDRESS" \
  "${CERT_ARGS[@]}" \
  --invalid-hereafter "$((TIP + 1000))" --witness-override 3 --out-file "$OUT/tx.raw"
cardano-cli conway transaction view --tx-body-file "$OUT/tx.raw" > "$OUT/tx.view.txt"
(cd "$OUT" && sha256sum tx.raw tx.view.txt > unsigned.sha256)
info "unsigned transaction built; review tx.view.txt before offline signing"
