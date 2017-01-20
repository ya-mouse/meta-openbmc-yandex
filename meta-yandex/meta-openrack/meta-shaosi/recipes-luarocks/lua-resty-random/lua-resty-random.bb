SUMMARY = "Random library for OpenResty"
DESCRIPTION = "Random library for OpenResty"

HOMEPAGE = "https://github.com/bungle/lua-resty-random"
LICENSE = "BSD"

LIC_FILES_CHKSUM = "file://LICENSE;md5=d221993dcf873298bce103d0036e774c"

PR = "r0"

SRC_URI = "git://github.com/bungle/lua-resty-random.git"
SRCREV = "${AUTOREV}"

S = "${WORKDIR}/git"

luadir = "/lua/5.1"

do_install () {
    install -pD -m644 ${S}/lib/resty/random.lua ${D}${datadir}${luadir}/resty/random.lua
}

FILES_${PN} += "${datadir}${luadir}/resty/random.lua"

inherit allarch
