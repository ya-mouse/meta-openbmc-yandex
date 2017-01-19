SUMMARY = "A high-level Lua library to provide HTTP REST"
DESCRIPTION = "A high-level Lua library to provide HTTP REST"

HOMEPAGE = "https://github.com/antonheryanto/lua-resty-stack"
LICENSE = "MIT"

LIC_FILES_CHKSUM = "file://${WORKDIR}/LICENSE;md5=c9d0cd0a1fddeb5c3cecce737c04d872"

PR = "r0"

SRC_URI = "git://github.com/antonheryanto/lua-resty-stack.git \
           file://splat.patch \
           file://LICENSE \
"
SRCREV = "${AUTOREV}"

S = "${WORKDIR}/git"
SYSROOTS = "${STAGING_DIR}/${MACHINE}"

luadir = "/lua/5.1"

do_install () {
    install -d ${D}${datadir}${luadir}/resty/
    cp -r ${S}/lib/resty/stack* ${D}${datadir}${luadir}/resty/
}

FILES_${PN} += "${datadir}${luadir}/resty/*.lua \
                ${datadir}${luadir}/resty/stack/*.lua \
"

inherit allarch
