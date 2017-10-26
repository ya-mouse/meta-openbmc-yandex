#!/bin/bash  -e

export PATH=/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin
if [ -z $1 ] || [ "$1" -gt 6 ] || [ "$1" -lt 1 ]; then
  echo "Usage: $0 <CB_NUMBER>"
  exit
fi

n=$1

mynum=$(cat /etc/openrack-board | tr -s "-" " " | awk '{print $2}')
if [ $n -eq $mynum ]; then
  echo "Can't reset myself, exiting"
  exit
fi

[ $n -lt 4 ] || n=$((n+1))

addr=$((0x20+n))
addrhex=$(printf "%x" ${addr})

i2cdetect -y 0 | grep "${addrhex}" > /dev/null 2>&1

if [ "$?" -ne "0" ]; then
 echo "CB not present, exiting"
 exit
fi

source /usr/share/openrack/functions
io_en 0 ${addr} 0.6
io_gpio 0 ${addr} 0.6 0
sleep 1
io_gpio 0 ${addr} 0.6 1
io_del 0 ${addr} 0.6

echo "CB $n reset, exiting"

