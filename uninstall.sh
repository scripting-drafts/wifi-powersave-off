#!/usr/bin/env bash
# Remove the mandatory Wi-Fi power-save drop-in.
set -euo pipefail

dest_dir=/etc/NetworkManager/conf.d
dest="${dest_dir}/zz-wifi-powersave-off.conf"
legacy="${dest_dir}/99-wifi-powersave-off.conf"

if [[ ${EUID} -ne 0 ]]; then
  printf 'error: run with sudo\n' >&2
  exit 1
fi

rm -f -- "$dest"
if [[ -e ${legacy} ]] && grep -q 'Mandatory: disable Wi-Fi power save' "$legacy" 2>/dev/null; then
  rm -f -- "$legacy"
fi
nmcli general reload >/dev/null 2>&1 || systemctl reload NetworkManager

apply_runtime() {
  local state=$1 dev type
  while IFS=: read -r dev type; do
    [[ ${type} == wifi ]] || continue
    if command -v iw >/dev/null 2>&1; then
      iw dev "$dev" set power_save "$state" >/dev/null 2>&1 || true
    fi
    if command -v iwconfig >/dev/null 2>&1; then
      iwconfig "$dev" power "$state" >/dev/null 2>&1 || true
    fi
  done < <(nmcli -t -f DEVICE,TYPE device status)
}

apply_runtime on
printf 'Removed %s without reconnecting.\n' "$dest"
printf 'Ubuntu default power-save policy is active again.\n'
