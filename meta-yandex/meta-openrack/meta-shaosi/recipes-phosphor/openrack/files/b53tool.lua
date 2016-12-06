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

local MII_REG = 0x1e

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

local function b53_mdio_op(page, reg, op)
  -- set current page
  if cur_page ~= page then
    local v = bor(lshift(page, 8), 1)
    mdio_write(MII_REG, REG_MII_PAGE, v)
    cur_page = page
  end

  -- set register address
  local v = bor(lshift(reg, 8), op)
  mdio_write(MII_REG, REG_MII_ADDR, v)

  local i
  for i=0,5 do
    v = mdio_read(MII_REG, REG_MII_ADDR)
    if band(v, 3) == 0 then
      i=5
    end
  end
end

local function b53_read16(page, reg)
  b53_mdio_op(page, reg, REG_MII_ADDR_READ)
  return mdio_read(MII_REG, REG_MII_DATA0)
end

local function b53_read32(page, reg)
  b53_mdio_op(page, reg, REG_MII_ADDR_READ)
  local v
  v = mdio_read(MII_REG, REG_MII_DATA0)
  return bor(v, lshift(mdio_read(MII_REG, REG_MII_DATA1), 16))
end

local function b53_write8(page, reg, val)
  mdio_write(MII_REG, REG_MII_DATA0, val)
  b53_mdio_op(page, reg, REG_MII_ADDR_WRITE)
end

local function b53_write16(page, reg, val)
  mdio_write(MII_REG, REG_MII_DATA0, val)
  b53_mdio_op(page, reg, REG_MII_ADDR_WRITE)
end

local function b53_write32(page, reg, val)
  b53_mdio_op(page, reg, REG_MII_ADDR_WRITE)
  local v
  v = mdio_read(MII_REG, REG_MII_DATA0)
  return bor(v, lshift(mdio_read(MII_REG, REG_MII_DATA1), 16))
end

if arg[4] ~= nil then
  b53_write16(tonumber(arg[2]), tonumber(arg[3]), tonumber(arg[4]))
else
  print(string.format("-- %04x", b53_read16(tonumber(arg[2]), tonumber(arg[3]))))
end
