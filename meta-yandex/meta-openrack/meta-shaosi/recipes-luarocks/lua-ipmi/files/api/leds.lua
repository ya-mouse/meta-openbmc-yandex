local ERR = ngx.ERR
local log = ngx.log
local read_body = ngx.req.read_body
local get_body_data = ngx.req.get_body_data
local cjson = require 'cjson'
local cjson_decode, cjson_encode = cjson.decode, cjson.encode
local gmatch = string.gmatch
local nixio = require 'nixio'

local store_db = ngx.shared.db

local leds_fd = {}
leds_fd.red   = {}
leds_fd.green = {}

local _M = { AUTHORIZE = true }

-- Functions to convert color names (red, green, yellow, off) to pair of inverted numbers (LED states)
function _M.c2nums(c)
 if c == 'r' or c == 'R' then return 1,0 end
 if c == 'g' or c == 'G' then return 0,1 end
 if c == 'y' or c == 'Y' then return 1,1 end
 if c == 'o' or c == 'O' then return 0,0 end
 return 1,1
end

function _M.nums2c(a,b)
 if a == 1 and b == 1 then return 'Y' end
 if a == 0 and b == 1 then return 'G' end
 if a == 1 and b == 0 then return 'R' end
 if a == 0 and b == 0 then return 'O' end
 return 'O'
end

-- Set LED. led is number, color is O, Y, R, G
function _M.setLed(led,color)
  local r, g = _M.c2nums(color)
  if leds_fd.red[tonumber(led)] ~= nil and leds_fd.green[tonumber(led)] ~= nil then
    local file = leds_fd.red[tonumber(led)]
    file:seek(0,"set")
    file:write(tostring(r))
    file:sync()
    file = leds_fd.green[tonumber(led)]
    file:seek(0,"set")
    file:write(tostring(g))
    file:sync()
  end
end

-- Open files and save descriptors
for led = 1,7 do
  for i, color in ipairs({'red', 'green'}) do
    local fname = '/sys/class/leds/led_'..tostring(color)..'_'..tostring(led)..'/brightness'
    local f = nixio.open(fname,'r+')
    if f == nil then
       ngx.log(ngx.STDERR,'Unable to open ', fname)
    else
       leds_fd[color][led] = f
    end
  end
end

-- Do funny test
for i, color in ipairs({'R', 'G', 'Y', 'O'}) do
  for led = 1,7 do
    _M.setLed(led,color)
    os.execute("sleep 0")
  end
end

function _M.get_json()
    read_body()
    local body, err = get_body_data()
    if not body then return nil, 'body: '..tostring(err) end
    local js, err = cjson_decode(body)
    if not js or err ~= nil then return nil, 'decode: '..tostring(err) end
    local data = js.data
    if not data then return nil, "No data" end
    return data
end

function _M.get(self)
    local inkey = self.match.key
    if inkey ~= nil and tonumber(inkey) > 0 and tonumber(inkey) < 8 then
      local colors = {}
      for i, color in ipairs({'red', 'green'}) do
        local file = leds_fd[color][tonumber(inkey)]
        if file ~= nil then
           file:seek(0,"set")
           local num = file:read(8)
           colors[color] = tonumber(num)
        else
           ngx.log(ngx.STDERR,"FD is NIL!!!!!")
        end
      end
      return cjson_encode({ data = _M.nums2c(tonumber(colors.red),tonumber(colors.green)), status = 'ok', message = '200 OK' })
    end
    return cjson_encode({ status = 'fail', message = '400 NULL REQUEST' })
end

function _M.post(self)
    local inkey = self.match.key
    local js = _M.get_json()
    if (not js or type(js) ~= 'string') then return cjson_encode({ status = 'fail', message = '400 BAD', error = err }) end
    local r, g = _M.c2nums(js)
    if leds_fd.red[tonumber(inkey)] ~= nil and leds_fd.green[tonumber(inkey)] ~= nil then
       local file = leds_fd.red[tonumber(inkey)]
       file:seek(0,"set")
       file:write(tostring(r))
       file:sync()
       file = leds_fd.green[tonumber(inkey)]
       file:seek(0,"set")
       file:write(tostring(g))
       file:sync()
    end
    return cjson_encode({ status = 'ok', message = '200 OK'})
end

return _M
