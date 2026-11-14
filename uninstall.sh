#!/usr/bin/env bash
# Remove the mandatory Wi-Fi power-save drop-in.
set -euo pipefail

dest=/etc/NetworkManager/conf.d/99-wifi-powersave-off.conf

if [[ ${EUID} -ne 0 ]]; then
  printf 'error: run with sudo\n' >&2
  exit 1
fi

rm -f -- "$dest"
nmcli general reload >/dev/null 2>&1 || systemctl reload NetworkManager

printf 'Reapplying active Wi-Fi connection; the link may drop briefly.\n'
while IFS=: read -r conn type; do
  [[ ${type} == 802-11-wireless ]] || continue
  nmcli connection up "$conn" >/dev/null
done < <(nmcli -t -f NAME,TYPE connection show --active)

printf 'Removed %s\n' "$dest"
printf 'Ubuntu default power-save policy is active again.\n'
