#!/bin/sh
#
# Run this on a new module
#

gpioctl dirout-low 42
echo
echo ---------------------------------------------------------------------------
echo
#echo IF YOU HAVE NOT DONE FACTORY RESET. PLEASE DO IT NOW THEN RERUN THIS AGAIN.
#echo
#while true; do
#	read -p "...Press Y to start." sel
#	case $sel in
#		[Yy]* ) break;;
#		[Nn]* ) exit;;
#		* ) echo "Please answer yes or no.";;
#	esac
#done
echo
echo 0. REMOVING UNNECESSARY PACKAGES AND FILES
echo
opkg remove onion-os
opkg remove uhttpd-mod-ubus
opkg remove uhttpd

rm /etc/config/uhttpd
rm -rf /www/*

echo
echo 1. INSTALLING NEW PACKAGES
echo
/mnt/sda1/install_packages.sh
echo
echo 2. REPLACING DEFAULT OPENWRT REPOSITORY
echo
/mnt/sda1/switch_openwrt_repo.sh
echo
echo 3. SETTING UP NETWORK
echo
/mnt/sda1/network_setup.sh
echo
echo 4. SETTING UP WI-FI DEVICES
echo
/mnt/sda1/wifi_setup.sh
echo
sleep 8
echo
echo
echo 5. SETTING UP LTE NETWORK
echo
/mnt/sda1/lte_setup.sh
echo
#echo "* Network Setup Done... Restarting Network..."
/etc/init.d/network restart > /dev/null 2>&1
echo
sleep 8
echo
echo
echo 6. INSTALLING NODE RED PACKAGES
echo
echo "  This may fail if the internet is not available via Ethernet during setup."
echo "  In such case, you can install individual node packages later by running:"
echo
echo "   node_install.sh <package name>"
echo
#while true; do
#	read -p "...Press Y to install node red packages now." sel
#	case $sel in
#		[Yy]* ) /mnt/sda1/nodered_setup.sh; break;;
#		[Nn]* ) break;;
#		* ) echo "Please answer yes or no.";;
#	esac
#done
/mnt/sda1/nodered_setup.sh
echo
echo
echo 7. SETTING UP UHTTPD
echo
/mnt/sda1/uhttpd_setup.sh
echo
echo 8. COPYING NEW WEB FILES
echo
cp -a /mnt/sda1/www/* /www/
echo
echo 9. RESTARTING UHTTPD
echo
/etc/init.d/uhttpd restart > /dev/null 2>&1
echo
echo 10. COPYING UTILITIES
echo
if [ -d "/root/bin" ]; then
	rm -rf /root/bin
fi
mkdir /root/bin

# Add ~/bin to the path
echo "if [ -d \"\$HOME/bin\" ] ; then" > /root/.profile
echo "    PATH=\"\$HOME/bin:\$PATH\"" >> /root/.profile
echo "fi" >> /root/.profile

# Copy useful scripts to the bin directory
cp /mnt/sda1/enable_openwrt_repo.sh /root/bin
cp /mnt/sda1/disable_openwrt_repo.sh /root/bin
cp /mnt/sda1/lte_connect.sh /root/bin
cp /mnt/sda1/lte_disconnect.sh /root/bin
cp /mnt/sda1/lte_reconnect.sh /root/bin
cp /mnt/sda1/lte_enable.sh /root/bin
cp /mnt/sda1/lte_disable.sh /root/bin
cp /mnt/sda1/modem_info.lua /root/bin
cp /mnt/sda1/modem_init.sh /root/bin
cp /mnt/sda1/modem_emoff.sh /root/bin
cp /mnt/sda1/modem_pwrdn.sh /root/bin
cp /mnt/sda1/modem_pwrup.sh /root/bin
cp /mnt/sda1/node_install.sh /root/bin
cp /mnt/sda1/reset_parameters.sh /root/bin
cp /mnt/sda1/wifi_setup.sh /root/bin
cp /mnt/sda1/enable_network.lua /root/bin

# Create a ~/config directory
if [ ! -d "/root/config" ]; then
	mkdir /root/config
fi
# copy config data to the directory
cp -a /mnt/sda1/profiles /root/config/profiles
cp -a /mnt/sda1/chatscripts /root/config/chatscripts

# Copy applications and make it as a daemon
cp /mnt/sda1/apps/* /root/bin
cp /mnt/sda1/icmpcfg /etc/init.d/
cp /mnt/sda1/system-monitor /etc/init.d/
cp /mnt/sda1/55_system-monitor /etc/uci-defaults/

# Copy shadow
cp /mnt/sda1/shadow /etc/
cp /mnt/sda1/shadow /root/config/

# Create a ncd package file in the /etc/config
/mnt/sda1/ncd_setup.sh

# Done!
sync
echo
echo ---------------------------------------------------------------------------
echo
echo Setup complete!
sync
echo
#read -p "...Press any key to reboot the device." boot
echo System will reboot shortly
echo
gpioctl dirout-high 42
reboot
