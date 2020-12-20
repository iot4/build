#!/bin/sh
#
# Disconnect PPP
#

echo stop lte network
ifdown lte
sleep 1

echo power down modem
/root/bin/modem_pwrdn.sh
