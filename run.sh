#!/bin/sh
interface=$(sed -n '1p' settings.cfg)
firmware_code=$(sed -n '2p' settings.cfg)

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
./kill.sh

# Construct and execute the command with the chosen script
echo "heartbeat" > /sys/class/leds/red:info/trigger
./${script_name} --interface $interface --fw $firmware_code --stage1 ./stage1_$firmware_code.bin --stage2 ./stage2_$firmware_code.bin --auto-retry 
echo "none" > /sys/class/leds/red:info/trigger
echo "default-on" > /sys/class/leds/green:info/trigger
