local nixio = require 'nixio'
local bit = require 'bit'

local dirname, basename = nixio.fs.dirname, nixio.fs.basename
local readlink, readdir = nixio.fs.readlink, nixio.fs.dir
local fopen, access = nixio.open, nixio.fs.access
local band, bor, lshift = bit.band, bit.bor, bit.lshift
local match, sub, upper = string.match, string.sub, string.upper

local _M = {}
local _S = {}

local SYSFS_HWMON = '/sys/class/hwmon/'

local SENSORS_FEATURE_IN = 0x00
local SENSORS_FEATURE_FAN = 0x01
local SENSORS_FEATURE_TEMP = 0x02
local SENSORS_FEATURE_POWER = 0x03

local function sysfs_read_attr(path, attr)
    local f = fopen(path..'/'..attr)
    if f then
        local v = f:read(256)
        f:close()
        if v then -- no IO-error
            return sub(v, 1, -2)
        end
    end
end

local function sysfs_get_attr_mode(path, attr)
    return access(path..'/'..attr, 'w')
end

local function get_value(path, attr)
    local v = sysfs_read_attr(path, attr)
    if not v then return 0 end
    return tonumber(v)
end

local M_mt = {
    __index = _M,
    __gc = function(self) print('FREE') end
}

local S_mt = {
    __index = _S,
    __eq = function(self, other)
        return self.path == other.path
    end
}

function _M.new(self)
    local t = { _s = {}, _bypath = {} }
    local prox = newproxy(true)
    getmetatable(prox).__gc = function() M_mt.__gc(t) end
    t[prox] = true
    local obj = setmetatable(t, M_mt)
    obj:load()

    return obj
end

function _M.load(self)
    -- Mark all sensors as visited
    for k,v in pairs(self._s) do
        v.visited = true
    end

    local e, he
    for e in readdir(SYSFS_HWMON) do
        local path = SYSFS_HWMON..e
        local link = path..'/device'
        local dev = readlink(link)
        if dev then
            -- read dynamic chip
            for he in readdir(path) do
                local feat, num, subfeat = match(he, '([a-z]+)(%d+)_(.+)')
                if subfeat then
                    local devn = dev..'@'..feat..num
                    local s = self._s[devn]
                    if s and s.visited then
                        -- Unmark visited flag
                        s.visited = false
                    else
                        if not s then
                            s = _S:new(path, link, dev, feat, num)
                            self._s[devn] = s
                        end
                        if s.visited == nil then
                            -- Recently added sensors, add more subfeatures to it
                            s:subfeat(subfeat)
                        end
                    end
                end
            end
        end
    end

    -- Remove all untouched
    local gc = false
    for k,v in pairs(self._s) do
        if v.visited then
            print('Remove', k)
            --
            -- FIXME: should be done in `__gc'
            --
            local f = v._subfeat.input
            if f then f:close() end
            --
            --
            self._s[k] = nil
            gc = true
        else v.visited = nil
        end
    end

    if gc then collectgarbage() end
end

local sensors_value = {
    temp = function(self)
        if self._subfeat.fault then return nil end
        return self:read_input()
    end,

    ['in'] = function(self)
        return self:read_input()
    end,

    fan = function(self)
        return self:read_input()
    end,

    power = function(self)
        return self:read_input()
    end,

    energy = function(self)
        return self:read_input()
    end,

    humidity = function(self)
        return self:read_input()
    end,

    curr = function(self)
        return self:read_input()
    end,
}

function _S.new(self, path, link, dev, feat, num)
    local label_prefix = sysfs_read_attr(path..'/of_node', 'label')
    if label_prefix then
        label_prefix = label_prefix..'_'
    else
        label_prefix = ''
    end
    local of_node = readlink(path..'/of_node') -- or '/sensor/'..t.prefix..'@'..tostring(t.addr)

    local parent_prefix = sysfs_read_attr(path..'/'..dirname(of_node), 'label')
    if parent_prefix then
        parent_prefix = parent_prefix..'_'
    else
        parent_prefix = ''
    end

    --
    -- FIXME: add or not non-labeled sensors to the list? otherwise return nil
    --
    local label = upper(parent_prefix..label_prefix..feat..num)
    --
    -- TODO: check label for blacklist
    --

    local t = {
        bus_nr = 0,
        addr = 0,
        feat = feat,
        num = num,
        path = path,
        of_node = of_node,
        label = label,
        prefix = sysfs_read_attr(path, 'name'),
        label_prefix = label_prefix,
        parent_prefix = parent_prefix,
        _subfeat = { },
        value = sensors_value[feat],
    }

    -- find bus type
    local subsys = basename(readlink(link..'/subsystem'))
        if subsys == 'i2c' then
            local a, b = match(dev, '/(%d+)-(%d+)')
            t.bus_nr = tonumber(a or 0)
            t.addr = tonumber(b or 0, 16)
        elseif subsys == 'platform' then
            local a = match(dev, '/[a-z0-9_].(%d)') or 0
            t.addr = tonumber(a or 0)
        end

    t.parent, t.devtype, t.dts_addr = match(t.of_node, '/(.[^/]-)/(.[^/]-)@?([0-9+]?)$')

    return setmetatable(t, S_mt)
end

function _S.read_input(self)
    if not self._subfeat.input then return end
    self._subfeat.input:seek(0, 'set')
    local v = self._subfeat.input:read(32)
    if v then
        return tonumber(v) / self.scale
    end
end

function _S.subfeat(self, subfeat)
    local k = self.feat..self.num..'_'..subfeat
    local fs = self.feat..'_'..subfeat
    -- rename power_average to power_input
    if self.feat..subfeat == 'poweraverage' then
        subfeat = 'input'
    end
    if subfeat == 'input' then
        self._subfeat[subfeat] = fopen(self.path..'/'..k)
        self.scale = 1
        if self.feat == 'in' or self.feat == 'temp' or self.feat == 'curr' or self.feat == 'humidity' then
            self.scale = 1000
        elseif self.feat == 'power' or self.feat == 'energy' then
            self.scale = 1000000
        end
        --
        -- TODO: make per sub-feat scale to fit power_average_interval and temp_offset
        --
    else
        local v = sysfs_read_attr(self.path, k)
        if v then
            self._subfeat[subfeat] = { tonumber(v), sysfs_get_attr_mode(self.path, k) }
        end
    end
end

function _S.subfeat_refresh(self)
    local k, v
    for k,_ in pairs(self._subfeat) do
        if k ~= 'input' then
            -- nil read will remove subfeat
            v = sysfs_read_attr(self.path, k)
            if v then v = { tonumber(v), sysfs_get_attr_mode(self.path, k) } end
            self._subfeat[k] = v
        end
    end
end

return _M
