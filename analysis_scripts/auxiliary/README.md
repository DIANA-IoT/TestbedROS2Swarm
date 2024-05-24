## Auxiliary scripts

This folder presents the scripts that may be handy for setting up the monitoring system.

* Specifically `check_promiscous.bash` and `set_promiscous.bash`, check and set the selected 
interface (configured inside `set_promiscous.bash`) to be set in monitor mode. In our case, 
the interface identifier is `wlp4s0`, so check yours beforehand. <br>
Both scripts need to be ran as superuser  plus the processes `ifconfig`, `iwconfig`and `rfkill` to be installed within the system. `systemctl`is used as well.
