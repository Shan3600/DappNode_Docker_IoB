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

# Install Docker
echo "Installing Docker..."
if ! command -v docker &> /dev/null; then
  curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
  sh /tmp/get-docker.sh
  systemctl enable docker
  systemctl start docker
  rm /tmp/get-docker.sh
else
  echo "Docker is already installed"
fi

# Install Docker Compose
echo "Installing Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
  DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')
  curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  chmod +x /usr/local/bin/docker-compose
else
  echo "Docker Compose is already installed"
fi

# Download and install DappNode
echo "Installing DappNode..."
if [ ! -d "/usr/src/dappnode" ]; then
  wget -O - https://prerequisites.dappnode.io | sudo bash
  wget -O - https://installer.dappnode.io | sudo bash
else
  echo "DappNode directory already exists, skipping installation"
fi

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

# Enable and start DappNode services
echo "Enabling DappNode services..."
systemctl enable docker

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
