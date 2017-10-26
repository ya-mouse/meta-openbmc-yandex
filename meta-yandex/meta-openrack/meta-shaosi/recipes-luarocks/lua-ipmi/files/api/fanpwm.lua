local ERR = ngx.ERR
local log = ngx.log
local read_body = ngx.req.read_body
local get_body_data = ngx.req.get_body_data
local cjson = require 'cjson'
local cjson_decode, cjson_encode = cjson.decode, cjson.encode
local gmatch = string.gmatch
local nixio = require 'nixio'

local store_db = ngx.shared.db

-- Open files and save filedescriptors
local pwmfile_fd = {}
for i = 1,8 do
	pwmfile_fd[i] = nixio.open('/sys/class/hwmon/hwmon0/device/pwm'..tostring(i),'r+')
end

local _M = { AUTHORIZE = true }

function get_json()
    read_body()
    local body, err = get_body_data()
    if not body then return nil, 'body: '..tostring(err) end
    local js, err = cjson_decode(body)
    if not js then return nil, 'decode: '..tostring(err) end
    local data = js.data
    if not data then return nil, "No data" end

    return data
end

function _M.set_fan(fan,pwm)
  log(ngx.DEBUG,"Fan: ", fan, " PWM:", pwm)
  local file = pwmfile_fd[fan]
  file:seek(0,'set')
  file:write(tostring(pwm))
  file:sync()
end

function _M.get(self)
    local inkey = self.match.key
    if inkey ~= nil and tonumber(inkey) > 0 and tonumber(inkey) < 9 then
	local file = pwmfile_fd[tonumber(inkey)]
	if file ~= nil then
	    file:seek(0,"set")
	    local pwm = tonumber(file:read(8))

            local data = {}
	    data['FAN'] = tonumber(inkey)
	    data['PWM'] = pwm
	    data['RPM'] = tonumber(store_db:get('SELF/FAN_TACHO_'..inkey))

           return cjson_encode({ data = data, status = 'ok', message = '200 OK' })
	end
    end

    return cjson_encode({ status = 'fail', message = '400 NULL REQUEST' })
end

-- Two types of requests are processed
-- 1. FANS_PWM data:{"1":100,"2":200} - set fans in a cycle, one request per fans set
-- 2. FAN_PWM_<FAN#> data:{100} - set one fan per request
function _M.post(self)
    local inkey = self.match.key
    if  string.match(ngx.var.request_uri, "FANS_PWM") then
       local js = get_json()
       if (type(js) == "table" ) then
          for key,value in pairs(js) do
             local fan = tonumber(key)
             local pwm = tonumber(value)
             if (fan ~= nil and pwm ~= nil and fan > 0 and fan < 9 and pwm >= 0 and pwm < 256) then
                _M.set_fan(fan,pwm)
             end
          end
       return cjson_encode({ status = 'ok', message = '200 OK'})
       end
    end
    local js = get_json()
    if (not inkey or not js or type(js) ~= 'number') then return cjson_encode({ status = 'fail', message = '400 BAD', error = err }) end
    local fan = tonumber(inkey)
    local pwm = tonumber(js)
    if (fan ~= nil and pwm ~= nil and fan > 0 and fan < 9 and pwm >= 0 and pwm < 256) then
       _M.set_fan(fan, pwm)
       return cjson_encode({ status = 'ok', message = '200 OK'})
    end
    return cjson_encode({ status = 'fail', message = '400 BAD', error = "Wrong request" })
end

return _M
