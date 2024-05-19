#!/bin/sh

#Grab our files
opkg install nano luci-app-commands

#Permissions
chmod +x pppwn_arch64
chmod +x pppwn_armv7
chmod +x pppwn_x86_64
chmod +x pppwn_mips
chmod +x run.sh
chmod +x kill.sh

#Add custom command in LuCi
echo -e "\nconfig command\n    option name 'PPPwn PS4'\n    option command '/root/PPPwn_WRT-main/run.sh'" | tee -a /etc/config/luci > /dev/null
echo

#Select Interface
ip link
echo
read -p "Select your network interface i.e: br-lan: " network_interface
echo "$network_interface" > settings.cfg
echo
read -p "Select your PS4 firmware (11.00/9.00): " firmware
if [ "$firmware" = "11.00" ]; then
    echo "1100" >> settings.cfg
elif [ "$firmware" = "9.00" ]; then 
    echo "900" >> settings.cfg
else
    echo "Invalid Firmware Selected"
    exit 1
fi


# Run on startup
echo
read -p "Do you want to run PPPwn on startup? (Y/N): " run_on_startup
if [ "$run_on_startup" = "Y" ] || [ "$run_on_startup" = "y" ]; then
    echo "cd /root/PPPwn_WRT-main && ./run.sh" > /etc/rc.local
fi
echo
echo "Install complete. Run it with ./run.sh"
