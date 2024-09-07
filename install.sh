#!/bin/sh

# Create working directory
mkdir PPPwn_WRT-main
if [ $? -ne 0 ]; then
    echo "Failed to create directory PPPwn_WRT-main"
    exit 1
fi

# Change to working directory
cd PPPwn_WRT-main
if [ $? -ne 0 ]; then
    echo "Failed to change to directory PPPwn_WRT-main"
    exit 1
fi

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

# Capture the output of uname -m
machine_arch=$(uname -m)

# Choose script based on the architecture
if echo "$machine_arch" | grep -q "arch64"; then
    wget https://github.com/MODDEDWARFARE/PPPwn_WRT/raw/main/pppwn_arch64
    if [ $? -ne 0 ]; then
        echo "Failed to download pppwn_arch64"
        exit 1
    fi
    chmod +x pppwn_arch64
elif echo "$machine_arch" | grep -q "armv7"; then
    wget https://github.com/MODDEDWARFARE/PPPwn_WRT/raw/main/pppwn_armv7
    if [ $? -ne 0 ]; then
        echo "Failed to download pppwn_armv7"
        exit 1
    fi
    chmod +x pppwn_armv7
elif echo "$machine_arch" | grep -q "x86_64"; then
    wget https://github.com/MODDEDWARFARE/PPPwn_WRT/raw/main/pppwn_x86_64
    if [ $? -ne 0 ]; then
        echo "Failed to download pppwn_x86_64"
        exit 1
    fi
    chmod +x pppwn_x86_64
elif echo "$machine_arch" | grep -q "mips"; then
    opkg install lscpu

    # Get byte order
    BYTE_ORDER=$(lscpu | grep "Byte Order" | awk '{print $3, $4}')
    
    if [ "$BYTE_ORDER" == "Big Endian" ]; then
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
else
    echo "Unsupported architecture: $machine_arch"
    exit 1
fi

# Select interface
ip link
echo
read -p "Select your network interface i.e: br-lan: " network_interface
echo "$network_interface" > settings.cfg
echo

# Firmware
echo
read -p "Select your PS4 firmware (9.00/9.60/10.00/10.01/10.50/10.70/10.71/11.00): " firmware
if [ "$firmware" = "11.00" ] || [ "$firmware" = "10.01" ] || [ "$firmware" = "10.00" ] || [ "$firmware" = "9.00" ] || [ "$firmware" = "9.60" ] || [ "$firmware" = "10.50" ] || [ "$firmware" = "10.70" ] || [ "$firmware" = "10.71" ]; then
    echo ${firmware//.} >> settings.cfg
    wget https://github.com/MODDEDWARFARE/PPPwn_WRT/raw/main/stage1_${firmware//.}.bin
    if [ $? -ne 0 ]; then
        echo "Failed to download stage1_${firmware//.}.bin"
        exit 1
    fi
    wget https://github.com/MODDEDWARFARE/PPPwn_WRT/raw/main/stage2_${firmware//.}.bin
    if [ $? -ne 0 ]; then
        echo "Failed to download stage2_${firmware//.}.bin"
        exit 1
    fi
else
    echo "Invalid Firmware Selected"
    exit 1
fi

# LuCi app commands
echo
read -p "Do you want to run PPPwn from the web interface? (Y/N): " app_commands
if [ "$app_commands" = "Y" ] || [ "$app_commands" = "y" ]; then
    opkg install luci-app-commands
    if [ $? -ne 0 ]; then
        echo "Failed to install luci-app-commands"
        exit 1
    fi

    # Add custom command in LuCi
    echo -e "\nconfig command\n    option name 'PPPwn PS4'\n    option command '/root/PPPwn_WRT-main/run.sh'" | tee -a /etc/config/luci > /dev/null
fi

# Run on startup
echo
read -p "Do you want to run PPPwn on startup? (Y/N): " run_on_startup
if [ "$run_on_startup" = "Y" ] || [ "$run_on_startup" = "y" ]; then
    echo "cd /root/PPPwn_WRT-main && ./run.sh" > /etc/rc.local
fi

# Shutdown after
echo
read -p "Do you want to power down the router after loading the exploit? (Y/N): " shutdown
if [ "$shutdown" = "Y" ] || [ "$shutdown" = "y" ]; then
    echo "WARNING: If anything is misconfigured then enabling this feature along with run on startup could cause a boot loop."
    read -p "Are you sure you want to enable this feature? (Y/N): " bootloop
    if [ "$bootloop" = "Y" ] || [ "$bootloop" = "y" ]; then
        echo "poweroff" >> run.sh
    fi
fi

# Install nano
echo
read -p "Do you want to install nano for editing the button config? (Y/N): " nano
if [ "$nano" = "Y" ] || [ "$nano" = "y" ]; then
    opkg install nano
    if [ $? -ne 0 ]; then
        echo "Failed to install nano"
        exit 1
    fi
fi

# Permissions
chmod +x run.sh
chmod +x kill.sh

echo
echo "Install complete. Run it with ./run.sh"

