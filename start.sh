#!/bin/bash
set -e

# Ensure IPFS repo exists and initialize if not
export IPFS_PATH="/data/ipfs"
if [ ! -d "${IPFS_PATH}/config" ]; then
  echo "Initializing IPFS repo at ${IPFS_PATH}"
  ipfs init || true
  # Allow API and Gateway on all interfaces for containerized demo
  ipfs config Addresses.API /ip4/0.0.0.0/tcp/5001
  ipfs config Addresses.Gateway /ip4/0.0.0.0/tcp/8080
fi

# Ensure geth datadir exists
mkdir -p /data/geth

# Touch supervisord log dir
mkdir -p /var/log/supervisor

# Start supervisord (configured to run geth, ipfs, node app, nginx)
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf