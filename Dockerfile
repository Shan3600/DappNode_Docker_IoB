FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive
ARG IPFS_VERSION="v0.18.1"

# Basic tools and supervisor, nginx, nodejs prerequisites
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      ca-certificates curl wget gnupg2 lsb-release software-properties-common \
      supervisor nginx jq build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 18.x
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs \
    && npm --version || true

# Install Geth (ethereum client) from ethereum PPA
RUN add-apt-repository -y ppa:ethereum/ethereum && \
    apt-get update && \
    apt-get install -y --no-install-recommends geth && \
    rm -rf /var/lib/apt/lists/*

# Install go-ipfs (IPFS binary)
RUN set -ex \
    && TARGET="go-ipfs-${IPFS_VERSION}-linux-amd64.tar.gz" \
    && wget -q "https://dist.ipfs.io/go-ipfs/${IPFS_VERSION}/${TARGET}" -O /tmp/ipfs.tar.gz \
    && tar -xzf /tmp/ipfs.tar.gz -C /tmp \
    && mv /tmp/go-ipfs/ipfs /usr/local/bin/ipfs \
    && chmod +x /usr/local/bin/ipfs \
    && rm -rf /tmp/ipfs.tar.gz /tmp/go-ipfs

# Create directories
RUN mkdir -p /var/log/supervisor /opt/dappnode /opt/dappnode-app /data/ipfs /data/geth

# Copy app and supervisor config
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY start.sh /usr/local/bin/start.sh
COPY nginx.conf /etc/nginx/sites-available/default

# Copy node app
COPY app /opt/dappnode-app

WORKDIR /opt/dappnode-app

# Install node app dependencies
RUN npm install --production

# Expose ports (dashboard 3000, nginx 80; RPC 8545; IPFS API 5001; IPFS Gateway 8080)
EXPOSE 80 3000 8545 5001 8080

# Ensure scripts executable
RUN chmod +x /usr/local/bin/start.sh

# Start script will initialize IPFS if needed and launch supervisord
CMD ["/usr/local/bin/start.sh"]