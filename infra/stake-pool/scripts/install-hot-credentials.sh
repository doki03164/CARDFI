#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"
load_env "$1"
BUNDLE="${2:?usage: install-hot-credentials.sh ENV_FILE TRANSFER_BUNDLE_DIR}"
[[ "${EUID:-$(id -u)}" -eq 0 ]] || die 'run as root on the block producer'
for file in node.cert vrf.skey kes.skey transfer-manifest.sha256; do require_file "$BUNDLE/$file"; done
(cd "$BUNDLE" && sha256sum --check --strict transfer-manifest.sha256)
DEST="$CARDANO_CONFIG_DIR/credentials"
install -d -o "$CARDANO_USER" -g "$CARDANO_USER" -m 0750 "$DEST"
install -o "$CARDANO_USER" -g "$CARDANO_USER" -m 0400 "$BUNDLE/node.cert" "$DEST/node.cert.new"
install -o "$CARDANO_USER" -g "$CARDANO_USER" -m 0400 "$BUNDLE/vrf.skey" "$DEST/vrf.skey.new"
install -o "$CARDANO_USER" -g "$CARDANO_USER" -m 0400 "$BUNDLE/kes.skey" "$DEST/kes.skey.new"
mv -f "$DEST/node.cert.new" "$DEST/node.cert"
mv -f "$DEST/vrf.skey.new" "$DEST/vrf.skey"
mv -f "$DEST/kes.skey.new" "$DEST/kes.skey"
if systemctl is-active --quiet cardano-node.service; then pkill -HUP cardano-node; fi
info 'hot credentials installed atomically; cold keys were not transferred'
