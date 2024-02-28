#!/bin/bash

# This bash script can be used on cloud computers (CentOS, RHEL or AWS Linux) to setup a nat gateway for egress
# A nat gateway is usually required if the cluster is in a private subnet, so that they can still access public package archives / container images

# Install iptables service wrapper
sudo yum install iptables-services -y
sudo systemctl enable iptables
sudo systemctl start iptables

# Enable ip forwarding
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.d/nat_gateway.conf
# Load kernel parameter live to system
sudo sysctl -p /etc/sysctl.d/nat_gateway.conf

# Find first BMRU (Broadcast, Multicast, Running, Up) interface (by default it expects only one public interface
iface=$(netstat -i | grep "BMRU" | awk '{print $1}')
sudo /sbin/iptables -t nat -A POSTROUTING -o $iface -j MASQUERADE
sudo /sbin/iptables -F FORWARD
sudo service iptables save