#!/bin/bash
set -eux

# Update packages
apt update -y
apt upgrade -y

# Install OpenVPN
apt install -y openvpn easy-rsa

# Create OpenVPN directory
mkdir -p /etc/openvpn/server

# Enable OpenVPN service
systemctl enable openvpn

echo "OpenVPN installed successfully."
echo "Further VPN certificates and server configuration can be added if required."

echo "VPN Setup Completed"