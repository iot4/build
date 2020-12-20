#!/bin/sh

# read last 4 digits of the ra0 address
m1=$(cat /sys/class/net/ra0/address | awk -F':' '{ print $5 }' | awk '{print toupper($0)}')
m2=$(cat /sys/class/net/ra0/address | awk -F':' '{ print $6 }' | awk '{print toupper($0)}')

echo " * changing system hostname"

uci set system.@system[0].hostname=NCDGateway-$m1$m2
uci commit system

echo " * changing wwan, wlan hostname"

uci set network.wwan.hostname=NCDGateway-$m1$m2
uci set network.wlan.hostname=NCDGateway-$m1$m2
uci commit network

echo " * setting default SSID and key for the device AP"

uci set wireless.ap.ssid="ncdgateway-${m1}${m2}"
uci set wireless.ap.key="ncdgateway"
uci commit wireless

echo " * clearing existing Wi-Fi configuration: this will restart Wi-Fi network"

wifisetup clear > /dev/null 2>&1
