DESCRIPTION = "PID regulator"
# TODO: put license
LICENSE = "PD"
LIC_FILES_CHKSUM = "file://main.cpp;beginline=1;endline=2;md5=ed0443b95075d48d7a632144acce0ac0"

#SRC_URI = "git://github.yandex-team.ru/rudimiv/pid3.git"
SRC_URI = "git://github.yandex-team.ru/kitsok/pid3.git"
# SRC_URI += "file://01-cmake-link.patch"
# SRC_URI += "file://02-install.patch"
# SRC_URI += "file://03-curl-disable-ssl.patch"
SRC_URI += "file://obmc-pid3.service"
SRC_URI += "file://pid3_wrapper"
SRC_URI += "file://jbod.conf"
SRC_URI += "file://node.conf"
SRC_URI += "file://nvme.conf"
#SRCREV = '1ab1c286b1f157bc98c6530e3aa030884f50d542'
SRCREV = '${AUTOREV}'

S = "${WORKDIR}/git"

DEPENDS = "curlpp bash "
RDEPENDS_${PN} += "bash "

inherit cmake

do_install_append () {
    mv ${D}${sbindir}/pid ${D}${sbindir}/pid3

    install -d ${D}${sysconfdir}/pid3
    install -d ${D}${sysconfdir}/systemd/system/obmc-pid3.service.d
    install -d ${D}${systemd_unitdir}/system
    install -m 0644 ${WORKDIR}/obmc-pid3.service ${D}${systemd_unitdir}/system/obmc-pid3.service
    install -m 0755 ${WORKDIR}/pid3_wrapper ${D}${sbindir}/pid3_wrapper
    for c in jbod node nvme; do
        install -m 0644 ${WORKDIR}/${c}.conf ${D}${sysconfdir}/pid3/${c}.conf
    done
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

CONFFILES_${PN} += "${sysconfdir}/pid3/*.conf"

FILES_${PN} = "${sbindir}/pid3 \
               ${sbindir}/pid3_wrapper \
               ${sysconfdir}/systemd/system/obmc-pid3.service.d \
               ${sysconfdir}/pid3/*.conf \
               ${systemd_unitdir}/system/obmc-pid3.service \
"
