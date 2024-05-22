#!/bin/sh

#Disable internet access
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

#Grab our files
opkg install nano luci-app-commands

#Permissions
chmod +x pppwn_arch64
chmod +x pppwn_armv7
chmod +x pppwn_x86_64
chmod +x pppwn_mips
chmod +x run.sh
chmod +x kill.sh
chmod +x stage1_900.bin
chmod +x stage2_900.bin
chmod +x stage1_1100.bin
chmod +x stage2_1100.bin

#Add custom command in LuCi
echo -e "\nconfig command\n    option name 'PPPwn PS4'\n    option command '/root/PPPwn_WRT-main/run.sh'" | tee -a /etc/config/luci > /dev/null
echo

#Select Interface - Function to get list of interfaces
get_interfaces() {
    ip link | awk -F: '$0 !~ "lo|virbr|wl|^[^0-9]"{print $2}' | tr -d ' '
}
#Select Interface - Function to prompt user to select a network interface
select_interface() {
    echo "=== [5/6] INSTALATION 4/5 - SAVE SETTINGS ==="
    ip link
    echo

    while true; do
        read -p "Select your network interface (e.g., br-lan): " network_interface
        if echo "$(get_interfaces)" | grep -qw "$network_interface"; then
            echo "$network_interface" > settings.cfg
            echo "Network interface '$network_interface' saved to settings.cfg"
            break
        else
            echo "[ERROR] Invalid network interface. Please try again."
        fi
    done
}
#Select Interface - Call the function
select_interface
echo

#Select firmware - Function to prompt user to select a valid PS4 firmware
select_firmware() {
    while true; do
        read -p "Select your PS4 firmware (11.00/9.00): " firmware
        if [ "$firmware" = "11.00" ] || [ "$firmware" = "1100" ]; then
            echo "1100" >> settings.cfg
            echo "Firmware 11.00 saved to settings.cfg"
            break
        elif [ "$firmware" = "9.00" ] || [ "$firmware" = "900" ]; then
            echo "Firmware 9.00 saved to settings.cfg"
            echo "900" >> settings.cfg
            break
        else
            echo "[ERROR] Invalid Firmware Selected. Please enter 11.00 or 9.00."
        fi
    done
}
#Select firmware - Call the function
select_firmware
echo

#Run on startup - Function to prompt user to select if PPPwn should run on startup
select_run_on_startup() {
    while true; do
        read -p "Do you want to run PPPwn on startup? (Y/N): " run_on_startup
        run_on_startup=$(echo "$run_on_startup" | awk '{print tolower($0)}')
        if [ "$run_on_startup" = "yes" ] || [ "$run_on_startup" = "y" ]; then
            echo "cd /root/PPPwn_WRT-main && ./run.sh" > /etc/rc.local
            echo "PPPwn will run on startup."
            break
        elif [ "$run_on_startup" = "no" ] || [ "$run_on_startup" = "n" ]; then
            echo "#cd /root/PPPwn_WRT-main && ./run.sh" > /etc/rc.local
            echo "PPPwn will not run on startup."
            break
        else
            echo "Invalid input. Please enter Y or N."
        fi
    done
}
#Run on startup - Call the function
select_run_on_startup
echo

echo "Install complete. Run it with ./run.sh"
