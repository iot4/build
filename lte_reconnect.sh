#!/bin/sh
#
# Disconnect then reconnect PPP
#

echo stop lte network
# shutdown network first
ifdown lte
sleep 1

echo power down modem
/root/bin/modem_pwrdn.sh

sleep 1

echo initialize modem interface
/root/bin/modem_init.sh

echo start lte network
# restart network
ifup lte
