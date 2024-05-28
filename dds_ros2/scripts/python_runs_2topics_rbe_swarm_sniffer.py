# Script for launching simulations via SSH to a set of hosts.
# Authors In alphabetical order: Cano-García J.M., Castillo-Sánchez J.B, González-Parada E.
# copyright: University of Malaga
# License: This program is free software, you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
import paramiko, os, yaml, time, threading, subprocess
from concurrent.futures import ThreadPoolExecutor

## Global variables
hosts = []
private_key_path = ''
config = ''
config2 = ''
package_bin_tuple = []


# Convert from YAML values to command string list
def config_to_command(config, package, executable):
    # Convert None values to empty strings
    for server in config['runs']:
        for key, value in server.items():
            if value is None:
                server[key] = ''
    # Create empty commands list
    commands = []
    # Access values to create command str
    for index, run in enumerate(config['runs']):
        command = f"ros2 run {package} {executable} --ros-args"
        for pairs in run.items():
            if pairs[0] == 'other_opts' and pairs[1] != None:
                # command += f"{pairs[1]} "
                command = ''.join((f"{pairs[1]} ", command))
                continue
            command += f" -p {pairs[0]}:={pairs[1]}"
        commands.append(command)
    return commands

def ensure_user_input(prompt):
    user_input = input(prompt)
    if user_input.lower() not in ['yes', 'y']:
        print("You didn't enter 'yes' or 'y'. Exiting.")
        exit()

# Get YAML tuples from path
def load_config(file_path):
    with open(file_path, 'r') as file:
        config = yaml.safe_load(file)
    return config

def run_command_on_background(host, username, private_key_path, command, executor_index):
    try:
        # Construct the SSH command for the single command
        ssh_command = f"""ssh -i {private_key_path} {username}@{host} -f 'nohup {command} > /dev/null 2>&1 &'"""

        # Execute the SSH command using subprocess
        subprocess.run(ssh_command, shell=True, check=False, text=True)

        # Print the command information
        t = time.localtime()
        current_time = time.strftime("%H:%M:%S", t)
        print(f"At: {current_time}, Command '{command}' for executor index {executor_index} on {host} started in the background")

    except subprocess.CalledProcessError as e:
        print(f"Error executing command '{command}' on {host} from executor index {executor_index}: {e}")


def run_command(host, username, private_key_path, command, executor_index):
    try:
        # Construct the SSH command for the single command
        ssh_command = f"""ssh -i {private_key_path} {username}@{host} '{command}'"""

        # Execute the SSH command using subprocess
        subprocess.run(ssh_command, shell=True, check=False)

        # Print the command information
        t = time.localtime()
        current_time = time.strftime("%H:%M:%S", t)
        print(f"At: {current_time}, Command '{command}' for executor index {executor_index} on {host} executed")

    except subprocess.CalledProcessError as e:
        print(f"Error executing command '{command}' on {host} from executor index {executor_index}: {e}")

def run_commands_on_remote(host, username, private_key_path, configs, package_bin_tuple, host_index, index_to_disc, command_barrier, publisher_barrier, sem, do_log):

    try:
        # Create ROS 2 command based on index
        my_package = package_bin_tuple[host_index][0]
        my_exec = package_bin_tuple[host_index][1]
        ros2_cmds = config_to_command(configs, my_package, my_exec)
        
        # Iterate through ros2 commands
        for cmd_index, cmd in enumerate(ros2_cmds):
            # Create new variables for the log commands.
            cpu_file = f"/home/ubuntu/dds_logs/cpu_robot{host_index}_run{cmd_index}.txt"
            mem_file = f"/home/ubuntu/dds_logs/mem_robot{host_index}_run{cmd_index}.txt"
            net_file = f"/home/ubuntu/dds_logs/net_robot{host_index}_run{cmd_index}.txt"
            update_seconds = "1"
            log_command = f"nohup mpstat {update_seconds} > {cpu_file} & "
            log_command += f"nohup bash print_mem.bash {mem_file} {update_seconds} & "
            # Create new variable for the run command
            ros2_command = ""
            # Append node id to command
            # Create ROS 2 command
            if index_to_disc == host_index:
             # Append file name to command
                ros2_command += "nohup " + cmd + f" -p file_name:=/home/ubuntu/dds_logs/robot{host_index}_run{cmd_index}.csv" 
                ros2_command += f" -r __node:=node{host_index} & sleep 80; iptables -A INPUT -i wlan0 -m statistic --mode random --probability 0.1 -j DROP"
            else:
                ros2_command += cmd + f" -p file_name:=/home/ubuntu/dds_logs/robot{host_index}_run{cmd_index}.csv" 
                ros2_command += f" -r __node:=node{host_index} > /dev/null 2>&1"
            # If CPU and RAM logging is enabled
            if do_log:

                cmd = f"nohup mpstat {update_seconds} > {cpu_file} 2>&1 &"
                run_command(host, username, private_key_path, cmd, host_index)
                time.sleep(1)
                command_barrier.wait()

                cmd = f"bash print_mem.bash {mem_file} {update_seconds}"
                run_command_on_background(host, username, private_key_path, cmd, host_index)
                time.sleep(1)
                command_barrier.wait()

                cmd = f"bash print_net.bash eth0 {net_file} {update_seconds}"
                run_command_on_background(host, username, private_key_path, cmd, host_index)
                time.sleep(1)
                command_barrier.wait()
            else:
                run_command(host, username, private_key_path, "echo ", host_index)
                time.sleep(1)
                command_barrier.wait()

                run_command(host, username, private_key_path, "echo ", host_index)
                time.sleep(1)
                command_barrier.wait()

                run_command(host, username, private_key_path, "echo ", host_index)
                time.sleep(1)
                command_barrier.wait()

            commands = [
                "sleep 5; ifconfig wlan0 down; sleep 5; ifconfig wlan0 up; sleep 10",
                "iptables-restore /home/ubuntu/iptables-withUDP",
                ros2_command,
                f"bash /root/kill_processes.bash {my_package}",
                f"bash /root/kill_processes.bash"
                ]

            for index, command in enumerate(commands):
                if index == 2:
                    if my_exec == 'publisher':
                        run_command(host, username, private_key_path, command, host_index)
                        publisher_barrier.wait()
                        sem.release()
                    elif my_exec == 'subscriber':
                        run_command_on_background(host, username, private_key_path, command, host_index)
#                         sem.acquire()
                    else:
                        run_command(host, username, private_key_path, command, host_index)
                    time.sleep(1)
                else:
                    run_command(host, username, private_key_path, command, host_index)
                    time.sleep(1)

                command_barrier.wait()

    except Exception as e:
        print(f"Error connecting to {host} from executor index {executor_index}: {e}")


def run_sniffer(host, username, private_key_path, command_barrier, num_cmds):
    try:
        for index in range(num_cmds):
            # Dummy echos to synchronise 
            for i in range(0, 3):
                run_command(host, username, private_key_path, "echo ", 99)
                time.sleep(1)
                command_barrier.wait()
            # Replace wlp4s0 by your WNIC alias. Runs the capture for 1200 seconds (20 min) 
            # or until the test ends, whichever happens first.
            tcpdump_cmd = "tcpdump -G 1200 -W 1 -i wlp4s0 -w"
            tcpdump_cmd += f" /home/USR/wshark_swarm_run{index}.pcapng"
            run_command_on_background(host, username, private_key_path, tcpdump_cmd, 99)
            time.sleep(1)
            command_barrier.wait()
            for i in range(0, 2):
                run_command(host, username, private_key_path, "echo ", 99)
                time.sleep(1)
                command_barrier.wait()
            # Kill in case the run takes less than 20 minutes
            run_command(host, username, private_key_path, 'pkill -9 tcpdump', 99)
            time.sleep(1)
            command_barrier.wait()

            run_command(host, username, private_key_path, "echo ", 99)
            time.sleep(1)
            command_barrier.wait()

    except Exception as e:
        print(f"Error connecting to {host} from executor index {executor_index}: {e}")

def worker_wrapper(index, command_barrier, publisher_barrier, sem):
    global private_key_path, config, config2, package_bin_tuple, hosts
    num_cmds = len(config_to_command(config2,'ros2', 'ab'))
    run_config = config if index <= n_pub else config2
    if index == len(hosts):
        run_sniffer('192.168.2.240','USR',private_key_path,command_barrier,num_cmds)
    else:
        run_commands_on_remote(hosts[index], 'root', private_key_path, run_config, package_bin_tuple, index, 99, command_barrier, publisher_barrier, sem, index <= n_pub)


if __name__ == "__main__":

    ensure_user_input("Have you rysnc'ed all files? Enter 'yes' or 'y' to continue\n")
    ensure_user_input("Have you correctly setup iptables? Enter 'yes' or 'y' to continue\n")
    ensure_user_input("Is directory '/home/ubuntu/dds_logs' present? Enter 'yes' or 'y' to continue\n")
    # Configuration for the Publishers or subscribers nodes
    config = load_config('/home/USR/PATH/run_configs.yaml')   
    # Configuration for the Publishers/subscribers.
    config2 = load_config('/home/USR/PATH/run_configs_parallel.yaml')

    node_names = []
    # IP addresses of each host
    hosts = [
        '192.168.2.2', 
        '192.168.2.3',
        '192.168.2.4',
        '192.168.2.5',
        '192.168.2.6',
        '192.168.2.7',
        '192.168.2.8',
        '192.168.2.9', 
        '192.168.2.10',
        '192.168.2.11',
        '192.168.2.12',
        '192.168.2.13',
        '192.168.2.14',
        '192.168.2.15',
        '192.168.2.16',
        '192.168.2.17',
        '192.168.2.18',
        '192.168.2.19', 
        '192.168.2.20',
        '192.168.2.21',
        '192.168.2.22',
        '192.168.2.23',
        '192.168.2.24',
        '192.168.2.25',
        '192.168.2.26',
        '192.168.2.27',
        '192.168.2.2', 
        '192.168.2.3',
        '192.168.2.4',
        '192.168.2.5',
        '192.168.2.6',
        '192.168.2.7',
        '192.168.2.8',
        '192.168.2.9', 
        '192.168.2.10',
        '192.168.2.11',
        '192.168.2.12',
        '192.168.2.13',
        '192.168.2.14',
        '192.168.2.15',
        '192.168.2.16',
        '192.168.2.17',
        '192.168.2.18',
        '192.168.2.19', 
        '192.168.2.20',
        '192.168.2.21',
        '192.168.2.22',
        '192.168.2.23',
        '192.168.2.24',
        '192.168.2.25',
        '192.168.2.26'
        ]
    # ROS 2 packages and nodes to be launch
    package_bin_tuple = [
        ("dds_study", "publisher"),
        ("dds_study", "publisher"),
        ("dds_study", "publisher"),
        ("dds_study", "publisher"),
        ("dds_study", "publisher"),
        ("dds_study", "publisher"),
        ("dds_study", "publisher"),
        ("dds_study", "publisher"),
        ("dds_study", "publisher"),
        ("dds_study", "publisher"),
        ("dds_study", "publisher"),
        ("dds_study", "publisher"),
        ("dds_study", "publisher"),
        ("dds_study", "publisher"),
        ("dds_study", "publisher"),
        ("dds_study", "publisher"),
        ("dds_study", "publisher"),
        ("dds_study", "publisher"),
        ("dds_study", "publisher"),
        ("dds_study", "publisher"),
        ("dds_study", "publisher"),
        ("dds_study", "publisher"),
        ("dds_study", "publisher"),
        ("dds_study", "publisher"),
        ("dds_study", "publisher"),
        ("dds_study", "subscriber"),
        ("dds_study", "pub_sub"),
        ("dds_study", "pub_sub"),
        ("dds_study", "pub_sub"),
        ("dds_study", "pub_sub"),
        ("dds_study", "pub_sub"),
        ("dds_study", "pub_sub"),
        ("dds_study", "pub_sub"),
        ("dds_study", "pub_sub"),
        ("dds_study", "pub_sub"),
        ("dds_study", "pub_sub"),
        ("dds_study", "pub_sub"),
        ("dds_study", "pub_sub"),
        ("dds_study", "pub_sub"),
        ("dds_study", "pub_sub"),
        ("dds_study", "pub_sub"),
        ("dds_study", "pub_sub"),
        ("dds_study", "pub_sub"),
        ("dds_study", "pub_sub"),
        ("dds_study", "pub_sub"),
        ("dds_study", "pub_sub"),
        ("dds_study", "pub_sub"),
        ("dds_study", "pub_sub"),
        ("dds_study", "pub_sub"),
        ("dds_study", "pub_sub"),
        ("dds_study", "pub_sub")
        ]
    
    n_threads = len(hosts) + 1

    command_barrier = threading.Barrier(n_threads)
    # Create a publisher barrier
    n_pub = sum(1 for tup in package_bin_tuple if "publisher" in tup)
    publisher_barrier = threading.Barrier(n_pub)
    sem = threading.Semaphore(value=0)
    # SSH private key path
    private_key_path = os.path.join(os.path.expanduser('~'), '.ssh/id_rsa')
    with ThreadPoolExecutor(max_workers=n_threads) as executor:
        for i in range(n_threads):
            fut = executor.submit(worker_wrapper, i, command_barrier, publisher_barrier, sem)
        # Wait for all threads to finish
        executor.shutdown()
