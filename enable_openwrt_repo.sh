#!/bin/sh

echo " * modifying distfeeds.conf"

sed -i -e 's/#src\/gz openwrt_core/src\/gz openwrt_core/; s/#src\/gz openwrt_base/src\/gz openwrt_base/; s/#src\/gz openwrt_luci/src\/gz openwrt_luci/; s/#src\/gz openwrt_packages/src\/gz openwrt_packages/' /etc/opkg/distfeeds.conf
