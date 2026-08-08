#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"
load_env "$1"
OUT="${2:-$ROOT/build/registration-context}"
for name in POOL_METADATA_URL; do reject_placeholder "$name"; done
require_cmd cardano-cli; require_cmd curl; require_cmd jq
ensure_empty_private_dir "$OUT"
mapfile -t NET < <(network_args)
cardano-cli latest query protocol-parameters "${NET[@]}" --out-file "$OUT/protocol.json"
cardano-cli latest query tip "${NET[@]}" > "$OUT/tip.json"
curl --proto '=https' --tlsv1.2 --fail --silent --show-error --location "$POOL_METADATA_URL" -o "$OUT/poolMetaData.json"
[[ "$(curl -sS -o /dev/null -w '%{num_redirects}' "$POOL_METADATA_URL")" == 0 ]] || die 'metadata URL must not redirect'
cardano-cli latest stake-pool metadata-hash --pool-metadata-file "$OUT/poolMetaData.json" --out-file "$OUT/poolMetaDataHash.txt"
jq -e '.minPoolCost and (.minPoolCost|tonumber>=0)' "$OUT/protocol.json" >/dev/null
(cd "$OUT" && sha256sum protocol.json tip.json poolMetaData.json poolMetaDataHash.txt > context.sha256)
info "registration context prepared: $OUT"
