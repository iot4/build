#!/bin/sh

echo enabling lte network
uci set network.lte.disabled=0
uci commit network
/etc/init.d/network restart
