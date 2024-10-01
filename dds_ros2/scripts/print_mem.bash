#!/bin/bash
# Script for saving memory usage into a file
# Authors In alphabetical order: Cano-García J.M., Castillo-Sánchez J.B, González-Parada E.
# copyright: University of Malaga
# License: This program is free software, you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
args=$#
if [[ $args -ne 2 ]]; then
	echo "Usage: log_file_path logging_interval_seconds"
	exit
fi

log_file=$1
sleep_time=$2

while true; do
	f=$(date "+%T"); 
	memory=$(cat /proc/meminfo | awk 'NR == 1 || NR == 3  || NR >= 15 && NR < 17 {print}')
	(echo -n $f; echo -n " "; echo $memory) >> $log_file
	sleep $sleep_time
done
