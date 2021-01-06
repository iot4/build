--[[ ENV TABLE for URL http://10.42.0.153/path/to/page?name=ferret&color=purple
-- (key:value)
--
-- HTTP_ACCEPT: "text/html,application/xhtml+xml,application/xml;..."
-- SCRIPT_NAME: "/"
-- QUERY_STRING: "name=ferret&color=purple"
-- HTTP_ACCEPT_ENCODING: "gzip, deflate"
-- SERVER_ADDR: "10.42.0.153"
-- GATEWAY_INTERFACE: "CGI/1.1"
-- REMOTE_ADDR: "10.42.0.1"
-- SERVER_PORT: "80"
-- SCRIPT_FILENAME: "/www/index.lua"
-- REQUEST_URI: "/path/to/page?name=ferret&color=purple"
-- SERVER_PROTOCOL: "HTTP/1.1"
-- REMOTE_HOST: "10.42.0.1"
-- REDIRECT_STATUS: "200"
-- headers:
--     connection: "keep-alive"
--     upgrade-insecure-requests: "1"
--     accept: "text/html,application/xhtml+xml,application/xml;..."
--     host: "10.42.0.153"
--     cache-control: "max-age=0"
--     accept-language: "en-GB,en;q=0.9"
--     user-agent: "value: Mozilla/5.0 (X11; Linux x86_64)..."
--     accept-encoding: "gzip, deflate"
--     URL: "/path/to/page?name=ferret&color=purple"
-- HTTP_VERSION: 1.1
-- SERVER_SOFTWARE: "uhttpd"
-- REMOTE_PORT: "50096"
-- HTTP_CONNECTION: "keep-alive"
-- SERVER_NAME: "10.42.0.153"
-- HTTP_HOST: "10.42.0.153"
-- PATH_INFO: "/path/to/page"
-- HTTP_USER_AGENT: "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit..."
-- HTTP_ACCEPT_LANGUAGE: "en-GB,en;q=0.9"
-- REQUEST_METHOD: "GET"
--]]

-- this package requires installation of stand-alone lua package
cjson = require('cjson')
rs232 = require('luars232')

CONSOLE_VERSION = "0.9.1"

-- GPIO pins
MODEM_RESET = 1
MODEM_POWER = 2
BUTTON_CFG  = 19
LED_RED = 40
LED_GREEN = 41
LED_BLUE = 42

-- Gloval variables
params = {}

-- various delays
AP_UP_DELAY = 10
AP_DN_DELAY = 5
STA_UP_DELAY = 10
STA_DN_DELAY = 5
ETH_UP_DELAY = 2
ETH_DN_DELAY = 2
LTE_UP_DELAY = 15
LTE_DN_DELAY = 5
MDM_UP_DELAY = 2
MDM_DN_DELAY = 2
SRV_RST_DELAY = 1
SYS_HALT_DELAY = 5
SYS_BOOT_DELAY = 25
PARAM_RST_DEALY = 10

LTE_CHECK_DELAY = 10

MAX_CHAT_DELAY = 30
MAX_PPPD_DELAY = 180
MAX_SCAN_DELAY = 30
MAX_JOIN_DELAY = 30
MAX_AUTH_DELAY = 30
MAX_DSCV_DELAY = 10
MAX_IPV4_DELAY = 60

-- LIST OF FUNCTIONS
-- decode_url
-- decode_query
-- decode_post
-- send_html
-- send_file
-- send_response
-- get_at_response
-- process_at_command
-- init_params
-- update_params
-- bringup_network
-- shutdown_network
-- handle_request

--
-- Decode URL string into a itable.
--
function decode_url(data)

    -- sanity check
    if data == nil then
        -- no string
        return {}
    elseif #data < 2 then
        -- too short
        return {}
    elseif string.sub(data,1,1) ~= "/" then
        -- not started with '/'
        return {}
    end

    -- split url into elements
    local url = {}

    for element in string.gmatch(data, "(/[%w_%-.]+)") do
        url[#url + 1] = string.sub(element,2,-1)
    end
    return url

end


--
-- Decode query string into a table.
--
function decode_query(data)
    -- sanity check
    if data == nil then
        -- no string
        return {}
    end

    -- decode query string into a lua table
    local query = {}

    --for element in string.gmatch(data, "([^/]+)") do
    for element in string.gmatch(data, "[^%&]+") do
        for k,v in string.gmatch(element,"([^%=]+)=([^%=]+)") do
            query[k] = v
        end
    end
    return query
end


--
-- Decode post data
--
function decode_post(data)
    -- sanity check
    if data == nil then
        return {}
    end

    -- json format
    if data:byte(1) == 123 and data:byte(-1) == 125 then
        return cjson.decode(data)
    -- urlencoded
    else
        return decode_query(data)
    end

end


--
-- Send HTML document with variables replaced by values
--
function send_html(fname)

    local ftype = fname:sub(fname:find("%.")+1)

    if ftype == "html" or ftype == "htm" then
        local header = io.open("/www/htdocs/header.html", "r")
        local footer = io.open("/www/htdocs/footer.html", "r")
        local body = io.open("/www/htdocs/" .. fname, "r")

        if header == nil or footer == nil or body == nil then
            uhttpd.send("Status: 404 Not found\r\n\r\n")

        else
            uhttpd.send("Status: 200 OK\r\n")
            uhttpd.send("Content-Type: text/html; charset=utf-8\r\n\r\n")

            -- header
            while true do
                local line = header:read()
                if line == nil then
                    break
                else
                    uhttpd.send(line
                        :gsub("$NodeRedURL","http://" .. params["ip"] .. ":1880")
                        :gsub("$TerminalURL","http://" .. params["ip"] .. ":4200")
                        )
                end
            end
            header:close()

            -- body
            while true do
                local line = body:read()
                if line == nil then
                    break
                else
                    uhttpd.send(line
                        :gsub("$RootURL","http://" .. params["ip"])
                        :gsub("$APSSID",params["ap ssid"])
                        :gsub("$APKey",params["ap key"])
                        :gsub("$APProto",params["ap proto"])
                        :gsub("$APIPAddr",params["ap ipv4 addr"])
                        :gsub("$APIPNetMask",params["ap ipv4 mask"])
                        :gsub("$APState",params["ap state"])
                        :gsub("$NetCtrlMode",params["net ctrl mode"])
                        :gsub("$NetSTAIface",params["net sta iface"])
                        :gsub("$NetETHIface",params["net eth iface"])
                        :gsub("$NetLTEIface",params["net lte iface"])
                        :gsub("$NetTargetEP",params["net target ep"])
                        :gsub("$STASSID",params["sta ssid"])
                        :gsub("$STAKey",params["sta key"])
                        :gsub("$STAProto",params["sta proto"])
                        :gsub("$STAIPAddr",params["sta ipv4 addr"])
                        :gsub("$STANetMask",params["sta ipv4 mask"])
                        :gsub("$STAGateway",params["sta gateway"])
                        :gsub("$STADNS",params["sta dns"])
                        :gsub("$STAMetric",params["sta metric"])
                        :gsub("$STAState",params["sta state"])
                        :gsub("$STAEnable",params["sta enable"])
                        :gsub("$ETHProto",params["eth proto"])
                        :gsub("$ETHIPAddr",params["eth ipv4 addr"])
                        :gsub("$ETHNetMask",params["eth ipv4 mask"])
                        :gsub("$ETHGateway",params["eth gateway"])
                        :gsub("$ETHDNS",params["eth dns"])
                        :gsub("$ETHMetric",params["eth metric"])
                        :gsub("$ETHState",params["eth state"])
                        :gsub("$LTEAPN",params["lte apn"])
                        :gsub("$LTEProto",params["lte proto"])
                        :gsub("$LTEIPAddr",params["lte ipv4 addr"])
                        :gsub("$LTENetMask",params["lte ipv4 mask"])
                        :gsub("$LTEGateway",params["lte gateway"])
                        :gsub("$LTEDNS",params["lte dns"])
                        :gsub("$LTEMetric",params["lte metric"])
                        :gsub("$LTEState",params["lte state"])
                        :gsub("$MODEMVendor",params["modem vendor"])
                        :gsub("$MODEMModel",params["modem model"])
                        :gsub("$MODEMRev",params["modem rev"])
                        :gsub("$MODEMIMEI",params["modem imei"])
                        :gsub("$MODEMSig",params["modem sig"])
                        :gsub("$MODEMESQ",params["modem esq"])
                        :gsub("$MODEMUMask",params["modem umask"])
                        :gsub("$MODEMURAT",params["modem urat"])
                        :gsub("$MODEMPSMS",params["modem psms"])
                        :gsub("$MODEMEDRXS",params["modem edrxs"])
                        :gsub("$MODEMUSVCD",params["modem usvcd"])
                        :gsub("$MODEMReg",params["modem reg"])
                        :gsub("$MODEMGPRS",params["modem gprs"])
                        :gsub("$MODEMESP",params["modem esp"])
                        :gsub("$MODEMPDP",params["modem pdp"])
                        :gsub("$MODEMUMNOProf",params["modem mno"])
                        :gsub("$MODEMOpr",params["modem opr"])
                        :gsub("$MODEMPIN",params["modem pin"])
                        :gsub("$MODEMICCID",params["modem iccid"])
                        :gsub("$CONSOLEVER",params["console version"])
                        :gsub("$SYSMONVER",params["sysmon version"])
                        )
                end
            end
            body:close()

            -- footer
            while true do
                local line = footer:read()
                if line == nil then
                    break
                else
                    uhttpd.send(line)
                end
            end
            footer:close()

            -- TODO: send footer
        end
    else
        uhttpd.send("Status: 404 Not Found\r\n\r\n")
    end
end


--
-- Send a CSS/PNG/JPG/ICO/TTF file
--
function send_file(fname)

    local ftype = fname:sub(fname:find("%.")+1)

    if ftype == "html" or ftype == "htm" then
        local file = io.open("/www/htdocs/" .. fname, "r")

        if file == nil then
            uhttpd.send("Status: 404 Not found\r\n\r\n")
        else
            uhttpd.send("Status: 200 OK\r\n")
            uhttpd.send("Content-Type: text/html; charset=utf-8\r\n\r\n")
            while true do
                local line = file:read()

                if line == nil then
                    break
                else
                    uhttpd.send(line
                        :gsub("$RootURL","http://" .. params["ip"]))
                end
            end
            file:close()
        end

    elseif ftype == "css" then
        local file = io.open("/www/css/" .. fname, "r")

        if file == nil then
            uhttpd.send("Status: 404 Not found\r\n\r\n")
        else
            uhttpd.send("Status: 200 OK\r\n")
            uhttpd.send("Content-Type: text/css\r\n\r\n")
            while true do
                local line = file:read()
                if line == nil then
                    break
                else
                    uhttpd.send(line)
                end
            end
            file:close()
        end

    elseif ftype == "png" or ftype == "jpg" or ftype == "ico" then
        local file = io.open("/www/images/" .. fname, "rb")

        if file == nil then
            uhttpd.send("Status: 404 Not Found\r\n\r\n")
        else
            uhttpd.send("Status: 200 OK\r\n")
            uhttpd.send("Content-Type: image/*\r\n\r\n")
            uhttpd.send(file:read("*all"))
            file:close()
        end

    elseif ftype == "ttf" then
        local file = io.open("/www/fonts/" .. fname, "rb")

        if file == nil then
            uhttpd.send("Status: 404 Not Found\r\n\r\n")
        else
            uhttpd.send("Status: 200 OK\r\n")
            uhttpd.send("Content-Type: image/*\r\n\r\n")
            uhttpd.send(file:read("*all"))
            file:close()
        end

    else
        uhttpd.send("Status: 404 Not Found\r\n\r\n")
    end
end


--
-- Send response with text content
--
function send_response(code, content)
    if code == 200 then
        uhttpd.send("Status: 200 OK\r\n")
    elseif code == 400 then
        uhttpd.send("Status: 400 Bad Request\r\n")
    elseif code == 404 then
        uhttpd.send("Status: 404 Not Found\r\n")
    elseif code == 408 then
        uhttpd.send("Status: 408 Request Timeout\r\n")
    elseif code == 500 then
        uhttpd.send("Status: 500 Internal Server Error\r\n")
    elseif code == 503 then
        uhttpd.send("Status: 503 Service Unavailable\r\n")
    else
        uhttpd.send("Status: " .. tostring(code) .. "\r\n")
    end

    uhttpd.send("Content-Type: text/plain; charset=utf-8\r\n\r\n")
    uhttpd.send(content);
    uhttpd.send("\r\n");
end


--
-- Get AT command response from the modem
--
function get_at_response(port, cmd, timeout)

    local err, len = port:write(cmd .. '\r\n')
    local result = {}
    local payload = ""
    local first_line = true
    timeout = timeout + os.time()

    while true do
        local err, partial, size = port:read(1, 10)

        if err == rs232.RS232_ERR_NOERROR then
            payload = payload .. partial

            local _line = string.find(payload, '\r\n')

            if _line ~= nil then
                payload = string.sub(payload,1,_line-1)

                if #payload > 0 then

                    local _col = string.find(payload, ':')

                    if _col == nil then
                        if string.find(payload, 'OK') ~= nil then
                            result['status'] = 'OK'
                            break
                        elseif string.find(payload, 'ERROR') ~= nil then
                            result['status'] = 'ERROR'
                            break
                        elseif #payload > 0 then
                            -- remove additional \r from SARA
                            if string.find(payload, '\r') then
                                payload = string.sub(payload,1,-2)
                            end
                            if payload ~= cmd then
                                result[cmd] = payload
                            end
                        end
                    else
                        local key = payload:sub(1,_col-1)
                        local val = payload:sub(_col+1,-1)
                        if val:sub(1,1) == ' ' then
                            val = val:sub(2,-1)
                        end
                        result[key] = val

                        if string.find(key, 'ERROR') ~= nil then
                            result['status'] = 'ERROR'
                            break
                        end
                    end
                end

                payload = ''
            end

            --[[
            if string.find(payload, "OK") ~= nil then
                result['payload'] = payload
                break
            end
            --]]

        end

        if os.time() > timeout then
            result['status'] = 'ERROR'
            result[cmd] = 'timeout'
            break
        end
    end

    return result
end


--
-- Run a set of AT commands on the modem
--
function process_at_command(profile)

    local flag = true
    local err,port = rs232.open('/dev/ttyS2')

    if err == rs232.RS232_ERR_NOERROR then
        -- check if modem is responding
        local result = get_at_response(port, "AT\r\n", 1)
        -- if not recycle the power
        if result["status"] ~= 'OK' then
            os.execute('/root/bin/modem_pwrup.sh > /dev/null 2>&1')
        end

        for line in string.gmatch(profile, "[%w%+= ?]+") do
            if string.find(line, 'sleep') ~= nil then
                os.execute(line)
            elseif string.find(line, 'SLEEP') ~= nil then
                os.execute(line)
            else
                get_at_response(port, line .. '\r\n', 10)
            end
        end
        port:close()
    else
        flag = false
    end

    return flag

end


--
-- Initialize the Paramter Set by sections
--
function init_params(section)

    -- AP (wlan)
    if section == "ap" or section == "all" then
        params["ap ssid"] = ""
        params["ap key"] = ""
        params["ap proto"] = ""
        params["ap ipv4 addr"] = ""
        params["ap ipv4 mask"] = ""
        params["ap state"] = ""
    end

    if section == "net" or section == "all" then
        params["net ctrl mode"] = ""
        params["net sta iface"] = ""
        params["net eth iface"] = ""
        params["net lte iface"] = ""
        params["net target ep"] = ""
    end

    -- STA (wwan)
    if section == "sta" or section == "all" then
        params["sta ssid"] = ""
        params["sta key"] = ""
        params["sta encr"] = ""
        params["sta enable"] = ""
        params["sta proto"] = ""
        params["sta metric"] = ""
        params["sta ipv4 addr"] = ""
        params["sta ipv4 mask"] = ""
        params["sta gateway"] = ""
        params["sta dns"] = ""
        params["sta state"] = ""
    end

    -- Ethernet (wan)
    if section == 'eth' or section == 'all' then
        params["eth proto"] = ""
        params["eth metric"] = ""
        params["eth ipv4 addr"] = ""
        params["eth ipv4 mask"] = ""
        params["eth gateway"] = ""
        params["eth dns"] = ""
        params["eth state"] = ""
    end

    -- LTE
    if section == 'lte' or section == 'all' then
        params["lte apn"] = ""
        params["lte proto"] = ""
        params["lte metric"] = ""
        params["lte ipv4 addr"] = ""
        params["lte ipv4 mask"] = ""
        params["lte gateway"] = ""
        params["lte dns"] = ""
        params["lte state"] = ""
    end

    -- MODEM
    if section == 'modem' or section == 'all' then
        params["modem vendor"] = ""
        params["modem model"] = ""
        params["modem rev"] = ""
        params["modem imei"] = ""
        params["modem fun"] = ""
        params["modem sig"] = ""
        params["modem umask"] = ""
        params["modem urat"] = ""
        params["modem psms"] = ""
        params["modem edrxs"] = ""
        params["modem usvcd"] = ""
        params["modem esq"] = ""
        params["modem reg"] = ""
        params["modem gprs"] = ""
        params["modem esp"] = ""
        params["modem pdp"] = ""
        params["modem opr"] = ""
        params["modem mno"] = ""
        params["modem pin"] = ""
        params["modem iccid"] = ""
    end

    -- common
    params["console version"] = CONSOLE_VERSION
    local f = io.popen('uci get ncd.control.sysmon_ver')
    params["sysmon version"] = f:read()
    f:close()

end


-- always start with initialized parameters
init_params('all')


--
--  Collect system parameters and status by sections
--
function update_params(section)

    init_params(section)

    -- AP (wlan)
    if section == "ap" or section == "all" then

        local f = io.popen('uci get wireless.ap.ssid')
        params["ap ssid"] = f:read()
        f:close()

        f = io.popen('uci get wireless.ap.key')
        params["ap key"] = f:read()
        f:close()

        f = io.popen('ifstatus wlan')
        local content = f:read("*all")
        f:close()

        if string.find(content, "not found") == nil then
            local data = cjson.decode(content)

            params["ap proto"] = data["proto"]

            if data["up"] then
                params["ap state"] = "up"

                if #data["ipv4-address"] > 0 then
                    params["ap ipv4 addr"] = data["ipv4-address"][1]["address"]
                    params["ap ipv4 mask"] = data["ipv4-address"][1]["mask"]
                end
            else
                f = io.popen('uci get wireless.ap.disabled')
                if f:read() == '0' then
                    params["ap state"] = "down"
                else
                    params["ap state"] = "disabled"
                end
                f:close()
            end
        else
            params["ap state"] = "disabled"
        end
    end

    -- Control
    if section == "control" or section == "all" then

        local f = io.popen('uci get ncd.control.ctrl_mode')
        params["net ctrl mode"] = f:read()
        f:close()

        f = io.popen('uci get ncd.control.sta_iface')
        params["net sta iface"] = f:read()
        f:close()

        f = io.popen('uci get ncd.control.eth_iface')
        params["net eth iface"] = f:read()
        f:close()

        f = io.popen('uci get ncd.control.lte_iface')
        params["net lte iface"] = f:read()
        f:close()

        f = io.popen('uci get ncd.control.target_ep')
        params["net target ep"] = f:read()
        f:close()

    end

    -- STA (wwan)
    if section == "sta" or section == "all" then

        local f = io.popen('wifisetup list')
        content = f:read("*all")
        f:close()

        if content ~= nil then
            local data = cjson.decode(content)

            if #data["results"] > 0 then
                params["sta ssid"] = data["results"][1]["ssid"]
                params["sta key"] = data["results"][1]["password"]
                params["sta encr"] = data["results"][1]["encryption"]

                if data["results"][1]["enabled"] == true then
                    params["sta enable"] = 'enabled'
                else
                    params["sta enable"] = 'disabled'
                end
            end
        end

        f = io.popen('ifstatus wwan')
        content = f:read("*all")
        f:close()

        if string.find(content, "not found") == nil then
            local data = cjson.decode(content)

            params["sta proto"] = data["proto"]

            if data["up"] then
                params["sta state"] = "up"
                params["sta metric"] = data["metric"]

                if #data["ipv4-address"] > 0 then
                    params["sta ipv4 addr"] = data["ipv4-address"][1]["address"]
                    params["sta ipv4 mask"] = data["ipv4-address"][1]["mask"]
                end

                if #data["route"] > 0 then
                    params["sta gateway"] = data["route"][1]["nexthop"]
                end

                for i=1,#data["dns-server"] do
                    params["sta dns"] = params["sta dns"] ..
                        data["dns-server"][i] .. ","
                end
                if string.sub(params["sta dns"], -1) == "," then
                    params["sta dns"] = string.sub(params["sta dns"], 1,-2)
                end
            else
                f = io.popen('uci get wireless.sta.disabled')
                if f:read() == '0' then
                    params["sta state"] = "down"
                else
                    params["sta state"] = "disabled"
                end
                f:close()
            end
        else
            param["sta state"] = "disabled"
        end
        --os.execute('uci set ncd.control.sta_state='..params['sta state'])
        --os.execute('uci commit ncd')
    end

    -- Ethernet (wan)
    if section == 'eth' or section == 'all' then

        local f = io.popen('ifstatus wan')
        content = f:read("*all")
        f:close()

        if string.find(content, "not found") == nil then
            local data = cjson.decode(content)

            params["eth proto"] = data["proto"]

            if data["up"] then
                params["eth state"] = "up"
                params["eth metric"] = data["metric"]

                if #data["ipv4-address"] > 0 then
                    params["eth ipv4 addr"] = data["ipv4-address"][1]["address"]
                    params["eth ipv4 mask"] = data["ipv4-address"][1]["mask"]
                end

                if #data["route"] > 0 then
                    params["eth gateway"] = data["route"][1]["nexthop"]
                end

                for i = 1,#data["dns-server"] do
                    params["eth dns"] = params["eth dns"] ..
                        data["dns-server"][i] .. ","
                end
                if string.sub(params["eth dns"], -1) == "," then
                    params["eth dns"] = string.sub(params["eth dns"], 1,-2)
                end
            else
                params['eth state'] = 'down'
            end
        else
            params['eth state'] = 'disabled'
        end
        --os.execute('uci set ncd.control.eth_state='..params['eth state'])
        --os.execute('uci commit ncd')
    end

    -- LTE
    if section == 'lte' or section == 'all' then

        --[[
        local f = io.popen('/root/bin/modem_info.lua AT')
        local res = f:read()

        if string.find(res, "status: OK") == nil then
            modem_busy = true;
        end
        f:close()
        --]]

        local modem_busy = false

        if modem_busy == true then
            params["lte apn"] = "..Modem is Busy.."
            content = "not found"
        else
            f = io.popen('uci get network.lte.apn')
            params["lte apn"] = f:read()
            f:close()

            f = io.popen('ifstatus lte')
            content = f:read("*all")
            f:close()
        end

        if string.find(content, "not found") == nil then
            local data = cjson.decode(content)

            params["lte proto"] = data["proto"]

            if data["up"] then
                params["lte state"] = "up"
                params["lte metric"] = data["metric"]

                if #data["ipv4-address"] > 0 then
                    params["lte ipv4 addr"] = data["ipv4-address"][1]["address"]
                    params["lte ipv4 mask"] = data["ipv4-address"][1]["mask"]
                end

                if #data["route"] > 0 then
                    params["lte gateway"] = data["route"][1]["nexthop"]
                end

                for i = 1,#data["dns-server"] do
                    params["lte dns"] = params["lte dns"] ..
                        data["dns-server"][i] .. ","
                end
                if string.sub(params["lte dns"], -1) == "," then
                    params["lte dns"] = string.sub(params["lte dns"], 1,-2)
                end
            else
                params["lte state"] = "down"
                --[[
                f = io.popen('uci get network.lte.disabled')
                if f:read() == '0' then
                    params["lte state"] = "down"
                else
                    params["lte state"] = "disabled"
                end
                f:close()
                --]]
            end
        else
            params["lte state"] = "disabled"
        end
        --os.execute('uci set ncd.control.lte_state='..params['lte state'])
        --os.execute('uci commit ncd')
    end

    -- MODEM
    if section == 'modem' or section == 'all' then

        if params["lte up"] == "up" then

        else
            local err,port = rs232.open('/dev/ttyS2')

            if err == rs232.RS232_ERR_NOERROR then

                port:set_baud_rate(rs232.RS232_BAUD_115200)
                port:set_data_bits(rs232.RS232_DATA_8)
                port:set_parity(rs232.RS232_PARITY_NONE)
                port:set_stop_bits(rs232.RS232_STOP_1)
                port:set_flow_control(rs232.RS232_FLOW_OFF)

                local result = get_at_response(port, "ATI", 1)
                if result["status"] == 'OK' then
                    params["modem vendor"] = result["Manufacturer"]
                    params["modem model"] = result["Model"]
                    params["modem rev"] = result["Revision"]
                    params["modem imei"] = result["IMEI"]
                end

                result = get_at_response(port, "AT+CFUN?", 1)
                if result["status"] == 'OK' then
                    params["modem fun"] = result["+CFUN"]
                end

                result = get_at_response(port, "AT+CSQ", 1)
                if result["status"] == 'OK' then
                    params["modem sig"] = result["+CSQ"]
                end

                result = get_at_response(port, "AT+UBANDMASK?", 1)
                if result["status"] == 'OK' then
                    params["modem umask"] = result["+UBANDMASK"]
                end

                result = get_at_response(port, "AT+URAT?", 1)
                if result["status"] == 'OK' then
                    params["modem urat"] = result["+URAT"]
                end

                result = get_at_response(port, "AT+CEDRXS?", 1)
                if result["status"] == 'OK' then
                    params["modem edrxs"] = result["+CEDRXS"]
                end

                result = get_at_response(port, "AT+USVCDOMAIN?", 1)
                if result["status"] == 'OK' then
                    params["modem usvcd"] = result["+USVCDOMAIN"]
                end

                result = get_at_response(port, "AT+CPSMS?", 1)
                if result["status"] == 'OK' then
                    params["modem psms"] = result["+CPSMS"]
                end

                result = get_at_response(port, "AT+CESQ", 1)
                if result["status"] == 'OK' then
                    params["modem esq"] = result["+CESQ"]
                end

                result = get_at_response(port, "AT+CREG?", 1)
                if result["status"] == 'OK' then
                    params["modem reg"] = result["+CREG"]
                end

                result = get_at_response(port, "AT+CGREG?", 1)
                if result["status"] == 'OK' then
                    params["modem gprs"] = result["+CGREG"]
                end

                result = get_at_response(port, "AT+CEREG?", 1)
                if result["status"] == 'OK' then
                    params["modem esp"] = result["+CEREG"]
                end

                result = get_at_response(port, "AT+CGDCONT?", 1)
                if result["status"] == 'OK' then
                    params["modem pdp"] = result["+CGDCONT"]
                end

                result = get_at_response(port, "AT+COPS?", 1)
                if result["status"] == 'OK' then
                    params["modem opr"] = result["+COPS"]
                end

                result = get_at_response(port, "AT+UMNOPROF?", 1)
                if result["status"] == 'OK' then
                    params["modem mno"] = result["+UMNOPROF"]
                end

                result = get_at_response(port, "AT+CPIN?", 1)
                if result["status"] == 'OK' then
                    params["modem pin"] = result["+CPIN"]
                end

                result = get_at_response(port, "AT+CCID", 1)
                if result["status"] == 'OK' then
                    params["modem iccid"] = result["+CCID"]
                end

                port:close()
            end
        end
    end

end


function bringup_network(iface)

    if iface == 'ap' then
        os.execute('ifup wlan > /dev/null 2>&1')
        os.execute('sleep ' .. tostring(AP_UP_DELAY))
        return 'AP is up'

    elseif iface == 'sta' then
        -- check if sta is up
        local f = io.popen('ifstatus wwan')
        local content = f:read("*all")
        f:close()

        local data = cjson.decode(content)
        -- sta is already up
        if data["up"] then
            -- DO NOT PROCEED!!!
            return 'Wi-Fi is already up. Shut it down first'
        end

        -- activate wwan
        os.execute('uci set wireless.sta.disabled=0')
        os.execute('uci commit wireless')
        -- DO NO USE wifi, which does not request DHCP to release IP
        -- os.execute('wifi')
        os.execute('ifup wwan')
        os.execute('sleep 5')
        -- clear log
        os.execute('/etc/init.d/log restart')

        -- wait util apcli0 found the target network
        local count = 0
        local res = '1'

        while(count < MAX_SCAN_DELAY) do
            os.execute('sleep 1')
            -- network discovered
            -- "kern.info ap_client: Found configured network"
            f = io.popen("logread | awk '/ap_client: Found configured/ {print 1}'")
            res = f:read()
            f:close()
            if res == '1' then break end

            count = count+1
        end

        -- failed to find the AP
        if count >= MAX_SCAN_DELAY then
            return 'Wi-Fi target network not found'
        end

        -- wait until joined the network
        -- daemon.notice netifd: Interface 'wwan' has link connectivity
        -- daemon.notice netifd: Interface 'wwan' is setting up now
        -- kern.info apclient: Interface 'apcli0' successfully associated to
        count = 0
        while(count < MAX_JOIN_DELAY) do
            os.execute('sleep 1')
            -- network associated
            f = io.popen("logread | awk '/successfully associated/ {print 1}'")
            res = f:read()
            f:close()
            if res == '1' then break end

            count = count+1
        end

        -- failed to join
        if count >= MAX_JOIN_DELAY then
            return 'Wi-Fi failed to join the network...Time out'
        end

        -- wait for the authenticate
        -- netifd: wwan (22504): udhcpc: lease of 192.168.1.189 obtained
        -- daemon.notice netifd: Interface 'wwan' is now up
        count = 0
        while(count < MAX_AUTH_DELAY) do
            os.execute('sleep 1')
            -- interface is up
            f = io.popen("logread | awk '/Interface .wwan. is now up/ {print 1}'")
            res = f:read()
            f:close()
            if res == '1' then return 'Wi-Fi is up' end

            count = count+1
        end

        -- failed to authnticated
        if count >= MAX_AUTH_DELAY then
            return 'Wi-Fi failed to connect...Time out'
        end

    elseif iface == 'eth' then
        -- check if eth is up
        local f = io.popen('ifstatus wan')
        local content = f:read("*all")
        f:close()

        local data = cjson.decode(content)
        -- sta is already up
        if data["up"] then
            -- DO NOT PROCEED!!!
            return 'Ethernet is already up. Shut it down first'
        end

        -- clear log
        os.execute('/etc/init.d/log restart')
        -- activate wan
        os.execute('ifup wan > /dev/null 2>&1')

        -- wait until sending discover packet
        -- wan (24054): udhcpc: started, v1.28.3
        -- wan (24054): udhcpc: sending discover
        count = 0
        while(count < MAX_DSCV_DELAY) do
            os.execute('sleep 1')
            -- network associated
            f = io.popen("logread | awk '/udhcpc: sending discover/ {print 1}'")
            res = f:read()
            f:close()
            if res == '1' then break end

            count = count+1
        end

        -- wan is not working
        if count >= MAX_DSCV_DELAY then
            return 'Ethernet is not working'
        end

        -- wait until IPv4 address is leased
        -- wan (24054): udhcpc: lease of 192.168.8.3
        count = 0
        while(count < MAX_IPV4_DELAY) do
            os.execute('sleep 1')
            -- network associated
            f = io.popen("logread | awk '/udhcpc: lease of/ {print 1}'")
            res = f:read()
            f:close()
            if res == '1' then return 'Ethernet is up' end

            count = count+1
        end

        -- wan is not working
        if count >= MAX_IPV4_DELAY then
            return 'Ethernet failed to get IPv4 address... Timed out'
        end

    elseif iface == 'lte' then
        -- check if lte enabled
        local enabled = false
        local f = io.popen('uci get network.lte.disabled')
        if f:read() == '0' then
            enabled = true
        end
        f:close()

        if enabled == false then
            os.execute('uci set network.lte.disabled=0')
            os.execute('uci commit network')
            os.execute('sleep 5')
        else
            -- check if lte network is up and running already
            f = io.popen('ifstatus lte')
            content = f:read("*all")
            f:close()

            local data = cjson.decode(content)
            -- lte is already up
            if data["up"] then
                -- DO NOT PROCEED!!!
                return 'LTE is already up. Shut it down first'
            end
        end

        local err,port = rs232.open('/dev/ttyS2')
        -- check if modem is responding
        local result = get_at_response(port, "AT\r\n", 1)
        port:close()

        -- if not recycle the power
        if result["status"] ~= 'OK' then
            os.execute('/root/bin/modem_pwrup.sh > /dev/null 2>&1')
        end

        -- activate lte network
        os.execute('ifup lte > /dev/null 2>&1')
        -- clear log
        os.execute('/etc/init.d/log restart')

        -- wait util it gets through the chatscript
        local count = 0
        local res = '1'

        while(count < MAX_CHAT_DELAY) do
            os.execute('sleep 1')
            -- waiting for the chat to connect
            -- chat[1234]: CONNECT
            -- pppd[2345]: Serial connection established
            f = io.popen("logread | awk '/chat\\[.+\\]: CONNECT/ {print 1}'")
            res = f:read()
            f:close()
            if res == '1' then break end

            -- or chat Failed
            -- chat[1234]: alarm
            -- chat[1234]: Failed
            f = io.popen("logread | awk '/chat\\[.+\\]: Failed/ {print 1}'")
            res = f:read()
            f:close()
            if res == '1' then return 'LTE modem is not responding' end

            count = count+1
        end

        -- no chat activity
        if count >= MAX_CHAT_DELAY then
            return 'CHAT is not working'
        end

        -- wait until get ppp connection
        count = 0
        while(count < MAX_PPPD_DELAY) do
            os.execute('sleep 1')
            -- waiting for the pppd to connect
            -- pppd[1234]: Connect 3g-lte <--> /dev/ttyS2
            f = io.popen("logread | awk '/pppd\\[.+\\]: Connect/ {print 1}'")
            res = f:read()
            f:close()
            if res == '1' then return 'LTE network connected' end

            -- or pppd failed
            -- pppd[1234]: Connection script failed
            f = io.popen("logread | awk '/chat\\[.+\\]: Connection script failed/ {print 1}'")
            res = f:read()
            f:close()
            if res == '1' then return 'PPPD failed to connect' end

            count = count+1
        end

        -- no chat activity
        if count >= MAX_PPPD_DELAY then
            return 'PPPD is not working'
        end

    end
end

--
-- Shutdown a network interface
--
function shutdown_network(iface)

    if iface == 'ap' then
        os.execute('ifdown wlan > /dev/null 2>&1')
        os.execute('sleep ' .. tostring(AP_DN_DELAY))
        return 'AP is down'

    elseif iface == 'sta' then
		-- DO NOT USE ifdown, which does not prevent the apcli0 from scanning
        -- os.execute('ifdown wwan > /dev/null 2>&1')
        os.execute('uci set wireless.sta.disabled=1')
        os.execute('uci commit wireless')
        os.execute('wifi')
        os.execute('sleep ' .. tostring(STA_DN_DELAY))
        return 'WiFi is down'

    elseif iface == 'eth' then
        os.execute('ifdown wan > /dev/null 2>&1')
        os.execute('sleep ' .. tostring(ETH_DN_DELAY))
        return 'Ethernet is down'

    elseif iface == 'lte' then
        os.execute('ifdown lte > /dev/null 2>&1')
        os.execute('sleep ' .. tostring(LTE_DN_DELAY))
        return 'LTE network is down'
    end

end

--------------------------------------------------------------------------------
-- Entry point of the CGI
--------------------------------------------------------------------------------
function handle_request(env)

    -- GET, PUT, POST,
    local method = env["REQUEST_METHOD"]
    -- decode url in a table: url[1],url[2],url[3]
    local url = decode_url(env["PATH_INFO"])
    -- decode query in a table: qry["name"] == "ferret"
    local qry = decode_query(env["QUERY_STRING"])
    -- server ip among other things
    params['ip'] = env["SERVER_ADDR"]

    --[[ debug: raw env table
    uhttpd.send("Status: 200 OK\r\n")
    uhttpd.send("Content-Type: text/plain\r\n\r\n")

    for k,v in pairs(env) do
        if type(v) == "string" then
            uhttpd.send(string.format("key:%s, value:%s\r\n", k,v))
        elseif type(v) == "number" then
            uhttpd.send(string.format("key:%s, value:%f\r\n", k,v))
        elseif type(v) == "integer" then
            uhttpd.send(string.format("key:%s, value:%d\r\n", k,v))
        elseif type(v) == "table" then
            uhttpd.send(string.format("key:%s\r\n", k))
            for l,w in pairs(v) do
                uhttpd.send(string.format("  key:%s, value:%s\r\n", l,w))
            end
        end
    end
    --]]

    --[[ debug: decoded
    uhttpd.send("Status: 200 OK\r\n")
    uhttpd.send("Content-Type: text/plain\r\n\r\n")

    uhttpd.send(string.format("METHOD: %s\r\n",env["REQUEST_METHOD"]))
    uhttpd.send(string.format("URL: %s\r\n",env["PATH_INFO"]))
    for k,v in ipairs(url) do
        uhttpd.send(string.format("  %d: %s\r\n",k, url[k]))
    end
    uhttpd.send(string.format("QUERY: %s\r\n",env["QUERY_STRING"]))
    for k,v in pairs(qry) do
        uhttpd.send(string.format("  %s: %s\r\n",k, qry[k]))
    end
    --]]

    ---[[

    -- GET ---------------------------------------------------------------------
    -- -------------------------------------------------------------------------
    if method == 'get' or method == 'GET' then

        -- (GET) root ----------------------------------------------------------
        if #url == 0 then
            init_params('all')
            send_file("index.html")

        elseif url[1] == "favicon.ico" then
            send_file("favicon.ico")

        elseif url[1] == "css" or url[1] == "images" or url[1] == "fonts" then
            send_file(url[2])

        -- (GET) system --------------------------------------------------------
        elseif url[1] == "system" then
            update_params("ap")
            send_html("system.html")

        -- (GET) network -------------------------------------------------------
        elseif url[1] == "network" then
            update_params("sta")
            update_params("eth")
            update_params("lte")
            update_params('control')
            send_html("network.html")

        -- (GET) modem ---------------------------------------------------------
        elseif url[1] == "modem" then
            update_params("lte")
            if params["lte up"] == "up" then
                send_message("LTE netwwork is running...\r\nShut it down first.")
            else
                update_params("modem")
                send_html("modem.html")
            end

        -- (GET) api -----------------------------------------------------------
        elseif url[1] == "api" then

            -- api/state
            if url[2] == "state" then
                uhttpd.send("Status: 200 OK\r\n")
                uhttpd.send("Content-Type: text/plain; charset=utf-8\r\n\r\n")
                if url[3] == "lte" then
                    update_params("lte")
                    uhttpd.send(cjson.encode(params))
                end

            -- api/modem
            elseif url[2] == "modem" then
                uhttpd.send("Status: 200 OK\r\n")
                uhttpd.send("Content-Type: text/plain; charset=utf-8\r\n\r\n")
                -- api/modem/cops
                if url[3] == "cops" then
                    local err,port = rs232.open('/dev/ttyS2')
                    if err == rs232.RS232_ERR_NOERROR then
                        local result = get_at_response(port, "AT+COPS=?", 120)
                        if result['status'] == 'OK' then
                            uhttpd.send(result["+COPS"])
                        else
                            uhttpd.send('Failed to scan operators')
                        end
                        port:close()
                    else
                        uhttpd.send('Failed to open the serial port')
                    end
                end

            -- api/syslog
            elseif url[2] == "syslog" then

                os.execute("logread > /tmp/syslog")
                local f = io.open("/tmp/syslog", "r")
                local content = f:read("*all")
                f:close()

                uhttpd.send("Status: 200 OK\r\n")
                uhttpd.send("Content-Type: text/plain; charset=utf-8\r\n\r\n")
                uhttpd.send(content)

            -- api/chatscripts
            elseif url[2] == "chatscripts" then
                local res = '{\"chatscripts\":['
                f = io.popen("find /root/config/chatscripts -type f | sort")
                for item in f:lines() do
                    res = res
                            .. '\"'
                            .. item:gsub("/root/config/chatscripts/","")
                            .. '\",'
                end
                f:close()
                res = res:sub(1,-2)
                res = res .. ']}'

                uhttpd.send("Status: 200 OK\r\n")
                uhttpd.send("Content-Type: text/plain; charset=utf-8\r\n\r\n")
                uhttpd.send(res)

            -- api/profiles
            elseif url[2] == "profiles" then
                local res = '{\"profiles\":['
                local f = io.popen("find /root/config/profiles -type f | sort")
                for item in f:lines() do
                    res = res
                            .. '\"'
                            .. item:gsub("/root/config/profiles/","")
                            .. '\",'
                end
                f:close()
                res = res:sub(1,-2)
                res = res .. ']}'

                uhttpd.send("Status: 200 OK\r\n")
                uhttpd.send("Content-Type: text/plain; charset=utf-8\r\n\r\n")
                uhttpd.send(res)

            end

        else
            uhttpd.send("Status: 400 Bad Request\r\n\r\n")
        end

    -- POST --------------------------------------------------------------------
    -- -------------------------------------------------------------------------
    elseif method == 'post' or method == 'POST' then

        local arg = io.stdin:read("*all")
        post = decode_post(arg)

        --[[ debug
        uhttpd.send("Status: 200 OK\r\n")
        uhttpd.send("Content-Type: text/plain\r\n\r\n")

        uhttpd.send(string.format("METHOD: %s\r\n",env["REQUEST_METHOD"]))
        uhttpd.send(string.format("URL: %s\r\n",env["PATH_INFO"]))
        for k,v in ipairs(url) do
            uhttpd.send(string.format("  %d: %s\r\n",k, url[k]))
        end
        uhttpd.send(string.format("QUERY: %s\r\n",env["QUERY_STRING"]))
        for k,v in pairs(qry) do
            uhttpd.send(string.format("  %s: %s\r\n",k, qry[k]))
        end
        uhttpd.send(string.format("arg: %s\r\n",arg))
        for k,v in pairs(post) do
            uhttpd.send(string.format("  %s: %s\r\n",k, post[k]))
        end
        --]]

        -- (POST) root ---------------------------------------------------------
        if #url == 0 then
            uhttpd.send("Status: 404 Not Found\r\n\r\n")

        -- (POST) system -------------------------------------------------------
        elseif url[1] == "system" then
            -- return message
            local message = ""

            -- password
            if post["password"] ~= nil then
                -- remove root password
                if post["password"] == "NULL" then
                    os.execute('passwd -d root > /dev/null 2>&1')
                    message = "Root password removed"
                -- change root password
                else
                    os.execute("echo 'root:" .. post["password"]
                        .. "'|chpasswd > /dev/null 2>&1")
                    message = "Root password changed"
                end
            end

            -- reset parameters to default
            if post["reset"] ~= nil then
                -- all
                if post["reset"] == "yes" then
                    os.execute('/root/bin/reset_parameters.sh > /dev/null 2>&1')
                    message = "Network parameters reset"
                end
            end

            -- oled control
            if post['oled'] ~= nil then
                -- system
                if post["oled"] == "system" then
                    os.execute('uci set ncd.oled.control=system')
                    os.execute('uci commit ncd')
                -- user
                else
                    os.execute('uci set ncd.oled.control=user')
                    os.execute('uci commit ncd')
                    local payload = string.gsub(post['content'], "\n", "\\n")
                    os.execute('oled-exp -i write "' .. payload
                        .. '" > /dev/null 2>&1')
                end
                message = 'OLED content changed'
            end

            -- color led control
            if post['red'] ~= nil then
                if post['red'] == 'on' then
                    os.execute('gpioctl dirout-low ' .. tostring(LED_RED)
                        .. ' > /dev/null 2>&1')
                else
                    os.execute('gpioctl dirout-high ' .. tostring(LED_RED)
                        .. ' > /dev/null 2>&1')
                end
                message = 'Color LED changed'
            end
            if post['green'] ~= nil then
                if post['green'] == 'on' then
                    os.execute('gpioctl dirout-low ' .. tostring(LED_GREEN)
                        .. ' > /dev/null 2>&1')
                else
                    os.execute('gpioctl dirout-high ' .. tostring(LED_GREEN)
                        .. ' > /dev/null 2>&1')
                end
                message = 'Color LED changed'
            end
            if post['blue'] ~= nil then
                if post['blue'] == 'on' then
                    os.execute('gpioctl dirout-low ' .. tostring(LED_BLUE)
                        .. ' > /dev/null 2>&1')
                else
                    os.execute('gpioctl dirout-high ' .. tostring(LED_BLUE)
                        .. ' > /dev/null 2>&1')
                end
                message = 'Color LED changed'
            end

            -- restart service
            if post['restart'] ~= nil then
                os.execute("/etc/init.d/" .. post['restart'] .. " restart")
                message = post['restart'] .. ' will be restarted'
            end

            -- device reboot
            if post['reboot'] ~= nil then
                if post['reboot'] == 'yes' then
                    os.execute("oled-exp -i > /dev/null 2>&1");
                    os.execute('sync')
                    os.execute('reboot > /dev/null 2>&1')
                    message = 'System will reboot shortly'
                end
            end

            -- device shutdown
            if post['shutdown'] ~= nil then
                if post['shutdown'] == 'yes' then
                    os.execute("oled-exp -i > /dev/null 2>&1");
                    os.execute('sync')
                    os.execute('halt > /dev/null 2>&1')
                    message = 'System shutdown started'
                end
            end

            send_response(200, message)

        -- (POST) ap -----------------------------------------------------------
        elseif url[1] == "ap" then

            -- ssid
            if post["ssid"] ~= nil then
                os.execute('uci set wireless.ap.ssid=' .. post['ssid'])
            end
            -- passkey
            if post["key"] ~= nil then
                os.execute('uci set wireless.ap.key=' .. post['key'])
            end

            --[[
            -- power state
            if post["state"] ~= nil then
                if post['state'] == 'enable' then
                    os.execute('uci set wireless.ap.disabled=0')
                else
                    os.execute('uci set wireless.ap.disabled=1')
                end
            end
            --]]

            -- ipaddr
            if post["ipaddr"] ~= nil then
                os.execute('uci set network.wlan.ipaddr=' .. post['ipaddr'])
            end

            os.execute('uci commit wireless')
            os.execute('uci commit network')

            send_response(200, 'Access Point parameters changed')

        -- (POST) sta ----------------------------------------------------------
        elseif url[1] == "sta" then
            -- get current status
            update_params('sta')

            --[[
            -- power state
            if post["state"] ~= nil then
                if post['state'] == 'enable' then
                    os.execute('uci set wireless.sta.disabled=0')
                else
                    os.execute('uci set wireless.sta.disabled=1')
                end
            end
            --]]

            -- protocol
            if post["proto"] ~= nil then
                os.execute('uci set network.wwan.proto=' .. post['proto'])
            end
            -- ipaddr
            if post["ipaddr"] ~= nil then
                os.execute('uci set network.wwan.ipaddr=' .. post['ipaddr'])
            end
            -- netmask
            if post["netmask"] ~= nil then
                os.execute('uci set network.wwan.netmask=' .. post['netmask'])
            end
            -- gateway
            if post["gateway"] ~= nil then
                os.execute('uci set network.wwan.gateway=' .. post['gateway'])
            end
            -- dns
            if post["dns"] ~= nil then
                os.execute('uci set network.wwan.dns=' .. post['dns'])
            end
            -- metric
            if post["metric"] ~= nil then
                os.execute('uci set network.wwan.metric=' .. post['metric'])
            end

            -- ssid and key
            if post["ssid"] ~= nil and post["key"] ~= nil then

                os.execute('wifisetup remove -ssid ' .. params['sta ssid']
                    .. ' > /dev/null 2>&1')
                os.execute('wifisetup add -ssid ' .. post['ssid']
                    .. ' -encr psk2 -password ' .. post['key']
                    .. ' > /dev/null 2>&1')
            end

            os.execute('uci commit network')
            os.execute('uci commit wireless')

            send_response(200, 'Wi-Fi Network parameters changed')


        -- (POST) eth ----------------------------------------------------------
        elseif url[1] == "eth" then
            -- get current status
            update_params('eth')

            -- protocol
            if post["proto"] ~= nil then
                os.execute('uci set network.wan.proto=' .. post['proto'])
            end
            -- gateway
            if post["gateway"] ~= nil then
                os.execute('uci set network.wan.gateway=' .. post['gateway'])
            end
            -- netmask
            if post["netmask"] ~= nil then
                os.execute('uci set network.wan.netmask=' .. post['netmask'])
            end
            -- ipaddr
            if post["ipaddr"] ~= nil then
                os.execute('uci set network.wan.ipaddr=' .. post['ipaddr'])
            end
            -- dns
            if post["dns"] ~= nil then
                os.execute('uci set network.wan.dns=' .. post['dns'])
            end
            -- metric
            if post["metric"] ~= nil then
                os.execute('uci set network.wan.metric=' .. post['metric'])
            end

            os.execute('uci commit network')

            send_response(200, 'Ethernet Network parameters changed')

        -- (POST) lte ----------------------------------------------------------
        elseif url[1] == "lte" then
            -- get current status
            update_params('lte')

            -- apn
            if post['apn'] ~= nil then
                os.execute('uci set network.lte.apn=' .. post['apn'])
            end

            -- chatscript
            if post['chatscript'] ~= nil then
                os.execute('cp /root/config/chatscripts/'
                    .. post['chatscript'] .. ' /etc/chatscripts/3g.chat')
                -- change apn as well
                local apn = post['chatscript']
                    :sub(1,post['chatscript']:find("%.")-1)
                os.execute('uci set network.lte.apn=' .. apn)
            end

            os.execute('uci commit network')

            send_response(200, 'LTE Network parameters changed')

        -- (POST) network ------------------------------------------------------
        elseif url[1] == "network" then
            -- return message
            --local message = " --- "

            -- new method
            if post['select'] ~= nil then


                if post['select'] == 'eth' then
                    os.execute('uci set ncd.control.eth_state=up')
                    os.execute('uci set ncd.control.sta_state=down')
                    os.execute('uci set ncd.control.lte_state=down')
                    os.execute('uci commit ncd')
                    os.execute('/root/bin/enable_network.lua eth')
                elseif post['select'] == 'sta' then
                    os.execute('uci set ncd.control.eth_state=down')
                    os.execute('uci set ncd.control.sta_state=up')
                    os.execute('uci set ncd.control.lte_state=down')
                    os.execute('uci commit ncd')
                    os.execute('/root/bin/enable_network.lua sta')
                elseif post['select'] == 'lte' then
                    os.execute('uci set ncd.control.eth_state=down')
                    os.execute('uci set ncd.control.sta_state=down')
                    os.execute('uci set ncd.control.lte_state=up')
                    os.execute('uci commit ncd')
                    os.execute('/root/bin/enable_network.lua lte')
                end

                local message = post['select'] .. ' will be enabled'
                send_response(200, message)
            end

            --[[
            if post['ap'] ~= nil then
                if post['ap'] == 'up' then
                    message = bringup_network('ap')

                elseif post['ap'] == 'down' then
                    message = shutdown_network('ap')
                end
            end

            if post['sta'] ~= nil then
                if post['sta'] == 'up' then
                    message = bringup_network('sta')

                elseif post['sta'] == 'down' then
                    message = shutdown_network('sta')
                end
            end

            if post['eth'] ~= nil then
                if post['eth'] == 'up' then
                    message = bringup_network('eth')

                elseif post['eth'] == 'down' then
                    message = shutdown_network('eth')
                end
            end

            if post['lte'] ~= nil then

                if post['lte'] == 'up' then
                    message = bringup_network('lte')
                elseif post['lte'] == 'down' then
                    message = shutdown_network('lte')
                end
            end
            --]]

            --send_response(200, message)

        -- (POST) control ------------------------------------------------------
        elseif url[1] == "control" then

            -- mode
            if post['mode'] ~= nil then
                os.execute('uci set ncd.control.ctrl_mode="'
                        .. post['mode'] .. '"')

                if post['mode'] == 'automatic' then
                    if post['eth'] ~= nil then
                        os.execute('uci set ncd.control.eth_iface="'
                                .. post['eth'] .. '"')
                    end
                    if post['sta'] ~= nil then
                        os.execute('uci set ncd.control.sta_iface="'
                                .. post['sta'] .. '"')
                    end
                    if post['lte'] ~= nil then
                        os.execute('uci set ncd.control.lte_iface="'
                                .. post['lte'] .. '"')
                    end
                end
            end
            if post['target'] ~= nil then
                os.execute('uci set ncd.control.target_ep="'
                        .. post['target'] .. '"')
            end
            os.execute('uci commit ncd')

            send_response(200, 'Network Control mode changed')

        -- (POST) modem --------------------------------------------------------
        elseif url[1] == "modem" then

            -- at command
            if post['atcmd'] ~= nil then
                -- replace .eq. with =
                local atcmd = string.gsub(post['atcmd'],".eq.","=")
                -- process the command
                process_at_command(atcmd)
            end

            -- profile
            if post['profile'] ~= nil then
                -- get profile script
                local f = io.open('/root/config/profiles/' .. post['profile'])
                -- run the script
                process_at_command(f:read("*all"))
                f:close()
            end

            -- state command
            if post['state'] ~= nil then
                if post['state'] == 'up' then
                    os.execute('/root/bin/modem_pwrup.sh > /dev/null 2>&1')
                elseif post['state'] == 'down' then
                    os.execute('/root/bin/modem_pwrdn.sh > /dev/null 2>&1')
                elseif post['state'] == 'emgr' then
                    os.execute('/root/bin/modem_emoff.sh > /dev/null 2>&1')
                elseif post['state'] == 'factory' then
                    os.execute('/root/bin/modem_inf.lua "AT&F" > /dev/null 2>&1')
                end
            end

            send_response(200, 'Modem State changed')

        end
    end
    --]]
end
