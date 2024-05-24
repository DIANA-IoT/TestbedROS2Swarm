# Scripts for DDS ROS 2 testing

This folder contains a set of Python 3 scripts to make reproducible tests
of a certain ROS 2 package and executable(s), with possibily varying conditions
between them. Each node, and the instructions that are passed them, make use of SSH
invokations.
<br>
Script list:

Each run is intended to be used with the configuration file `run_configs.yaml`, a YAML
file where key-values tuples follow the same nomenclature as the run arguments as the node subject to 
test. 

### Configuration utilities for the Raspberry Pis:

Our tests were primarly made using Eclipse's Foundation CycloneDDS middleware.
Thus, this ROS 2 package is required to be installed (`ros-humble-cyclonedds` and `ros-humble-rmw-cyclonedds-cpp`). To enable it, the following line must be appended to `.bashrc` -> `export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp`. <br>
To further tweak the configuration, an XML file located at `rpi_config/cyclonedds.xml`is given. As it is, it enables multicast communication using the WLAN0 interface. To disable multicast, simply comment the line `<AllowMulticast>true</AllowMulticast>`<br>
At the same directory, `iptables-withUDP` is a firewall rules file that blocks all DDS and UDP traffic on the `eth0` interface, except for the ports 2077 and 2078, which are used for the feedback traffic during our tests. Firewall rules can be applied by typing `iptables-restore iptables-withUDP` and rules can be deleted as well by `iptables -F`. <br>
Some additional logging, like CPU, memory and network interface usage are provided by using `mpstat`, `print_mem.bash` and `print_net.bash` respectively. <br>
If processes need to be killed, `kill_processes.bash` is given. This script additionally allows to kill a ROS 2 node by its name or by its package name. For example: `kill_processes.bash dds_study`. <br>

To ensure network addresses consistency, an example for netplan's configuration file is appended below. 

```
network:
    version: 2
    ethernets:
        renderer: networkd
        eth0:
            addresses: [192.168.2.24/24]
            nameservers:
              addresses: [192.168.2.1,8.8.8.8]
            dhcp4: no
            routes:
              - to: 0.0.0.0/0
                via: 192.168.2.1
                metric: 100
    wifis:
        renderer: networkd
        wlan0:
            access-points:
                WIFI_SSID:
                    password: PSK
            dhcp4: no
            addresses: [192.168.1.124/24]
            nameservers:
              addresses: [192.168.1.1,8.8.8.8]
            routes:
              - to: 0.0.0.0/0
                via: 192.168.1.1
                metric: 200
```
As in our tests, this file configures the Ethernet interface using the 192.168.2.1/24 domain while
wlan addresses are included in the 192.168.1.1/24 range. <br>
Both the interface name and address for the Ethernet are of great importance, because they will affect the effectiveness of the iptables file. <br>
Additionally, the address represents the control interface in which
SSH commands will be sent as ordered by the control script. 