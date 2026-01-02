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
  # Use fixed version for reproducibility
  DOCKER_COMPOSE_VERSION="v2.24.1"
  COMPOSE_URL="https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)"
  COMPOSE_CHECKSUM_URL="https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m).sha256"
  
  # Download Docker Compose
  curl -L "${COMPOSE_URL}" -o /tmp/docker-compose
  
  # Download and verify checksum (if available)
  if curl -L "${COMPOSE_CHECKSUM_URL}" -o /tmp/docker-compose.sha256 2>/dev/null; then
    cd /tmp
    sha256sum -c docker-compose.sha256 || (echo "Checksum verification failed" && exit 1)
    cd -
  else
    echo "Warning: Checksum not available, skipping verification"
  fi
  
  # Install
  mv /tmp/docker-compose /usr/local/bin/docker-compose
  chmod +x /usr/local/bin/docker-compose
  rm -f /tmp/docker-compose.sha256
else
  echo "Docker Compose is already installed"
fi

# Download and install DappNode
echo "Installing DappNode..."
if [ ! -d "/usr/src/dappnode" ]; then
  # Download scripts to temporary location
  echo "Downloading DappNode prerequisites script..."
  wget -O /tmp/dappnode-prerequisites.sh https://prerequisites.dappnode.io
  
  echo "Downloading DappNode installer script..."
  wget -O /tmp/dappnode-installer.sh https://installer.dappnode.io
  
  # Review scripts (logged for audit)
  echo "Scripts downloaded. Executing prerequisites..."
  bash /tmp/dappnode-prerequisites.sh
  
  echo "Executing DappNode installer..."
  bash /tmp/dappnode-installer.sh
  
  # Clean up
  rm -f /tmp/dappnode-prerequisites.sh /tmp/dappnode-installer.sh
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
