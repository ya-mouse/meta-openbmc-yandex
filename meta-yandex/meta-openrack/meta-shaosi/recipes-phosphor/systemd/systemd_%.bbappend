do_install_append() {
     sed 's/#RuntimeWatchdogSec=0/RuntimeWatchdogSec=20s/' \
         -i ${D}${sysconfdir}/systemd/system.conf
}
