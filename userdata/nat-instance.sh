#!/bin/bash
set -eux

echo "Starting NAT Instance Setup"

apt update -y
apt install -y iptables-persistent

# Enable IPv4 forwarding
cat <<EOF >> /etc/sysctl.conf
net.ipv4.ip_forward=1
EOF

sysctl -w net.ipv4.ip_forward=1


# Detect network interface
PUBLIC_IFACE=$(ip route | awk '/default/ {print $5}')


echo "Using interface: $PUBLIC_IFACE"


# Clear existing rules
iptables -F
iptables -t nat -F


# NAT Internet Traffic
iptables -t nat -A POSTROUTING -o $PUBLIC_IFACE -j MASQUERADE


# Allow forwarding
iptables -A FORWARD -i $PUBLIC_IFACE -j ACCEPT
iptables -A FORWARD -o $PUBLIC_IFACE -m state --state RELATED,ESTABLISHED -j ACCEPT


# Save rules
iptables-save > /etc/iptables/rules.v4


echo "NAT Setup Completed"
