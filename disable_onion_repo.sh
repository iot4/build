#!/bin/sh

echo " * modifying distfeeds.conf"

sed -i -e 's/^src\/gz omega2/#src\/gz omega2/' /etc/opkg/distfeeds.conf
