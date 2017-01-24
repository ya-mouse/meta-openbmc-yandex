SUMMARY = "A Lua library to access IPMI"
DESCRIPTION = "A Lua library to access IPMI."

HOMEPAGE = "https://github.com/daurnimator/ldbus"
LICENSE = "BSD"

LIC_FILES_CHKSUM = "file://LICENSE;md5=c9d0cd0a1fddeb5c3cecce737c04d872"

SRC_URI = "file://LICENSE \
           file://ipmi.lua \
           file://api.lua \
           file://attr.lua \
           file://auth.lua \
"

S = "${WORKDIR}"

luadir = "/lua/5.1"

do_install () {
    install -d ${D}${datadir}${luadir}/openbmc
    install -m 644 ${WORKDIR}/ipmi.lua ${D}${datadir}${luadir}/ipmi.lua
    for f in api attr auth; do
        install -m 644 ${WORKDIR}/$f.lua ${D}${datadir}${luadir}/openbmc/
    done
}

FILES_${PN} += "${datadir}${luadir}/*.lua \
    ${datadir}${luadir}/openbmc/*.lua \
"

RDEPENDS_${PN} = " lua-struct lua-nixio lua-pam lua-resty-random lua-resty-stack lua-resty-cookie "

inherit allarch
