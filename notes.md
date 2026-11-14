# Notes

- Diagnosis: a Telegram call ended while the client process exited; there
  was no coredump, OOM kill, suspend, or Wi-Fi link-down. Signal was
  roughly -71 to -81 dBm on 5 GHz.
- Effective power save came from NetworkManager's global default:
  `/etc/NetworkManager/conf.d/default-wifi-powersave-on.conf`
  (`wifi.powersave = 3`). The active profile had `0 (default)`, so it
  inherited 3. The `iwlwifi` module parameter was already `N`.
- `/etc/NetworkManager/conf.d` is read in lexicographic order, later files
  overriding earlier ones. A `99-` prefix sorts **before** `default-`, so
  it lost. `zz-` sorts after and wins.
- A profile with an explicit `802-11-wireless.powersave` value can still
  override the global default. Check with
  `nmcli -f 802-11-wireless.powersave connection show <name>`.
- Runtime verify with `iwconfig <wlan>` or
  `iw dev <wlan> get power_save` when `iw` is installed.
- Bluetooth HFP `mSBC decoding error` messages are a separate audio-link
  issue; this change only addresses Wi-Fi power save.
