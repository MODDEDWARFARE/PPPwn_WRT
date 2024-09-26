#!/bin/sh

interface=$(sed -n '1p' /root/PPPwn_WRT-main/settings.cfg)
firmware=$(sed -n '2p' /root/PPPwn_WRT-main/settings.cfg)

# kill any previous instance
/root/PPPwn_WRT-main/kill.sh

# Construct and execute the command with the chosen script
echo "heartbeat" > /sys/class/leds/red:info/trigger
/root/PPPwn_WRT-main/pppwn --interface $interface --fw $firmware --auto-retry 
echo "none" > /sys/class/leds/red:info/trigger
echo "default-on" > /sys/class/leds/green:info/trigger

