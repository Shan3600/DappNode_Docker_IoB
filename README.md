# DappNode Infrastructure CI/CD Pipeline

This repository contains the infrastructure-as-code for deploying DappNode servers on Google Cloud Platform (GCP) using Terraform, with automated CI/CD via Google Cloud Build.

## Quick Links

- 🚀 **[Quick Start Guide](QUICKSTART.md)** - Get started in minutes
- 📖 **[Terraform Documentation](terraform/README.md)** - Detailed deployment guide
- ✅ **[Validation Checklist](VALIDATION.md)** - Verify your deployment
- 🔧 **[Troubleshooting Guide](TROUBLESHOOTING.md)** - Common issues and solutions
- 📋 **[Setup Instructions](SETUP.md)** - Initial repository setup

## Overview

**Project Configuration:**
- **GCP Project ID**: `blockchaindappnode`
- **Default Region**: `us-central1`
- **Default Zone**: `us-central1-a`

The CI/CD pipeline automates the deployment of DappNode infrastructure with the following features:

- **Automated Terraform validation** on pull requests
- **Terraform planning** to preview infrastructure changes
- **Automated deployment** when code is merged to the main branch
- **Built-in safety checks** to prevent merging if Terraform plan fails

## Architecture

### Infrastructure Components

- **VPC Network**: Isolated network for DappNode infrastructure
- **Subnet**: Private subnet for VM instances
- **Firewall Rules**: Security rules for SSH and DappNode services
- **Static IP**: External IP address for DappNode server
- **VM Instance**: Debian-based virtual machine running DappNode

### CI/CD Pipeline

The pipeline is defined in `cloudbuild.yaml` and executes the following steps:

#### On Pull Request (PR):
1. **Terraform Format Check** - Validates code formatting
2. **Terraform Init** - Initializes Terraform working directory
3. **Terraform Validate** - Validates configuration syntax
4. **Terraform Plan** - Generates execution plan
5. **Plan Output** - Saves plan for review

#### On Merge to Main Branch:
1. All steps from PR workflow
2. **Terraform Apply** - Applies changes to infrastructure (auto-approved)

## Prerequisites

### GCP Setup

1. **GCP Project**: Create or have access to a GCP project
2. **APIs**: Enable the following APIs:
   - Compute Engine API
   - Cloud Build API
   - Cloud Storage API

3. **Service Account**: Cloud Build service account needs permissions:
   - `roles/compute.admin` - For managing Compute Engine resources
   - `roles/iam.serviceAccountUser` - For using service accounts
   - `roles/storage.admin` - For managing Terraform state

4. **GCS Bucket**: Create a bucket for Terraform state:
   ```bash
   gsutil mb gs://YOUR-PROJECT-ID-terraform-state
   gsutil versioning set on gs://YOUR-PROJECT-ID-terraform-state
   ```

5. **Artifacts Bucket**: Create a bucket for build artifacts:
   ```bash
   gsutil mb gs://YOUR-PROJECT-ID-build-artifacts
   ```

### Cloud Build Triggers

Set up two Cloud Build triggers:

#### Trigger 1: Pull Request Validation
- **Name**: `terraform-pr-validation`
- **Event**: Pull request (against main branch)
- **Source**: Connect to this GitHub repository
- **Configuration**: Cloud Build configuration file (`cloudbuild.yaml`)
- **Included files filter**: `terraform/**` (optional)

#### Trigger 2: Main Branch Deployment
- **Name**: `terraform-deploy-main`
- **Event**: Push to branch `^main$`
- **Source**: Connect to this GitHub repository
- **Configuration**: Cloud Build configuration file (`cloudbuild.yaml`)
- **Included files filter**: `terraform/**` (optional)

### Configure PR Merge Requirements

To prevent PRs from being merged if Terraform plan fails:

1. Go to GitHub repository settings
2. Navigate to **Branches** → **Branch protection rules**
3. Add rule for `main` branch:
   - ✅ Require status checks to pass before merging
   - ✅ Require branches to be up to date before merging
   - Select: `terraform-pr-validation` (Cloud Build check)
   - ✅ Do not allow bypassing the above settings

## Quick Deployment

For the `blockchaindappnode` project, you can deploy quickly using the automated script:

```bash
# Clone the repository
git clone https://github.com/Shan3600/DappNode_Docker_IoB.git
cd DappNode_Docker_IoB

# Checkout the terraform configuration branch
git checkout copilot/terraform-config-dappnode

# Run the automated deployment
cd terraform
./init-deployment.sh
```

The script will:
1. ✅ Check prerequisites (gcloud, terraform)
2. ✅ Enable required GCP APIs
3. ✅ Create GCS buckets for Terraform state
4. ✅ Configure Cloud Build permissions
5. ✅ Initialize and validate Terraform
6. ✅ Generate execution plan
7. ✅ Prompt for deployment confirmation

For detailed steps, see the **[Quick Start Guide](QUICKSTART.md)**.

## Configuration

### Terraform Variables

The repository is pre-configured for the `blockchaindappnode` project with a `terraform.tfvars` file.

To customize the configuration, edit `terraform/terraform.tfvars`:

```hcl
project_id = "blockchaindappnode"  # Pre-configured
region     = "us-central1"
zone       = "us-central1-a"
environment = "dev"

# Network configuration
subnet_cidr = "10.0.1.0/24"

# VM configuration
machine_type  = "n1-standard-4"
disk_size_gb  = 100
disk_type     = "pd-standard"

# SSH configuration
ssh_source_ranges = ["YOUR-IP/32"]  # Update to your public IP for security
ssh_user          = "admin"
ssh_public_key    = "ssh-rsa AAAAB3... your-email@example.com"  # Add your SSH key
```

⚠️ **Security Note**: The `terraform.tfvars` file is committed to this branch for the specific `blockchaindappnode` project. Always restrict `ssh_source_ranges` to your IP address.

## Usage

### Local Development

#### Initialize Terraform
```bash
cd terraform
terraform init -backend-config="bucket=blockchaindappnode-terraform-state"
```

#### Format Code
```bash
terraform fmt -recursive
```

#### Validate Configuration
```bash
terraform validate
```

#### Plan Changes
```bash
terraform plan
```

#### Apply Changes (manual)
```bash
terraform apply
```

### CI/CD Workflow

#### Making Infrastructure Changes

1. **Create a feature branch**:
   ```bash
   git checkout -b feature/your-change
   ```

2. **Make changes** to Terraform files in the `terraform/` directory

3. **Commit and push**:
   ```bash
   git add .
   git commit -m "Description of changes"
   git push origin feature/your-change
   ```

4. **Create a Pull Request** on GitHub

5. **Cloud Build automatically**:
   - Runs `terraform fmt -check`
   - Initializes Terraform
   - Validates configuration
   - Generates plan
   - Saves plan output as artifact

6. **Review the plan**:
   - Check Cloud Build logs for plan output
   - Download plan artifact from GCS if needed
   - Review changes carefully

7. **Merge PR** (if plan succeeds):
   - Cloud Build runs again on merge
   - Applies changes automatically
   - Infrastructure is updated

#### Viewing Build Status

- **GitHub**: Check the build status in the PR
- **Cloud Build Console**: `https://console.cloud.google.com/cloud-build/builds`
- **gcloud CLI**:
  ```bash
  gcloud builds list --limit=5
  ```

#### Viewing Plan Output

Plans are saved to: `gs://YOUR-PROJECT-ID-build-artifacts/terraform-plans/BUILD-ID/`

Download a plan:
```bash
gsutil cp gs://YOUR-PROJECT-ID-build-artifacts/terraform-plans/BUILD-ID/plan-output.txt .
```

## DappNode Installation

The VM instance is automatically configured with DappNode using the startup script located at `terraform/scripts/install-dappnode.sh`.

The script:
- Updates system packages
- Installs Docker and Docker Compose
- Downloads and installs DappNode
- Configures firewall rules
- Applies system optimizations

### Accessing DappNode

After deployment (allow 5-10 minutes for installation):

1. **Get the external IP**:
   ```bash
   terraform output dappnode_external_ip
   ```

2. **SSH to the VM**:
   ```bash
   terraform output ssh_command
   # Or
   gcloud compute ssh INSTANCE-NAME --zone=ZONE
   ```

3. **Access DappNode Web UI**:
   - Navigate to: `http://EXTERNAL-IP`
   - Follow DappNode setup instructions

## Troubleshooting

### Build Failures

1. **Check Cloud Build logs**:
   ```bash
   gcloud builds list --limit=5
   gcloud builds log BUILD-ID
   ```

2. **Common issues**:
   - Missing GCP permissions
   - Terraform state bucket not found
   - Invalid configuration syntax
   - Resource quota exceeded

### Terraform State Issues

If state becomes corrupted or locked:

```bash
# Remove lock (if stuck)
gsutil rm gs://YOUR-PROJECT-ID-terraform-state/terraform/state/default.tflock

# Backup state
gsutil cp gs://YOUR-PROJECT-ID-terraform-state/terraform/state/default.tfstate ./backup.tfstate
```

### DappNode Installation Issues

SSH to the VM and check:

```bash
# Check Docker status
sudo systemctl status docker

# Check DappNode containers
sudo docker ps

# View installation logs
sudo journalctl -u google-startup-scripts.service
```

## Security Best Practices

1. **Restrict SSH access**: Update `ssh_source_ranges` to your specific IP
2. **Use service accounts**: Don't use personal credentials
3. **Enable VPC flow logs**: For network monitoring
4. **Regular updates**: Keep Terraform and providers updated
5. **State encryption**: GCS buckets encrypt data by default
6. **Secrets management**: Use Google Secret Manager for sensitive data

## Cost Optimization

- Use `preemptible = true` for non-production environments
- Choose appropriate machine types
- Use `pd-standard` disks for development
- Delete resources when not in use:
  ```bash
  terraform destroy
  ```

## Project Structure

```
.
├── cloudbuild.yaml                 # Cloud Build pipeline configuration
├── terraform/
│   ├── main.tf                     # Main Terraform configuration
│   ├── variables.tf                # Variable definitions
│   ├── outputs.tf                  # Output definitions
│   ├── terraform.tfvars.example    # Example variables file
│   └── scripts/
│       └── install-dappnode.sh     # DappNode installation script
├── .gitignore                      # Git ignore patterns
└── README.md                       # This file
```

## Support

For issues related to:
- **Terraform**: Check [Terraform documentation](https://www.terraform.io/docs)
- **Cloud Build**: Check [Cloud Build documentation](https://cloud.google.com/build/docs)
- **DappNode**: Check [DappNode documentation](https://docs.dappnode.io/)

## License

This project is licensed under the terms included in the repository.
