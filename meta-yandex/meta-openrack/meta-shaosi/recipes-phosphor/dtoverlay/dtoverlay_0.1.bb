DESCRIPTION = "DTS overlay & merge utils"
LICENSE = "PD"
LIC_FILES_CHKSUM = "file://dtoverlay_main.c;beginline=2;endline=25;md5=96679a98d4f3d5a5be58f1e7652d98fa"

SRC_URI = "git://github.com/ya-mouse/dtoverlay.git"
SRC_URI += "file://001-cmake-include.patch"
SRCREV = 'd503ddae11d62f12762b2fd3a52d37da55645d4b'

S = "${WORKDIR}/git"

inherit cmake

FILES_${PN} = "${bindir}"
