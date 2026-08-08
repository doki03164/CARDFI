#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"
load_env "$1"
OUT="${2:?usage: airgap-key-ceremony.sh ENV_FILE ABSOLUTE_OUTPUT_DIR}"
[[ "$OUT" = /* ]] || die 'output directory must be absolute'
[[ ! -e "$OUT" ]] || die "output path already exists: $OUT"
mkdir -p "$OUT"
assert_not_git_tree "$OUT"
chmod 700 "$OUT"
umask 077
require_cmd cardano-cli

if [[ "$NETWORK" == mainnet && "${ALLOW_MAINNET_RAW_KEYS:-NO}" != YES ]]; then
  die 'mainnet raw-key generation is locked; use a hardware wallet or explicitly set ALLOW_MAINNET_RAW_KEYS=YES after operator review'
fi

cardano-cli node key-gen --cold-verification-key-file "$OUT/cold.vkey" --cold-signing-key-file "$OUT/cold.skey" --operational-certificate-issue-counter "$OUT/cold.counter"
cardano-cli node key-gen-KES --verification-key-file "$OUT/kes.vkey" --signing-key-file "$OUT/kes.skey"
cardano-cli node key-gen-VRF --verification-key-file "$OUT/vrf.vkey" --signing-key-file "$OUT/vrf.skey"
cardano-cli address key-gen --verification-key-file "$OUT/payment.vkey" --signing-key-file "$OUT/payment.skey"
cardano-cli stake-address key-gen --verification-key-file "$OUT/stake.vkey" --signing-key-file "$OUT/stake.skey"
mapfile -t NET < <(network_args)
cardano-cli stake-address build --stake-verification-key-file "$OUT/stake.vkey" "${NET[@]}" --out-file "$OUT/stake.addr"
cardano-cli address build --payment-verification-key-file "$OUT/payment.vkey" --stake-verification-key-file "$OUT/stake.vkey" "${NET[@]}" --out-file "$OUT/payment.addr"
cardano-cli stake-pool id --cold-verification-key-file "$OUT/cold.vkey" --output-format hex > "$OUT/pool.id"
(cd "$OUT" && sha256sum ./*.vkey ./*.addr pool.id > public-manifest.sha256)
printf 'CEREMONY COMPLETE\nnetwork=%s\npool_id=%s\npayment_address=%s\n' "$NETWORK" "$(cat "$OUT/pool.id")" "$(cat "$OUT/payment.addr")"
