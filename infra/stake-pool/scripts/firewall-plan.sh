#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"
load_env "$1"
MODE="${2:-plan}"
[[ "$NODE_ROLE" == relay || "$NODE_ROLE" == block-producer ]] || die 'NODE_ROLE must be relay or block-producer'
reject_placeholder ADMIN_SSH_CIDR
COMMANDS=("ufw default deny incoming" "ufw default allow outgoing" "ufw allow from $ADMIN_SSH_CIDR to any port 22 proto tcp")
if [[ "$NODE_ROLE" == relay ]]; then
  COMMANDS+=("ufw allow $RELAY_PORT/tcp")
else
  reject_placeholder RELAY_1_PRIVATE_CIDR
  reject_placeholder RELAY_2_PRIVATE_CIDR
  COMMANDS+=("ufw allow from $RELAY_1_PRIVATE_CIDR to any port $BP_PORT proto tcp")
  COMMANDS+=("ufw allow from $RELAY_2_PRIVATE_CIDR to any port $BP_PORT proto tcp")
fi
COMMANDS+=("ufw logging low" "ufw --force enable")
printf 'FIREWALL_PLAN role=%s\n' "$NODE_ROLE"
printf '  %s\n' "${COMMANDS[@]}"
[[ "$MODE" == plan ]] && exit 0
[[ "$MODE" == apply ]] || die 'mode must be plan or apply'
[[ "${APPLY_FIREWALL:-NO}" == YES ]] || die 'set APPLY_FIREWALL=YES after confirming SSH access and provider firewall rules'
[[ "${EUID:-$(id -u)}" -eq 0 ]] || die 'run firewall apply as root'
require_cmd ufw
ufw default deny incoming
ufw default allow outgoing
ufw allow from "$ADMIN_SSH_CIDR" to any port 22 proto tcp
if [[ "$NODE_ROLE" == relay ]]; then
  ufw allow "$RELAY_PORT/tcp"
else
  ufw allow from "$RELAY_1_PRIVATE_CIDR" to any port "$BP_PORT" proto tcp
  ufw allow from "$RELAY_2_PRIVATE_CIDR" to any port "$BP_PORT" proto tcp
fi
ufw logging low
ufw --force enable
ufw status verbose
