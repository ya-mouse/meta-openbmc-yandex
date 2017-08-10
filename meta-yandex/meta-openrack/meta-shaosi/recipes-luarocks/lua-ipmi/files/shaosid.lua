#!/usr/bin/lua
local nixio = require 'nixio'
local bit = require 'bit'
-- local sensors = require 'sensors'
local uloop = require 'uloop'
local ipmi = require 'ipmi'
local bin = require 'struct'
local cjson = require 'cjson'

local cjson_encode = cjson.encode
local stunpack = bin.unpack
local sub = string.sub
local byte = string.byte
local band, bxor = bit.band, bit.bxor

local board_number = nixio.open('/etc/openrack-board'):read(16):sub(1, -2)
if board_number:sub(1, 3) ~= 'CB-' then
     return
end

uloop.init()

local pollgpio = { }
local presence = { }
local nodegpio = { 0, 1, 2, 3, 4, 5 } -- 72, 73, 74, 75, 48, 49, 50, 51 }

-- local hwmon = sensors:new()

function init_gpio(base, n)
    local gp = tostring(base + n)
    local path = '/sys/class/gpio/gpio'..gp..'/value'
    local f = nixio.open(path, 'r+')
    if not f then
        f = nixio.open('/sys/class/gpio/export', 'w'); f:write(gp); f:close()
--        f = nixio.open('/sys/class/gpio/gpio'..gp..'/edge', 'w'); f:write('both'); f:close()
        f = nixio.open(path, 'r+')
    end
    getmetatable(f).getfd = function(self) return tonumber(tostring(self):sub(11)) end
    return f
end

-- Table for dtoverlay invocation serialization
local overlay_acts = { }
local overlay_lock = { }

--
-- Node change handler
--
for i, n in pairs(nodegpio) do
    local f = init_gpio(304, n) -- 320 - base SoC
    local timer
    -- presence[f].ev = uloop.fd_add(f, function(ufd, events)
    -- ...
    -- end, uloop.ULOOP_READ + uloop.ULOOP_EDGE_TRIGGER + 0x40) -- uloop.ULOOP_ERROR_CB
    presence[f] = setmetatable({ n = tostring(i), v = false, ev = false, f = f }, {
        __call = function(tbl)
            timer:set(1000)
            local ufd = tbl.f
            ufd:seek(0, "set")
            local v = tonumber(ufd:read(2)) == 0
            local p = tbl
            -- print(v, '<>', p.v)
            if p.v ~= v then
                print(p.n, 'CHANGED', p.v, v)
                p.v = v
                if not overlay_acts[p.n] then overlay_acts[p.n] = {} end
                table.insert(overlay_acts[p.n], v)
            end
       end
    })
    timer = uloop.timer(presence[f], 1000)
    presence[f].timer = timer
end

local ipmi_ev = {}
local ipmi_devs = {}

local db_resty = nixio.socket('unix', 'stream')
if not db_resty:connect('/run/openresty/socket') then exit(-1) end
getmetatable(db_resty).getfd = function(self) return tonumber(tostring(self):sub(13)) end
getmetatable(db_resty).request = function(self, devnum, name, value, method)
    -- TODO: keep values in array and post it independetly in coroutine
    local body = cjson_encode({ data = value })
    if name ~= '' then name = '/'..name end
    if type(devnum) == 'number' then devnum = devnum + 1 end
    body = (method or 'POST')..' /api/storage/'..board_number..'/'..tostring(devnum)..name.." HTTP/1.1\r\nUser-Agent: collector/1.0\r\nAccept: */*\r\nHost: localhost\r\nContent-type: application/json\r\nConnection: keep-alive\r\nContent-Length: "..#body.."\r\n\r\n"..body.."\r\n\r\n"
    local cnt, errno, errmsg = db_resty:write(body)
    if errno ~= nil then
        -- print('RECONNECT', errno, errmsg)
        db_resty:close()
        db_resty = nixio.socket('unix', 'stream')
        db_resty:connect('/run/openresty/socket')
        uloop.fd_add(db_resty, resty_event, uloop.ULOOP_READ + 0x40)
        if db_resty:write(body) == nil then print('WRITE failed') end
    end
end
local db_que = {}

local L_ipmi_scope = 'eth1'

local O_ipmi_sdrs = {}
local L_ipmi_sdrs = {
  -- pattern | round | ttl | *replace pattern
  {'CPU[0-9]_TEMP', 2, 60.0},
  {'NVME_([0-9])_TEMP', 2, 60.0},
  {'SATA[0-9]+_TEMP', 2, 60.0},
  {'SIO_TEMP_[0-9]', 2, 60.0},
  {'BP[12]_HDD_TEMP[12]', 2, 60.0},
  {'.+_TEMP', 2, 60.0},
  {'SYS_PWR', 2, 60.0},
  {'P12V', 2, 60.0},
  {'SATA[0-9]+_STAT', 2, 60.0},
  {'P0N[01]_STAT', 2, 60.0},
  {'SATA[0-9]+_P1N[01]_STAT', 2, 60.0},
}

local rounds = 0
local L_ipmi_cmds
local O_ipmi_cmds = {
    [9] = {
        { function(self, response)
            if #response == 7 then return true end
            if #response ~= 41 then return false end
            local ip = ''
            local getmac = function(o)
                local s, i
                s = ''
                for i=0,5 do
                    s = s .. string.format('%02x:', tonumber(response:byte(o+i) or 0))
                end
                return s:sub(1, -2)
            end
            local i
            for i=0,3 do
                ip = ip .. string.format('%d.', response:byte(8+i))
            end
            ip = ip:sub(1, -2)
            db_resty:request(self.n, 'ipv4', ip)
            -- if self._lan == nil then
            --    L_ipmi_add(self.n, ip)
            -- end
            for i=0,3 do
                local n = string.format('mac/eth%d', i-1)
                local mac = getmac(8+4 + 6*i)
                if i == 0 then
                    L_ipmi_add(self.n, response:byte(8+4 + 6*i, 8+4 + 6*(i+1) - 1))
                    n = 'mac/ipmi'
                end
                print(self.n, i, mac)
                if mac ~= '00:00:00:00:00:00' then db_resty:request(self.n, n, mac) end
            end
            return true
        end, 0x38, 0x30, 0x02 },
    },
}

L_ipmi_cmds = {
    [0] = {
        { function(self, response)
          if #response < 11 then return false end
          local sescnt = band(response:byte(8+3), 0x3f)
          if sescnt >= 10 and not (self._mfg == 42385 and obj._prod == 1) then -- exclude AIC RMM
              print(self.n, 'Maximum session count exceeded', sescnt, 'Restart BMC')
              self:_send_payload(0x6, 0x02)
              self._stopped = true
              self._logged = false
          end
          -- print('SESS INFO:'..tostring(self.n), band(response:byte(8+3), 0x3f), self._ver, self._mfg, self._prod, self._builtin_sdr)
        end, 0x6, 0x3d },
    },

    [10] = {
        { function(self, response)
            if #response == 7 then return true end
            local rackid = string.gsub(response:sub(8+5, 8+14), '[^a-zA-Z0-9_.-]', '')
            if not self._debug then print('rackid', rackid) end
            db_resty:request(self.n, 'type', response:byte(8+3))
            db_resty:request(self.n, 'rackid', rackid)
            db_resty:request(self.n, 'slotid', response:byte(8+15))
        end, 0x38, 0x30, { 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 } },
        { function(self, response)
            if #response < 12 then return false end
            v6len = tonumber(response:byte(8+3))
            if v6len > 1 then
                db_resty:request(self.n, 'ipv6', string.sub(response, 8+4, 8+4+v6len-1))
            end
        end, 0x2e, 0x21, { 0x0a, 0x3c, 0, 4, 2 } },
    },

    sdr_read = function(self, name, value)
        db_que[name] = value
        if self._DEBUG then print('GOT READ: ', self.n, name, value, 'round', self._round, 'retries', self._retry, 'stopped', self._stopped, 'logged', self._logged, 'tout', self._timedout) end
        self._retry = 0
        db_resty:request(self.n, name, { value = value, duration = self.sdr_ttl[name] })
    end,

    ready = function(self)
        -- Add Session ID to the command's param
        self._fpn[self._cmds[10][1][1]] = '_recv_38_30_00'
        self._cmds[0][1][4] = '\xff' .. self._sessionid

        if not self._DEBUG then print('READY', self.n, self.ip, cjson_encode(self.sdr_names)) end
        if next(self.sdr_names) ~= nil then
            db_resty:request(self.n, '', cjson_encode(self.sdr_names))
        end
    end
}

function ipmi_uloop_cb(ufd, events)
        local icli = ipmi_ev[ufd:getfd()]
        if icli then
           if events ~= 1 and icli.ip ~= nil then
               print('\n\n               CLOSE IPMI', icli.n, '\n')
               L_ipmi_del(icli.n)
               return
           end
           local rc = icli:recv()
           if rc and not icli._stopped then
           -- if not icli._logged or not icli._stopped then
               icli:send()
           end
        end
end

function update_nodes_list()
    local k, nodes
    nodes = {}
    for k, _ in pairs(ipmi_devs) do
        table.insert(nodes, k+1)
    end
    db_resty:request('nodes', '', cjson_encode(nodes))
end

function O_ipmi_add(devnum)
    if ipmi_devs[devnum] ~= nil then return end

    -- if devnum ~= 2 then return end

    local oip = ipmi.open:new(devnum, O_ipmi_cmds, O_ipmi_sdrs, 4)
    local ufd = oip.f:getfd()
    ipmi_ev[ufd] = oip
    ipmi_devs[devnum] = ufd
    -- oip._DEBUG = true

    local u = uloop.fd_add(oip.f, ipmi_uloop_cb, uloop.ULOOP_READ)
    oip._u = u
    oip._stopped = false
    oip:send()
    db_resty:request(devnum, 'presence', 1)

    update_nodes_list()
end

function L_ipmi_add(devnum, ...)
    local ufd = ipmi_devs[devnum]
    local oip = ipmi_ev[ufd]
    if oip == nil or oip._lan ~= nil then return end

    if select('#', ...) ~= 6 then return end

    local ip = string.format('fe80::%x%02x:%xff:fe%02x:%x%02x%%%s',
        bxor(select(1, ...), 2), select(2, ...),
        select(3, ...), select(4, ...),
        select(5, ...), select(6, ...),
        L_ipmi_scope)

    local sock, code, err = nixio.connect(ip, 623, 'any', 'dgram')
    if sock == nil then
        print(devnum, 'Unable to connect to', ip, 'with', code, err)
        return
    end

    local lip = ipmi.lan:new(sock, 'ADMIN', 'ADMIN', L_ipmi_cmds, L_ipmi_sdrs)
    local ufd = sock:getfd()
    ipmi_ev[ufd] = lip
    oip._lan = ufd
    lip.n = devnum
    lip.ip = ip
    -- oip._DEBUG = true
    -- lip._DEBUG = true

    local u = uloop.fd_add(sock, ipmi_uloop_cb, uloop.ULOOP_READ + 0x40)
    lip._u = u
    lip._stopped = false
    lip:send()
end

function O_ipmi_del(devnum)
    local ufd = ipmi_devs[devnum]
    if ufd == nil then return end
    local oip = ipmi_ev[ufd]
    local sdr
    db_resty:request(devnum, 'presence', nil, 'DELETE')
    db_resty:request(devnum, '', nil, 'DELETE')
    for _, sdr in pairs(oip.sdr_names) do
        db_resty:request(devnum, sdr, nil, 'DELETE')
    end
    local i
    db_resty:request(devnum, 'ipv4', nil, 'DELETE')
    db_resty:request(devnum, 'mac/ipmi', nil, 'DELETE')
    for i=1,3 do
        db_resty:request(devnum, string.format('mac/eth%d', i), nil, 'DELETE')
    end
    oip:close()

    L_ipmi_del(devnum)

    ipmi_ev[ufd] = nil
    ipmi_devs[devnum] = nil 

    update_nodes_list()
end

function L_ipmi_del(devnum)
    local ufd = ipmi_devs[devnum]
    if ufd == nil then return end
    local oip = ipmi_ev[ufd]
    if oip == nil or oip._lan == nil then return end

    local lip = oip._lan
    lip:close()

    oip._lan = nil
end

function resty_event(ufd, events)
    local d, errno, errmsg = ufd:read(4096)
    if d == '' or d == nil then
        -- print('RECONNECT', events)
        db_resty:close()
        db_resty = nixio.socket('unix', 'stream')
        db_resty:connect('/run/openresty/socket')
        uloop.fd_add(db_resty, resty_event, uloop.ULOOP_READ + 0x40)
--    else
--        print('RESTY: ', tostring(d), #db_que, events)
    end
end

local r = uloop.fd_add(db_resty, resty_event, uloop.ULOOP_READ + 0x40)

update_nodes_list()

local sdr_timer
local dtoverlay_support = true
sdr_timer = uloop.timer(function()
    sdr_timer:set(3000)

    local k, v, t, i

    rounds = rounds + 1
    --
    -- TODO: do this in separate timer event
    --

    -- Check overlay kernel layer presence
    if not dtoverlay_support then goto skip end
    if not nixio.fs.access('/sys/kernel/config/device-tree/overlays', 'x') then
        -- Should never happen
        print('ERROR: Lack of overlay support')
        dtoverlay_support = false
        goto skip
    end

    -- Check dtoverlay queue
    for k, t in pairs(overlay_acts) do
        if not overlay_lock[k] then
            -- Process only one action per node at once
            local overlay = 'node'..k

            i = -1
            for v in nixio.fs.dir('/sys/kernel/config/device-tree/overlays') do
                local name
                i, name = v:match('^(%d+)_(.+)$')
                if name == overlay then break end
                i = -1
            end

            -- Compact actions by removing duplicate add/remove
            local action_add
            if #t > 2 then
                if i ~= -1 then
                    -- A: R A
                    overlay_acts[k] = { true }
                    action_add = false
                else
                    -- R: A
                    overlay_acts[k] = nil
                    action_add = true
                end
            else
                action_add = table.remove(t, 1)

                -- Remove from the queue
                if #overlay_acts[k] == 0 then overlay_acts[k] = nil end
            end


            -- Sanity check
            local args
            if not action_add then
                if i ~= -1 then
                    args = { '-r', i }
                end
                O_ipmi_del(k-1)
            elseif i == -1 then
                -- Run when no same overlay loaded
                args = { overlay }
                O_ipmi_add(k-1)
            end

            -- Lock and run
            if args then
                overlay_lock[k] = true
                uloop.process('/usr/bin/dtoverlay', args, { NODE = k }, function(ret)
                    -- if ret == 0 then hwmon:load() end
                    overlay_lock[k] = false
                end)
            end
        end
    end

    ::skip::

    for k,v in pairs(ipmi_ev) do
        v:process_commands()
    end

    -- Process sensors
    -- print('========')
--     for k,v in pairs(hwmon._s) do
--         print(v.label, v:value())
--     end
end, 1000)

uloop.run()
