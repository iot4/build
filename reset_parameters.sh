#!/bin/sh
#
# Reset parameters to defalut values
#

# Setup /etc/config/network
/mnt/sda1/network_setup.sh

# Setup lte
/mnt/sda1/lte_setup.sh

# Setup /etc/config/wireless
/mnt/sda1/wifi_setup.sh

# Restart network
/etc/init.d/network restart

