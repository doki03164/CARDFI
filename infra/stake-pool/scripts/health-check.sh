#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"
load_env "$1"
require_cmd cardano-cli; require_cmd jq; require_cmd systemctl
mapfile -t NET < <(network_args)
systemctl is-active --quiet cardano-node.service || die 'cardano-node.service is not active'
TIP="$(cardano-cli latest query tip "${NET[@]}")"
SYNC="$(jq -r '.syncProgress // "unknown"' <<<"$TIP")"
SLOT="$(jq -r '.slot // 0' <<<"$TIP")"
[[ "$SLOT" =~ ^[0-9]+$ && "$SLOT" -gt 0 ]] || die 'node has not reached a valid slot'
printf 'HEALTHY network=%s slot=%s sync=%s service=active\n' "$NETWORK" "$SLOT" "$SYNC"
