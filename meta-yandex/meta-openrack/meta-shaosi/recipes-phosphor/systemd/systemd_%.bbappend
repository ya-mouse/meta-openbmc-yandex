do_install_append() {
     sed 's/#RuntimeWatchdogSec=0/RuntimeWatchdogSec=20s/' \
         -i ${D}${sysconfdir}/systemd/system.conf

     cat <<EOF>${D}/usr/lib/sysctl.d/60-enable_ra.conf
net.ipv6.conf.all.accept_ra=1
net.ipv6.conf.eth0.accept_ra=1
net.ipv6.conf.eth1.accept_ra=1
EOF

     cat <<EOF1>${D}/usr/lib/systemd/network/ipv6.network
[Match]
Name=eth*
[Network]
IPv6AcceptRouterAdvertisements=yes
EOF1


}
