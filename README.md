# Wi-Fi power save off (mandatory)

Ubuntu's `default-wifi-powersave-on.conf` sets `wifi.powersave = 3`.
This repo's `zz-wifi-powersave-off.conf` sorts after it and sets `2`.
NetworkManager merges both; the later `zz-` value wins.
Install always reapplies the active Wi-Fi connection; the link drops briefly.

Install: `sudo ./install.sh`  
Verify merged: `NetworkManager --print-config | grep wifi.powersave`  
Verify runtime: `iwconfig <wlan> | grep 'Power Management'`
