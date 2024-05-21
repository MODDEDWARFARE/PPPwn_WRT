#!/bin/sh

# KILL PPPwn++ PS4 function
pppwn_ps4_run () {
	return 1
}

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

# Find all PIDs of processes containing 'myprocess' in their command line
pids=$(ps | grep '[./]pppwn' | grep -v grep | awk '{print $1}')

# Check if pids variable is empty
if [ -z "$pids" ]; then
  echo "---"
else
  # Kill each PID found
  echo "$pids" | xargs kill -9
  echo "Killed the following PIDs: $pids"
fi
