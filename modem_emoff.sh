#!/bin/sh
#
# Power down SARA R4 module
#

echo set RESET_N low
# set GPIO1 low
gpioctl dirout-low 1
# low period should be more than 10 sec: see 4.2.2 of the datasheet
sleep 11

echo set RESET_N high
# set GPIO1 high again
gpioctl dirout-high 1
#sleep 1
# DO NOT SET PIN 1 AS DIRIN
