SUMMARY = "Shaosi board wiring"
DESCRIPTION = "Board wiring information for the Shaosi OpenRack system."
PR = "r1"

SRC_URI += "file://Shaosi.py"

inherit config-in-skeleton

S = "${WORKDIR}"
