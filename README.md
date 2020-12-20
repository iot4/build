# LTE edge device build
 ncd.io PR55-36 firmware
# build
ncd.io PR55-36 firmware
1. USB flash drive
2. download build dir
3. Copy the contents of the build directory into a USB key (Do not copy the build directory itself)

Installing firmware in gateway

Supply power to the gateway and waits for 1 minutes.

(recommended) Connect the gateway to the network using Ethernet

If the Omega module is modified previously, performs factory reset.

Connect the Omega module to the PC via a USB cable and opens up a serial terminal.

Plug in the setup USB key, waits for the USB key is recognized.

Run the setup script:
 # /mnt/sda1/setup.sh
If the gateway is not connected to the network, choose N for Node Red package installation step.

At the end of the setup, the device will reboot itself. After the reboot, check the OLED panel for the network state.
