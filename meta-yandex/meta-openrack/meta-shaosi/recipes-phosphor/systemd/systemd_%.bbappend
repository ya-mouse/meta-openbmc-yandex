FILESEXTRAPATHS_append := "${THISDIR}/${PN}:"
SRC_URI += "file://01-systemd-hostnamed.service.patch"
SRC_URI += "file://02-networkd-link.c.patch"

