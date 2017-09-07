#!/bin/bash -e

# Reset BMC via GPIO

export PATH=/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin
if [ -z $1 ] || [ "$1" -gt 6 ] || [ "$1" -lt 1 ]; then
  echo "Usage: $0 <BMC_NUMBER>"
  exit
fi

n=$1
io=$((n-1))
rst="1.${io}"
#[ $n -lt 4 ] || n=$((n+1))

source /usr/share/openrack/functions
io_en 7 $((0x24)) ${rst}
io_gpio 7 $((0x24)) ${rst} 0 
sleep 1
io_gpio 7 $((0x24)) ${rst} 1 

echo "BMC $n reset, exiting"

