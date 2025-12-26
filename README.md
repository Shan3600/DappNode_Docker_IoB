# DAppNode-demo Docker image (Azure Container Instance friendly)

This repository contains a single-container image that runs:
- geth in dev mode (Ethereum JSON-RPC on port 8545)
- IPFS daemon (API on 5001, Gateway on 8080)
- Node.js dashboard (port 3000)
- nginx reverse proxy (port 80)

This is intended for demos and development. For production or multi-package DAppNode behavior prefer VMs or Kubernetes.

## Build locally

From the directory containing the Dockerfile:

```bash
docker build -t dappnode-demo:latest .
```

Run locally:

```bash
docker run --rm -p 80:80 -p 8545:8545 -p 5001:5001 -p 8080:8080 -p 3000:3000 \
  -v $(pwd)/data/ipfs:/data/ipfs \
  -v $(pwd)/data/geth:/data/geth \
  dappnode-demo:latest
```

- Dashboard: http://localhost/
- Geth RPC: http://localhost:8545
- IPFS API: http://localhost:5001
- IPFS Gateway: http://localhost/ipfs

## Push to Azure Container Registry (ACR)

1. Log in and create an ACR (skip if you already have one):

```bash
az login
az group create -n myResourceGroup -l eastus
az acr create -g myResourceGroup -n myDappAcr --sku Basic
az acr login --name myDappAcr
```

2. Tag and push:

```bash
ACR_NAME=myDappAcr
IMAGE_NAME=dappnode-demo
docker tag ${IMAGE_NAME}:latest ${ACR_NAME}.azurecr.io/${IMAGE_NAME}:v1
docker push ${ACR_NAME}.azurecr.io/${IMAGE_NAME}:v1
```

## Deploy to Azure Container Instances (ACI)

ACI example (expose port 80 publicly):

```bash
RESOURCE_GROUP=myResourceGroup
ACI_NAME=dappnode-demo-aci
ACR_NAME=myDappAcr
IMAGE=${ACR_NAME}.azurecr.io/dappnode-demo:v1

# Create the container instance and attach the ACR
az container create \
  --resource-group $RESOURCE_GROUP \
  --name $ACI_NAME \
  --image $IMAGE \
  --cpu 2 --memory 4 \
  --ports 80 8545 5001 8080 3000 \
  --registry-login-server ${ACR_NAME}.azurecr.io \
  --registry-username $(az acr credential show -n $ACR_NAME --query "username" -o tsv) \
  --registry-password $(az acr credential show -n $ACR_NAME --query "passwords[0].value" -o tsv)
```

After creation, get the FQDN:

```bash
az container show -g $RESOURCE_GROUP -n $ACI_NAME --query ipAddress.fqdn -o tsv
```

Visit `http://<FQDN>/` for the dashboard.

## Limitations & recommendations

- ACI cannot run sibling containers or host a Docker daemon — this image runs multiple services inside one container. For a true DAppNode experience (packages as separate containers, Docker socket access, discovery, package manager UI) use a VM or Kubernetes.
- Persist data: mount or attach a persistent volume to `/data/ipfs` and `/data/geth` (or use Azure File Shares) so the node state survives container restarts.
- Security: opening geth RPC to the public internet is insecure. Use firewall rules or private networking, and enable auth in production.
- For production-grade deployment consider AKS + managed disks or dedicated VMs for hosting full DAppNode.

## Customize

- Change `GETH` command-line args in `supervisord.conf` to join a real network or use different flags.
- Pin geth/IPFS versions by editing the Dockerfile ARG/URLs.
- Add more DAppNode-style packages by installing binaries and adding supervisord entries.
