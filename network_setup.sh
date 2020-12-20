#!/bin/sh
#
# Change /etc/config/network
#

echo " * delete network bridge from the wlan"
uci delete network.wlan.type

echo " * add disable option to the wan interface"
uci set network.wan.disabled='0'

echo " * give name to the wlan interface"
uci set network.wlan.ifname='ra0'

echo " * give name to the wwan interface"
uci set network.wwan.ifname='apcli0'

echo " * set router metics"
uci set network.wan.metric='1'
uci set network.wwan.metric='10'

# save the changes
uci commit network

