#!/bin/sh

echo " * registering lua backend for the uhttpd"

uci delete uhttpd.main.lua_prefix
uci set uhttpd.main.lua_prefix="/"
uci set uhttpd.main.lua_handler="/www/index.lua"
uci commit uhttpd
