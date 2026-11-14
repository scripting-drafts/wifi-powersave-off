# Notes

- The Ubuntu file `default-wifi-powersave-on.conf` must stay unchanged at
  `wifi.powersave = 3`; it is a package-owned default. The effective value
  comes from `NetworkManager --print-config`.
- `/etc/NetworkManager/conf.d` is read in lexicographic order, later files
  overriding earlier ones. `zz-wifi-powersave-off.conf` sorts after
  `default-wifi-powersave-on.conf` and sets `wifi.powersave=2`.
- The installer applies runtime `power_save off` through `iw` or
  `iwconfig` without reactivating the connection. Pass `--reconnect` only
  when a full profile reapply is wanted.
- A profile with an explicit `802-11-wireless.powersave` value can still
  override the global default. Check with
  `nmcli -f 802-11-wireless.powersave connection show <name>`.
- Runtime verify with `iwconfig <wlan>` or
  `iw dev <wlan> get power_save` when `iw` is installed.
- Bluetooth HFP `mSBC decoding error` messages are a separate audio-link
  issue; this change only addresses Wi-Fi power save.
