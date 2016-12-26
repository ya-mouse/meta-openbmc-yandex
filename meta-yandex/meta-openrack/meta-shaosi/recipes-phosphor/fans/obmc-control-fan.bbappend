FILESEXTRAPATHS_prepend := "${THISDIR}/obmc-control-fan:"
SRC_URI += "file://fan_control.c"

do_patchappend () {
    install -m 0644 ${WORKDIR}/fan_control.c ${WORKDIR}/git/fanctl/fan_control.c
}

addtask patchappend after do_patch before do_compile
