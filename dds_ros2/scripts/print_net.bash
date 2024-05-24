#!/bin/bash
# Script for saving a specific network interface usage into a file
# Authors In alphabetical order: Cano-García J.M., Castillo-Sánchez J.B, González-Parada E.
# copyright: University of Malaga
# License: This program is free software, you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
args=$#
if [[ $args -ne 3 ]]; then
        echo "Usage: iface_name log_path logging_interval_seconds"
        exit
fi

iface=$1
log_file=$2
sleep_time=$3

stats_path="/sys/class/net/$iface/statistics"
echo "Time | RX_bytes | RX_packets | TX_bytes | Tx_packets | Multicast" >> $log_file

while true; do
        f=$(date "+%T")
        rxb=$(cat $stats_path/rx_bytes)
        rxp=$(cat $stats_path/rx_packets)
        txb=$(cat $stats_path/tx_bytes)
        txp=$(cat $stats_path/tx_packets)
        mcast=$(cat $stats_path/multicast)
        (echo "$f | $rxb | $rxp | $txb | $txp | $mcast") >> $log_file
        sleep $sleep_time
done
