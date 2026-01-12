# DappNode Terraform Deployment

This directory contains Terraform configuration to deploy DappNode on Google Cloud Platform (GCP) with automated infrastructure setup.

## Overview

This Terraform configuration creates a complete DappNode infrastructure on GCP including:

- **VPC Network**: Isolated network for DappNode
- **Subnet**: Private subnet with configurable CIDR range
- **Firewall Rules**: SSH access and DappNode service ports (80, 443, 8080, 30303)
- **Static External IP**: Dedicated IP address for the DappNode server
- **VM Instance**: Debian 11 VM with automatic DappNode installation

## Project Configuration

- **GCP Project ID**: `blockchaindappnode`
- **Default Region**: `us-central1`
- **Default Zone**: `us-central1-a`

## Prerequisites

Before deploying, ensure you have:

1. **Google Cloud SDK (gcloud)** installed
   ```bash
   # Install gcloud CLI
   # https://cloud.google.com/sdk/docs/install
   ```

2. **Terraform** installed (version >= 1.6.0)
   ```bash
   # Install Terraform
   # https://www.terraform.io/downloads
   ```

3. **GCP Project Access**: You need owner or editor permissions on the `blockchaindappnode` project

4. **Authentication**: Authenticate with GCP
   ```bash
   gcloud auth login
   gcloud auth application-default login
   ```

## Quick Start Deployment

### Option 1: Automated Deployment (Recommended)

Use the initialization script for a guided deployment:

```bash
cd terraform
./init-deployment.sh
```

This script will:
- ✅ Check prerequisites
- ✅ Enable required GCP APIs
- ✅ Create GCS buckets for Terraform state and build artifacts
- ✅ Configure Cloud Build permissions
- ✅ Initialize Terraform with remote backend
- ✅ Validate and format Terraform configuration
- ✅ Generate execution plan
- ✅ Prompt for deployment confirmation
- ✅ Deploy infrastructure and display access information

### Option 2: Manual Deployment

If you prefer manual control:

#### Step 1: Enable GCP APIs

```bash
gcloud services enable compute.googleapis.com \
  cloudbuild.googleapis.com \
  storage.googleapis.com \
  --project=blockchaindappnode
```

#### Step 2: Create GCS Buckets

```bash
# Create bucket for Terraform state
gsutil mb -p blockchaindappnode -l us-central1 gs://blockchaindappnode-terraform-state
gsutil versioning set on gs://blockchaindappnode-terraform-state

# Create bucket for build artifacts
gsutil mb -p blockchaindappnode -l us-central1 gs://blockchaindappnode-build-artifacts
```

#### Step 3: Initialize Terraform

```bash
cd terraform
terraform init -backend-config="bucket=blockchaindappnode-terraform-state"
```

#### Step 4: Review Configuration

Check the `terraform.tfvars` file and update if needed:

```bash
cat terraform.tfvars
```

Key variables:
- `project_id`: GCP project ID (already set to `blockchaindappnode`)
- `region`: GCP region for resources
- `zone`: GCP zone for VM instance
- `machine_type`: VM machine type (default: `n1-standard-4`)
- `disk_size_gb`: Boot disk size (default: 100 GB)
- `ssh_source_ranges`: IP ranges allowed for SSH (⚠️ default allows all, restrict for production)

#### Step 5: Plan and Apply

```bash
# Validate configuration
terraform validate

# Format code
terraform fmt -recursive

# Generate plan
terraform plan -out=tfplan

# Review plan and apply
terraform apply tfplan
```

## Configuration Files

### Core Terraform Files

- **`main.tf`**: Main infrastructure configuration
  - VPC network and subnet
  - Firewall rules
  - Static IP address
  - VM instance with startup script

- **`variables.tf`**: Variable definitions with defaults
  - Project, region, and zone configuration
  - Network CIDR ranges
  - VM specifications
  - SSH access configuration

- **`outputs.tf`**: Output values after deployment
  - VM name and IPs
  - Network information
  - SSH command

- **`terraform.tfvars`**: Variable values (configured for `blockchaindappnode` project)

### Scripts

- **`scripts/install-dappnode.sh`**: VM startup script that:
  - Updates system packages
  - Installs Docker and Docker Compose
  - Downloads and installs DappNode
  - Configures firewall and system optimizations

- **`init-deployment.sh`**: Automated deployment initialization script

## Accessing DappNode After Deployment

### Get Deployment Information

```bash
cd terraform

# Get external IP
terraform output dappnode_external_ip

# Get SSH command
terraform output ssh_command

# Get all outputs
terraform output
```

### SSH to VM Instance

```bash
# Use the output SSH command
gcloud compute ssh dev-dappnode-server --zone=us-central1-a --project=blockchaindappnode

# Or use standard SSH with your key
ssh admin@<EXTERNAL_IP>
```

### Access DappNode Web Interface

1. Wait 5-10 minutes for DappNode installation to complete
2. Open browser and navigate to: `http://<EXTERNAL_IP>`
3. Follow DappNode setup wizard

### Monitor Installation Progress

```bash
# SSH to the VM first
gcloud compute ssh dev-dappnode-server --zone=us-central1-a --project=blockchaindappnode

# Check startup script logs
sudo journalctl -u google-startup-scripts.service -f

# Check Docker status
sudo systemctl status docker

# Check DappNode containers
sudo docker ps
```

## Customization

### Change VM Size

Edit `terraform.tfvars`:

```hcl
machine_type = "n1-standard-8"  # More CPU/RAM
disk_size_gb = 200              # Larger disk
```

Then apply changes:

```bash
terraform plan
terraform apply
```

### Restrict SSH Access

⚠️ **Security**: By default, SSH is open to all IPs (`0.0.0.0/0`). Restrict this in production:

Edit `terraform.tfvars`:

```hcl
ssh_source_ranges = ["YOUR_IP/32"]  # Replace with your public IP
```

### Add SSH Key

Edit `terraform.tfvars`:

```hcl
ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2E... your-email@example.com"
```

### Use Preemptible Instance (Cost Savings)

For non-production environments:

```hcl
preemptible = true
```

⚠️ Preemptible instances can be terminated by GCP at any time.

## Updating Infrastructure

To make changes to the infrastructure:

```bash
# 1. Edit configuration files
vim terraform.tfvars

# 2. Format code
terraform fmt -recursive

# 3. Validate
terraform validate

# 4. Plan changes
terraform plan

# 5. Apply changes
terraform apply
```

## Destroying Infrastructure

To remove all deployed resources:

```bash
cd terraform

# Review what will be destroyed
terraform plan -destroy

# Destroy infrastructure
terraform destroy
```

⚠️ This will permanently delete all resources including the VM and data.

## Troubleshooting

### Permission Issues

If you encounter permission errors:

```bash
# Ensure you're authenticated
gcloud auth login
gcloud auth application-default login

# Verify project access
gcloud projects describe blockchaindappnode
```

### Terraform State Issues

If state becomes locked:

```bash
# List locks
gsutil ls gs://blockchaindappnode-terraform-state/**

# Force unlock (use with caution)
terraform force-unlock LOCK_ID
```

### DappNode Installation Failed

```bash
# SSH to VM
gcloud compute ssh dev-dappnode-server --zone=us-central1-a --project=blockchaindappnode

# Check logs
sudo journalctl -u google-startup-scripts.service -n 100

# Re-run installation script manually
sudo bash /var/lib/cloud/instance/scripts/part-001
```

### VM Not Accessible

```bash
# Check VM status
gcloud compute instances describe dev-dappnode-server \
  --zone=us-central1-a \
  --project=blockchaindappnode

# Check firewall rules
gcloud compute firewall-rules list --project=blockchaindappnode

# Check serial port output
gcloud compute instances get-serial-port-output dev-dappnode-server \
  --zone=us-central1-a \
  --project=blockchaindappnode
```

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────┐
│  GCP Project: blockchaindappnode                        │
├─────────────────────────────────────────────────────────┤
│                                                           │
│  ┌───────────────────────────────────────────────────┐  │
│  │  VPC Network: dev-dappnode-network                │  │
│  │                                                     │  │
│  │  ┌─────────────────────────────────────────────┐  │  │
│  │  │  Subnet: dev-dappnode-subnet               │  │  │
│  │  │  CIDR: 10.0.1.0/24                         │  │  │
│  │  │                                             │  │  │
│  │  │  ┌─────────────────────────────────────┐   │  │  │
│  │  │  │  VM Instance                        │   │  │  │
│  │  │  │  dev-dappnode-server                │   │  │  │
│  │  │  │                                      │   │  │  │
│  │  │  │  - Debian 11                        │   │  │  │
│  │  │  │  - Docker + Docker Compose          │   │  │  │
│  │  │  │  - DappNode Stack                   │   │  │  │
│  │  │  │  - Static External IP               │   │  │  │
│  │  │  └─────────────────────────────────────┘   │  │  │
│  │  │                                             │  │  │
│  │  └─────────────────────────────────────────────┘  │  │
│  │                                                     │  │
│  │  Firewall Rules:                                   │  │
│  │  - allow-ssh (port 22)                            │  │
│  │  - allow-services (80, 443, 8080, 30303)         │  │
│  └───────────────────────────────────────────────────┘  │
│                                                           │
│  GCS Buckets:                                            │
│  - blockchaindappnode-terraform-state                   │
│  - blockchaindappnode-build-artifacts                   │
└─────────────────────────────────────────────────────────┘
```

## Security Best Practices

1. **Restrict SSH Access**: Limit `ssh_source_ranges` to specific IPs
2. **Use SSH Keys**: Always configure `ssh_public_key`
3. **Regular Updates**: Keep DappNode and system packages updated
4. **Firewall Rules**: Review and restrict port access as needed
5. **State Security**: GCS buckets are encrypted by default
6. **IAM Permissions**: Use least privilege principle

## Cost Estimation

Estimated monthly costs (us-central1 region):

- **n1-standard-4 VM**: ~$140/month
- **100 GB pd-standard disk**: ~$4/month
- **Static IP**: ~$7/month
- **Network egress**: Variable
- **Total**: ~$151/month (plus network costs)

Cost optimization:
- Use `preemptible = true` for ~80% cost reduction (non-production)
- Choose smaller machine type if workload permits
- Use regional resources to minimize costs

## Additional Resources

- [Terraform GCP Provider Documentation](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [DappNode Official Documentation](https://docs.dappnode.io/)
- [Google Cloud Compute Engine](https://cloud.google.com/compute/docs)
- [Terraform Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices/index.html)

## Support

For issues with:
- **Terraform Configuration**: Check this README and Terraform documentation
- **GCP Resources**: Use `gcloud` commands or GCP Console
- **DappNode**: Visit [DappNode Discourse](https://discourse.dappnode.io/)

## License

This configuration is part of the DappNode_Docker_IoB project.
