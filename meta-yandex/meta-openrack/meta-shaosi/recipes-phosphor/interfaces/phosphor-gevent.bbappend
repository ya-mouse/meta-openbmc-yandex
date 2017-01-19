FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI += "file://use-unix-socket.patch"

SYSTEMD_SERVICE_${PN} = "${PN}.service"
