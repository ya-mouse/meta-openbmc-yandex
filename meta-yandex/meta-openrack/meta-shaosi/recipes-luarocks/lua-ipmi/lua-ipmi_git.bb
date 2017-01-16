SUMMARY = "A Lua library to access IPMI"
DESCRIPTION = "A Lua library to access IPMI."

HOMEPAGE = "https://github.com/daurnimator/ldbus"
LICENSE = "BSD"

LIC_FILES_CHKSUM = "file://LICENSE;md5=c9d0cd0a1fddeb5c3cecce737c04d872"

SRC_URI = "file://LICENSE \
           file://ipmi.lua \
"

S = "${WORKDIR}"

luadir = "/lua/5.1"

do_install () {
    install -d ${D}${datadir}${luadir}
    install -m 644 ${WORKDIR}/ipmi.lua ${D}${datadir}${luadir}/ipmi.lua
}

FILES_${PN} += "${datadir}${luadir}/*.lua"

RDEPENDS_${PN} = " lua-struct lua-nixio"

inherit allarch
