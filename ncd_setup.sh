rm -rf /etc/config/ncd

touch /etc/config/ncd

uci add ncd device
uci rename ncd.@device[-1]='oled'
uci set ncd.oled.control='system'

uci add ncd device
uci rename ncd.@device[-1]='lte'
uci set ncd.lte.sim='hologram'

uci add ncd device
uci rename ncd.@device[-1]='control'
uci set ncd.control.ctrl_mode='manual'
uci set ncd.control.target_ep='google.com'
uci set ncd.control.eth_iface='selected'
uci set ncd.control.sta_iface='selected'
uci set ncd.control.lte_iface='selected'
uci set ncd.control.eth_state='up'
uci set ncd.control.sta_state='disabled'
uci set ncd.control.lte_state='down'
uci set ncd.control.sysmon_ver='0.0.0'

uci commit ncd
