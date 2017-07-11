local nixio = require 'nixio'
local bit = require 'bit'
local sensors = require 'sensors'
local uloop = require 'uloop'
local ipmi = require 'ipmi'
local bin = require 'struct'

local stunpack = bin.unpack
local sub = string.sub
local byte = string.byte
local band = bit.band

uloop.init()

local pollgpio = { }
local presence = { }
local nodegpio = { 72, 73, 74, 75, 48, 49, 50, 51 }

local hwmon = sensors:new()

function init_gpio(base, n)
    local gp = tostring(base + n)
    local path = '/sys/class/gpio/gpio'..gp..'/value'
    local f = nixio.open(path, 'r+')
    if not f then
        f = nixio.open('/sys/class/gpio/export', 'w'); f:write(gp); f:close()
        f = nixio.open('/sys/class/gpio/gpio'..gp..'/edge', 'w'); f:write('both'); f:close()
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
    local f = init_gpio(320, n)
    presence[f] = { n = tostring(i), v = false, ev = false } -- tonumber(f:read(2)) == 0, ev = false }
    presence[f].ev = uloop.fd_add(f, function(ufd, events)
        ufd:seek(0, "set")
        local v = tonumber(ufd:read(2)) == 0
        local p = presence[ufd]
        print(v, '<>', p.v)
        if p.v ~= v then
            print(p.n, 'CHANGED', p.v, v)
            p.v = v
            if not overlay_acts[p.n] then overlay_acts[p.n] = {} end
            table.insert(overlay_acts[p.n], v)
        end
    end, uloop.ULOOP_READ + uloop.ULOOP_EDGE_TRIGGER + 0x40) -- uloop.ULOOP_ERROR_CB
end

local ipmi_ev = {}
local sock, code, err = nixio.connect('2a02:6b8:0:2e0d:ffff:0:a0f:fe6c', 623)

local ipmi_cmds = {}

if sock then
    getmetatable(sock).getfd = function(self) return tonumber(tostring(self):sub(14)) end

    ipmi_ev[sock:getfd()] = ipmi.lan:new(sock, 'ADMIN', 'ADMIN', ipmi_cmds)
    ipmi_ev[sock:getfd()]:send()
else
    local oip = ipmi.open:new(0, ipmi_cmds)
    sock = oip.f

    ipmi_ev[sock:getfd()] = oip
    ipmi_ev[sock:getfd()]:send()
end

local u = uloop.fd_add(sock, function(ufd, events)
    local icli = ipmi_ev[ufd:getfd()]
    if icli then
        icli:recv()
        if not icli._logged or not icli._stopped then
            icli:send()
        end
    end
end, uloop.ULOOP_READ)

print('ULOOP', u)

local sdr_timer
local dtoverlay_support = true
sdr_timer = uloop.timer(function()
    sdr_timer:set(1000)

    local k, v, t, i

    --
    -- TODO: do this in separate timer event
    --

    -- Check overlay kernel layer presence
    if not dtoverlay_support then goto skip end
    if not nixio.fs.access('/sys/kernel/config/device-tree/overlays', 'x') then
        os.execute('/usr/bin/dtoverlay -l')
        if not nixio.fs.access('/sys/kernel/config/device-tree/overlays', 'x') then
            -- Should never happen
            print('ERROR: Lack of overlay support')
            dtoverlay_support = false
            goto skip
        end
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
            elseif i == -1 then
                -- Run when no same overlay loaded
                args = { overlay }
            end

            -- Lock and run
            if args then
                overlay_lock[k] = true
                uloop.process('/usr/bin/dtoverlay', args, { NODE = k }, function(ret)
                    if ret == 0 then hwmon:load() end
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
    print('========')
    for k,v in pairs(hwmon._s) do
        print(v.label, v:value())
    end
end, 1000)

uloop.run()
