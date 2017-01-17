## System states
##   state can change to next state in 2 ways:
##   - a process emits a GotoSystemState signal with state name to goto
##   - objects specified in EXIT_STATE_DEPEND have started

board = None
try:
    with open('/etc/openrack-board', 'r') as f:
        board, number = f.read().split('-', 2)
except: pass

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
		'/org/openbmc/control/fans' : 0,
	}
}

FRU_INSTANCES = {
	'<inventory_root>/system' : { 'fru_type' : 'SYSTEM','is_fru' : True, 'present' : "True" },
	'<inventory_root>/system/systemevent' : { 'fru_type' : 'SYSTEM_EVENT', 'is_fru' : False, },
	'<inventory_root>/system/board' : { 'fru_type' : board,'is_fru' : False, 'manufacturer' : 'ASPEED', 'eeprom' : '7-0056@16384' },
}

if board == 'RMC':
    for i in range(1, 7):
        n = i
        if n > 3: n += 1
        FRU_INSTANCES.update({
            '<inventory_root>/system/CB{}'.format(i) : { 'fru_type' : 'CB','is_fru' : False, 'manufacturer' : 'ASPEED', 'eeprom' : '0-003{}@0'.format(n) },
        })
    for i in ('A', 'B'):
        if i == 'A': n = '9'
        else: n = 'b'
        FRU_INSTANCES.update({
            '<inventory_root>/system/RMC{}'.format(i) : { 'fru_type' : 'RMC','is_fru' : False, 'manufacturer' : 'ASPEED', 'eeprom' : '0-003{}@0'.format(n) },
        })

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

if board == 'CB':
    CB_temp_48 = 'ambient'
    if number == 3:
	CB_temp_48 = 'front'
    elif number == 4:
	CB_temp_48 = 'rear'

    HWMON_CONFIG = {
	'7-002f' : {
		'names' : {
			'pwm1' : { 'object_path' : 'speed/fan1','poll_interval' : 1000,'scale' : 1,'units' : '' },
			'pwm2' : { 'object_path' : 'speed/fan2','poll_interval' : 1000,'scale' : 1,'units' : '' },
			'pwm3' : { 'object_path' : 'speed/fan3','poll_interval' : 1000,'scale' : 1,'units' : '' },
			'pwm4' : { 'object_path' : 'speed/fan4','poll_interval' : 1000,'scale' : 1,'units' : '' },
			'pwm5' : { 'object_path' : 'speed/fan5','poll_interval' : 1000,'scale' : 1,'units' : '' },
			'pwm6' : { 'object_path' : 'speed/fan6','poll_interval' : 1000,'scale' : 1,'units' : '' },
			'pwm7' : { 'object_path' : 'speed/fan7','poll_interval' : 1000,'scale' : 1,'units' : '' },
			'pwm8' : { 'object_path' : 'speed/fan8','poll_interval' : 1000,'scale' : 1,'units' : '' },
			'fan1_input' : { 'object_path' : 'tach/fan1','poll_interval' : 1000,'scale' : 1,'units' : '' },
			'fan2_input' : { 'object_path' : 'tach/fan2','poll_interval' : 1000,'scale' : 1,'units' : '' },
			'fan3_input' : { 'object_path' : 'tach/fan3','poll_interval' : 1000,'scale' : 1,'units' : '' },
			'fan4_input' : { 'object_path' : 'tach/fan4','poll_interval' : 1000,'scale' : 1,'units' : '' },
			'fan5_input' : { 'object_path' : 'tach/fan5','poll_interval' : 1000,'scale' : 1,'units' : '' },
			'fan6_input' : { 'object_path' : 'tach/fan6','poll_interval' : 1000,'scale' : 1,'units' : '' },
			'fan7_input' : { 'object_path' : 'tach/fan7','poll_interval' : 1000,'scale' : 1,'units' : '' },
			'fan8_input' : { 'object_path' : 'tach/fan8','poll_interval' : 1000,'scale' : 1,'units' : '' },
		}
	},
	'7-0040' : {
		'names' : {
			'in1_input' : { 'object_path' : 'power/current','poll_interval' : 5000,'scale' : 10000,'units' : 'A' },
		}
	},
	'7-0048' :  {
		'names' : {
			'temp1_input' : { 'object_path' : 'temperature/{}'.format(CB_temp_48),'poll_interval' : 5000,'scale' : -3,'units' : 'C' },
		}
	},
	'7-0049' :  {
		'names' : {
			'temp1_input' : { 'object_path' : 'temperature/board','poll_interval' : 5000,'scale' : -3,'units' : 'C' },
		}
	},
    }
else:
    HWMON_CONFIG = {
	'7-0048' :  {
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
