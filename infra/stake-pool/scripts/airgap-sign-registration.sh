#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"
load_env "$1"
TX_BODY="${2:?usage: airgap-sign-registration.sh ENV_FILE TX_RAW AIRGAP_KEYS_DIR OUTPUT_FILE}"
KEYS="${3:?key directory required}"
OUT="${4:?output file required}"
[[ ! -e "$OUT" && ! -e "$OUT.sha256" ]] || die 'signed transaction output already exists'
assert_not_git_tree "$KEYS"
require_file "$TX_BODY"
TX_DIR="$(cd "$(dirname "$TX_BODY")" && pwd)"
if [[ -f "$TX_DIR/unsigned.sha256" ]]; then (cd "$TX_DIR" && sha256sum --check --strict unsigned.sha256); fi
for file in payment.skey cold.skey stake.skey; do require_file "$KEYS/$file"; done
mapfile -t NET < <(network_args)
cardano-cli conway transaction sign "${NET[@]}" --tx-body-file "$TX_BODY" \
  --signing-key-file "$KEYS/payment.skey" --signing-key-file "$KEYS/cold.skey" --signing-key-file "$KEYS/stake.skey" --out-file "$OUT"
chmod 600 "$OUT"
(cd "$(dirname "$OUT")" && sha256sum "$(basename "$OUT")" > "$(basename "$OUT").sha256")
info 'signed transaction created; visually confirm the reviewed tx body hash before returning it online'
