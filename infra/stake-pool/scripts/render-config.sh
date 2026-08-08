#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"
load_env "${1:-$ROOT/pool.env}"

for name in RELAY_1_DNS RELAY_2_DNS RELAY_PORT BP_PORT CARDANO_CONFIG_BASE_URL; do reject_placeholder "$name"; done
require_cmd curl
require_cmd jq

OUT="${2:-$ROOT/build/rendered/$NETWORK}"
if [[ -d "$OUT" && -n "$(find "$OUT" -mindepth 1 -maxdepth 1 -print -quit)" ]]; then die "output directory is not empty: $OUT"; fi
mkdir -p "$OUT"

files=(config.json topology.json peer-snapshot.json byron-genesis.json shelley-genesis.json alonzo-genesis.json conway-genesis.json)
for file in "${files[@]}"; do
  info "downloading $file"
  curl --proto '=https' --tlsv1.2 --fail --silent --show-error --location \
    "$CARDANO_CONFIG_BASE_URL/$file" -o "$OUT/$file"
  jq empty "$OUT/$file"
done

jq --arg r1 "$RELAY_1_DNS" --arg r2 "$RELAY_2_DNS" --argjson port "$RELAY_PORT" \
  '.localRoots[0].accessPoints = [{address:$r1,port:$port},{address:$r2,port:$port}] |
   .localRoots[0].advertise = false |
   .localRoots[0].hotValency = 2 |
   .localRoots[0].warmValency = 2 |
   .bootstrapPeers = null | .publicRoots = [] | .useLedgerAfterSlot = -1' \
  "$ROOT/topology/block-producer-topology.json" > "$OUT/block-producer-topology.json"

jq empty "$OUT/block-producer-topology.json"
cp "$OUT/topology.json" "$OUT/relay-topology.json"
(cd "$OUT" && sha256sum "${files[@]}" block-producer-topology.json relay-topology.json > SHA256SUMS)
info "rendered and hashed configuration: $OUT"
