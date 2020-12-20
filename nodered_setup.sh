#!/bin/sh

# read last 4 digits of the ra0 address
m1=$(cat /sys/class/net/ra0/address | awk -F':' '{ print $5 }' | awk '{print toupper($0)}')
m2=$(cat /sys/class/net/ra0/address | awk -F':' '{ print $6 }' | awk '{print toupper($0)}')

echo " * copying default flows"
cp /mnt/sda1/node/flows.json ~/.node-red/flows_NCDGateway-${m1}${m2}.json

cd /root/.node-red

echo " * installing ncd-red-wireless"
node -max_old_space_size=512 $(which npm) install ncd-red-wireless

echo " * installing node-red-dashboard"
node -max_old_space_size=512 $(which npm) install node-red-dashboard
