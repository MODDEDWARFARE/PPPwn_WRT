#!/bin/sh

interface=$(sed -n '1p' /root/PPPwn_WRT-main/settings.cfg)
firmware=$(sed -n '2p' /root/PPPwn_WRT-main/settings.cfg)

# Disable WAN and WAN6 interface
ifdown wan && ifdown wan6
# Disable WiFi interface
uci set wireless.radio0.disabled=1
uci set wireless.radio1.disabled=1
# Commit changes
uci commit wireless
# reload WiFI config				
wifi reload
# Commit changes
/etc/init.d/network reload

# capture the output of uname -m
machine_arch=$(uname -m)

# choose script based on the architecture
if echo "$machine_arch" | grep -q "arch64"; then
    script_name="pppwn_arch64"
elif echo "$machine_arch" | grep -q "armv7"; then
    script_name="pppwn_armv7"
elif echo "$machine_arch" | grep -q "x86_64"; then
    script_name="pppwn_x86_64"
elif echo "$machine_arch" | grep -q "mips"; then
    script_name="pppwn_mips"
else
    echo "Unsupported architecture: $machine_arch"
    exit 1
fi

# kill any previous instance
/root/PPPwn_WRT-main/kill.sh

# Construct and execute the command with the chosen script
echo "heartbeat" > /sys/class/leds/red:info/trigger
pppwn_ps4_run () {
	./${script_name} --interface $interface --fw $firmware --stage1 "stage1_$firmware.bin" --stage2 "stage2_$firmware.bin" --auto-retry
}
if pppwn_ps4_run; then 
	# Enable WAN and WAN6 interface
	ifup wan && ifup wan6
	# Enable WiFi interface
	uci set wireless.radio0.disabled=0
	uci set wireless.radio1.disabled=0
	# Commit changes
	uci commit wireless
	# reload WiFI config				
	wifi reload
	# Commit changes
	/etc/init.d/network reload
	echo "[ENABLED] INTERFACE WAN & WAN6 & WIFI"
	echo "YOU HAVE GRANTED ACCESS TO INTERNET"
else
	# Disable WAN and WAN6 interface
	ifdown wan && ifdown wan6
	# Disable WiFi interface
	uci set wireless.radio0.disabled=1
	uci set wireless.radio1.disabled=1
	# Commit changes
	uci commit wireless
	# reload WiFI config				
	wifi reload
	# Commit changes
	/etc/init.d/network reload
	echo "[DISABLED] INTERFACE WAN & WAN6 & WIFI"
	echo "YOU HAVEN'T ACCESS TO INTERNET"
	echo
fi
echo "none" > /sys/class/leds/red:info/trigger
echo "default-on" > /sys/class/leds/green:info/trigger
