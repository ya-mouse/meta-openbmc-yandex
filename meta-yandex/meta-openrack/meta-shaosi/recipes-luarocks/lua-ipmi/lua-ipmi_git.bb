SUMMARY = "A Lua library to access IPMI"
DESCRIPTION = "A Lua library to access IPMI."

HOMEPAGE = "https://github.com/daurnimator/ldbus"
LICENSE = "BSD"

LIC_FILES_CHKSUM = "file://LICENSE;md5=c9d0cd0a1fddeb5c3cecce737c04d872"

SRC_URI = "file://LICENSE \
           file://shaosid.lua \
           file://ipmi.lua \
           file://api.lua \
           file://api/attr.lua \
           file://api/proc.lua \
           file://api/storage.lua \
           file://api/fanpwm.lua \
           file://api/leds.lua \
           file://auth.lua \
"

S = "${WORKDIR}"

luadir = "/lua/5.1"

do_install () {
    install -d ${D}${datadir}${luadir}/openbmc/api
    install -m 644 ${WORKDIR}/ipmi.lua ${D}${datadir}${luadir}/ipmi.lua
    install -m 755 -pD ${WORKDIR}/shaosid.lua ${D}${sbindir}/shaosid
    for f in api api/attr api/storage api/proc api/fanpwm api/leds auth; do
        install -m 644 ${WORKDIR}/$f.lua ${D}${datadir}${luadir}/openbmc/$f.lua
    done
}

FILES_${PN} += "${datadir}${luadir}/*.lua \
    ${datadir}${luadir}/openbmc/*.lua \
    ${datadir}${luadir}/openbmc/api/*.lua \
    ${sbindir}/shaosid \
"

RDEPENDS_${PN} = " lua-struct lua-nixio lua-pam lua-resty-random lua-resty-stack lua-resty-cookie lua-uloop "

inherit allarch
