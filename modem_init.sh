#!/bin/sh
#
# Initialize modem by activating UART2 and setting RESET_N pin high
#

echo set gpiomux for uart2
# set uart2 pins to uart mode
omega2-ctrl gpiomux set uart2 uart

echo hold RESET high
# set RESET_N pin high
gpioctl dirout-high 1

echo power up modem
/root/bin/modem_pwrup.sh
