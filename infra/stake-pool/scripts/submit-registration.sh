#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"
load_env "$1"
TX="${2:?usage: submit-registration.sh ENV_FILE SIGNED_TX}"
require_file "$TX"
mapfile -t NET < <(network_args)
cardano-cli conway transaction submit "${NET[@]}" --tx-file "$TX"
TXID="$(cardano-cli conway transaction txid --tx-file "$TX")"
printf 'SUBMITTED_TX_ID=%s\n' "$TXID"
