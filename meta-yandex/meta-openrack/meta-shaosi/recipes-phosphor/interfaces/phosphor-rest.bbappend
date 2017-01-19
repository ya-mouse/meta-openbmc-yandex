FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI += "file://disable-auth.patch"

REGISTERED_SERVICES_${PN} = ""
