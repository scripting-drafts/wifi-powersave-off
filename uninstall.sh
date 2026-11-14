#!/usr/bin/env bash
# Remove the mandatory Wi-Fi power-save drop-in.
set -euo pipefail

if (( $# )); then
  printf 'usage: %s\n' "${0##*/}" >&2
  exit 2
fi

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

# Mandatory reconnect: NetworkManager applies the default policy at activation.
printf 'Reapplying active Wi-Fi connection; the link will drop briefly.\n'
while IFS=: read -r conn type; do
  [[ ${type} == 802-11-wireless ]] || continue
  nmcli connection up "$conn" >/dev/null
done < <(nmcli -t -f NAME,TYPE connection show --active)

printf 'Removed %s\n' "$dest"
printf 'Ubuntu default power-save policy is active again.\n'
