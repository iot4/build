#!/bin/sh

echo " * modifying distfeeds.conf"

sed -i -e 's/^src\/gz openwrt/#src\/gz openwrt/' /etc/opkg/distfeeds.conf
