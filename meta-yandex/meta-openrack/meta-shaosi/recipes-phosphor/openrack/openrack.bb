SUMMARY = "Openrack OpenBMC test files"
DESCRIPTION = "Openrack OpenBMC test files."
PR = "r1"

inherit obmc-phosphor-license

S = "${WORKDIR}"
SRC_URI += "file://shaosi-CB.dtbo"
SRC_URI += "file://shaosi-RMC.dtbo"
SRC_URI += "file://b53tool.lua"
SRC_URI += "file://miitool.lua"
SRC_URI += "file://setup-CB"
SRC_URI += "file://openrack.tar.gz"

do_install() {
        install -d ${D}/etc/overlays ${D}/usr/sbin
        install -m 0644 ${WORKDIR}/shaosi-CB.dtbo ${D}/etc/overlays/shaosi-CB.dtbo
        install -m 0644 ${WORKDIR}/shaosi-RMC.dtbo ${D}/etc/overlays/shaosi-RMC.dtbo

        install -m 0755 ${WORKDIR}/b53tool.lua ${D}/usr/sbin/b53tool
        install -m 0755 ${WORKDIR}/miitool.lua ${D}/usr/sbin/miitool

        rsync -a ${WORKDIR}/openrack/root/ ${D}/
        rsync -a ${WORKDIR}/openrack/tests/ ${D}/usr/share/openrack/tests/

        install -m 0755 ${WORKDIR}/setup-CB ${D}/usr/share/openrack/setup-vlan-CB
}

FILES_${PN} += " /etc/overlays /etc/default /etc/systemd /usr/share/openrack /usr/sbin "
