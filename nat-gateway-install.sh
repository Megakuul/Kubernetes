#!/bin/bash

# This bash script sets up a NAT gateway using nftables on cloud computers (CentOS, RHEL, AWS Linux)
# A NAT gateway allows instances in a private subnet to access public package archives / container images

# Don't forget to disable source/destination check

# Install nftables
sudo yum install nftables -y
sudo systemctl enable nftables
sudo systemctl start nftables

# Enable IP forwarding
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.d/nat_gateway.conf
# Load kernel parameter live to system
sudo sysctl -p /etc/sysctl.d/nat_gateway.conf

# Find first BMRU (Broadcast, Multicast, Running, Up) interface (by default it expects only one public interface)
iface=$(netstat -i | grep "BMRU" | awk '{print $1}')

# Configure NAT masquerading with nftables
sudo nft add table ip nat
sudo nft add chain ip nat postrouting { type nat hook postrouting priority 100 \; }
sudo nft add rule ip nat postrouting oif "$iface" masquerade

# Save the nftables configuration
sudo nft list ruleset > /etc/nftables.conf