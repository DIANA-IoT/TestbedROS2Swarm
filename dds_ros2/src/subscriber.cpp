/**
 * \class Subscriber
 * 
 * \brief Source code for subscriber node
 * \date 2024
 * 
 * \authors In alphabetical order: Cano-García J.M., Castillo-Sánchez J.B, González-Parada E.
 * 
 * \b copyright: University of Malaga
 * 
 * \b License: This program is free software, you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
*/
#include <chrono>
#include <functional>
#include <memory>
#include <string>
/* C headers for sockets. */
#include <arpa/inet.h>
#include <netinet/in.h>
#include <netinet/udp.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <unistd.h>

#include "rclcpp/rclcpp.hpp"
#include "std_msgs/msg/u_int8_multi_array.hpp"

using namespace std::chrono_literals;

class Subscriber : public rclcpp::Node, public rclcpp::Context
{
private:
    int history_;
    bool use_reliable_;
    bool use_volatile_;
    int sub_sock_;
    int payload_bytes_;
    int port_;
    rclcpp::Subscription<std_msgs::msg::UInt8MultiArray>::SharedPtr sub_;
    socklen_t sub_len;
    std::string topic_ = "";
    struct sockaddr_in servaddr;

    void initialize_ros_and_params(void)
    {
        /* Parameters declaration */
        this->declare_parameter<int>("history", 10);
        this->declare_parameter<int>("payload_bytes", 0);
        this->declare_parameter<int>("port", 0);
        this->declare_parameter<std::string>("publisher_topic", "");
        this->declare_parameter<bool>("use_default_reliability", true);
        this->declare_parameter<bool>("use_default_volatibility", true);
        /* Parameters get */
        this->get_parameter_or<int>("history",  history_, 10);
        this->get_parameter<int>("payload_bytes", payload_bytes_);
        this->get_parameter<int>("port", port_);
        this->get_parameter_or<std::string>("publisher_topic", topic_, "");
        this->get_parameter_or<bool>("use_default_reliability", use_reliable_, true);
        this->get_parameter_or<bool>("use_default_volatibility", use_volatile_, true);
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
        sub_ = this->create_subscription<std_msgs::msg::UInt8MultiArray>(topic_, qos, std::bind(&Subscriber::msg_rx_callback, this, std::placeholders::_1));
        // Wait for some time to allow all nodes to "wake up"
        rclcpp::sleep_for(10s);
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

    /// @brief ROS 2 message reception callback (subscription-triggered callback)
    /// @param ros_data Array that contains our useful data (header) plus some constant payload.
    void msg_rx_callback(const std_msgs::msg::UInt8MultiArray &ros_data)
    {
        /* Expected bytes equals header: [SN +  Ethernet Src ADDR +  timestamp]  plus payload. */
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

public:
    Subscriber() : Node("DDS_Subscriber")
    {
        initialize_ros_and_params();
        initialize_subscriber_socket();
    }
};

int main(int argc, char *argv[])
{
    rclcpp::init(argc, argv);
    // Wait for some time to allow all nodes to "wake up"
    rclcpp::sleep_for(10s);
    rclcpp::spin(std::make_shared<Subscriber>());
    rclcpp::shutdown();
    return 0;
}
