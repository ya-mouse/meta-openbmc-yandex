SUMMARY = "A Lua library for polling, process & timers"
DESCRIPTION = "A Lua library for polling, process & timers"

HOMEPAGE = "https://github.com/openwrt"
LICENSE = "BSD"

LIC_FILES_CHKSUM = "file://LICENSE;md5=c9d0cd0a1fddeb5c3cecce737c04d872"

SRC_URI = "file://lua-uloop-${PV}.tar.gz"

S = "${WORKDIR}/${PN}-${PV}"
SYSROOTS = "${STAGING_DIR}/${MACHINE}"

DEPENDS = " luajit"
luadir = "/lua/5.1"

MAKE_FLAGS = "'PREFIX=${D}${prefix}' \
'CC=${CC}' \
'LUAINC=${SYSROOTS}${includedir}/luajit-2.1' \
'LUALIB=${D}${libdir}${luadir}' \
"

do_compile () {
    oe_runmake ${MAKE_FLAGS}
}

do_install () {
    install -pD -m 644 ${S}/uloop.so ${D}${libdir}${luadir}/uloop.so
}

FILES_${PN} += "${libdir}${luadir}/*.so"
