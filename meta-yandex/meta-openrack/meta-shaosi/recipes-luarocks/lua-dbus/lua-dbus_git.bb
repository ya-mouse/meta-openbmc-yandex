SUMMARY = "A high-level Lua library to access dbus"
DESCRIPTION = "A high-level Lua library to access dbus."

HOMEPAGE = "https://github.com/dodo/lua-dbus"
LICENSE = "MIT"

LIC_FILES_CHKSUM = "file://${WORKDIR}/LICENSE;md5=c9d0cd0a1fddeb5c3cecce737c04d872"

PR = "r0"

SRC_URI = "git://github.com/dodo/lua-dbus.git \
           file://getall.patch \
           file://LICENSE \
"
SRCREV = "${AUTOREV}"

S = "${WORKDIR}/git"
SYSROOTS = "${STAGING_DIR}/${MACHINE}"

luadir = "/lua/5.1"

do_install () {
    install -d ${D}${datadir}${luadir}/${PN}
    cp ${S}/init.lua ${S}/interface.lua ${D}${datadir}${luadir}/${PN}/
    cp -r ${S}/awesome ${D}${datadir}${luadir}/${PN}/
}

FILES_${PN} += "${datadir}${luadir}/${PN}/*.lua \
                ${datadir}${luadir}/${PN}/*/*.lua \
"

RDEPENDS_${PN} = "lua-ldbus"

inherit allarch
