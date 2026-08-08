#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"
KEYS="${1:?usage: issue-op-cert.sh AIRGAP_KEYS_DIR KES_PERIOD OUTPUT_DIR}"
KES_PERIOD="${2:?KES period is required}"
OUT="${3:?output directory is required}"
assert_not_git_tree "$KEYS"
[[ "$KES_PERIOD" =~ ^[0-9]+$ ]] || die 'KES period must be an integer'
for file in cold.skey cold.counter kes.vkey vrf.skey kes.skey; do require_file "$KEYS/$file"; done
ensure_empty_private_dir "$OUT"
cardano-cli node issue-op-cert --kes-verification-key-file "$KEYS/kes.vkey" --cold-signing-key-file "$KEYS/cold.skey" --operational-certificate-issue-counter "$KEYS/cold.counter" --kes-period "$KES_PERIOD" --out-file "$OUT/node.cert"
install -m 0400 "$KEYS/vrf.skey" "$OUT/vrf.skey"
install -m 0400 "$KEYS/kes.skey" "$OUT/kes.skey"
(cd "$OUT" && sha256sum node.cert vrf.skey kes.skey > transfer-manifest.sha256)
info "hot credential bundle created; cold.skey and cold.counter remain in $KEYS"
