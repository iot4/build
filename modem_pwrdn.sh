#!/bin/sh
#
# Power down SARA R4 module
#

echo set POWER low
# set GPIO2 low
gpioctl dirout-low 2
# low period should be more than 3.2 sec: see 4.2.8 of the datasheet
sleep 4

echo set POWER high
# set GPIO2 high again
gpioctl dirout-high 2
sleep 1
# DO NOT SET PIN 2 AS DIRIN

