#!/bin/sh

echo " * SNAPSHOT repo is replaced by .8 repo"
sed -i -e 's/-SNAPSHOT/.8/' /etc/opkg/distfeeds.conf
