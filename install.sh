#!/usr/bin/env bash
# Install a mandatory NetworkManager drop-in that disables Wi-Fi power save.
set -euo pipefail

reconnect=0
case ${1:-} in
  --reconnect) reconnect=1 ;;
  '') ;;
  *) printf 'usage: %s [--reconnect]\n' "${0##*/}" >&2; exit 2 ;;
esac

repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
src="${repo_dir}/zz-wifi-powersave-off.conf"
dest_dir=/etc/NetworkManager/conf.d
dest="${dest_dir}/zz-wifi-powersave-off.conf"
legacy="${dest_dir}/99-wifi-powersave-off.conf"

if [[ ${EUID} -ne 0 ]]; then
  printf 'error: run with sudo\n' >&2
  exit 1
fi

if ! command -v nmcli >/dev/null 2>&1; then
  printf 'error: nmcli not found\n' >&2
  exit 1
fi

install -d -m 0755 -- "$dest_dir"
if [[ -e ${legacy} ]] && grep -q 'Mandatory: disable Wi-Fi power save' "$legacy" 2>/dev/null; then
  rm -f -- "$legacy"
  printf 'Removed obsolete %s\n' "$legacy"
fi
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

if (( reconnect )); then
  printf 'Reapplying active Wi-Fi connection; the link may drop briefly.\n'
  while IFS=: read -r conn type; do
    [[ ${type} == 802-11-wireless ]] || continue
    nmcli connection up "$conn" >/dev/null
  done < <(nmcli -t -f NAME,TYPE connection show --active)
else
  apply_runtime off
  printf 'Applied runtime power save off without reconnecting.\n'
fi

dev=$(nmcli -t -f DEVICE,TYPE device status | awk -F: '$2 == "wifi" { print $1; exit }')
if [[ -n ${dev} ]] && command -v iwconfig >/dev/null 2>&1; then
  iwconfig "$dev" 2>/dev/null | grep -q 'Power Management:off' \
    || printf 'warning: %s still reports power management on\n' "$dev" >&2
fi

printf 'Installed %s\n' "$dest"
printf 'Undo with: %s/uninstall.sh\n' "$repo_dir"
