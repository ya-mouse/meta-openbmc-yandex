DESCRIPTION = "Script to set MAC and save MAC addresses"
# TODO: put license
LICENSE = "PD"
LIC_FILES_CHKSUM = "file://setmacs.sh;beginline=1;endline=2;md5=88a069a93872f62fcd7aa03b8d78ae93"
BB_STRICT_CHECKSUM = "0"

SRC_URI = "file://setmacs.sh"

S = "${WORKDIR}"

DEPENDS = "bash "
RDEPENDS_${PN} += "bash "

do_install () {
    install -d ${D}${sbindir}
    install -m 0755 ${WORKDIR}/setmacs.sh ${D}${sbindir}/setmacs.sh
}

FILES_${PN} = "${sbindir}/setmacs.sh"
