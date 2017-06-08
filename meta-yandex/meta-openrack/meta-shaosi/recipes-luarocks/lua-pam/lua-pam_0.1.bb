SUMMARY = "A Lua PAM library"
DESCRIPTION = "A Lua PAM library."

HOMEPAGE = "https://github.com/devurandom/lua-pam"
LICENSE = "Apache-2.0"

LIC_FILES_CHKSUM = "file://LICENSE;md5=ebc95de02d2ee01908997fb7690e9540"

SRC_URI = "gitsm://github.com/devurandom/lua-pam.git"
SRCREV = "${AUTOREV}"

S = "${WORKDIR}/git"

SYSROOTS = "${STAGING_DIR}/${MACHINE}"

DEPENDS = " luajit libpam"
luadir = "/lua/5.1"

MAKE_FLAGS = "'CC=${CC}' \
'LUA_VERSION=jit-5.1' \
'LUA_CPPFLAGS=-I${SYSROOTS}${includedir}/luajit-2.1' \
'LUA_LDFLAGS=${LDFLAGS}' \
'EXTRA_CFLAGS=${CFLAGS}' \
"

do_compile () {
    oe_runmake ${MAKE_FLAGS}
}

do_install () {
    install -m644 -pD ${S}/pam.so ${D}${libdir}${luadir}/pam.so
}

FILES_${PN} += "${libdir}${luadir}/*.so"

