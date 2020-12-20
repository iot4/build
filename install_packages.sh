#!/bin/sh
#
# Install packages from the local repositories
#

echo " * updating customfeeds.conf to include the local omega2 repositories"

if grep -q "mnt/sda1/packages/o2" /etc/opkg/customfeeds.conf; then
	echo " * skipping to add local omega2 package repositories"
else
	echo " * adding local omega2 package repositories"
	echo "src/gz o2_base file:///mnt/sda1/packages/omega2_base" >> /etc/opkg/customfeeds.conf
	echo "src/gz o2_core file:///mnt/sda1/packages/omega2_core" >> /etc/opkg/customfeeds.conf
	echo "src/gz o2_onion file:///mnt/sda1/packages/omega2_onion" >> /etc/opkg/customfeeds.conf
	echo "src/gz o2_packages file:///mnt/sda1/packages/omega2_packages" >> /etc/opkg/customfeeds.conf
	echo "src/gz o2_routing file:///mnt/sda1/packages/omega2_routing" >> /etc/opkg/customfeeds.conf
fi

echo " * disabling onion repositories during installation"

/mnt/sda1/disable_onion_repo.sh > /dev/null 2>&1

echo " * updating package repository for local omega2 packages"

opkg update > /dev/null 2>&1

echo " * installing local omega2 packages"
echo
echo

opkg install comgt
opkg install shadow-common
opkg install shadow-chpasswd
opkg install node
opkg install onion-node-red
opkg install node-npm
opkg install python

echo
#echo " * turning back the content of customfeeds.conf to original"
#sed -i '/src\/gz o2/d' /etc/opkg/customfeeds.conf

echo
echo
echo " * updating customfeeds.conf to include the local openwrt repositories"

if grep -q "mnt/sda1/packages/ow" /etc/opkg/customfeeds.conf; then
	echo " * skipping to add local openwrt package repositories"
else
	echo " * adding local openwrt package repositories"
	echo "src/gz ow_base file:///mnt/sda1/packages/openwrt_base" >> /etc/opkg/customfeeds.conf
	echo "src/gz ow_core file:///mnt/sda1/packages/openwrt_core" >> /etc/opkg/customfeeds.conf
	echo "src/gz ow_packages file:///mnt/sda1/packages/openwrt_packages" >> /etc/opkg/customfeeds.conf
fi

echo " * updating package repository for local openwrt packages"

opkg update > /dev/null 2>&1

echo " * installing openwrt packages"
echo
echo

opkg install make
opkg install gcc
opkg install uhttpd
opkg install uhttpd-mod-lua
opkg install lua
opkg install lua-cjson
opkg install lua-rs232
opkg install picocom

echo
echo
echo " * creating pthread library"

ar -rc /usr/lib/libpthread.a

echo " * turning back the content of customfeeds.conf to original"

sed -i '/src\/gz o2/d' /etc/opkg/customfeeds.conf
sed -i '/src\/gz ow/d' /etc/opkg/customfeeds.conf

echo " * reenabling onion repositories"

/mnt/sda1/enable_onion_repo.sh
