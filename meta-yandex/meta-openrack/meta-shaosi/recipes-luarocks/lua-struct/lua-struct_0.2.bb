SUMMARY = "A Lua library to access dbus"
DESCRIPTION = "A Lua library to access dbus."

HOMEPAGE = "https://github.com/daurnimator/ldbus"
LICENSE = "BSD"

LIC_FILES_CHKSUM = "file://LICENSE;md5=c9d0cd0a1fddeb5c3cecce737c04d872"

SRC_URI = "file://LICENSE \
           file://Makefile \
           file://struct.c \
           file://struct.html \
"

S = "${WORKDIR}"
SYSROOTS = "${STAGING_DIR}/${MACHINE}"

DEPENDS = " luajit dbus"
luadir = "/luajit-2.1"

MAKE_FLAGS = "'PREFIX=${D}${prefix}' \
'CC=${CC}' \
'LUAINC=${SYSROOTS}${includedir}${luadir}' \
'LUALIB=${D}${datadir}${luadir}' \
"

do_compile () {
    oe_runmake ${MAKE_FLAGS} -C ${WORKDIR}
}

do_install () {
    install -pD -m 644 ${WORKDIR}/struct.so ${D}${datadir}${luadir}/struct.so
}

FILES_${PN} += "${datadir}${luadir}/*.so"
