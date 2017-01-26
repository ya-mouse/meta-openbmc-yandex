local ldbus = dbus
local ERR = ngx.ERR
local log = ngx.log
local cjson = require 'cjson'
local cjson_decode, cjson_encode = cjson.decode, cjson.encode

local _M = { AUTHORIZE = true }

function _M.post(self)
    local unit = self.match.unit

    local run, res
    run = ldbus.call('RestartUnit', function(obj)
        local k, v, ifaces
        run = false
        if type(obj) ~= 'table' then
            res = obj
            return
        end
        res = tostring(obj)
    end, {
        bus = 'system',
        path = '/org/freedesktop/systemd1',
        interface = 'org.freedesktop.systemd1.Manager',
        destination = 'org.freedesktop.systemd1',
        args = { 's', unit, 's', 'fail' }
    })

    -- when running
    while run do
        ldbus.poll()
    end

    return cjson_encode({ data = res, status = 'ok', message = '200 OK' })
end

return _M
