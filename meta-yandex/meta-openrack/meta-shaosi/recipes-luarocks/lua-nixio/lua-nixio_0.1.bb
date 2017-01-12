SUMMARY = "A Lua IO-library"
DESCRIPTION = "A Lua IO-library."

HOMEPAGE = "https://github.com/daurnimator/ldbus"
LICENSE = "Apache-2.0"

LIC_FILES_CHKSUM = "file://LICENSE;md5=c9d0cd0a1fddeb5c3cecce737c04d872"

SRC_URI = "file://nixio-${PV}.tar.gz"

S = "${WORKDIR}/nixio-${PV}"

SYSROOTS = "${STAGING_DIR}/${MACHINE}"

DEPENDS = " luajit dbus"
luadir = "/luajit-2.1"

MAKE_FLAGS = "'PREFIX=${D}${prefix}' \
'CC=${CC}' \
'CFLAGS=-I${SYSROOTS}${includedir}${luadir}' \
"

do_compile () {
    oe_runmake ${MAKE_FLAGS} compile
}

do_install () {
    oe_runmake ${MAKE_FLAGS} DESTDIR=${D} install
}

FILES_${PN} += "${datadir}${luadir}/*.so"

