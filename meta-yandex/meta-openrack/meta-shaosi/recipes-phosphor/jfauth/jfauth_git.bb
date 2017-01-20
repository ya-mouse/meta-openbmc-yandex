SUMMARY = "Just Fast Authentication via PAM"
DESCRIPTION = "Authentication daemon via PAM using local socket."

HOMEPAGE = "https://github.com/apenwarr/jfauth"
LICENSE = "GPLv2"

LIC_FILES_CHKSUM = "file://COPYING;md5=8ca43cbc842c2336e835926c2166c28b"

PR = "r0"

SRC_URI = "git://github.com/apenwarr/jfauth.git \
           file://jfauth.service \
           file://pam.d-openresty \
           file://wvstreams.patch \
"
SRCREV = "${AUTOREV}"

S = "${WORKDIR}/git"
SYSROOTS = "${STAGING_DIR}/${MACHINE}"

DEPENDS = " libpam wvstreams"

MAKE_FLAGS = " \
CC='${CC}' \
CXX='${CXX}' \
CPPFLAGS='-DJF_UNIX_SOCKFILE=\"/run/jfauthd/sock\" -I${SYSROOTS}${includedir}/wvstreams' \
"

do_compile () {
    oe_runmake ${MAKE_FLAGS}
}

do_install () {
    oe_runmake ${MAKE_FLAGS} install DESTDIR=${D}
    install -d ${D}${systemd_unitdir}/system
    install -m 0644 ${WORKDIR}/jfauth.service ${D}${systemd_unitdir}/system/jfauth.service
    install -m 0644 ${WORKDIR}/pam.d-openresty ${D}${sysconfdir}/pam.d/openresty
}

pkg_postinst_${PN} () {
OPTS=""

if [ -n "$D" ]; then
    OPTS="--root=$D"
fi

if type systemctl >/dev/null 2>/dev/null; then
	systemctl $OPTS enable jfauth.service

	if [ -z "$D" -a "enable" = "enable" ]; then
		systemctl restart jfauth.service
	fi
fi
}

CONFFILES_${PN} += "${sysconfdir}/pam.d/*"

FILES_${PN} += "${sbindir}/jfauthd \
                ${systemd_unitdir}/system/jfauth.service \
                /lib/security/pam_*.so \
                ${sysconfdir}/pam.d/* \
"
