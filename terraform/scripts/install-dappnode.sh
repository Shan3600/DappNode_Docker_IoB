#!/bin/bash
#
# DappNode Installation Script for Debian VM
# This script installs DappNode on a fresh Debian 11 instance
#

set -e

echo "=========================================="
echo "Starting DappNode Installation"
echo "=========================================="

# Update system packages
echo "Updating system packages..."
apt-get update
apt-get upgrade -y

# Install required dependencies
echo "Installing dependencies..."
apt-get install -y \
  curl \
  wget \
  git \
  apt-transport-https \
  ca-certificates \
  gnupg \
  lsb-release \
  sudo

# Install DappNode prerequisites using official script
echo "Installing DappNode prerequisites..."
wget -O - https://prerequisites.dappnode.io | bash

# Install DappNode using official installer
echo "Installing DappNode..."
wget -O - https://installer.dappnode.io | bash

# Configure firewall (if UFW is installed)
if command -v ufw &> /dev/null; then
  echo "Configuring firewall..."
  ufw allow 22/tcp
  ufw allow 80/tcp
  ufw allow 443/tcp
  ufw allow 8080/tcp
  ufw allow 30303/tcp
  ufw allow 30303/udp
  echo "y" | ufw enable
fi

# Set up system optimizations for DappNode
echo "Applying system optimizations..."
sysctl -w vm.max_map_count=262144
echo "vm.max_map_count=262144" >> /etc/sysctl.conf

echo "=========================================="
echo "DappNode Installation Complete!"
echo "=========================================="
echo ""
echo "Access DappNode at: http://$(hostname -I | awk '{print $1}')"
echo "Or via the external IP assigned to this VM"
echo ""
echo "Note: It may take a few minutes for all services to start"
echo "=========================================="

# Log installation completion
logger "DappNode installation completed successfully"
