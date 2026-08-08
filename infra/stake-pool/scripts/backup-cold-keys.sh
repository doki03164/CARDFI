#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"
KEYS="${1:?usage: backup-cold-keys.sh AIRGAP_KEYS_DIR AGE_RECIPIENT OUTPUT_FILE}"
RECIPIENT="${2:?age recipient is required}"
OUT="${3:?encrypted output file is required}"
[[ ! -e "$OUT" && ! -e "$OUT.sha256" ]] || die 'backup output already exists'
assert_not_git_tree "$KEYS"
require_cmd age; require_cmd tar; require_cmd sha256sum
for file in cold.skey cold.vkey cold.counter payment.skey payment.vkey stake.skey stake.vkey; do require_file "$KEYS/$file"; done
umask 077
tar -C "$KEYS" -czf - cold.skey cold.vkey cold.counter payment.skey payment.vkey stake.skey stake.vkey | age -r "$RECIPIENT" -o "$OUT"
chmod 600 "$OUT"
(cd "$(dirname "$OUT")" && sha256sum "$(basename "$OUT")" > "$(basename "$OUT").sha256")
info 'encrypted backup created; store two verified copies in physically separate locations'
