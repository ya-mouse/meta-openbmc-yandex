DESCRIPTION = "Phosphor IPMI LAN/LAN+ bridge"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://LICENSE;md5=e3fc50a88d0a364313df4b21ef20c29e"

SRC_URI = "git://github.com/openbmc/phosphor-net-ipmid"
SRCREV = '8c0446c102646b7ba8622594f5b1b808c88a9077'

SRC_URI += "file://01-pending.patch"
SRC_URI += "file://02-m4-stdcxx.patch"

S = "${WORKDIR}/git"

inherit autotools pkgconfig

FILES_${PN} = "${sbindir}"
