#!/usr/bin/env lua

if arg[1] ~= nil then
    if arg[1] == 'eth' or arg[1] == 'ETH' or arg[1] == 'eth0' then
        -- enable eth
        os.execute("sed -i '/config interface \\x27wan\\x27/,/option disabled/!b;/option disabled/!b;s/1/0/' /etc/config/network");
        -- disable sta
        os.execute("sed -i '/config wifi-iface \\x27sta\\x27/,/option disabled/!b;/option disabled/!b;s/0/1/' /etc/config/wireless");
        -- disable lte
        os.execute("sed -i '/config interface \\x27lte\\x27/,/option disabled/!b;/option disabled/!b;s/0/1/' /etc/config/network");
        -- restart network
        os.execute('/etc/init.d/network restart')
        os.execute('sleep 7')

    elseif arg[1] == 'sta' or arg[1] == 'STA' or arg[1] == 'apcli0' then
        -- disable eth
        os.execute("sed -i '/config interface \\x27wan\\x27/,/option disabled/!b;/option disabled/!b;s/0/1/' /etc/config/network");
        -- enable sta
        os.execute("sed -i '/config wifi-iface \\x27sta\\x27/,/option disabled/!b;/option disabled/!b;s/1/0/' /etc/config/wireless");
        -- disable lte
        os.execute("sed -i '/config interface \\x27lte\\x27/,/option disabled/!b;/option disabled/!b;s/0/1/' /etc/config/network");
        -- restart network
        os.execute('/etc/init.d/network restart')
        os.execute('sleep 7')

    elseif arg[1] == 'lte' or arg[1] == 'LTE' or arg[1] == '3g-lte' then
        -- disable eth
        os.execute("sed -i '/config interface \\x27wan\\x27/,/option disabled/!b;/option disabled/!b;s/0/1/' /etc/config/network");
        -- disable sta
        os.execute("sed -i '/config wifi-iface \\x27sta\\x27/,/option disabled/!b;/option disabled/!b;s/0/1/' /etc/config/wireless");
        -- enable lte
        os.execute("sed -i '/config interface \\x27lte\\x27/,/option disabled/!b;/option disabled/!b;s/1/0/' /etc/config/network");
        -- restart network
        os.execute('/etc/init.d/network restart')
        os.execute('sleep 7')
    end
end
