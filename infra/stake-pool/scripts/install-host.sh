#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"
load_env "${1:-$ROOT/pool.env}"

[[ "${EUID:-$(id -u)}" -eq 0 ]] || die 'run install-host.sh as root on Ubuntu Linux'
[[ "$NODE_ROLE" == relay || "$NODE_ROLE" == block-producer ]] || die 'NODE_ROLE must be relay or block-producer'
reject_placeholder CARDANO_NODE_VERSION
require_cmd curl
require_cmd tar
require_cmd sha256sum

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends ca-certificates curl jq tar libnuma1 libsnappy1v5
if apt-cache show liburing2 >/dev/null 2>&1; then apt-get install -y --no-install-recommends liburing2;
elif apt-cache show liburing1 >/dev/null 2>&1; then apt-get install -y --no-install-recommends liburing1; fi

ARCH="$(uname -m)"
case "$ARCH" in
  x86_64) RELEASE_ARCH=amd64; EXPECTED_SHA256="${CARDANO_NODE_SHA256_AMD64:?CARDANO_NODE_SHA256_AMD64 is required}" ;;
  aarch64|arm64) RELEASE_ARCH=arm64; EXPECTED_SHA256="${CARDANO_NODE_SHA256_ARM64:?CARDANO_NODE_SHA256_ARM64 is required}" ;;
  *) die "unsupported architecture: $ARCH" ;;
esac
reject_placeholder EXPECTED_SHA256
URL="https://github.com/IntersectMBO/cardano-node/releases/download/${CARDANO_NODE_VERSION}/cardano-node-${CARDANO_NODE_VERSION}-linux-${RELEASE_ARCH}.tar.gz"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
curl --proto '=https' --tlsv1.2 --fail --show-error --location "$URL" -o "$TMP/cardano-node.tar.gz"
printf '%s  %s\n' "$EXPECTED_SHA256" "$TMP/cardano-node.tar.gz" | sha256sum --check --strict
tar -xzf "$TMP/cardano-node.tar.gz" -C "$TMP"

id "$CARDANO_USER" >/dev/null 2>&1 || useradd --system --create-home --shell /usr/sbin/nologin "$CARDANO_USER"
install -d -o "$CARDANO_USER" -g "$CARDANO_USER" -m 0750 "$CARDANO_CONFIG_DIR" "$CARDANO_DB_DIR" "$(dirname "$CARDANO_NODE_SOCKET_PATH")"
install -m 0755 "$(find "$TMP" -type f -name cardano-node | head -1)" /usr/local/bin/cardano-node
install -m 0755 "$(find "$TMP" -type f -name cardano-cli | head -1)" /usr/local/bin/cardano-cli

RENDERED="$ROOT/build/rendered/$NETWORK"
require_file "$RENDERED/config.json"
install -m 0644 "$RENDERED"/*.json "$CARDANO_CONFIG_DIR/"
if [[ "$NODE_ROLE" == relay ]]; then
  install -m 0644 "$ROOT/systemd/cardano-node-relay.service" /etc/systemd/system/cardano-node.service
else
  install -m 0644 "$ROOT/systemd/cardano-node-block-producer.service" /etc/systemd/system/cardano-node.service
  install -d -o "$CARDANO_USER" -g "$CARDANO_USER" -m 0750 "$CARDANO_CONFIG_DIR/credentials"
fi
systemctl daemon-reload
systemctl enable cardano-node.service
info "installed cardano-node $(cardano-node --version | head -1); start only after topology and credential review"
