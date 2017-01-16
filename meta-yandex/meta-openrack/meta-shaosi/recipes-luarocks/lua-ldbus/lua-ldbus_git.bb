SUMMARY = "A Lua library to access dbus"
DESCRIPTION = "A Lua library to access dbus."

HOMEPAGE = "https://github.com/daurnimator/ldbus"
LICENSE = "MIT"

LIC_FILES_CHKSUM = "file://LICENSE;md5=841da061a68844a35fb37ab3c094288a"

PR = "r0"

SRC_URI = "git://github.com/daurnimator/ldbus.git"
SRCREV = "${AUTOREV}"

S = "${WORKDIR}/git"
SYSROOTS = "${STAGING_DIR}/${MACHINE}"

DEPENDS = " luajit dbus"
luadir = "/lua/5.1"

MAKE_FLAGS = "'PREFIX=${D}${prefix}' \
'CFLAGS=${CFLAGS} -Wall -fPIC -std=gnu99 -I${SYSROOTS}${includedir}/luajit-2.1 -I${SYSROOTS}${includedir}/dbus-1.0 -I${SYSROOTS}${libdir}/dbus-1.0/include -I../vendor/compat-5.3/c-api' \
'LIBS=-ldbus-1 -lluajit-5.1' \
'LUA_LIBDIR=${D}${libdir}${luadir}' \
"

do_compile () {
    oe_runmake ${MAKE_FLAGS} -C src
}

do_install () {
    oe_runmake ${MAKE_FLAGS} install -C src
}

FILES_${PN} += "${libdir}${luadir}/*.so"
