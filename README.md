# PPPwn on OpenWRT

A method of running PPPwn on an OpenWRT-based router.

## Supported Routers

You can check to see if your router is supported [here](https://openwrt.org/toh/start).

## Prerequisites

Once OpenWRT is installed, you will need to temporarily connect the router to the internet. You can do this in the LuCI web interface by following these steps:

1. Go to **Wireless** settings and select the **Scan** option.
2. Select your network and join it as a client.

**WARNING:** Ensure your `br-lan` interface does not use the same subnet as your home network before joining as a client. Otherwise they will conflict.

## Setup

Remote into your router through SSH

Download the project to your router:

```sh
opkg update
wget https://github.com/MODDEDWARFARE/PPPwn_WRT/raw/main/install.sh
chmod +x install.sh && . ./install.sh
```

Select your interface most common is `br-lan`.

Select your firmware `11.00`, `10.00` or `9.00`.

You will be asked if you want to load PPPwn from the Web Interface. You should not use this option if you have limited storage space and
are planning to load PPPwn on startup or with a button on the router.

You will be asked if you want to load the script on startup. If you select `Y` for Yes you can edit this in future by editing the file: `/etc/rc.local`.

You will be asked if you want to power down the router after loading the exploit. This feature may not work on some routers and could
cause them to reboot instead. If any files do not download correctly during installation this option could also cause a boot loop.

You will be asked if you want to install nano. If you have limited storage space it's best to decline this option and use vi instead.

You can now run the script from the terminal by entering `./run.sh` or run it from the LuCI web interface by going to **System > Custom Commands > PPPwn PS4 > Run**.

## Using a Button to Trigger the Exploit 
(1-click WPS button to run "run.sh") or Triger the process killer (Hold 3 sec WPS button to run "kill.sh")

This method is a bit more involved than the previous one.

1. SSH into the router and navigate to `cd /etc/rc.button`.

2. Type `ls` to list available buttons.
   ![Available Buttons](https://i.imgur.com/kb0hZrT.png)

3. Find a button you want to replace, e.g., `wps`.

4. Edit the button script with:

    ```sh
    nano wps
    ```

5. Look for the `wps` button "released" code. It should look something like:
   ![WPS Button Code](https://i.imgur.com/ej8kr91.png)

6. Delete everything inside the `if` statement and replace it with the following command:
   
    ```sh
    cd /root/PPPwn_WRT-main && ./run.sh
       if [ "$SEEN" -ge 3 ] ; then
          cd /root/PPPwn_WRT-main && ./kill.sh
       else
          cd /root/PPPwn_WRT-main && ./run.sh
       fi
    ```
    

   Example:
   ![Button Script](https://i.imgur.com/IMSN7Np.png)

Now, when you press the `wps` button, it will run the script.

## LED Support

If your router has LED indicators for `wps`, `power`, `wlan`, etc., you can use them to indicate when the script is running.

1. Type `ls /sys/class/leds/` to list available LEDs.
2. Choose an LED, e.g., `red:info`.
3. Edit the script to change the LED behavior:

    ```sh
    nano /root/PPPwn_WRT-main/run.sh
    ```

4. Replace `green:wps` with `red:info` in:

    ```sh
    echo "heartbeat" > /sys/class/leds/green:wps/trigger
    ```

You can also change the LED behavior from `heartbeat` to:
- `none` = off
- `default-on` = always on
- `heartbeat` = blinking
- `timer` = time delay

---
