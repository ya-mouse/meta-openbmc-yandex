## System states
##   state can change to next state in 2 ways:
##   - a process emits a GotoSystemState signal with state name to goto
##   - objects specified in EXIT_STATE_DEPEND have started
SYSTEM_STATES = [
	'BASE_APPS',
	'BMC_STARTING',
	'BMC_READY',
]

EXIT_STATE_DEPEND = {
	'BASE_APPS' : {
		'/org/openbmc/sensors': 0,
	},
	'BMC_STARTING' : {
		'/org/openbmc/control/led/identify' : 0,
	}
}

FRU_INSTANCES = {
	'<inventory_root>/system' : { 'fru_type' : 'SYSTEM','is_fru' : True, 'present' : "True" },
	'<inventory_root>/system/systemevent' : { 'fru_type' : 'SYSTEM_EVENT', 'is_fru' : False, },
	'<inventory_root>/system/board' : { 'fru_type' : 'BMC','is_fru' : False, 'manufacturer' : 'ASPEED' },
}

ID_LOOKUP = {
	'FRU' : {
		0x33 : '<inventory_root>/system',
	},
	'FRU_STR' : {
		'PRODUCT_15' : '<inventory_root>/system',
	},
	'SENSOR' : {
		0x35 : '<inventory_root>/system/systemevent',
		0x09 : '/org/openbmc/sensors/host/BootCount',
		0x05 : '/org/openbmc/sensors/host/BootProgress',
		0x32 : '/org/openbmc/sensors/host/OperatingSystemStatus',
	},
#	'GPIO_PRESENT' : {
#		'SLOT0_PRESENT' : '<inventory_root>/system/chassis/motherboard/pciecard_x16',
#		'SLOT1_PRESENT' : '<inventory_root>/system/chassis/motherboard/pciecard_x8',
#	}
}

GPIO_CONFIG = {}
GPIO_CONFIG['POWER_BUTTON'] = { 'gpio_pin': 'H1', 'direction': 'both' }
#GPIO_CONFIG['SLOT0_PRESENT'] =         { 'gpio_pin': 'N3', 'direction': 'in' }
#GPIO_CONFIG['SLOT1_PRESENT'] =         { 'gpio_pin': 'N4', 'direction': 'in' }
#GPIO_CONFIG['SLOT2_PRESENT'] =         { 'gpio_pin': 'N5', 'direction': 'in' }

HWMON_CONFIG = {
	'8-0048' :  {
		'names' : {
			'temp1_input' : { 'object_path' : 'temperature/ambient','poll_interval' : 5000,'scale' : -3,'units' : 'C' },
		}
	},
}

# Miscellaneous non-poll sensor with system specific properties.
# The sensor id is the same as those defined in ID_LOOKUP['SENSOR'].
MISC_SENSORS = {
	0x09 : { 'class' : 'BootCountSensor' },
	0x05 : { 'class' : 'BootProgressSensor' },
	0x32 : { 'class' : 'OperatingSystemStatusSensor' },
}

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
