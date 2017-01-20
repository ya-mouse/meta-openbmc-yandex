do_installappend () {
    sed 's/pam_unix/pam_jfauth/' -i ${D}${sysconfdir}/pam.d/common-auth
}

addtask installappend after do_install before do_package
