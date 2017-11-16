#!/bin/bash

defaultfan=140
if [ ! -z $1 ]; then
    re='^[0-9]+$'
    if [[ $1 =~ $re ]] ; then
        defaultfan=$1
    fi

fi

fgrep w83795g /sys/class/hwmon/hwmon*/uevent -l | while read hwmon; do
    for pwm in ${hwmon%%/uevent}/device/pwm[1-8]; do
        [ -f "$pwm" ] || continue
        echo $defaultfan > $pwm
    done
done

