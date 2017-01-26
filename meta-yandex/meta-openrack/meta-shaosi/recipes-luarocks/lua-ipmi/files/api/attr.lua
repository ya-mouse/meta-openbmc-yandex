local ldbus = dbus
local log = ngx.log
local ERR = ngx.ERR
local _M = { AUTHORIZE = true }

function _M.get(self)
    local run = 1 
    local res = ''
    local path = '/'..self.match.path
    local oid

    local ok = ldbus.call('GetObject', function(obj)
        local k, v, ifaces
        run = 0
        if type(obj) ~= 'table' then
            res = obj
            return
        end
        for k, v in pairs(obj) do
            oid = k
            ifaces = v
        end
        for _, v in ipairs(ifaces) do
            ok = dbus.property.getall(function(...)
                local k1, v2
                for k1, v2 in pairs(...) do
                   res = res .. tostring(k1)..'='..tostring(v2).. " ; ".. "\n"
                end
                run = run - 1
            end, { bus = 'system', interface = v, path = path, destination = oid })
            if ok then run = run + 1 end
        end
    end, {
        bus = 'system',
        path = '/xyz/openbmc_project/ObjectMapper',
        interface = 'xyz.openbmc_project.ObjectMapper',
        destination = 'xyz.openbmc_project.ObjectMapper',
        args = { 's', path, 'as', { } }
    })
    if not ok then run = 0 end

    -- when running
    while run ~= 0 do
        ldbus.poll()
    end

    return 'GET:'..tostring(self.match.path)..':'..tostring(self.match.prop).."===\n"..res
end

function _M.post(self)
    return 'POST:'..tostring(self.match.path)..':'..tostring(self.match.prop)
end

return _M
