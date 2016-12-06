#!/usr/bin/luajit
local ffi = require 'ffi'
local bit = require 'bit'

local bor, band, bxor, lshift, rshift = bit.bor, bit.band, bit.bxor, bit.lshift, bit.rshift

ffi.cdef[[
   int socket(int, int, int);
   int ioctl(int d, unsigned int request, ...);
struct ifreq {
        union
        {
                char    ifrn_name[16];            /* if name, e.g. "en0" */
        } ifr_ifrn;

        union {
                char    ifru_data[16];   /* Just fits the size */
	unsigned short 	int	ifru_int[8];
        } ifr_ifru;
};
]]

local C = ffi.C
local _ioctl = function(fd, ...) return C.ioctl(fd, ...) end

local REG_MII_PAGE	= 0x10
local REG_MII_ADDR	= 0x11
local REG_MII_DATA0	= 0x18
local REG_MII_DATA1	= 0x19
local REG_MII_DATA2	= 0x1a
local REG_MII_DATA3	= 0x1b

local REG_MII_ADDR_WRITE = 1
local REG_MII_ADDR_READ	= 2

local t = C.socket(0x2, 0x2, 0)
local cur_page

local ifr = ffi.new("struct ifreq")
ifr.ifr_ifrn.ifrn_name = arg[1] or "eth1"

local function mdio_read(phy, reg)
  ifr.ifr_ifru.ifru_int[0] = phy
  ifr.ifr_ifru.ifru_int[1] = reg
  if _ioctl(t, 0x8948, ifr) == 0 then
    return ifr.ifr_ifru.ifru_int[3]
  end
  return 0xffffffff
end

local function mdio_write(phy, reg, value)
  ifr.ifr_ifru.ifru_int[0] = phy
  ifr.ifr_ifru.ifru_int[1] = reg
  ifr.ifr_ifru.ifru_int[2] = value
  return _ioctl(t, 0x8949, ifr)
end

if arg[4] ~= nil then
  mdio_write(tonumber(arg[2]), tonumber(arg[3]), tonumber(arg[4]))
else
  print(string.format("-- %04x", mdio_read(tonumber(arg[2]), tonumber(arg[3]))))
end
