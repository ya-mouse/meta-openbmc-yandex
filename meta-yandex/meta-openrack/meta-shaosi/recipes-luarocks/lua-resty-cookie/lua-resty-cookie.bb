SUMMARY = "Library to parse/set HTTP Cookie for OpenResty"
DESCRIPTION = "This library parses HTTP Cookie header for Nginx and returns each field in the cookie."

HOMEPAGE = "https://github.com/cloudflare/lua-resty-cookie"
LICENSE = "BSD"

LIC_FILES_CHKSUM = "file://${WORKDIR}/LICENSE;md5=c9d0cd0a1fddeb5c3cecce737c04d872"

PR = "r0"

SRC_URI = "git://github.com/cloudflare/lua-resty-cookie.git \
           file://LICENSE \
"
SRCREV = "${AUTOREV}"

S = "${WORKDIR}/git"
SYSROOTS = "${STAGING_DIR}/${MACHINE}"

luadir = "/lua/5.1"

do_install () {
    install -pD -m644 ${S}/lib/resty/cookie.lua ${D}${datadir}${luadir}/resty/cookie.lua
}

FILES_${PN} += "${datadir}${luadir}/resty/cookie.lua"

inherit allarch
