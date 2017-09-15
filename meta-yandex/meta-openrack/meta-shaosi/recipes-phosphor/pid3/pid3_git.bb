DESCRIPTION = "PID regulator"
# TODO: put license
LICENSE = "PD"
LIC_FILES_CHKSUM = "file://main.cpp;beginline=1;endline=2;md5=ed0443b95075d48d7a632144acce0ac0"
BB_STRICT_CHECKSUM = "0"

#SRC_URI = "https://github.yandex-team.ru/rudimiv/pid3"
#SRC_URI = "git://github.yandex-team.ru/kitsok/pid3.git;branch=V8.12"
SRC_URI = "git://github.yandex-team.ru/kitsok/pid3.git;branch=RND-576"
#SRC_URI[md5sum] = "f8c73f055c992950cec4454e3e8109c6"
#SRC_URI[md5sum] = "54318499697b35249b217b386eb52281"
SRC_URI += "file://obmc-pid3.service"
SRC_URI += "file://pid3_wrapper"
SRC_URI += "file://safefans.sh"
SRCREV = '${AUTOREV}'

S = "${WORKDIR}/git"

DEPENDS = "curlpp bash "
RDEPENDS_${PN} += "bash "

inherit cmake

do_install_append () {
    install -d ${D}${systemd_unitdir}/system
    install -m 0644 ${WORKDIR}/obmc-pid3.service ${D}${systemd_unitdir}/system/obmc-pid3.service
    install -m 0755 ${WORKDIR}/pid3_wrapper ${D}${sbindir}/pid3_wrapper
    install -m 0755 ${WORKDIR}/safefans.sh ${D}${sbindir}/safefans.sh
}

pkg_postinst_${PN} () {
OPTS=""

if [ -n "$D" ]; then
    OPTS="--root=$D"
fi

if type systemctl >/dev/null 2>/dev/null; then
	systemctl $OPTS enable obmc-pid3.service

	if [ -z "$D" -a "enable" = "enable" ]; then
		systemctl restart obmc-pid3.service
	fi
fi
}

#CONFFILES_${PN} += "${sysconfdir}/pid3/*.conf"

FILES_${PN} = "${sbindir}/pid3 \
               ${sbindir}/pid3_wrapper \
               ${sysconfdir}/pid3.conf \
               ${sbindir}/safefans.sh \
               ${sysconfdir}/systemd/system/obmc-pid3.service.d \
               ${systemd_unitdir}/system/obmc-pid3.service \
"
