#!/bin/bash
# Script for killing mpstat, print_mem, print net and the given program (passed as argument).
# Authors In alphabetical order: Cano-García J.M., Castillo-Sánchez J.B, González-Parada E.
# copyright: University of Malaga
# License: This program is free software, you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
args=$#
cmd=$1
kill -9 $(ps aux | grep 'mpstat' | grep -v grep | awk '{{print $2}}') > /dev/null 2>&1
kill -9 $(ps aux | grep 'print_mem' | grep -v grep | awk '{{print $2}}') > /dev/null 2>&1
kill -9 $(ps aux | grep 'sleep 1' | grep -v grep | awk '{{print $2}}') > /dev/null 2>&1
kill -9 $(ps aux | grep 'print_net' | grep -v grep | awk '{{print $2}}') > /dev/null 2>&1
if [[ $args -eq 1 ]]; then
	kill -9 $(ps aux | grep $cmd | grep -v grep | awk '{{print $2}}') > /dev/null 2>&1
fi
