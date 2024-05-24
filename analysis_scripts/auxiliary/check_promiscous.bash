#!/bin/bash
# Script that checks monitor mode. Substitute 'wlp4s0' by your specific interface.
# Authors In alphabetical order: Cano-García J.M., Castillo-Sánchez J.B, González-Parada E.
# copyright: University of Malaga
# License: This program is free software, you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
if [ "$EUID" -ne 0 ]
        then echo "Please run as root"
        exit
fi

iwconfig | grep 'Monitor'
