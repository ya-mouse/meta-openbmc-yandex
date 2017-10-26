DESCRIPTION = "Script to set MAC and save MAC addresses"
# TODO: put license
LICENSE = "PD"
LIC_FILES_CHKSUM = "file://setmacs.sh;beginline=1;endline=2;md5=88a069a93872f62fcd7aa03b8d78ae93"
BB_STRICT_CHECKSUM = "0"

SRC_URI = "file://setmacs.sh"
SRC_URI += "file://reset_cb.sh"
SRC_URI += "file://reset_bmc.sh"

S = "${WORKDIR}"

DEPENDS = "bash "
RDEPENDS_${PN} += "bash "

do_install () {
    install -d ${D}${sbindir}
    install -m 0755 ${WORKDIR}/setmacs.sh ${D}${sbindir}/setmacs.sh
    install -m 0755 ${WORKDIR}/reset_cb.sh ${D}${sbindir}/reset_cb.sh
    install -m 0755 ${WORKDIR}/reset_bmc.sh ${D}${sbindir}/reset_bmc.sh
}

FILES_${PN} = "${sbindir}/setmacs.sh ${sbindir}/reset_cb.sh ${sbindir}/reset_bmc.sh"
