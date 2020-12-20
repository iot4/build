#!/bin/sh

echo disabling lte network
uci set network.lte.disabled=1
uci commit network
/etc/init.d/network restart
