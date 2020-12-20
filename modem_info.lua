#!/usr/bin/lua

local rs232 = require('luars232')
local out = io.stderr
local err,port = rs232.open('/dev/ttyS2')

function get_at_response(cmd, timeout)

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


if err ~= rs232.RS232_ERR_NOERROR then
    out:write(string.format('Cannot open serial port: %d\n', err))
    return
end

port:set_baud_rate(rs232.RS232_BAUD_115200)
port:set_data_bits(rs232.RS232_DATA_8)
port:set_parity(rs232.RS232_PARITY_NONE)
port:set_stop_bits(rs232.RS232_STOP_1)
port:set_flow_control(rs232.RS232_FLOW_OFF)

if arg[1] == nil then
    arg[1] = 'ati'
end

if arg[2] == nil then
    arg[2] = '1'
end

local result = get_at_response(arg[1], tonumber(arg[2]))

for k,v in pairs(result) do
    print(string.format('%s: %s', k, v))
end

port:close()
