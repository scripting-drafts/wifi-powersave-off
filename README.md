# Wi-Fi power save off (mandatory)

Ubuntu enables Wi-Fi power save in
`/etc/NetworkManager/conf.d/default-wifi-powersave-on.conf`.
This repo installs `zz-wifi-powersave-off.conf`, which sorts after it and
sets `wifi.powersave = 2`.

Install: `sudo ./install.sh` (no reconnect)  
Reapply link: `sudo ./install.sh --reconnect`  
Verify: `iwconfig <wlan> | grep 'Power Management'`
