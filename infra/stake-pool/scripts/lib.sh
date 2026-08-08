#!/usr/bin/env bash
set -euo pipefail

die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
info() { printf 'INFO: %s\n' "$*"; }
require_cmd() { command -v "$1" >/dev/null 2>&1 || die "required command not found: $1"; }
require_file() { [[ -f "$1" ]] || die "required file not found: $1"; }
require_dir() { [[ -d "$1" ]] || die "required directory not found: $1"; }
resolve_host() {
  if command -v getent >/dev/null 2>&1; then getent hosts "$1" >/dev/null;
  elif command -v nslookup >/dev/null 2>&1; then nslookup "$1" >/dev/null;
  else die 'no DNS resolver command found (getent or nslookup)'; fi
}

load_env() {
  local env_file="${1:-}"
  [[ -n "$env_file" ]] || die 'usage requires an environment file'
  require_file "$env_file"
  # shellcheck disable=SC1090
  source "$env_file"
  : "${NETWORK:?NETWORK is required}"
  : "${CARDANO_NODE_NETWORK_ID:?CARDANO_NODE_NETWORK_ID is required}"
  : "${CARDANO_NODE_SOCKET_PATH:?CARDANO_NODE_SOCKET_PATH is required}"
  export CARDANO_NODE_NETWORK_ID CARDANO_NODE_SOCKET_PATH
  case "$NETWORK" in preprod|preview|mainnet) ;; *) die "unsupported NETWORK=$NETWORK" ;; esac
}

network_args() {
  if [[ "$NETWORK" == mainnet ]]; then printf '%s\n' '--mainnet';
  else printf '%s\n' '--testnet-magic' "$CARDANO_NODE_NETWORK_ID"; fi
}

reject_placeholder() {
  local name="$1" value="${!1:-}"
  [[ -n "$value" ]] || die "$name is empty"
  [[ "$value" != *TARGET* && "$value" != HOST_* && "$value" != *REQUIRED_* && "$value" != QUERY_* ]] || die "$name still contains a placeholder"
}

ensure_private_dir() {
  local path="$1"
  mkdir -p "$path"
  chmod 700 "$path"
}

ensure_empty_private_dir() {
  local path="$1"
  if [[ -d "$path" && -n "$(find "$path" -mindepth 1 -maxdepth 1 -print -quit)" ]]; then
    die "output directory is not empty: $path"
  fi
  ensure_private_dir "$path"
}

assert_not_git_tree() {
  local path
  path="$(cd "$1" && pwd -P)"
  if git -C "$path" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    die "secret operation path must be outside a Git working tree: $path"
  fi
}
