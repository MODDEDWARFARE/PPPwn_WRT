# PPPwn on OpenWRT

A method of running PPPwn on devices running OpenWRT.  
Based on the Pi-Pwn project from [stooged](https://github.com/stooged/PI-Pwn).

---

## Features

- Internet Passthrough over PPPoE after successful Jailbreak  
- DNS Blockers to prevent system updates when connected to the internet  
- Autolaunch PPPwn after the PS4 reboots  
- Detect GoldHEN to prevent relaunching PPPwn when recovering from rest mode  
- Web Panel for loading payloads, adjusting settings & restarting PPPwn  
- Connect additional devices over PPPoE to access the PS4 over the network  
- Option to use a button on your device to load PPPwn  
- Option to load PPPwn from the LuCI web interface  
- Activity LED can be enabled to indicate when PPPwn is running  

---

## Supported Devices

Check if your device is supported [here](https://openwrt.org/toh/start).  

This project supports OpenWRT versions as low as 21.02.  
Older versions may fail to download files using `wget`, but you can work around this by manually downloading files from the repo and uploading them to the device via `scp` or `sftp`.

---

## Prerequisites

Once OpenWRT is installed, connect the device to the internet using either:

- A wired connection to the WAN port  
- A wireless connection via the LuCI web interface:
  1. Go to **Wireless** settings
  2. Select **Scan**
  3. Join your network as a **Client**

> ⚠️ **Warning:** Ensure your `br-lan` interface does not use the same subnet as your home network before joining as a client to avoid IP conflicts.

---

## Setup

SSH into your device using:
Host: openwrt.lan 
User: root
Pass: yourpassword

Download and run the install script
```sh
wget https://github.com/MODDEDWARFARE/PPPwn_WRT/raw/main/install.sh
chmod +x install.sh && . ./install.sh
```

You will be asked a series of configuration questions:

- **Storage Constraints:**  
  If your device has less than 16MB of internal flash storage, it is recommended **not** to enable:
  - LuCI web interface integration  
  - GoldHEN detection  
  - Web panel and web panel payloads  

  👉 Instead, you can run the install script from a USB drive. This will install most files to the USB and free up internal storage.

- **LAN Interface Selection:**  
  Choose your LAN interface (typically `br-lan`).

- **PS4 Port Assignment:**  
  Select the LAN port to which your PS4 will be connected.

- **Additional LAN Ports:**  
  Optionally assign more LAN ports for other devices to access the PS4 over PPPoE—for FTP, remote PKG installs, debugging, etc.

- **Firmware Selection:**  
  Choose your PS4 firmware version (from `9.00` to `11.00`).

- **Timeout Value:**  
  Default is 5 minutes. Determines how long to keep PPPwn running before automatically reloading it in case of a hang.

- **Custom Subnet:**  
  Optional. Only change if your network already uses the default 192.168.3.X subnet.

- **PPPoE Credentials:**  
  Defaults are:
  - **PS4 Username:** `ppp`  
  - **PS4 Password:** `ppp`  
  - **Guest Username:** `guest`  
  - **Guest Password:** `ppp`

- **Internet Access After PPPwn:**  
  - **Yes**: PS4 gets internet access post-jailbreak.  
  - **No**: Firewall rules block internet but allow local network access.

- **Enable Web Panel (Recommended):**  
  Access via your device’s IP at port 8080 or `http://pppwn.local:8080` from the PS4 browser. Allows control over settings, PPPwn, and payloads.

- **Install Bin Loader Payloads:**  
  Optional. Allows loading payloads via web panel. Not recommended for low-storage devices.

- **Enable from LuCI Web Interface:**  
  Adds a custom command in LuCI under **System > Custom Commands**. Not advised for devices with limited storage.

- **Detect Console Shutdown:**  
  Allows auto-reload of PPPwn when the console reboots.

- **Enable GoldHEN Detection:**  
  Prevents PPPwn from reloading after rest mode if GoldHEN is already running. Avoid on low-storage devices.

- **Activity LED Indicator:**  
  Select an LED to blink while PPPwn is running.

- **Physical Button Trigger:**  
  Choose a device button (e.g., `wps`) to manually run PPPwn.

- **Run PPPwn on Startup:**  
  Automatically launches PPPwn when the device boots.

- **Shutdown After PPPwn Loads:**  
  Optional and risky. Powers down the device after PPPwn completes. Can cause reboot loops or failure if setup is incomplete. Only use if powering from the PS4's USB.

Once installation completes, your device will reboot.

> 🔧 Settings can later be adjusted via `settings.cfg` and `pconfig.cfg` in the project directory, or through the web panel (if installed).  
> 💥 If installation fails midway, reset your device before trying again.

---

## PS4 Configuration

1. **GoldHEN Payload:**  
   - Download the latest `goldhen.bin` from [GoldHEN Releases](https://github.com/GoldHEN/GoldHEN/releases)  
   - Place it in the root of a FAT32 or exFAT USB drive  
   - Insert the USB into the PS4  

   > Once PPPwn loads, it copies GoldHEN to the PS4’s internal storage. The USB is no longer needed afterwards.

2. **Set Up Network on PS4:**
   - Navigate to **Settings > Network > Set Up Internet Connection**
   - Choose **LAN Cable > Custom > PPPoE**
   - Use the credentials:
     ```
     Username: ppp
     Password: ppp
     ```
    Unless you changed them in the install script
   
4. **Start PPPwn:**
   - Terminal:  
     ```bash
     cd PPPwn_WRT-main && ./run.sh
     ```
   - Web Panel:  
     Open `http://pppwn.local:8080` > click **Restart PPPwn**
   - LuCI:  
     **System > Custom Commands > PPPwn PS4 > Run**
   - Device Button:  
     Press the selected button (e.g., `wps`)

---

## PC Configuration

If you added another LAN port for the PPPoE network, you can use it to connect a PC and access the PS4 network.

1. Go to **Settings > Network & Internet > Dial-up**
2. Click **Set up a new connection**
3. Choose **Broadband (PPPoE)**
4. Enter credentials:
5. Click **Connect**

Your PC is now on the same subnet as the PS4. You can connect to the PS4 using the PS4 IP or `ps4.local`.

---

## Credits

This project relies on the work of others. 
Special thanks to:
- [stooged](https://github.com/stooged/PI-Pwn) 
- [TheFlow0](https://github.com/TheOfficialFloW/PPPwn)  
- [xfangfang](https://github.com/xfangfang/PPPwn_cpp)

