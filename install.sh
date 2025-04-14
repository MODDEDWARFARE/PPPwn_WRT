#!/bin/sh

TARGET_DIR="/"
THRESHOLD_MB=16

AVAILABLE_MB=$(df -m "$TARGET_DIR" | awk 'NR==2 {print $4}')

if [ "$AVAILABLE_MB" -lt "$THRESHOLD_MB" ]; then
    echo "\033[31mWARNING: \033[0mYou have less than the recommended storage capacity available."
    echo "To preserve space, do not enable additional options like the web panel and GoldHEN detection."
else
    echo -e "\r\n\r\nAvailable storage is sufficient: \033[32m${AVAILABLE_MB}MB \033[0mavailable."
fi

# Wait for DNS resolution
DNS_CHECK_HOST="one.one.one.one"
MAX_WAIT=60
WAIT_INTERVAL=2
ELAPSED=0

echo "Waiting for network/DNS to be available..."

while ! ping -c 1 -W 1 "$DNS_CHECK_HOST" >/dev/null 2>&1; do
    sleep "$WAIT_INTERVAL"
    ELAPSED=$((ELAPSED + WAIT_INTERVAL))
    if [ "$ELAPSED" -ge "$MAX_WAIT" ]; then
        echo "Network not available after $MAX_WAIT seconds. Exiting..."
        exit 1
    fi
done

echo "Network is available. Continuing installation..."


opkg update || { echo "opkg update failed"; exit 1; }
opkg install coreutils-timeout

# Remove previous install
rm -r PPPwn_WRT-main

# Create working directory
mkdir PPPwn_WRT-main
if [ $? -ne 0 ]; then
    echo "Failed to create directory PPPwn_WRT-main"
    exit 1
fi

cd PPPwn_WRT-main
if [ $? -ne 0 ]; then
    echo "Failed to change to directory PPPwn_WRT-main"
    exit 1
fi

#Add services
ppwnpath="$(cd "$(dirname "$0")" && pwd)"
echo '#!/bin/sh /etc/rc.common

START=99
USE_PROCD=1

start_service() {
    export NODE_ENV=production

    procd_open_instance
    procd_set_param command '"${ppwnpath}"'/dtlink.sh
    procd_close_instance
}

stop_service() {
    echo "Stopping PPPwn service..."
    PIDS=$(pgrep -f "'"${ppwnpath}"'/dtlink.sh")

    # Check if there are any matching processes
    if [ -n "$PIDS" ]; then
       #echo "Terminating the following process IDs for run.sh: $PIDS"

    # Terminate each process
    for PID in $PIDS; do
        kill "$PID"
    done
    fi

}' | tee /etc/init.d/dtlink

echo '#!/bin/sh /etc/rc.common

START=99  # Start late in the boot process

USE_PROCD=1 

start_service() {
    export NODE_ENV=production

    procd_open_instance
    procd_set_param command '"${ppwnpath}"'/run.sh
    procd_close_instance
}

stop_service() {
    echo "Stopping PPPwn service..."

    PIDS=$(pgrep -f "'"${ppwnpath}"'/run.sh")

    # Check if there are any matching processes
    if [ -n "$PIDS" ]; then
       #echo "Terminating the following process IDs for run.sh: $PIDS"
    
    # Terminate each process
    for PID in $PIDS; do
        kill "$PID"
    done
    fi
}'| tee /etc/init.d/pppwn


echo '#!/bin/sh
XFWAP="5"
XFGD="4"
XFBS="0"
XFNWB=true' | tee pconfig.cfg



# Download scripts
wget https://github.com/MODDEDWARFARE/PPPwn_WRT/raw/main/run.sh
if [ $? -ne 0 ]; then
    echo "Failed to download run.sh"
    exit 1
fi

wget https://github.com/MODDEDWARFARE/PPPwn_WRT/raw/main/kill.sh
if [ $? -ne 0 ]; then
    echo "Failed to download kill.sh"
    exit 1
fi

wget https://github.com/MODDEDWARFARE/PPPwn_WRT/raw/main/dtlink.sh
if [ $? -ne 0 ]; then
    echo "Failed to download dtlink.sh"
    exit 1
fi


# Choose script based on architecture
machine_arch=$(uname -m)
case "$machine_arch" in
    *arch64*)
        wget https://github.com/MODDEDWARFARE/PPPwn_WRT/raw/main/pppwn_arch64
        if [ $? -ne 0 ]; then
            echo "Failed to download pppwn_arch64"
            exit 1
        fi
        chmod +x pppwn_arch64
        ;;
    *armv7*)
        wget https://github.com/MODDEDWARFARE/PPPwn_WRT/raw/main/pppwn_armv7
        if [ $? -ne 0 ]; then
            echo "Failed to download pppwn_armv7"
            exit 1
        fi
        chmod +x pppwn_armv7
        ;;
    *x86_64*)
        wget https://github.com/MODDEDWARFARE/PPPwn_WRT/raw/main/pppwn_x86_64
        if [ $? -ne 0 ]; then
            echo "Failed to download pppwn_x86_64"
            exit 1
        fi
        chmod +x pppwn_x86_64
        ;;
    *mips*)
        opkg install lscpu
        BYTE_ORDER=$(lscpu | grep "Byte Order" | awk '{print $3, $4}')
        if [ "$BYTE_ORDER" = "Big Endian" ]; then
            wget https://github.com/MODDEDWARFARE/PPPwn_WRT/raw/main/pppwn_mips
            if [ $? -ne 0 ]; then
                echo "Failed to download pppwn_mips"
                exit 1
            fi
            chmod +x pppwn_mips
        else
            wget https://github.com/MODDEDWARFARE/PPPwn_WRT/raw/main/pppwn_mipsel
            if [ $? -ne 0 ]; then
                echo "Failed to download pppwn_mipsel"
                exit 1
            fi
            chmod +x pppwn_mipsel
        fi
        ;;
    *)
        echo "Unsupported architecture: $machine_arch"
        exit 1
        ;;
esac

firmware_list="9.00 9.03 9.60 10.00 10.01 10.50 10.70 10.71 11.00"

while true; do
    echo
    echo "Firmware:"
    echo "
1) 9.00
2) 9.03
3) 9.60
4) 10.00
5) 10.01
6) 10.50
7) 10.70
8) 10.71
9) 11.00"

    read -p "$(printf '\r\n\033[36mSelect your PS4 firmware (by number): \033[0m')" selection

    if echo "$selection" | grep -qE '^[1-9]$'; then
        set -- $firmware_list
        firmware_version=$(eval echo \$$selection)
        firmware_numeric=${firmware_version//./}

        echo "Selected firmware: $firmware_version (numeric: $firmware_numeric)"

        # Download stage1 and stage2
        wget https://github.com/MODDEDWARFARE/PPPwn_WRT/raw/main/stage1_${firmware_numeric}.bin
        if [ $? -ne 0 ]; then
            echo "Failed to download stage1_${firmware_numeric}.bin"
            exit 1
        fi

        wget https://github.com/MODDEDWARFARE/PPPwn_WRT/raw/main/stage2_${firmware_numeric}.bin
        if [ $? -ne 0 ]; then
            echo "Failed to download stage2_${firmware_numeric}.bin"
            exit 1
        fi

        break
    else
        printf "Please select a valid number from the list\n"
    fi
done

# Network Interface
while true; do
    echo
    echo "Available Interfaces:"
    
        ip link | awk -F: '/^[0-9]+:/ {gsub(/^[ \t]+|[ \t]+$/, "", $2); print NR ": " $2}' | tee iface.txt

        read -p "$(printf '\r\n\033[36mRecommended interface is br-lan. Select your network interface (by number): \033[0m ')" iface
    
        if grep -q "^$iface:" iface.txt; then
            network_interface=$(grep "^$iface:" iface.txt | awk '{print $2}')
            echo -e '\033[32mSelected interface: \033[0m' $network_interface
            rm -r iface.txt
            break
        else
            echo "Please enter a valid number"
        fi
done

# LAN Ports for PPPoE
echo
echo "Select the LAN port your PS4 will be connected to."

# Temporary files
available_ports_file="available_lan_ports.txt"
selected_ports_file="lan_ports.txt"

lan_ports=$(awk '/^config device$/ {
    getline next_line
    if (next_line ~ /option name .*'${network_interface}'/) {
        while (getline > 0) {
            if ($1 == "list" && $2 == "ports") {
                print $3
            }
            if ($1 == "config") break
        }
    }
}' /etc/config/network)

if [ -z "$lan_ports" ]; then
    echo "Error: No LAN ports found in /etc/config/network under 'config device' with 'option name ${network_interface}'."
    exit 1
fi

echo "$lan_ports" > "$available_ports_file"
: > "$selected_ports_file"

# Select LAN ports
while true; do

    if [ ! -s "$available_ports_file" ]; then
        echo "No LAN ports left to select."
        break
    fi

    echo "Available LAN ports:"
    count=1
    while read -r port; do
        echo "$count: $port"
        count=$((count + 1))
    done < "$available_ports_file"

    while true; do
        read -p "$(printf '\r\n\033[36mSelect a LAN port (Enter the number): \033[0m')" lanp

        total_ports=$(wc -l < "$available_ports_file")
        if [ "$lanp" -ge 1 ] 2>/dev/null && [ "$lanp" -le "$total_ports" ]; then
            selected_port=$(sed -n "${lanp}p" "$available_ports_file")
            echo "$selected_port" >> "$selected_ports_file"

            sed -i "${lanp}d" "$available_ports_file"

            echo -e "\033[32mSelected LAN port: \033[0m$selected_port"
            echo
            break
        else
            echo "Invalid selection. Please enter a valid number."
        fi
    done

    read -p "$(printf '\033[36mAdd another LAN port so devices can connect for FTP, BinLoader and other network features? (Y/N): \033[0m')" add_more
    case "$add_more" in
        [Yy]*) ;;
        *) break ;;
    esac
done

echo "Selected LAN ports:"
cat "$selected_ports_file"

#------------------------------- network config -------------------------------#

original_network_file="/etc/config/network"
modified_network_file="./network"

if [ ! -f "$original_network_file" ]; then
    echo "Error: Original network file not found at $original_network_file."
    exit 1
fi
if [ ! -f "$selected_ports_file" ]; then
    echo "Error: Selected ports file not found. Run the selection script first."
    exit 1
fi

selected_ports=$(awk '{gsub(/'\''/, ""); print}' "$selected_ports_file")

# Modify the network file
awk -v selected_ports="$selected_ports" '
    BEGIN {
        split(selected_ports, ports_to_remove, " ")
    }
    /^config device$/ {
        print  # Print the `config device` line
        getline
        if ($1 == "option" && $2 == "name" && $3 == "'\'"${network_interface}"\''") {
            print  # Print the `option name` line
            while (getline) {
                if ($1 == "list" && $2 == "ports") {
                    # Check if the current port is in the ports_to_remove array
                    to_remove = 0
                    for (i in ports_to_remove) {
                        if ($3 == "'"'"'" ports_to_remove[i] "'"'"'") {
                            to_remove = 1
                            break
                        }
                    }
                    if (to_remove) {
                        # Skip this `list ports` line
                        continue
                    }
                }
                # Print the rest of the block
                if ($1 == "config") {
                    print
                    break
                }
                print
            }
        }
        next  # Skip further processing of this block
    }
    { print }  # Print all other lines
' "$original_network_file" > "$modified_network_file"

{
    echo ""
    echo "config device"
    echo "        option name 'ps4'"
    echo "        option type 'bridge'"
    while read -r port; do
        port=$(echo "$port" | tr -d "'")
        echo "        list ports '$port'"
    done < "$selected_ports_file"

    echo ""
    echo "config interface 'pppwn'"
    echo "        option proto 'none'"
    echo "        option device 'ps4'"
} >> "$modified_network_file"

cp $modified_network_file $original_network_file
echo "Modified network file"
rm -r available_lan_ports.txt
rm -r ./network

#------------------------------- firewall config -------------------------------#

CONFIG_FILE="/etc/config/firewall"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: $CONFIG_FILE does not exist."
    exit 1
fi

TMP_FILE="${CONFIG_FILE}.tmp"

in_lan_zone=0
line_inserted=0

while IFS= read -r line || [ -n "$line" ]; do
    if echo "$line" | grep -q "^[[:space:]]*option name 'lan'"; then
        in_lan_zone=1
    fi

    if [ $in_lan_zone -eq 1 ] && echo "$line" | grep -q "^[[:space:]]*list network 'lan'"; then
        if [ $line_inserted -eq 0 ]; then
            echo "	list device 'ppp+'" >> "$TMP_FILE"
            line_inserted=1
        fi
    fi

    echo "$line" >> "$TMP_FILE"

    if [ $in_lan_zone -eq 1 ] && [ -z "$line" ]; then
        in_lan_zone=0
    fi
done < "$CONFIG_FILE"

mv "$TMP_FILE" "$CONFIG_FILE"

chmod 600 "$CONFIG_FILE"

if [ $line_inserted -eq 1 ]; then
    echo "Successfully updated $CONFIG_FILE."
else
    echo "No changes made. 'lan' zone not found or already updated."
fi

# Select LAN ports
while true; do

    if [ ! -s "$available_ports_file" ]; then
        echo "No LAN ports left to select."
        break
    fi

    echo "Available LAN ports:"
    count=1
    while read -r port; do
        echo "$count: $port"
        count=$((count + 1))
    done < "$available_ports_file"

    while true; do
        read -p "$(printf '\r\n\033[36mSelect a LAN port (Enter the number): \033[0m')" lanp

        total_ports=$(wc -l < "$available_ports_file")
        if [ "$lanp" -ge 1 ] 2>/dev/null && [ "$lanp" -le "$total_ports" ]; then
            selected_port=$(sed -n "${lanp}p" "$available_ports_file")
            echo "$selected_port" >> "$selected_ports_file"

            sed -i "${lanp}d" "$available_ports_file"

            echo -e "\033[32mSelected LAN port: \033[0m$selected_port"
            echo
            break
        else
            echo "Invalid selection. Please enter a valid number."
        fi
    done

    read -p "$(printf '\033[36mAdd another LAN port so devices can connect for FTP, BinLoader and other network features? (Y/N): \033[0m')" add_more
    case "$add_more" in
        [Yy]*) ;;
        *) break ;;
    esac
done

# Timeout
while true; do
    echo
    echo "Timeout:"   
    echo "
1) 1 minutes
2) 2 minutes
3) 3 minutes
4) 4 minutes
5) 5 minutes"

    read -p "$(printf '\r\n\033[36mSet timeout value to restart PPPwn if it hangs (5 is default): \033[0m ')" timer
    case "$timer" in
        [1|2|3|4|5|])
            echo -e "\033[32m$timer minute timeout set\033[0m"
            timeout=$((timer * 60))
            break;;
        *)
            printf "Please select a valid number from the list"
            ;;
        esac
done

# Internet Passthrough
echo

        opkg install rp-pppoe-server rp-pppoe-common
        if [ $? -ne 0 ]; then
            echo "Failed to install rp-pppoe-server"
            exit 1
        fi

        while true; do
            read -p "$(printf '\r\n\r\n\033[36mDo you want to change the default subnet?\r\nif you select no then these defaults will be used\r\n\r\nGateway: \033[33m192.168.3.1\r\n\033[36mPS4 IP: \033[33m192.168.3.11\r\n\033[36mGuest IP: \033[33m192.168.3.12\033[33m\r\n\r\n\033[36m(Y|N)?: \033[0m')" pppoecred
            case "$pppoecred" in
            [Yy])
                #Gateway
                while true; do
                    read -p "$(printf '\r\n\r\n\033[36mEnter new gateway (192.168.x.x): \033[0m')" gateway
                    if echo "$gateway" | grep -Eq '^192\.168\.[0-9]{1,3}\.[0-9]{1,3}$'; then

                        third_octet=$(echo "$gateway" | cut -d. -f3)
                        fourth_octet=$(echo "$gateway" | cut -d. -f4)
                    
                        if [ "$third_octet" -ge 1 ] 2>/dev/null && [ "$third_octet" -le 254 ] 2>/dev/null && \
                        [ "$fourth_octet" -ge 1 ] 2>/dev/null && [ "$fourth_octet" -le 254 ] 2>/dev/null; then

                            remoteip=$(echo "$gateway" | awk -F'.' '{ $4 = $4 + 1; print $1"."$2"."$3"."$4 }')
                            # Prompt for static IP
                            while true; do
                                read -p "$(printf '\r\n\r\n\033[36mEnter the last digit for the PS4 IP (1-254): \033[0m')" static_octet

                                if [ "$static_octet" -ge 1 ] 2>/dev/null && [ "$static_octet" -le 254 ] 2>/dev/null; then
                                    static_ip="192.168.${third_octet}.${static_octet}"
                                    echo "PS4 IP set to: $static_ip"
                                    ps4ip="$static_ip"
                                    break
                                else
                                    echo "Invalid number. Please enter a number between 1 and 254."
                                fi
                            done
                            # Prompt for guest IP
                            while true; do
                                read -p "$(printf '\r\n\r\n\033[36mEnter the last digit for the guest IP (1-254): \033[0m')" static_octet

                                if [ "$static_octet" -ge 1 ] 2>/dev/null && [ "$static_octet" -le 254 ] 2>/dev/null; then
                                    static_ip="192.168.${third_octet}.${static_octet}"
                                    echo "PS4 IP set to: $static_ip"
                                    guestip="$static_ip"
                                    break
                                else
                                    echo "Invalid number. Please enter a number between 1 and 254."
                                fi
                            done
                            break
                        else
                            echo "Invalid format. Please enter an address in the format 192.168.x.x where x is 1-254."
                    fi
                    else
                        echo "Invalid format. Please enter an address in the format 192.168.x.x where x is 1-254."
                    fi
                done
            break;;
            [Nn])                
                gateway="192.168.3.1"
                remoteip="192.168.3.2"
                ps4ip="192.168.3.11"
                guestip="192.168.3.12"
                break;;
            *)
            break;;
            esac
        done
        dns_server=$(ifconfig $network_interface | grep 'inet addr' | awk -F: '{print $2}' | awk '{print $1}')
        echo '# PPP options for the PPPoE server
# LIC: GPL
require-chap
login
lcp-echo-interval 10
lcp-echo-failure 2
mru 1492
mtu 1492

ms-dns '"${gateway}"'' | tee /etc/ppp/pppoe-server-options

echo 'config pppoe_server
	option ac_name 'access-concentrator-name'
	list service_name 'service-name1'
	list service_name 'service-name2'
	option maxsessionsperpeer '0'
	option localip '${gateway}'
	option firstremoteip '${remoteip}'
	option maxsessions '64'
	option optionsfile '/etc/ppp/pppoe-server-options'
	option randomsessions '1'
	option unit '0'
	option offset '0'
	option timeout '60'
	option mss '1468'
	option sync '0'
	option interface 'pppwn'

config pppoe_relay
	list server_interface 'eth1'
	list client_interface 'eth0'
	list both_interface 'eth2'
	option maxsessions '64'
	option timeout '60'' | tee /etc/config/pppoe

        while true; do
        read -p "$(printf '\r\n\r\n\033[36mDo you want to change the PPPoE username and password?\r\nif you select no then these defaults will be used\r\n\r\nUsername: \033[33mppp\r\n\033[36mPassword: \033[33mppp\r\n\r\n\033[36mGuest Username: \033[33mguest\r\n\033[36mPassword: \033[33mppp\r\n\r\n\033[36m(Y|N)?: \033[0m')" ppp_cred
        case "$ppp_cred" in
        [Yy])
            #Username
            while true; do
                read -p "$(printf '\n\033[33mEnter Username: \033[0m')" pppusr
                case "$pppusr" in
                    "" )
                        printf '\033[33mCannot be empty!\033[0m';;
                    * )
                    if echo "$pppusr" | grep -q '^[0-9a-zA-Z_ -]*$'; then
                        if [ ${#pppusr} -le 1 ]  || [ ${#pppusr} -ge 33 ] ; then
                            printf '\033[31mUsername must be between 2 and 32 characters long\033[0m';
                        else 
                            break;
                        fi
                    else
                        printf '\033[31mUsername must only contain alphanumeric characters\033[0m';
                    fi
                esac
            done
            #Password
            while true; do
                read -p "$(printf '\033[33mEnter password: \033[0m')" pppw
                case $pppw in
                    "" ) 
                        printf '\033[31mCannot be empty!\033[0m';;
                    * )  
                    if [ ${#pppw} -le 1 ]  || [ ${#pppw} -ge 33 ] ; then
                        printf '\033[31mPassword must be between 2 and 32 characters long\033[0m';
                    else 
                        break;
                    fi
                esac
            done
            printf '\033[36mUsing custom settings\r\n\r\nUsername: \033[33m'$pppusr'\r\n\033[36mPassword: \033[33m'$pppw'\r\n\r\n\033[0m'
            break;;
        [Nn])
            printf '\033[36mUsing default settings\033[0m'
            pppusr="ppp"
            pppw="ppp"
            break;;
        *)
            echo "Please enter Y or N."
            ;;
        esac
        done
        echo ''$pppusr'  *  '$pppw'  '$ps4ip'' > /etc/ppp/chap-secrets
        echo 'guest  *  '$pppw'  '$guestip'' >> /etc/ppp/chap-secrets

while true; do
    read -p "$(printf '\r\n\r\n\033[36mWould you like the PS4 to connect to the internet after loading PPPwn? (Y/N): \033[0m')" passthrough
    case "$passthrough" in
        [Yy])            
            pppoeb=true
            printf '\033[32mInternet access permitted\033[0m'
            break;;
        [Nn])
            CUT_IP=$(echo "$gateway" | cut -d '.' -f1-3)
            pppoeb=false
            echo "config rule
        option name 'WANBLOCKER'
        list proto 'all'
        option src 'lan'
        list src_ip '${CUT_IP}.0/24'
        option dest 'wan'
        option target 'REJECT'

" >> /etc/config/firewall
            printf '\033[32mInternet access will be blocked by the firewall\033[0m'
            break;;
        *)
            echo "Please enter Y or N."
            ;;
    esac
done

# Run on startup
while true; do
    read -p "$(printf '\r\n\r\n\033[36mDo you want to run PPPwn on startup? (Recommended) (Y/N):\033[0m ')" run_on_startup
    case "$run_on_startup" in
    [Yy])
        echo -e "sleep 20\nchmod +x ${ppwnpath}/run.sh && ${ppwnpath}/run.sh" > /etc/rc.local
        printf '\033[32mPPPwn will be loaded on startup\033[0m'
        startup=true
        break;;
    [Nn])
        printf '\033[32mPPPwn will NOT be loaded on startup\033[0m'
        startup=false
        break;;
    *)
        echo "Please enter Y or N."
        ;;
    esac
done


# Dtlink
echo
while true; do
    read -p "$(printf '\r\n\r\n\033[36mDo you want to detect a console shutdown and relaunch PPPwn? (Recommended) (Y/N):\033[0m ')" dtlink
    case "$dtlink" in
        [Yy])
            dtl="true"
            dtlan=$(sed -n '1p' lan_ports.txt | tr -d "'\"")
            rm -r lan_ports.txt
            printf '\033[32mDevice will attempt to detect console shutdown\033[0m'
            break;;
        [Nn])
            dtl="false"
            printf '\033[32mDevice will NOT attempt to detect console shutdown\033[0m'
            break;;
        *)
            echo "Please enter Y or N."
            ;;
    esac
done

# GoldHEN Detection
AVAILABLE_MB=$(df -m "$TARGET_DIR" | awk 'NR==2 {print $4}')
echo
echo -e "\r\n\r\n${AVAILABLE_MB}MB available."
if [ "$AVAILABLE_MB" -lt "$THRESHOLD_MB" ]; then
    printf "\033[31mWARNING: \033[0mYou have less than the recommended storage capacity available."
    echo "To preserve space, do not enable additional options like the web panel and GoldHEN detection."
fi
while true; do
    read -p "$(printf '\r\n\r\n\033[36mEnable GoldHEN detection for rest mode support? (Y/N):\033[0m ')" ghcheck
    case "$ghcheck" in
        [Yy])
            opkg install nmap
            ghd="true"
            printf '\033[32mGoldhen detection enabled\033[0m'
            break;;
        [Nn])
            ghd="false"
            printf '\033[32mGoldhen detection disabled\033[0m'
            break;;
        *)
            echo "Please enter Y or N."
            ;;
    esac
done


# Shutdown after
echo
while true; do
    read -p "$(printf '\r\n\r\n\033[36mDo you want to power down the router after PPPwn loads successfully? (Y/N):\033[0m ')" shutdown
    case "$shutdown" in
        [Yy])
            echo ""
            printf '\033[31mWARNING If anything is misconfigured then enabling this feature along with run on startup could cause a boot loop\n\033[0m'
            while true; do
                read -p  "Are you sure you want to enable this feature? (Y/N): " bootloop
                case "$bootloop" in
                    [Yy])
                        printf '\033[32mDevice will shutdown after PPPwn\033[0m'
                        echo "poweroff" >> run.sh
                        break;;
                    [Nn])
                        printf '\033[32mDevice will NOT shutdown after PPPwn\033[0m'
                        break;;
                    *)
                        echo "Please enter Y or N."
                        ;;
                esac
            done
            ;;
        [Nn])
            printf '\033[32mDevice will NOT shutdown after PPPwn\033[0m'
            break;;
        *)
            echo "Please enter Y or N."
            ;;
    esac
done

# Web server
AVAILABLE_MB=$(df -m "$TARGET_DIR" | awk 'NR==2 {print $4}')
echo
echo -e "\r\n\r\n${AVAILABLE_MB}MB available."
if [ "$AVAILABLE_MB" -lt "$THRESHOLD_MB" ]; then
    printf "\033[31mWARNING: \033[0mYou have less than the recommended storage capacity available."
    echo "To preserve space, do not enable additional options like the web panel and GoldHEN detection."
fi
while true; do
    read -p "$(printf '\r\n\r\n\033[36mWould you like to enable a web panel to load payloads & adjust settings? (Y/N):\033[0m ')" webpanel
    case "$webpanel" in
        [Yy])

            # download web panel
            wget https://github.com/MODDEDWARFARE/PPPwn_WRT/raw/main/index.php
            if [ $? -ne 0 ]; then
                echo "Failed to download index.php"
                #exit 1
            fi
            wget https://github.com/MODDEDWARFARE/PPPwn_WRT/raw/main/pconfig.php
            if [ $? -ne 0 ]; then
                echo "Failed to download pconfig.php"
                #exit 1
            fi
            wget https://github.com/MODDEDWARFARE/PPPwn_WRT/raw/main/network.php
            if [ $? -ne 0 ]; then
                echo "Failed to download network.php"
                #exit 1
            fi
            wget https://github.com/MODDEDWARFARE/PPPwn_WRT/raw/main/payloads.php
            if [ $? -ne 0 ]; then
                echo "Failed to download payloads.php"
                #exit 1
            fi

            #required pkgs
            opkg install nginx php8-fastcgi php8-fpm

            #configure nginx
            echo 'user root;

events {}

http {

    server {
        listen 8080 default_server;
        listen [::]:8080 default_server;
        root '"${ppwnpath}"';
        index index.html index.htm index.php;

        server_name _;

        location / {
            try_files $uri $uri/ =404;
        }

        error_page 404 = @mainindex;
        location @mainindex {
            return 302 /;
        }

        location ~ \.php$ {
            include fastcgi_params;
            fastcgi_split_path_info ^(.+\.php)(/.+)$;
            fastcgi_pass unix:/var/run/php8-fpm.sock;
            fastcgi_index index.php;
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        }
    }
}

            ' | tee /etc/nginx/uci.conf.template

        #php permissions

        CONFIG_FILE="/etc/php8-fpm.d/www.conf"
        INIT_FILE="/etc/init.d/php8-fpm"
        PHP_FILE="/etc/php.ini"

        sed -i 's|^doc_root = "/www"|doc_root = "'"$ppwnpath"'"|' "$PHP_FILE"
        sed -i 's/^user = nobody$/user = root/' "$CONFIG_FILE"
        sed -i 's/service_start \$PROG -y \$CONFIG -g \$SERVICE_PID_FILE/service_start \$PROG -R -y \$CONFIG -g \$SERVICE_PID_FILE/' "$INIT_FILE"

        if grep -q 'service_start \$PROG -R -y \$CONFIG -g \$SERVICE_PID_FILE' "$INIT_FILE"; then
            echo "Successfully updated the php service"
        else
            echo "Failed to update the service"
            exit 1
        fi
        printf '\033[32mWeb Panel will be accessible via pppwn.local:8080 or '"${gateway}"':8080\033[0m'
            #install payloads
            AVAILABLE_MB=$(df -m "$TARGET_DIR" | awk 'NR==2 {print $4}')
            echo
            echo -e "\r\n\r\n${AVAILABLE_MB}MB available."
            if [ "$AVAILABLE_MB" -lt "$THRESHOLD_MB" ]; then
                echo "WARNING: You have less than the recommended storage capacity available."
                echo "To preserve space, do not enable additional options like the web panel and GoldHEN detection."
            fi
            while true; do
                read -p "$(printf '\r\n\r\n\033[36mDownload bin loader payloads? (Y/N):\033[0m ')" payloads
                case "$payloads" in
                [Yy])        
                    mkdir payloads
                    wget --no-check-certificate -O PS4-Payloads.zip "https://github.com/EchoStretch/ps4-payload-sdk/releases/download/PS4-Payloads-1.018/PS4-Payloads.zip"
                    if [ $? -ne 0 ]; then
                        echo "Failed to download PS4-Payloads"
                    fi
                    opkg install unzip
                    unzip -o PS4-Payloads.zip
                    rm -f PS4-Payloads.zip
                    break;;
                [Nn])
                    break;;
                *)
                    echo "Please enter Y or N."
                    ;;
                esac
            done
            break;;
        [Nn])
            printf '\033[32mWeb Panel will NOT be used\033[0m'
            break;;
        *)
            echo "Please enter Y or N."
            ;;
    esac
done

# LuCi app commands
AVAILABLE_MB=$(df -m "$TARGET_DIR" | awk 'NR==2 {print $4}')
echo
echo -e "\r\n\r\n${AVAILABLE_MB}MB available."
if [ "$AVAILABLE_MB" -lt "$THRESHOLD_MB" ]; then
    printf "\033[31mWARNING: \033[0mYou have less than the recommended storage capacity available."
    echo "To preserve space, do not attempt to install the payloads"
fi
while true; do
    read -p "$(printf '\r\n\r\n\033[36mDo you also want to run PPPwn from the LuCi web interface? (Y/N):\033[0m ')" app_commands
    case "$app_commands" in
        [Yy])
            opkg install luci-app-commands
            if [ $? -ne 0 ]; then
                echo "Failed to install luci-app-commands"
                exit 1
            fi
            echo -e "\nconfig command\n    option name 'PPPwn PS4'\n    option command '${ppwnpath}/run.sh'" | tee -a /etc/config/luci > /dev/null
            printf '\033[32mPPPwn will be accessible from the web interface\033[0m'
            break;;
        [Nn])
            printf '\033[32mPPPwn will not be accessible from the web interface\033[0m'
            break;;
        *)
            echo "Please enter Y or N."
            ;;
    esac
done

#LED
echo
while true; do
    read -p "$(printf '\r\n\r\n\033[36mDo you want to use the devices LED(s) to indicate when PPPwn is running? (Y/N): \033[0m ')" activeled
    case "$activeled" in
        [Yy])
            echo
            echo "Available LED options:"
            count=1
            > led_list.tmp
            for led in $(ls /sys/class/leds); do
                echo "$count: $led"
                echo "$led" >> led_list.tmp
                count=$((count + 1))
            done
            echo "$count: none"
            echo "none" >> led_list.tmp
            count=$((count + 1))
            echo

            while true; do
                read -p "$(printf '\r\n\r\n\033[36mEnter the number corresponding to the LED you want to select: \033[0m ')" choice

                if [ "$choice" -ge 1 ] 2>/dev/null && [ "$choice" -lt "$count" ]; then
                    led_info=$(sed -n "${choice}p" led_list.tmp)
                    echo -e "${led_info} \033[32mwill be used \033[0m"
                    break
                else
                    printf "Invalid selection. Please enter a number between 1 and $((count - 1))."
                fi
            done
            rm -f led_list.tmp
            break;;
        [Nn])
            led_info="none"
            echo -e '\033[32mLED Disabled\033[0m'
            break;;
        *)
            echo "Please enter Y or N."
            ;;
    esac
done

#rc.button
cp -r /etc/rc.button rc.button
echo
while true; do
    read -p "$(printf '\r\n\r\n\033[36mDo you want the option to load PPPwn by pressing a button on your device? (Y/N): \033[0m ')" btnpromt
    case "$btnpromt" in
        [Yy])

            echo
            echo "Available buttons:"
            count=1
            > btn_list.tmp
            for btn in $(ls /etc/rc.button); do
                echo "$count: $btn"
                echo "$btn" >> btn_list.tmp
                count=$((count + 1))
            done
            echo "$count: none"
            echo "none" >> btn_list.tmp
            count=$((count + 1))
            echo

            while true; do
                read -p "$(printf '\r\n\r\n\033[36mSelect a button on your device to overwrite (Enter number): \033[0m ')" choice

                if [ "$choice" -ge 1 ] 2>/dev/null && [ "$choice" -lt "$count" ]; then
                    btn_info=$(sed -n "${choice}p" btn_list.tmp)
                    printf "$btn_info \033[32mwill be used\033[0m"
                    break
                else
                    printf "Invalid selection. Please enter a number between 1 and $((count - 1))."
                fi
            done

            rm -f btn_list.tmp

            INPUT_FILE="/etc/rc.button/${btn_info}"
            echo '#!/bin/sh

        if [ "$ACTION" = "released" ] && [ "$BUTTON" = "'$btn_info'" ]; then
            chmod +x ' $ppwnpath'/run.sh && '$ppwnpath'/run.sh
        fi

        return 0' > /etc/rc.button/${btn_info}
            break;;
        [Nn])
            printf '\033[32mButton Disabled\033[0m'
            break;;
        *)
            echo "Please enter Y or N."
            ;;
    esac
done

# DNS config
CONFIG_FILE="/etc/config/dhcp"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: $CONFIG_FILE does not exist."
    exit 1
fi

TMP_FILE="${CONFIG_FILE}.tmp"

in_dnsmasq_section=0
in_lan_dhcp_section=0
listen_address_inserted=0
interface_modified=0

while IFS= read -r line || [ -n "$line" ]; do

    if echo "$line" | grep -q "^config dnsmasq"; then
        in_dnsmasq_section=1
    fi

    if [ $in_dnsmasq_section -eq 1 ] && [ $listen_address_inserted -eq 0 ] && [ -z "$line" ]; then
        echo "        list listen_address '$gateway'" >> "$TMP_FILE"
        echo "        list listen_address '$dns_server'" >> "$TMP_FILE"
        echo "        list listen_address '127.0.0.1'" >> "$TMP_FILE"
        listen_address_inserted=1
    fi

    if [ $in_dnsmasq_section -eq 1 ] && [ -z "$line" ]; then
        in_dnsmasq_section=0
    fi

    echo "$line" >> "$TMP_FILE"

    if [ $in_lan_dhcp_section -eq 1 ] && [ -z "$line" ]; then
        in_lan_dhcp_section=0
    fi

done < "$CONFIG_FILE"

    echo "config dhcp 'ppp0'
            option interface 'ppp0'  # Separate PPPoE settings
            option ignore '1'" >> "$TMP_FILE"

mv "$TMP_FILE" "$CONFIG_FILE"

chmod 600 "$CONFIG_FILE"

if [ $listen_address_inserted -eq 1 ] || [ $interface_modified -eq 1 ]; then
    printf "\nSuccessfully updated $CONFIG_FILE."
else
    echo "No changes made. Relevant sections not found or already updated."
fi

# DNS blocker
DHCP_CONFIG="/etc/config/dhcp"

NEW_ENTRIES="
    list server '/ea.com/127.0.0.1'
    list address '/ea.com/127.0.0.1'
    list server '/nintendo.net/127.0.0.1'
    list address '/nintendo.net/127.0.0.1'
    list server '/cddbp.net/127.0.0.1'
    list address '/cddbp.net/127.0.0.1'
    list server '/ribob01.net/127.0.0.1'
    list address '/ribob01.net/127.0.0.1'
    list server '/sonyentertainmentnetwork.com/127.0.0.1'
    list address '/sonyentertainmentnetwork.com/127.0.0.1'
    list server '/llnwi.net/127.0.0.1'
    list address '/llnwi.net/127.0.0.1'
    list server '/sie-rd.com/127.0.0.1'
    list address '/sie-rd.com/127.0.0.1'
    list server '/scea.com/127.0.0.1'
    list address '/scea.com/127.0.0.1'
    list server '/llnwd.net/127.0.0.1'
    list address '/llnwd.net/127.0.0.1'
    list server '/edgesuite.net/127.0.0.1'
    list address '/edgesuite.net/127.0.0.1'
    list server '/edgekey.net/127.0.0.1'
    list address '/edgekey.net/127.0.0.1'
    list server '/akamaiedge.net/127.0.0.1'
    list address '/akamaiedge.net/127.0.0.1'
    list server '/akamai.net/127.0.0.1'
    list address '/akamai.net/127.0.0.1'
    list server '/akadns.net/127.0.0.1'
    list address '/akadns.net/127.0.0.1'
    list server '/playstation.org/127.0.0.1'
    list address '/playstation.org/127.0.0.1'
    list server '/playstation.net/127.0.0.1'
    list address '/playstation.net/127.0.0.1'
    list server '/playstation.com/127.0.0.1'
    list address '/playstation.com/127.0.0.1'
    list address '/pppwn.local/${gateway}'
    list address '/ps4.local/${ps4ip}'
"

cp "$DHCP_CONFIG" "$DHCP_CONFIG.bak"

if grep -q "config dnsmasq" "$DHCP_CONFIG"; then
  echo "$NEW_ENTRIES" | while IFS= read -r line; do
    if ! grep -qF "$line" "$DHCP_CONFIG"; then
      sed -i "/config dnsmasq/a \    $line" "$DHCP_CONFIG"
    fi
  done
else
  echo "config dnsmasq" >> "$DHCP_CONFIG"
  echo "$NEW_ENTRIES" | while IFS= read -r line; do
    echo "    $line" >> "$DHCP_CONFIG"
  done
fi

service dnsmasq restart
echo
echo "The DHCP configuration updated"


# Write to config
echo '
iface='$network_interface'
dtlan='$dtlan'
fw='$firmware_version'
shutdown=false
pppoe='$pppoeb'
dtl='$dtl'
PPDBG=false
timeout='$timeout'
ghd='$ghd'
led='$led_info'
DDNS=false
oipv=false
path='$ppwnpath'
btn='$btn_info'
ps4ip='$ps4ip'
startup='$startup'
' | tee settings.cfg


# Permissions
chmod +x run.sh
chmod +x kill.sh
chmod +x dtlink.sh
chmod +x /etc/init.d/dtlink
chmod +x /etc/init.d/pppwn

echo
echo -e '\033[32m--Install Complete--\033[0m'
echo 'Connect PS4 to '$dtlan'' 
echo -e '\033[36mRebooting...\033[0m'
reboot