#!/bin/sh
#
# Setup SARA R4
#

echo " * deleting lte setting if exists"

if grep -q "lte" /etc/config/network; then
	uci delete network.lte
fi

echo " * adding lte setting to the network"

uci add network interface
uci rename network.@interface[-1]='lte'
uci set network.lte.defaultroute=1
uci set network.lte.device='/dev/ttyS2'
uci set network.lte.apn='hologram'
uci set network.lte.service='umts'
uci set network.lte.proto='3g'
uci set network.lte.pppd_options='noipdefault'
uci set network.lte.keepalive='100 30'
uci set network.lte.metric='100'
uci set network.lte.disabled='1'
# save the changes
uci commit network

echo " * creating backup for the current chat script"

if grep -q "3g.chat" /etc/chatscripts; then
	cp /etc/chatscripts/3g.chat /etc/chatscripts/3g.chat.backup
fi

echo " * copying a new chat script"

if [ -f "/mnt/sda1/chatscripts/default.chat" ]; then
	cp /mnt/sda1/chatscripts/default.chat /etc/chatscripts/3g.chat
elif [ -f "/root/config/chatscripts/default.chat" ]; then
	cp /root/config/chatscripts/default.chat /etc/chatscripts/3g.chat
else
	echo " * chat script not found... skipping"
fi

echo " * removing lte entry from the firewall if exists"

if grep -q "lte" /etc/config/firewall; then
	uci delete firewall.lte
fi

echo " * registering lte network to firewall"

uci add firewall zone
uci rename firewall.@zone[-1]='lte'
uci set firewall.lte.name='lte'
uci set firewall.lte.input='ACCEPT'
uci set firewall.lte.output='ACCEPT'
uci set firewall.lte.forward='REJECT'
uci set firewall.lte.masq='1'
uci set firewall.lte.mtu_fix='1'
uci set firewall.lte.network='lte'
uci commit firewall

#echo " * modifying rc.local to activate the modem when boot"
#sed -i '/^exit/i \/root\/bin\/modem_init.sh\nsleep 30\n\/root\/bin\/modem_pwrup.sh' /etc/rc.local
#sed -i '/^exit/i lua \/root\/bin\/modem_info.lua AT+UGPIOC=16,2' /etc/rc.local

