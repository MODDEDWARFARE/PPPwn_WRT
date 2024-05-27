#!/bin/sh
echo "========================================"
echo "==|  INSTALLATION PPPwn-WRT STARTED  |=="
echo "========================================"
echo 

# Create working directory
mkdir PPPwn_WRT-main
if [ $? -ne 0 ]; then
    echo "[PPPwn-WRT][FAILED] Failed to create directory PPPwn_WRT-main"
    exit 1
else
    echo "[PPPwn-WRT][SUCCESS] Directory PPPwn_WRT-main created"
fi

# Set permissions to folder (because why not)
chmod +x PPPwn_WRT-main
if [ $? -ne 0 ]; then
    echo "[PPPwn-WRT][FAILED] Failed set CHMOD +x for PPPwn_WRT-main"
    exit 1
else
    echo "[PPPwn-WRT][SUCCESS] Successfully set CHMOD +x for PPPwn_WRT-main"
fi

# Change to working directory (If a directory change operation fails, it allows the script to terminate on a directory change error, preventing the script from accidentally continuing execution in an unexpected location.)
cd PPPwn_WRT-main || {
    echo "[PPPwn-WRT][FAILED] Failed to change to directory PPPwn_WRT-main"
    exit 1
}
echo "[PPPwn-WRT][SUCCESS] Successfully changed to directory PPPwn_WRT-main"

# Download scripts - download run.sh
wget "https://github.com/MODDEDWARFARE/PPPwn_WRT/raw/main/run.sh"
if [ $? -ne 0 ]; then
    echo "[PPPwn-WRT][FAILED] Failed to download run.sh"
    exit 1
else
    echo "[PPPwn-WRT][SUCCESS] Successfully downloaded run.sh"
fi

# Permissions - Set permissions to run.sh
chmod +x run.sh
if [ $? -ne 0 ]; then
    echo "[PPPwn-WRT][FAILED] Failed set CHMOD +x for run.sh"
    exit 1
else
    echo "[PPPwn-WRT][SUCCESS] Successfully set CHMOD +x for run.sh"
fi

# Download scripts - download /kill.sh
wget "https://github.com/MODDEDWARFARE/PPPwn_WRT/raw/main/kill.sh"
if [ $? -ne 0 ]; then
    echo "[PPPwn-WRT][FAILED] Failed to download kill.sh"
    exit 1
else
    echo "[PPPwn-WRT][SUCCESS] Successfully downloaded kill.sh"
fi

# Permissions - Set permissions to kill.sh
chmod +x kill.sh
if [ $? -ne 0 ]; then
    echo "[PPPwn-WRT][FAILED] Failed set CHMOD +x for kill.sh"
    exit 1
else
    echo "[PPPwn-WRT][SUCCESS] Successfully set CHMOD +x for kill.sh"
fi

# Capture the output of uname -m
machine_arch=$(uname -m)
if [ $? -ne 0 ]; then
    echo "[PPPwn-WRT][FAILED] Failed to capture the result of uname -m"
    exit 1
else
    echo "[PPPwn-WRT][SUCCESS] Successfully captured the architecture: $machine_arch"
        # Choose script based on the architecture
    if echo "$machine_arch" | grep -q "arch64"; then
        wget "https://github.com/MODDEDWARFARE/PPPwn_WRT/raw/main/pppwn_arch64"
        if [ $? -ne 0 ]; then
            echo "[PPPwn-WRT][FAILED] Failed to download pppwn_arch64"
            exit 1
        else
            echo "[PPPwn-WRT][SUCCESS] Successfully downloaded pppwn_arch64"
            chmod +x pppwn_arch64
            if [ $? -ne 0 ]; then
                echo "[PPPwn-WRT][FAILED] Failed set CHMOD +X for pppwn_arch64"
                exit 1
            else
                echo "[PPPwn-WRT][SUCCESS] Successfully set CHMOD +X for pppwn_arch64"
            fi 
        fi
    elif echo "$machine_arch" | grep -q "armv7"; then
        wget "https://github.com/MODDEDWARFARE/PPPwn_WRT/raw/main/pppwn_armv7"
        if [ $? -ne 0 ]; then
            echo "[PPPwn-WRT][FAILED] Failed to download pppwn_armv7"
            exit 1
        else
            echo "[PPPwn-WRT][SUCCESS] Successfully downloaded pppwn_armv7"
            chmod +x pppwn_armv7
            if [ $? -ne 0 ]; then
                echo "[PPPwn-WRT][FAILED] Failed set CHMOD +x for pppwn_armv7"
                exit 1
            else
                echo "[PPPwn-WRT][SUCCESS] Successfully set CHMOD +x for pppwn_armv7"
            fi 
        fi
    elif echo "$machine_arch" | grep -q "x86_64"; then
        wget "https://github.com/MODDEDWARFARE/PPPwn_WRT/raw/main/pppwn_x86_64"
        if [ $? -ne 0 ]; then
            echo "[PPPwn-WRT][FAILED] Failed to download pppwn_x86_64"
            exit 1
        else
            echo "[PPPwn-WRT][SUCCESS] Successfully downloaded pppwn_x86_64"
            chmod +x pppwn_x86_64
            if [ $? -ne 0 ]; then
                echo "[PPPwn-WRT][FAILED] Failed set CHMOD +x for pppwn_x86_64"
                exit 1
            else
                echo "[PPPwn-WRT][SUCCESS] Successfully set CHMOD +x for pppwn_x86_64"
            fi 
        fi
    elif echo "$machine_arch" | grep -q "mips"; then
        wget "https://github.com/MODDEDWARFARE/PPPwn_WRT/raw/main/pppwn_mips"
        if [ $? -ne 0 ]; then
            echo "[PPPwn-WRT][FAILED] Failed to download pppwn_mips"
            exit 1
        else
            echo "[PPPwn-WRT][SUCCESS] Successfully downloaded pppwn_mips"
            chmod +x pppwn_mips
            if [ $? -ne 0 ]; then
                echo "[PPPwn-WRT][FAILED] Failed set CHMOD +x for pppwn_mips"
                exit 1
            else
                echo "[PPPwn-WRT][SUCCESS] Successfully set CHMOD +x for pppwn_mips"
            fi 
        fi
    else
        echo "[PPPwn-WRT][FAILED] Unsupported architecture: $machine_arch"
        exit 1
    fi
fi

#Select Interface
#Select Interface - Function to get list of interfaces
get_interfaces() {
    ip link | awk -F: '$0 !~ "lo|virbr|wl|^[^0-9]"{print $2}' | tr -d ' '
}
#Select Interface - Function to prompt user to select a network interface
select_interface() {
    ip link
    echo
    while true; do
        echo "[PPPwn-WRT] Select your network interface (e.g., br-lan): "
        read -r network_interface
        if echo "$(get_interfaces)" | grep -qw "$network_interface"; then
            echo "$network_interface" > settings.cfg
            echo "[PPPwn-WRT][SUCCESS] Network interface '$network_interface' saved to settings.cfg"
            break
        else
            echo "[PPPwn-WRT][ERROR] Invalid network interface. Please try again."
        fi
    done
}
#Select Interface - Call the function
select_interface
echo

# Firmware
echo "[PPPwn-WRT] Select your PS4 firmware. Type 11.00 or 9.00 or 10.00: "
read -r firmware
if [ "$firmware" = "11.00" ] || [ "$firmware" = "10.00" ] || [ "$firmware" = "9.00" ]; then
    case "$firmware" in
        "11.00") firmware_code=1100 ;;
        "10.01") firmware_code=1000 ;;
        "9.00") firmware_code=900 ;;
    esac
    echo "$firmware_code" >> settings.cfg
    wget "https://github.com/MODDEDWARFARE/PPPwn_WRT/raw/main/stage1_$firmware_code.bin"
    if [ $? -ne 0 ]; then
        echo "[PPPwn-WRT][FAILED] Failed to download stage1_$firmware_code.bin"
        exit 1
    else
        echo "[PPPwn-WRT][SUCCESS] Successfully downloaded stage1_$firmware_code.bin"
    fi
    wget "https://github.com/MODDEDWARFARE/PPPwn_WRT/raw/main/stage2_$firmware_code.bin"
    if [ $? -ne 0 ]; then
        echo "[PPPwn-WRT][FAILED] Failed to download stage2_$firmware_code.bin"
        exit 1
    else
        echo "[PPPwn-WRT][SUCCESS] Successfully downloaded stage2_$firmware_code.bin"
    fi
else
    echo "[PPPwn-WRT][FAILED] Invalid Firmware Selected"
    exit 1
fi

# LuCi app commands
# LuCi app commands - Function to prompt user to select if PPPwn should run on startup
select_luci_app_commands() {
    while true; do
        echo "[PPPwn-WRT] Do you want to run PPPwn from the web interface? (Y/N): "
        read -r luci_app_commands
        luci_app_commands=$(echo "$luci_app_commands" | awk '{print tolower($0)}')
        if [ "$luci_app_commands" = "yes" ] || [ "$luci_app_commands" = "y" ]; then
            opkg install luci-app-commands
            if [ $? -ne 0 ]; then
                echo "[PPPwn-WRT][FAILED] Failed to install luci-app-commands"
                exit 1
            else
                echo "[PPPwn-WRT][SUCCESS] Successfully installed luci-app-commands"
            fi
            # Add custom command in LuCi
            echo -e "\nconfig command\n    option name 'PPPwn PS4'\n    option command '/root/PPPwn_WRT-main/run.sh'" | tee -a /etc/config/luci > /dev/null
            break
        elif [ "$luci_app_commands" = "no" ] || [ "$luci_app_commands" = "n" ]; then
            echo "#cd /root/PPPwn_WRT-main && ./run.sh" > /etc/rc.local
            echo "[PPPwn-WRT][INFO] luci-app-commands will not be installed."
            break
        else
            echo "[PPPwn-WRT][ERROR] Invalid input. Please enter Y or N."
        fi
    done
}
# LuCi app commands - Call the function
select_luci_app_commands

# Run on startup
#Run on startup - Function to prompt user to select if PPPwn should run on startup
select_run_on_startup() {
    while true; do
        echo "[PPPwn-WRT] Do you want to run PPPwn on startup? (Y/N): "
        read -r run_on_startup
        run_on_startup=$(echo "$run_on_startup" | awk '{print tolower($0)}')
        if [ "$run_on_startup" = "yes" ] || [ "$run_on_startup" = "y" ]; then
            echo "cd /root/PPPwn_WRT-main && ./run.sh" > /etc/rc.local
            echo "[PPPwn-WRT][SUCCESS] PPPwn will run on startup."
            break
        elif [ "$run_on_startup" = "no" ] || [ "$run_on_startup" = "n" ]; then
            echo "#cd /root/PPPwn_WRT-main && ./run.sh" > /etc/rc.local
            echo "[PPPwn-WRT][SUCCESS] PPPwn will not run on startup."
            break
        else
            echo "[PPPwn-WRT][ERROR] Invalid input. Please enter Y or N"
        fi
    done
}
#Run on startup - Call the function
select_run_on_startup

# Shutdown after loading the exploit
# Shutdown after loading the exploit - Function to prompt user to select
select_shutdown_router_after_loading_exploit() {
    while true; do
        echo "[PPPwn-WRT] Do you want to power down the router after loading the exploit? (Y/N): "
        read -r shutdown_router_after_loading_exploit
        shutdown_router_after_loading_exploit=$(echo "$shutdown_router_after_loading_exploit" | awk '{print tolower($0)}')
        if [ "$shutdown_router_after_loading_exploit" = "yes" ] || [ "$shutdown_router_after_loading_exploit" = "y" ]; then
            # Confirm the shutdown after loading the exploit - Function to prompt user to confirm selection
            select_confirm_shutdown_router_after_loading_exploit() {
                while true; do
                    echo -e "\e[31m[PPPwn-WRT][WARNING]\e[0m If anything is misconfigured then enabling this feature along with run on startup could cause a boot loop."
                    echo "[PPPwn-WRT] Are you sure you want to enable this feature? (Y/N): "
                    read -r confirm_shutdown_router_after_loading_exploit_bootloop
                    confirm_shutdown_router_after_loading_exploit_bootloop=$(echo "$confirm_shutdown_router_after_loading_exploit_bootloop" | awk '{print tolower($0)}')
                    if [ "$confirm_shutdown_router_after_loading_exploit_bootloop" = "yes" ] || [ "$confirm_shutdown_router_after_loading_exploit_bootloop" = "y" ]; then
                        echo "poweroff" >> run.sh
                        echo "[PPPwn-WRT][INFO] Your router will be powered down after loading the exploit"
                        break
                    elif [ "$confirm_shutdown_router_after_loading_exploit_bootloop" = "no" ] || [ "$confirm_shutdown_router_after_loading_exploit_bootloop" = "n" ]; then
                        echo "[PPPwn-WRT][INFO] Your router will not be powered down after loading the exploit."
                        break
                    else
                        echo "[PPPwn-WRT][ERROR] Invalid input. Please enter Y to confirm or N to decline"
                    fi
                done
            }
            # Confirm the shutdown after loading the exploit - Call the function
            select_confirm_shutdown_router_after_loading_exploit 
            break
        elif [ "$shutdown_router_after_loading_exploit" = "no" ] || [ "$shutdown_router_after_loading_exploit" = "n" ]; then
            echo "[PPPwn-WRT][INFO] Your router will not be power down after loading the exploit."
            break
        else
            echo "[PPPwn-WRT][ERROR] Invalid input. Please enter Y or N"
        fi
    done
}
# Shutdown after loading the exploit - Call the function
select_shutdown_router_after_loading_exploit


# Install nano
# Install nano - Function to prompt user to select if PPPwn should run on startup
select_install_nano() {
    while true; do
        echo "[PPPwn-WRT] Do you want to install nano for editing the button config? (Y/N): "
        read -r install_nano
        install_nano=$(echo "$install_nano" | awk '{print tolower($0)}')
        if [ "$install_nano" = "yes" ] || [ "$install_nano" = "y" ]; then
            opkg install nano
            if [ $? -ne 0 ]; then
                echo "[PPPwn-WRT][FAILED] Failed to install nano"
                exit 1
            else
                echo "[PPPwn-WRT][SUCCESS] Successfully installed nano"
            fi
            break
        elif [ "$install_nano" = "no" ] || [ "$install_nano" = "n" ]; then
            echo "[PPPwn-WRT][INFO] nano will not be installed."
            break
        else
            echo "[PPPwn-WRT][ERROR] Invalid input. Please enter Y or N."
        fi
    done
}
# Install nano - Call the function
select_install_nano

echo 
echo "========================================"
echo "=======|   INSTALL  COMPLETED   |======="
echo "=======|  Run it with ./run.sh  |======="
echo "========================================"
