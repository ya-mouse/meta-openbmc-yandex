do_install_append() {
       histoff="shopt -u -o history"
       echo "${histoff}" >> ${D}${sysconfdir}/profile
       echo "${histoff}" >> ${D}${sysconfdir}/skel/.profile
}



