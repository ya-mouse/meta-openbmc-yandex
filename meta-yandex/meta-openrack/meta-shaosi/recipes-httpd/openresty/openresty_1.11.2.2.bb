SUMMARY = "Scalable Web Platform by Extending NGINX with Lua"

DESCRIPTION = "OpenResty is a dynamic web platform based on NGINX and LuaJIT."

HOMEPAGE = "http://openresty.org/"
LICENSE = "BSD-2-Clause"

LIC_FILES_CHKSUM = "file://COPYRIGHT;md5=d1d96b51eecded4955a1148ec4ae3aeb"

SRC_URI[md5sum] = "f4b9aa960e57ca692c4d3da731b7e38b"

SECTION = "net"

DEPENDS = "libpcre gzip openssl luajit"

SRC_URI = " \
	https://openresty.org/download/openresty-${PV}.tar.gz \
	file://nginx-cross.patch \
	file://nginx-configure.patch \
	file://nginx.conf \
	file://nginx.init \
	file://nginx-volatile.conf \
	file://openresty.service \
"

inherit update-rc.d useradd

CFLAGS_append = " -fPIE -pie"
CXXFLAGS_append = " -fPIE -pie"

NGINX_WWWDIR ?= "${localstatedir}/www/localhost"
NGINX_USER   ?= "www"

EXTRA_OECONF = ""
DISABLE_STATIC = ""

do_configure () {
	if [ "${SITEINFO_BITS}" = "64" ]; then
		PTRSIZE=8
	else
		PTRSIZE=4
	fi

	echo $CFLAGS
	echo $LDFLAGS

	./configure \
	--with-cc="${CC}" \
	--crossbuild=Linux:${TUNE_ARCH} \
	--with-endian=${@base_conditional('SITEINFO_ENDIANNESS', 'le', 'little', 'big', d)} \
	--with-int=4 \
	--with-long=${PTRSIZE} \
	--with-long-long=8 \
	--with-ptr-size=${PTRSIZE} \
	--with-sig-atomic-t=${PTRSIZE} \
	--with-size-t=${PTRSIZE} \
	--with-off-t=${PTRSIZE} \
	--with-time-t=${PTRSIZE} \
	--with-sys-nerr=132 \
	--with-pcre-jit \
	--with-luajit=${STAGING_LIBDIR}/.. \
	--conf-path=${sysconfdir}/openresty/nginx.conf \
	--http-log-path=${localstatedir}/log/nginx/access.log \
	--error-log-path=${localstatedir}/log/nginx/error.log \
	--pid-path=/run/openresty/openresty.pid \
	--prefix=${prefix} \
	--with-http_ssl_module \
	--with-http_gzip_static_module \
	\
	--without-lua_redis_parser \
	--without-lua_rds_parser \
	${EXTRA_OECONF}
}

do_install () {
	oe_runmake 'DESTDIR=${D}' 'LUA_CMODULE_DIR=${D}${libdir}/lua/5.1' install
	rm -fr ${D}${localstatedir}/run ${D}/run
	if ${@bb.utils.contains('DISTRO_FEATURES', 'systemd', 'true', 'false', d)}; then
		install -d ${D}${sysconfdir}/tmpfiles.d
		echo "d /run/${BPN} - - - -" \
		     > ${D}${sysconfdir}/tmpfiles.d/${BPN}.conf
	fi
	install -d ${D}${sysconfdir}/${BPN}
	ln -snf ${localstatedir}/run/${BPN} ${D}${sysconfdir}/${BPN}/run
	install -d ${D}${NGINX_WWWDIR}
	mv ${D}/usr/html ${D}${NGINX_WWWDIR}/
	chown ${NGINX_USER}:www-data -R ${D}${NGINX_WWWDIR}

	install -d ${D}${sysconfdir}/init.d
	install -m 0755 ${WORKDIR}/nginx.init ${D}${sysconfdir}/init.d/openresty
	sed -i 's,/usr/sbin/,${sbindir}/,g' ${D}${sysconfdir}/init.d/openresty
	sed -i 's,/etc/,${sysconfdir}/,g'  ${D}${sysconfdir}/init.d/openresty

	install -d ${D}${sysconfdir}/openresty
	install -m 0644 ${WORKDIR}/nginx.conf ${D}${sysconfdir}/openresty/nginx.conf
	sed -i 's,/var/,${localstatedir}/,g' ${D}${sysconfdir}/openresty/nginx.conf
	install -d ${D}${sysconfdir}/openresty/sites-enabled

	install -d ${D}${sysconfdir}/default/volatiles
	install -m 0644 ${WORKDIR}/nginx-volatile.conf ${D}${sysconfdir}/default/volatiles/99_nginx
	sed -i 's,/var/,${localstatedir}/,g' ${D}${sysconfdir}/default/volatiles/99_nginx

        if ${@bb.utils.contains('DISTRO_FEATURES','systemd','true','false',d)};then
            install -d ${D}${systemd_unitdir}/system
            install -m 0644 ${WORKDIR}/openresty.service ${D}${systemd_unitdir}/system/openresty.service
            sed -i -e 's,@SYSCONFDIR@,${sysconfdir},g' \
                    -e 's,@LOCALSTATEDIR@,${localstatedir},g' \
                    -e 's,@BASEBINDIR@,${base_bindir},g' \
                    ${D}${systemd_unitdir}/system/openresty.service
        fi

	# Cleanup
	rm -rf ${D}/usr/pod ${D}/usr/site ${D}/usr/resty.index ${D}/usr/bin
}

pkg_postinst_${PN} () {
	if [ -z "$D" ]; then
		if type systemd-tmpfiles >/dev/null; then
			systemd-tmpfiles --create
		elif [ -e ${sysconfdir}/init.d/populate-volatile.sh ]; then
			${sysconfdir}/init.d/populate-volatile.sh update
		fi
	fi
OPTS=""

if [ -n "$D" ]; then
    OPTS="--root=$D"
fi

if type systemctl >/dev/null 2>/dev/null; then
	systemctl $OPTS enable openresty.service

	if [ -z "$D" -a "enable" = "enable" ]; then
		systemctl restart openresty.service
	fi
fi
}

FILES_${PN} += "${localstatedir}/ \
                ${systemd_unitdir}/system/openresty.service \
                ${datadir}/lua/5.1/*/*/*.lua \
                ${datadir}/lua/5.1/*/*.lua \
                ${libdir}/lua/5.1/*.so \
                "

CONFFILES_${PN} = "${sysconfdir}/openresty/nginx.conf \
		${sysconfdir}/openresty/fastcgi.conf\
		${sysconfdir}/openresty/fastcgi_params \
		${sysconfdir}/openresty/koi-utf \
		${sysconfdir}/openresty/koi-win \
		${sysconfdir}/openresty/mime.types \
		${sysconfdir}/openresty/scgi_params \
		${sysconfdir}/openresty/uwsgi_params \
		${sysconfdir}/openresty/win-utf \
"

INITSCRIPT_NAME = "openresty"
INITSCRIPT_PARAMS = "defaults 92 20"

USERADD_PACKAGES = "${PN}"
USERADD_PARAM_${PN} = " \
    --system --no-create-home \
    --home ${NGINX_WWWDIR} \
    --groups www-data \
    --user-group ${NGINX_USER}"
