#!/usr/bin/env bash
# Install a mandatory NetworkManager drop-in that disables Wi-Fi power save.
set -euo pipefail

repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
src="${repo_dir}/99-wifi-powersave-off.conf"
dest_dir=/etc/NetworkManager/conf.d
dest="${dest_dir}/99-wifi-powersave-off.conf"

if [[ ${EUID} -ne 0 ]]; then
  printf 'error: run with sudo\n' >&2
  exit 1
fi

if ! command -v nmcli >/dev/null 2>&1; then
  printf 'error: nmcli not found\n' >&2
  exit 1
fi

install -d -m 0755 -- "$dest_dir"
if [[ -e ${dest} ]] && ! cmp -s -- "$src" "$dest"; then
  backup="${dest}.bak.$(date +%Y%m%d-%H%M%S)"
  cp -a -- "$dest" "$backup"
  printf 'Backed up existing drop-in to %s\n' "$backup"
fi
install -m 0644 -- "$src" "$dest"

if command -v NetworkManager >/dev/null 2>&1; then
  if ! NetworkManager --print-config 2>/dev/null | grep -qx 'wifi.powersave=2'; then
    printf 'error: NetworkManager did not merge wifi.powersave=2\n' >&2
    exit 1
  fi
fi

nmcli general reload >/dev/null 2>&1 || systemctl reload NetworkManager

# Reactivate active Wi-Fi profiles so the new default applies now.
while IFS=: read -r conn type; do
  [[ ${type} == 802-11-wireless ]] || continue
  nmcli connection up "$conn" >/dev/null
done < <(nmcli -t -f NAME,TYPE connection show --active)

dev=$(nmcli -t -f DEVICE,TYPE device status | awk -F: '$2 == "wifi" { print $1; exit }')
if [[ -n ${dev} ]] && command -v iwconfig >/dev/null 2>&1; then
  iwconfig "$dev" 2>/dev/null | grep -q 'Power Management:off' \
    || printf 'warning: %s still reports power management on\n' "$dev" >&2
fi

printf 'Installed %s\n' "$dest"
printf 'Undo with: %s/uninstall.sh\n' "$repo_dir"
