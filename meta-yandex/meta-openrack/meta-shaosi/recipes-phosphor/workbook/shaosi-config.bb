SUMMARY = "Shaosi board wiring"
DESCRIPTION = "Board wiring information for the Shaosi OpenRack system."
PR = "r1"

SRC_URI += "file://01-shaosi-config.patch"

inherit config-in-skeleton
