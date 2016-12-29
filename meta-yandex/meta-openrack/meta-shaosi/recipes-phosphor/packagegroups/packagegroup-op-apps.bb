SUMMARY = "OpenBMC for OpenRACK - Applications"
PR = "r1"

inherit packagegroup
inherit obmc-phosphor-license

PROVIDES = "${PACKAGES}"
PACKAGES = " \
        ${PN}-sensors \
        ${PN}-chassis \
        ${PN}-fans \
        ${PN}-flash \
        ${PN}-system \
        "

PROVIDES += "virtual/obmc-sensor-mgmt"
PROVIDES += "virtual/obmc-chassis-mgmt"
PROVIDES += "virtual/obmc-fan-mgmt"
PROVIDES += "virtual/obmc-flash-mgmt"
PROVIDES += "virtual/obmc-system-mgmt"

RPROVIDES_${PN}-sensors += "virtual-obmc-sensor-mgmt"
RPROVIDES_${PN}-chassis += "virtual-obmc-chassis-mgmt"
RPROVIDES_${PN}-fans += "virtual-obmc-fan-mgmt"
RPROVIDES_${PN}-flash += "virtual-obmc-flash-mgmt"
RPROVIDES_${PN}-system += "virtual-obmc-system-mgmt"

SUMMARY_${PN}-sensors = "OpenRACK Sensors"
RDEPENDS_${PN}-sensors = " \
        obmc-hwmon \
        obmc-mgr-sensor \
        "

SUMMARY_${PN}-chassis = "OpenRACK Chassis"
RDEPENDS_${PN}-chassis = " \
        obmc-mgr-inventory \
        obmc-control-led \
        "

SUMMARY_${PN}-sensors = "OpenRACK Fans"
RDEPENDS_${PN}-fans = " \
        obmc-hwmon \
        obmc-control-fan \
        "

SUMMARY_${PN}-flash = "OpenRACK Flash"
RDEPENDS_${PN}-flash = " \
        obmc-mgr-download \
        obmc-control-bmc \
        "

SUMMARY_${PN}-system = "OpenRACK System"
RDEPENDS_${PN}-system = " \
        obmc-mgr-system \
        obmc-mgr-state \
        "
