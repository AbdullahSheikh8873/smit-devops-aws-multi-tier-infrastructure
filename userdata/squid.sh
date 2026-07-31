#!/bin/bash
set -eux

# Update packages
apt update -y
apt upgrade -y

# Install Squid
apt install -y squid

# Backup default config
cp /etc/squid/squid.conf /etc/squid/squid.conf.bak

# Create new config
cat > /etc/squid/squid.conf <<EOF

http_port 3128

acl localnet src 10.1.0.0/16

http_access allow localnet

http_access deny all

visible_hostname squid-server

EOF

# Enable service
systemctl enable squid

# Restart service
systemctl restart squid

echo "Squid Proxy Setup Completed"