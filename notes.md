# Notes

- The Ubuntu file `default-wifi-powersave-on.conf` stays unchanged at
  `wifi.powersave = 3`; it is a package-owned default. The effective value
  comes from `NetworkManager --print-config`.
- `/etc/NetworkManager/conf.d` is read in lexicographic order, later files
  overriding earlier ones. `zz-wifi-powersave-off.conf` sorts after
  `default-wifi-powersave-on.conf` and sets `wifi.powersave=2`.
- Reconnect is mandatory: NetworkManager applies the merged default when
  the Wi-Fi profile is activated. The installer reconnects and verifies
  the runtime state rather than relying on `iwconfig` alone.
- A profile with an explicit `802-11-wireless.powersave` value can still
  override the global default. Check with
  `nmcli -f 802-11-wireless.powersave connection show <name>`.
- Runtime verify with `iwconfig <wlan>` or
  `iw dev <wlan> get power_save` when `iw` is installed.
- Bluetooth HFP `mSBC decoding error` messages are a separate audio-link
  issue; this change only addresses Wi-Fi power save.
