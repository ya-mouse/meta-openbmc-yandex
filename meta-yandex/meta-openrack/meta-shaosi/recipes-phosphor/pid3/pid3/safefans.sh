#!/bin/bash

for i in {1..8}; do 
  echo 140 > /sys/class/hwmon/hwmon0/device/pwm${i}
done

