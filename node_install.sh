#!/bin/sh

if [ "$#" -ne 1 ]; then
	echo "Usage: node_install.sh <package name>"
	exit 0
fi

cd /root/.node-red
node -max_old_space_size=512 $(which npm) install $1
