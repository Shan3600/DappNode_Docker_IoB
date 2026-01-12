# Quick Start Guide - DappNode Terraform Deployment

This guide provides a streamlined process to deploy DappNode on Google Cloud Platform using Terraform.

## Prerequisites

- Google Cloud SDK (`gcloud`) installed and configured
- Terraform >= 1.6.0 installed
- Access to the `blockchaindappnode` GCP project

## Deployment Steps

### 1. Authenticate with Google Cloud

```bash
gcloud auth login
gcloud auth application-default login
gcloud config set project blockchaindappnode
```

### 2. Navigate to Terraform Directory

```bash
cd terraform
```

### 3. Run Automated Deployment

```bash
./init-deployment.sh
```

This script will:
- ✅ Enable required GCP APIs (Compute Engine, Cloud Build, Cloud Storage)
- ✅ Create GCS buckets for Terraform state and build artifacts
- ✅ Configure Cloud Build service account permissions
- ✅ Initialize Terraform with remote state backend
- ✅ Validate and format Terraform configuration
- ✅ Generate and display execution plan
- ✅ Prompt for deployment confirmation
- ✅ Deploy DappNode infrastructure on GCP

### 4. Access DappNode

After deployment completes (5-10 minutes for full installation):

```bash
# Get the external IP address
cd terraform
terraform output dappnode_external_ip

# SSH to the VM
terraform output ssh_command

# Access DappNode Web UI
# Open browser to: http://<EXTERNAL_IP>
```

### 5. Monitor Installation

```bash
# SSH to the VM
gcloud compute ssh dev-dappnode-server --zone=us-central1-a --project=blockchaindappnode

# Check startup script logs
sudo journalctl -u google-startup-scripts.service -f

# Check Docker containers
sudo docker ps
```

## Configuration

The deployment is pre-configured with:
- **Project ID**: `blockchaindappnode`
- **Region**: `us-central1`
- **Zone**: `us-central1-a`
- **VM Type**: `n1-standard-4` (4 vCPUs, 15 GB RAM)
- **Disk**: 100 GB SSD
- **OS**: Debian 11

To customize the configuration, edit `terraform/terraform.tfvars` before running the deployment script.

## Important Notes

### Security
⚠️ **Default SSH access is open to all IPs (`0.0.0.0/0`)**. For production use, restrict this:

Edit `terraform/terraform.tfvars`:
```hcl
ssh_source_ranges = ["YOUR_PUBLIC_IP/32"]
```

### SSH Keys
To add your SSH public key for access:

Edit `terraform/terraform.tfvars`:
```hcl
ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2E... your-email@example.com"
```

## Troubleshooting

### Permission Denied

Ensure you have proper GCP project permissions:
```bash
gcloud projects get-iam-policy blockchaindappnode
```

### API Not Enabled

Manually enable required APIs:
```bash
gcloud services enable compute.googleapis.com cloudbuild.googleapis.com storage.googleapis.com --project=blockchaindappnode
```

### DappNode Not Responding

The installation takes 5-10 minutes. Check status:
```bash
gcloud compute ssh dev-dappnode-server --zone=us-central1-a --project=blockchaindappnode
sudo journalctl -u google-startup-scripts.service -n 100
```

## Manual Deployment Alternative

If you prefer manual control, see the detailed guide in `terraform/README.md`.

## Cleanup

To destroy all deployed resources:
```bash
cd terraform
terraform destroy
```

⚠️ This permanently deletes all resources including the VM and data.

## Next Steps

1. Configure DappNode through the web interface
2. Set up monitoring and backups
3. Install DappNode packages and services
4. Configure blockchain nodes

## Additional Documentation

- **Detailed Terraform Guide**: `terraform/README.md`
- **Repository Setup Guide**: `SETUP.md`
- **Main README**: `README.md`

## Support

- DappNode Documentation: https://docs.dappnode.io/
- Terraform GCP Provider: https://registry.terraform.io/providers/hashicorp/google/latest/docs
- GCP Compute Engine: https://cloud.google.com/compute/docs
