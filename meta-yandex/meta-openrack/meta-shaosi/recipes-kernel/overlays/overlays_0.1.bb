DESCRIPTION = "Device tree overlays"
PR = "r0"

inherit obmc-phosphor-license

SRC_URI = "file://shaosi-CB.dts"
SRC_URI += "file://shaosi-CB-factory.dts"
SRC_URI += "file://shaosi-RMC.dts"
SRC_URI += "file://shaosi-RMC-factory.dts"
SRC_URI += "file://master-pmbus.dts"

DEPENDS = "linux-obmc bash "
RDEPENDS_${PN} += "bash "

S = "${WORKDIR}"

do_compile() {
    BUILDDIR="${WORKDIR}/../../../../.."
    dtc=$BUILDDIR/tmp/work/*-openbmc-linux-gnueabi/linux-obmc/4.*/linux-*-standard-build/scripts/dtc/dtc
    inc=$(readlink -f $BUILDDIR/tmp/work-shared/*/kernel-source/arch/arm/boot/dts)
    for dts in *.dts; do
       dt=${dts%%.dts}
       ${CPP} -nostdinc -I${inc} -I${inc}/include -undef -D__DTS__  -x assembler-with-cpp -o ${WORKDIR}/$dts.tmp ${WORKDIR}/$dts
       $dtc -I dts -O dtb -o ${WORKDIR}/$dt.dtbo -b 0 -H epapr -@ ${WORKDIR}/$dts.tmp
       rm ${WORKDIR}/$dts.tmp
    done
}

do_install() {
    echo "D is ${D}" >> asdf.asdf
    install -d ${D}/${sysconfdir}/overlays
    install -m 0755 ${WORKDIR}/*.dtbo ${D}${sysconfdir}/overlays
}

FILES_${PN} = "${sysconfdir}/overlays"

