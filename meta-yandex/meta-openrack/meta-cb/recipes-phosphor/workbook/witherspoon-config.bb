SUMMARY = "Witherspoon board wiring"
DESCRIPTION = "Board wiring information for the Witherspoon OpenPOWER system."
PR = "r1"

inherit config-in-skeleton

python() {
	machine = 'Witherspoon.py'
	d.setVar('_config_in_skeleton', machine)
}
