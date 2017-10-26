do_install_append() {
       histfile="touch /tmp/bash_history; rm /home/root/.bash_history > /dev/null 2>&1; ln -s /tmp/bash_history /home/root/.bash_history"
       echo "${histfile}" >> ${D}${sysconfdir}/profile
       echo "${histfile}" >> ${D}${sysconfdir}/skel/.profile
}



