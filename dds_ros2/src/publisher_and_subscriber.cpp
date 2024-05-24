/**
 * \class PubSub
 * 
 * \brief Source code for publisher/subscriber node
 * \date 2024
 * 
 * \authors In alphabetical order: Cano-García J.M., Castillo-Sánchez J.B, González-Parada E.
 * 
 * \b copyright: University of Malaga
 * 
 * \b License: This program is free software, you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
*/
#include <chrono>
#include <fstream>
#include <functional>
#include <iostream>
#include <memory>
#include <string>
#include <thread>
/* C headers for sockets. */
#include <arpa/inet.h>
#include <netinet/in.h>
#include <netinet/udp.h>
#include <stdio.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <unistd.h>

#include "rclcpp/rclcpp.hpp"
#include "std_msgs/msg/u_int8_multi_array.hpp"

#define LOCALHOST 0x0100007F

using namespace std::chrono_literals;

class PubSub : public rclcpp::Node, public rclcpp::Context
{
private:
    typedef std_msgs::msg::UInt8MultiArray test_msg_type;
    /* Internal variables: */
    bool use_file_;
    int sub_sock_;
    socklen_t sub_len;
    rclcpp::Publisher<test_msg_type>::SharedPtr pub_;
    rclcpp::Subscription<test_msg_type>::SharedPtr sub_;
    rclcpp::TimerBase::SharedPtr message_timer_ , end_timer_;
    uint32_t current_sequence;
    uint32_t ether_ip_addr_; /* IP4 addr binary form. */

    std::ofstream file_handler_;
    std::thread *listener_thread_;
    std::string topic_ = "";
    std_msgs::msg::UInt8MultiArray ros_msg;
    struct sockaddr_in servaddr;
    /* Parameters: */
    int history_ = 0;
    int packets_to_send_ = 0;
    int port_ = 0;
    std::string file_name_;
    bool use_reliable_;
    bool use_volatile_; /* If true, volatibility set to volatile. */
    int publishing_period_ms_;
    int payload_bytes_;
    
    /// @brief Performs the time difference between two timespec structs.
    /// @return A timespec struct.
    struct timespec diff_timespec(const struct timespec &time1, const struct timespec &time0)
    {
        struct timespec diff;
        diff.tv_sec = time1.tv_sec - time0.tv_sec;
        diff.tv_nsec = time1.tv_nsec - time0.tv_nsec;
        if (diff.tv_nsec < 0)
        {
            diff.tv_nsec += 1000000000; // nsec/sec
            diff.tv_sec--;
        }
        return diff;
    }

    /// @brief End callback triggered when packet limit generation is reached.
    /// @param  None
    void end_callback(void)
    {
        // This should be protected with a mutex.
        file_handler_.close();
        RCLCPP_DEBUG(this->get_logger(), "Shutting down node");
        rclcpp::shutdown();
    }

    /// @brief Attemps to open a pipe to execute a command in order to retrieve the Ethernet interface IP address.
    /// @param  None.
    /// @return Returns 0 on success, 1 on failure. 
    int get_ethernet_addr(void)
    {
        /* File handlers for system calls. */
        FILE *fp;
        char path[1024];
        /* Create a temporary C++ string to trim trailing network prefix. */
        std::string temp_str;
        fp = popen("ip addr | grep inet | grep global | awk '{ print $2 }' | head -n 1", "r");
        if (fp == NULL)
        {
            RCLCPP_ERROR(this->get_logger(), "Failed to open system command");
            goto err;
        }
        if (fgets(path, sizeof(path), fp) == NULL)
        {
            RCLCPP_ERROR(this->get_logger(), "Failed to retrieve Ethernet address");
            goto err;
        }
        temp_str = path;
        temp_str.erase(temp_str.find('/'));
        RCLCPP_INFO(this->get_logger(), "Ethernet address: %s", temp_str.c_str());
        /* Converts IPv4 address from text form to binary form. */
        if (inet_pton(AF_INET, temp_str.c_str(), &ether_ip_addr_) != 1)
        {
            RCLCPP_ERROR(this->get_logger(), "Failed to convert address to binary form");
            goto err;
        }
        pclose(fp);
        return 0;
    err:
        pclose(fp);
        return 1;
    }
    
    /// @brief Initialize ROS 2 parameters and other API utilities.
    /// @param  None.
    void initialize_ros_and_params(void)
    {
        /* Parameters declaration */
        this->declare_parameter<std::string>("file_name", "");
        this->declare_parameter<int>("history", 10);
        this->declare_parameter<int>("packets_to_send", 0);
        this->declare_parameter<int>("payload_bytes", 0);
        this->declare_parameter<int>("port", 0);
        this->declare_parameter<int>("publisher_period_ms", 1000);
        this->declare_parameter<std::string>("publisher_topic", "");
        this->declare_parameter<bool>("use_default_reliability", true);
        this->declare_parameter<bool>("use_default_volatibility", true);
        /* Parameters get*/
        this->get_parameter<std::string>("file_name", file_name_);
        this->get_parameter_or<int>("history",  history_, 10);
        this->get_parameter<int>("packets_to_send", packets_to_send_);
        this->get_parameter<int>("payload_bytes", payload_bytes_);
        this->get_parameter<int>("port", port_);
        this->get_parameter<int>("publisher_period_ms", publishing_period_ms_);
        this->get_parameter<std::string>("publisher_topic", topic_);
        this->get_parameter_or<bool>("use_default_reliability", use_reliable_, true);
        this->get_parameter_or<bool>("use_default_volatibility", use_volatile_, true);
        if (file_name_.empty())
        {
            use_file_ = false;
            RCLCPP_INFO(this->get_logger(), "No logfile path was provided. Not logging.");
        }
        else
        {
            use_file_ = true;
            RCLCPP_INFO(this->get_logger(), "Logging into: %s", file_name_.c_str());
        }
        /* Sequence number initialization. */
        current_sequence = 0;
        /* Resizes ROS 2 message:
            | ----------------Header---------------|| Payload|
            [SN +  Ethernet Src ADDR +  timestamp]  + payload
         */
        auto new_size = sizeof(uint32_t) + sizeof(uint32_t) + sizeof(time_t) + sizeof(long int) + payload_bytes_;
        ros_msg.data.resize(new_size);
        if (ros_msg.data.capacity() != new_size)
        {
            RCLCPP_ERROR(this->get_logger(), "Could not allocate memory for message");
            rclcpp::sleep_for(2s);
            rclcpp::shutdown();
        }
        /* Fill constant information as payload. */
        memset(&ros_msg.data[new_size - payload_bytes_], 0xA5, payload_bytes_);
        /* Initialize ROS 2 API components. */
        /* QoS settings. */
        auto qos = rclcpp::QoS((size_t)history_);
        if (!use_reliable_)
        {
            qos.best_effort();
        }
        if (!use_volatile_)
        {
            qos.transient_local();
        }
        pub_ = this->create_publisher<test_msg_type>(topic_, qos);
        sub_ = this->create_subscription<test_msg_type>(topic_, qos, std::bind(&PubSub::msg_rx_callback, this, std::placeholders::_1));
        // Wait for some time to allow all nodes to "wake up"
        rclcpp::sleep_for(10s);
        message_timer_ = this->create_wall_timer(std::chrono::milliseconds(publishing_period_ms_), std::bind(&PubSub::message_timer_cb, this));
    }

    /// @brief Initialize subscriber UDP socket
    /// @param None
    void initialize_subscriber_socket(void)
    {
        if ((sub_sock_ = socket(AF_INET, SOCK_DGRAM, 0)) < 0)
        {
            RCLCPP_ERROR(this->get_logger(), "Could not create socket");
            rclcpp::sleep_for(2s);
            rclcpp::shutdown();
        }
        /* Asserts destination ports fits in 16 bits range. */
        assert(port_ < 0xFFFF);
        /* Initialize sockaddr struct. */
        memset(&servaddr, 0, sizeof(servaddr));
        servaddr.sin_family = AF_INET;
        servaddr.sin_port = htons((uint16_t)port_);
        /* Servaddr will be set at subscription callback as it will vary 
            from message to message. */
        sub_len = sizeof(servaddr);
    }

    /// @brief Callback triggered whenever it is time to send a new ROS 2 message.
    /// @param None.
    void message_timer_cb(void)
    {
        struct timespec rp;
        (void)clock_gettime(CLOCK_MONOTONIC, &rp);
        memcpy(&ros_msg.data[0], &current_sequence, sizeof(uint32_t));
        memcpy(&ros_msg.data[4], &ether_ip_addr_, sizeof(uint32_t));
        memcpy(&ros_msg.data[8], &rp.tv_sec, sizeof(time_t));
        memcpy(&ros_msg.data[8 + sizeof(time_t)], &rp.tv_nsec, sizeof(long int));
        /* Leaves the rest of the message as it was (constant payload). */
        pub_->publish(ros_msg);
        if (current_sequence == packets_to_send_)
        {
            /* The desired amount of packets have been transmitted. */
            RCLCPP_DEBUG(this->get_logger(), "Packet limit reached.");
            /* Wait for some time and then close the node. */
            end_timer_ = this->create_wall_timer(5s, std::bind(&PubSub::end_callback, this));
            message_timer_->cancel();
        }
        current_sequence++;
    }

    /// @brief ROS 2 message reception callback (subscription-triggered callback)
    /// @param ros_data Array that contains our useful data (header) plus some constant payload.
    void msg_rx_callback(const std_msgs::msg::UInt8MultiArray &ros_data)
    {
        /* Expected bytes    // Wait for some time to allow all nodes to "wake up"
    rclcpp::sleep_for(10s); equals header: [SN +  Ethernet Src ADDR +  timestamp]  plus payload. */
        size_t header_size = sizeof(uint32_t) + sizeof(uint32_t) + sizeof(time_t) + sizeof(long int);
        size_t expected_bytes = payload_bytes_ + header_size;
        if (ros_data.data.size() < expected_bytes)
        {
            RCLCPP_INFO(this->get_logger(), "Size mismatch between expected to received bytes and actual data");
        }
        /* Creates response buffer. */
        char buffer[sizeof(time_t) + sizeof(long int) + sizeof(uint32_t)];
        /* Copy SN. */
        memcpy(&buffer, &ros_data.data[0], sizeof(uint32_t));
        /* Copy Integer part of the TX timestamp. */
        memcpy(&buffer[4], &ros_data.data[8], sizeof(time_t));
        /* Copy Fractional part of the TX timestamp (nsec)-. */
        memcpy(&buffer[4 + sizeof(time_t)], &ros_data.data[8 + sizeof(time_t)], sizeof(long int));
        /* Updates struct sockaddr struct, so that the destination will receive its intended message. */
        memcpy(&servaddr.sin_addr.s_addr, &ros_data.data[4], sizeof(struct sockaddr_in));
        /* Sends data to destination. */
        sendto(sub_sock_, &buffer, header_size, 0, (const struct sockaddr *)&servaddr, sub_len);
    }

    /// @brief Listener thread function. 
    void thread_func_()
    {
        int sock_;
        socklen_t len;
        struct sockaddr_in servaddr, cliaddr;
        /* Filesystem initialization: */
        /* Firstly, we will create the file that we shall use as log. */
        if (use_file_)
        {
            /* Attempts to open file. */
            file_handler_.open(file_name_, std::ios::out | std::ios::trunc);
            if (!file_handler_.is_open())
            {
                RCLCPP_ERROR(this->get_logger(), "Could not open file: exiting now");
                rclcpp::shutdown();
            }
            /* Succeed, so create the first line. */
            file_handler_ << "SN " << "TX_s " << "TX_ns " << "RX_s " << "RX_ns " \
             << "d_s " << "d_ns " << "IP\n";
        }
        /* UDP server initialization. */
        if ((sock_ = socket(AF_INET, SOCK_DGRAM, 0)) < 0)
        {
            RCLCPP_ERROR(this->get_logger(), "Could not create socket");
            rclcpp::sleep_for(2s);
            rclcpp::shutdown();
        }
        /* Asserts destination ports fits in 16 bits range. */
        assert(port_ < 0xFFFF);
        /* Initialize sockaddr, cliaddr struct. */
        memset(&servaddr, 0, sizeof(servaddr));
        memset(&cliaddr, 0, sizeof(cliaddr));
        /* IPv4 protocol listening on port "port_" of any address. */
        servaddr.sin_family = AF_INET;
        servaddr.sin_port = htons((uint16_t)port_);
        servaddr.sin_addr.s_addr = INADDR_ANY;
        /* Attempts to bind server address to socket. */
        if (bind(sock_, (const struct sockaddr *)&servaddr, sizeof(servaddr)) < 0)
        {
            RCLCPP_ERROR(this->get_logger(), "Could bind socket to server address");
            rclcpp::sleep_for(2s);
            rclcpp::shutdown();
        }
        /* Client address length. */
        len = sizeof(cliaddr);  
        char buffer[sizeof(time_t) + sizeof(long int) + sizeof(uint32_t)];
        while(1)
        {
            size_t received_bytes = 0;    
            do
            {
                received_bytes += recvfrom(sock_,
                                        &buffer[received_bytes], 
                                        32 - received_bytes,
                                        0,
                                        (struct sockaddr *)&servaddr,
                                        &len);
            } while (received_bytes < (sizeof(struct timespec) + sizeof(uint32_t)));
            /* Checks if I am not the the sender. */
            if(servaddr.sin_addr.s_addr == ether_ip_addr_)
            {
                servaddr.sin_addr.s_addr = LOCALHOST;
            }
            struct timespec current_rp, past_rp;
            (void)clock_gettime(CLOCK_MONOTONIC, &current_rp);
            memset(&past_rp, 0, sizeof(past_rp));
            uint32_t sn = 0;
            memcpy(&sn, &buffer[0], sizeof(uint32_t));
            memcpy(&past_rp.tv_sec, &buffer[4], sizeof(time_t));
            memcpy(&past_rp.tv_nsec, &buffer[4 + sizeof(time_t)], sizeof(long int));
            if (use_file_)
                stream_to_file(file_handler_, sn, past_rp, current_rp, servaddr.sin_addr.s_addr);
        }
        close(sock_);
        file_handler_.close();
    }

    /// @brief Write parameters in text mode with spaces in between. This function is not thread-safe.
    /// @param fh file handler to use
    /// @param sn Sequence number.
    /// @param tx_ts Transmission timestamp.
    /// @param rx_ts Reception timestamp.
    /// @param ip IPv4, sender address.
    void stream_to_file(std::ofstream &fh, const uint32_t &sn, const struct timespec &tx_ts, 
        const struct timespec &rx_ts, const uint32_t &ip)
    {
        char ip_str[INET_ADDRSTRLEN];
        // Consider if the subsequent calls are going to introduce a significant delay
        if(inet_ntop(AF_INET, (void *) &ip, ip_str, INET_ADDRSTRLEN) == nullptr)
        {
            RCLCPP_ERROR(this->get_logger(), "Error at converting IP from binary to text form");
            return;
        }
        auto diff = diff_timespec(rx_ts, tx_ts);
        fh << sn << " " << tx_ts.tv_sec << " " << tx_ts.tv_nsec << " " << rx_ts.tv_sec  \
            << " " << rx_ts.tv_nsec << " " << diff.tv_sec \
            << " " << diff.tv_nsec << " " << ip_str << "\n";
        #if 0 /* Binary mode. */
        /* Write the sequence number */
        file_handler_.write((char *)&sn, sizeof(sn));
        /* Write transmission timestamp. */
        file_handler_.write((char *)&tx_ts, sizeof(tx_ts));
        /* Write reception timestamp. */
        file_handler_.write((char *)&rx_ts, sizeof(rx_ts));
        /* Write time difference. */
        #endif
    }

public:
    PubSub() : Node("DDS_publishersubscriber")
    {
        /* Firstly, get our address before initializing the rest of components. */
        if (get_ethernet_addr() != 0)
            rclcpp::shutdown();
        /* Initialize ROS 2 related stuff. */
        initialize_ros_and_params();
        /* Initialize subscriber UDP client socket. */
        initialize_subscriber_socket();
        /* Spawn thread: this thread will be blocked until an UDP message comes. */
        listener_thread_ = new std::thread(&PubSub::thread_func_, this);
    }
    ~PubSub()
    {
        close(sub_sock_);
        delete listener_thread_;
    }
};

int main(int argc, char *argv[])
{
    rclcpp::init(argc, argv);
    // Wait for some time to allow all nodes to "wake up"
    rclcpp::sleep_for(10s);
    rclcpp::spin(std::make_shared<PubSub>());
    rclcpp::shutdown();
    return 0;
}