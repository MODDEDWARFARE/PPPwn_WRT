# PPPwn on OpenWRT

A method of running PPPwn on devices running OpenWRT. 
Based on the Pi-Pwn project from stooged: https://github.com/stooged/PI-Pwn 

## Features

- Internet Passthrough over PPPoE after successful Jailbreak
- DNS Blockers to prevent system updates when connected to the internet
- Autolaunch PPPwn after the PS4 reboots
- Detect GoldHEN to prevent relaunching PPPwn when recovering from rest mode
- Web Panel for loading payloads, adjusting settings & restarting PPPwn
- Connect additional devices over PPPoE to access the PS4 over the network
- Option to use a button on your device to load PPPwn
- Option to load PPPwn from the LuCi web interface
- Activity LED can be enabled to indicate when PPPwn is running

## Supported Devices

You can check to see if your device is supported [here](https://openwrt.org/toh/start).

This project should support OpenWRT versions as low as 21.02. Older versions will fail to download the files using wget but this can be worked around by simply downloading the files manually from the repo and installing them via scp/sftp to support even older versions.

## Prerequisites

Once OpenWRT is installed, you will need to connect the device to the internet. Either through a wired connection to your devices WAN port or wireless by heading to the LuCI web interface and following these steps:

1. Go to **Wireless** settings and select the **Scan** option.
2. Select your network and join it as a client.

**WARNING:** Ensure your `br-lan` interface does not use the same subnet as your home network before joining as a client, otherwise they will conflict.

## Setup

Remote into your device through SSH using hostname: openwrt.lan or your devices local ip, username: root and your devices password if you set one up.

Download and execute the install script on your device:

```sh
wget https://github.com/MODDEDWARFARE/PPPwn_WRT/raw/main/install.sh
chmod +x install.sh && . ./install.sh
```

You will be asked a series of questions for how you want the exploit configured. You should take your
devices storage capacity into account when enabling additional features.

If you have less than 16MBs of internal flash storage it's not recommended to enable additional features like:
- Running PPPwn from the LuCi web interface
- GoldHEN detection for rest mode support
- Web panel
- Web panel payloads

These options use the most storage. Alternatively you can use a USB drive. Place the install script on the USB and run it from there. This will install most of the files to the USB and free up more space on the internal flash.

Select your LAN interface which is known most commonly as `br-lan`.

You will be asked to select a LAN port that the PS4 will be connected to.

You can add additional LAN ports for other devices to be able to connect to the PS4 over PPPoE for FTP access, remote PKG installing, remote debugging and other network features.

Select your firmware from `9.00` to `11.00`.

You will be asked to set a timeout value, the default is 5 minutes. This is how long you want to keep running PPPwn before reloading it. Useful if PPPwn hangs.

You also have the option to change the default subnet to avoid conflicting with other subnets on your network. You only need to change this if there's another subnet on your network that's using the same address space of 192.168.3.X. Otherwise you can just say no to skip this step.

Next you have the option to change the default username and password for the PPPoE connection for the PS4 and Guest networks. Defaults are listed below:

PS4 Username: ppp
PS4 Password: ppp

Guest Username: guest
Guest Password: ppp

You will be asked to allow the PS4 to connect to the internet after loading PPPwn. If you select no a firewall rule is added to block connections to the internet while still allowing local network access. If you say yes internet will be accessible after loading PPPwn.

You will be asked to enable a web panel (Recommended). This can be accessed via your devices local ip on port 8080 or http://pppwn.local:8080 from the PS4's web browser. The web panel can be used to change settings, start/stop PPPwn, reboot your device and load bin loader payloads.

You will have the option to install bin loader payloads that can later be loaded from the web panel. This is not recommended for devices with limited storage capacity.

You will have the option to enable PPPwn from the LuCi web interface. 
The option can be found in System > Custom Commands.
Not recommended for devices with limited storage capacity.

You will be asked if you want to detect a console shutdown. Allows your device to know when the console has rebooted so that it can reload PPPwn automatically.

You will be asked if you want GoldHEN detection. After recovering from rest mode it will detect that GoldHEN is already running and continue with internet passthrough instead of reloading PPPwn. Not recommended for devices with limited storage capacity.

You will be asked if you want to select an LED which will blink to indicate when PPPwn is running.

You will be asked if you want to select a button on your device to run PPPwn. wps is recommended.

You will be asked if you want to load PPPwn on startup. Useful if you want PPPwn to load as soon as the device boots.

You will be asked if you want to power down the device after loading PPPwn. This feature may not work on some devices and could
cause them to reboot instead. If any files do not download correctly during installation this option could also cause a boot loop. Only recommended on devices that are being powered by the PS4's USB ports.

Once the installation completes your device will reboot.

You can adjust these options by editing the settings.cfg and pconfig.cfg files in the project directory or via the web panel if you installed it.

If the install script fails before completion, reset your device before attempting to run it again.

## PS4 Configuration

If this is your first time running PPPwn on your PS4 you will need to download the latest goldhen.bin file from: https://github.com/GoldHEN/GoldHEN/releases and place it on the root of an exFAT or FAT32 formatted USB drive and plug it into the PS4. Once PPPwn loads it will copy the GoldHEN payload to the PS4's internal storage. After which point the USB will no longer be needed.

Once the PS4 is connected to your devices selected LAN port you need to navigate to Settings > Network > Set up an internet connection > choose LAN cable > Custom > Select PPPoE and enter the username and password you set in the install script. 

username: ppp
password: ppp

Now PPPwn will trigger automatically if you enabled run PPPwn on startup, otherwise you can start it using the following options:
From the terminal by navigating to the PPPwn_WRT-main folder and entering `./run.sh`
Web Panel: http://pppwn.local:8080 > Restart PPPwn
LuCi: System > Custom Commands > PPPwn PS4 > Run
Pressing the selected button on your device

## PC Configuration

If you added another LAN port to the PPPoE network you can connect another device like a PC to that LAN port to access the PS4 over the network. This is handy for FTP access, remote pkg installing, remote debugging and more.

On a Windows PC open your Settings > Network & Internet > Dial-up > Set up a new connection.
Then select Connect to the Internet > Set up a new connection anyway > Broadband (PPPoE)
Then enter the guest accounts username: guest and password: ppp and click connect.

This will place your PC on the same network as the PS4 and you can access it via the PS4's local ip or the hostname: ps4.lan.

## Video Guide


## Credits

Special Thanks to: 
Stooged 
TheFlow0
xfangfang

---
