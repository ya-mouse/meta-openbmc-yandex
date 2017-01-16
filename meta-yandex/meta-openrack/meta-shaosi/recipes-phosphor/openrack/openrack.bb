SUMMARY = "Openrack OpenBMC support files"
DESCRIPTION = "Openrack OpenBMC support files."
PR = "r1"

inherit obmc-phosphor-license

S = "${WORKDIR}"
SRC_URI += "file://shaosi-CB.dtbo"
SRC_URI += "file://shaosi-RMC.dtbo"
SRC_URI += "file://shaosi-CB-factory.dtbo"
SRC_URI += "file://shaosi-RMC-factory.dtbo"
SRC_URI += "file://b53tool.lua"
SRC_URI += "file://miitool.lua"
SRC_URI += "file://setup-CB"
SRC_URI += "file://openrack.tar.gz"
SRC_URI += "file://lua.tar.gz"

do_install() {
        install -d ${D}/etc/overlays ${D}/usr/sbin ${D}/usr/share/lua/5.1 ${D}/usr/share/openrack/tests
        install -m 0644 ${WORKDIR}/shaosi-*.dtbo ${D}/etc/overlays/

        install -m 0755 ${WORKDIR}/b53tool.lua ${D}/usr/sbin/b53tool
        install -m 0755 ${WORKDIR}/miitool.lua ${D}/usr/sbin/miitool

        # rsync -a ${WORKDIR}/lua/*.lua ${D}/usr/share/lua/5.1/
        rsync -a ${WORKDIR}/openrack/root/ ${D}/
        rsync -a ${WORKDIR}/openrack/tests/ ${D}/usr/share/openrack/tests/

        install -m 0755 ${WORKDIR}/setup-CB ${D}/usr/share/openrack/setup-vlan-CB
}

FILES_${PN} += " /etc/overlays /etc/default /etc/systemd /usr/share/openrack /usr/sbin /usr/share/lua/5.1 "
