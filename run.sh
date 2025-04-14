#!/bin/sh

source "$(cd "$(dirname "$0")" && pwd)/settings.cfg"
source "$(cd "$(dirname "$0")" && pwd)/pconfig.cfg"

if [ -f "${path}/pwn.log" ]; then
   rm -f "${path}/pwn.log"
fi

if [ ! -e "${path}/stage1_${fw//.}.bin" ]; then
    wget https://github.com/MODDEDWARFARE/PPPwn_WRT/raw/main/stage1_${fw//.}.bin -P $path
    if [ $? -ne 0 ]; then
        echo "Failed to download stage1_${fw//.}.bin"
        exit 1
    fi
fi
if [ ! -e "${path}/stage2_${fw//.}.bin" ]; then
    wget https://github.com/MODDEDWARFARE/PPPwn_WRT/raw/main/stage2_${fw//.}.bin -P $path
    if [ $? -ne 0 ]; then
        echo "Failed to download stage2_${fw//.}.bin"
        exit 1
    fi
fi

# Choose script based on the architecture
machine_arch=$(uname -m)
if echo "$machine_arch" | grep -q "arch64"; then
    script_name="pppwn_arch64"
elif echo "$machine_arch" | grep -q "armv7"; then
    script_name="pppwn_armv7"
elif echo "$machine_arch" | grep -q "x86_64"; then
    script_name="pppwn_x86_64"
elif echo "$machine_arch" | grep -q "mips"; then
    if [ -e "${path}/pppwn_mips" ]; then
        script_name="pppwn_mips"
    else
        script_name="pppwn_mipsel"
    fi
else
    echo "Unsupported architecture: $machine_arch"
    exit 1
fi

# GoldHEN Check
if [ "$ghd" = "true" ]; then

    # Check if nmap is installed
    CHECK=$(which nmap)
    if [ "$CHECK" = "" ]; then
        opkg update
        opkg install nmap
    fi

    # wait for linkup
    /etc/init.d/pppoe-server restart
    while true; do
        STATUS=$(nmap -p 3232 $ps4ip | grep "3232/tcp" | cut -f2 -d' ')
        if [ "$STATUS" = "" ]; then            
	        echo "awaiting link"
        else
            echo "link found"
            break
        fi
        sleep 1
    done

    STATUS=$(nmap -p 3232 $ps4ip | grep "3232/tcp" | cut -f2 -d' ')
    
    # GoldHEN present?
    if [ "$STATUS" = "open" ]; then
        printf "\033[33m\nGoldHEN Detected\033[0m\n"
        /etc/init.d/dtlink restart
        exit 0
    fi
fi

/etc/init.d/dtlink stop

if [ "$oipv" = true ]; then
    ipv6='-old'
else
    ipv6=''
fi

if [ "$XFNWB" = true ]; then
    nowait='-nw'
else
    nowait=''
fi

finished=false

ifconfig $dtlan down
sleep 1
ifconfig $dtlan up
sleep 1
/etc/init.d/pppoe-server stop

while [ "$finished" = false ]; do
    printf "\033[33m\nAttempting to execute PPPwn script...\033[0m\n"


    # Ensure no old instances are running
    pkill -f "${path}${script_name}" 2>/dev/null

    if [ "$led" != "none" ] && [ "$led" != "" ]; then
        echo "heartbeat" > /sys/class/leds/${led}/trigger
    fi

    start_time=$(date +%s)  # Capture start time

    # Run the program in the background and direct output to log file
    ( chmod +x "${path}/${script_name}" && \
      "${path}/${script_name}" --interface "ps4" --fw "${fw//.}" \
      --stage1 "${path}/stage1_${fw//.}.bin" --stage2 "${path}/stage2_${fw//.}.bin" \
      -wap "${XFWAP}" -gd "${XFGD}" -bs "${XFBS}" ${nowait} -t 5 \
      ${ipv6} --auto-retry ) > program_output.log 2>&1 &

    program_pid=$!

    fifo_file="/tmp/pppwn_fifo"
    rm -f "$fifo_file"
    mkfifo "$fifo_file"

    # Start tail -F and redirect output to FIFO (background process)
    tail -F program_output.log > "$fifo_file" &
    tail_pid=$!

    while read -r stdo < "$fifo_file"; do
        current_time=$(date +%s)
        elapsed_time=$((current_time - start_time))

        if [ "$PPDBG" = "true" ]; then
            echo -e "$stdo" | tee /dev/tty | tee /dev/pts/* | tee -a "${path}/pwn.log"
        else
            echo -e "$stdo"
        fi

        # Check for completion message
        if [ "$stdo" = "[+] Done!" ]; then
            if [ "$pppoe" = "true" ]; then
                printf "\033[32m\nPPPwn Finished! Starting PPPoE Server...\033[0m\n"
                ifconfig $dtlan down
                sleep 1
                ifconfig $dtlan up
                sleep 1              
                /etc/init.d/pppoe-server start                
            else
                printf "\033[32m\nPPPwn Finished!\033[0m\n"
            fi
            finished=true
            kill "$program_pid" 2>/dev/null  # Ensure the program stops if done
            break
        fi
        # Check timeout condition
        if [ "$elapsed_time" -ge "$timeout" ]; then
            echo "Timeout reached! Terminating program..."
            kill "$program_pid" 2>/dev/null
            break
        fi
    done

    kill "$tail_pid" 2>/dev/null
    rm -f "$fifo_file"

    # Check if the script did not complete successfully (timeout or other failure)
    if [ "$finished" = false ]; then
        printf "\033[31m\nAttempt failed or timed out. Retrying...\033[0m\n"
        sleep 3
    fi
done

if [ "$shutdown" = "true" ]; then
    poweroff
fi

# Kill any lingering tail processes
killall tail 2>/dev/null

# Final cleanup before exiting
if [ "$led" != "none" ] && [ "$led" != "" ]; then
    echo "none" > /sys/class/leds/${led}/trigger
fi

sleep 2
if [ "$dtl" = "true" ]; then
    /etc/init.d/dtlink start
    echo -e "\033[32m\nShutdown detection active\033[0m\n"
fi
