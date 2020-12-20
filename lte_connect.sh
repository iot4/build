#!/bin/sh
#
# Connect PPP
#

echo stop lte network
# shutdown network first
ifdown lte
sleep 1

echo initialize modem interface
/root/bin/modem_init.sh

echo start lte network
ifup lte
