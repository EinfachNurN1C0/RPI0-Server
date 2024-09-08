#!/bin/bash

while true; do
  echo "$(date +%T): $(vcgencmd measure_temp)"
  sleep 10
done