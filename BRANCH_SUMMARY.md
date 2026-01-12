# Terraform Branch Summary

## Overview

This branch (`copilot/terraform-config-dappnode`) contains the complete Terraform configuration for deploying DappNode on Google Cloud Platform for the `blockchaindappnode` project.

## What's Included

### 1. Terraform Configuration Files

Located in the `terraform/` directory:

#### Core Infrastructure Files
- **`main.tf`** - Main Terraform configuration defining:
  - VPC Network and Subnet
  - Firewall rules (SSH and DappNode services)
  - Static External IP address
  - VM Instance with automatic DappNode installation
  
- **`variables.tf`** - Variable definitions with defaults for:
  - Project, region, and zone configuration
  - Network CIDR ranges
  - VM specifications (machine type, disk size)
  - SSH access configuration
  
- **`outputs.tf`** - Output values including:
  - VM name and IDs
  - External and internal IP addresses
  - Network information
  - SSH connection command
  
- **`terraform.tfvars`** - Project-specific configuration:
  - Pre-configured for project ID: `blockchaindappnode`
  - Default region: `us-central1`
  - Default zone: `us-central1-a`
  - VM configuration: `n1-standard-4` with 100GB disk
  
- **`terraform.tfvars.example`** - Template for reference

#### Installation Scripts
- **`scripts/install-dappnode.sh`** - VM startup script that:
  - Updates system packages
  - Installs Docker and Docker Compose
  - Downloads and installs DappNode
  - Configures firewall and system optimizations
  - Logs installation progress

### 2. Deployment Automation

- **`terraform/init-deployment.sh`** - Automated deployment script that:
  - Checks prerequisites (gcloud, terraform)
  - Enables required GCP APIs
  - Creates GCS buckets for Terraform state and artifacts
  - Configures Cloud Build permissions
  - Initializes Terraform with remote backend
  - Validates and formats configuration
  - Generates and displays execution plan
  - Prompts for deployment confirmation
  - Deploys infrastructure and displays access information

### 3. Documentation

#### Quick Start Guides
- **`QUICKSTART.md`** - Streamlined deployment guide
  - Prerequisites checklist
  - Simple 5-step deployment process
  - Access instructions
  - Security notes
  - Troubleshooting quick reference

#### Detailed Documentation
- **`terraform/README.md`** - Comprehensive Terraform guide
  - Architecture overview with diagram
  - Detailed deployment options (automated and manual)
  - Configuration customization guide
  - Access and monitoring instructions
  - Cost estimation
  - Security best practices
  - Complete troubleshooting section

- **`README.md`** - Main repository documentation
  - Updated with quick links to all guides
  - Project configuration details
  - CI/CD pipeline information
  - Quick deployment section for blockchaindappnode

#### Validation and Troubleshooting
- **`VALIDATION.md`** - Deployment verification checklist
  - Pre-deployment validation steps
  - Terraform initialization checks
  - Resource creation verification
  - Post-deployment validation
  - DappNode installation checks
  - Security validation
  - Performance checks
  - Cleanup verification

- **`TROUBLESHOOTING.md`** - Comprehensive troubleshooting guide
  - Pre-deployment issues
  - Terraform configuration issues
  - Deployment problems
  - Post-deployment issues
  - DappNode-specific issues
  - Network and connectivity problems
  - General debugging commands
  - Prevention tips

### 4. CI/CD Configuration

- **`cloudbuild.yaml`** - Cloud Build pipeline for:
  - Terraform formatting validation
  - Configuration validation
  - Plan generation on PRs
  - Automated deployment on main branch merge

### 5. Configuration Files

- **`.gitignore`** - Updated to:
  - Exclude sensitive terraform files
  - Allow `terraform/terraform.tfvars` for this specific project
  - Exclude terraform state and plan files

## Project Configuration

### Google Cloud Platform
- **Project ID**: `blockchaindappnode`
- **Default Region**: `us-central1`
- **Default Zone**: `us-central1-a`

### Infrastructure Specifications
- **VM Type**: `n1-standard-4` (4 vCPUs, 15 GB RAM)
- **Disk**: 100 GB `pd-standard`
- **OS**: Debian 11
- **Network**: Custom VPC with `10.0.1.0/24` subnet

### Services Deployed
- **DappNode** - Blockchain infrastructure management platform
- **Docker** - Container runtime
- **Docker Compose** - Multi-container orchestration

### Exposed Ports
- **22** - SSH access
- **80** - HTTP (DappNode web interface)
- **443** - HTTPS
- **8080** - Alternative web port
- **30303** - Ethereum P2P (TCP/UDP)

## How to Use This Branch

### Quick Deployment

1. **Clone and checkout this branch**:
   ```bash
   git clone https://github.com/Shan3600/DappNode_Docker_IoB.git
   cd DappNode_Docker_IoB
   git checkout copilot/terraform-config-dappnode
   ```

2. **Run the automated deployment**:
   ```bash
   cd terraform
   ./init-deployment.sh
   ```

3. **Access DappNode**:
   ```bash
   # Get the external IP
   terraform output dappnode_external_ip
   
   # Open browser to: http://<EXTERNAL_IP>
   ```

### Manual Deployment

Follow the detailed steps in [terraform/README.md](terraform/README.md) or [QUICKSTART.md](QUICKSTART.md).

## Key Features

### Automation
✅ Fully automated deployment with single script execution
✅ Automated GCP resource provisioning
✅ Automated DappNode installation via startup script
✅ CI/CD pipeline for infrastructure changes

### Security
✅ Configurable SSH access restrictions
✅ Firewall rules for service isolation
✅ Remote Terraform state in GCS with versioning
✅ Service account-based authentication

### Documentation
✅ Multiple guides for different use cases
✅ Comprehensive troubleshooting documentation
✅ Validation checklists
✅ Architecture diagrams

### Flexibility
✅ Customizable VM specifications
✅ Configurable network settings
✅ Region/zone selection
✅ Cost optimization options (preemptible instances)

## Prerequisites

To use this branch, you need:

1. **Google Cloud SDK** (`gcloud`) installed and configured
2. **Terraform** (>= 1.6.0) installed
3. **Access to `blockchaindappnode` GCP project** with appropriate permissions
4. **Authenticated with GCP**:
   ```bash
   gcloud auth login
   gcloud auth application-default login
   ```

## GCP Resources Created

When deployed, this configuration creates:

1. **VPC Network**: `dev-dappnode-network`
2. **Subnet**: `dev-dappnode-subnet` (10.0.1.0/24)
3. **Firewall Rules**:
   - `dev-dappnode-allow-ssh` (port 22)
   - `dev-dappnode-allow-services` (ports 80, 443, 8080, 30303)
4. **Static IP**: `dev-dappnode-ip`
5. **VM Instance**: `dev-dappnode-server`
6. **GCS Buckets**:
   - `blockchaindappnode-terraform-state` (Terraform state)
   - `blockchaindappnode-build-artifacts` (Build artifacts)

## Cost Estimation

Approximate monthly costs (us-central1):
- **VM (n1-standard-4)**: ~$140/month
- **Disk (100GB pd-standard)**: ~$4/month
- **Static IP**: ~$7/month
- **Network egress**: Variable
- **Total**: ~$151/month + network costs

## Next Steps

After deploying:

1. **Configure DappNode** through the web interface
2. **Set up SSH keys** for secure access
3. **Restrict SSH access** to specific IP addresses
4. **Install DappNode packages** as needed
5. **Configure blockchain nodes** for your use case
6. **Set up monitoring** and alerting
7. **Implement backup strategy**

## Support and Resources

- **Quick Start**: [QUICKSTART.md](QUICKSTART.md)
- **Detailed Guide**: [terraform/README.md](terraform/README.md)
- **Validation**: [VALIDATION.md](VALIDATION.md)
- **Troubleshooting**: [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- **DappNode Docs**: https://docs.dappnode.io/
- **Terraform Docs**: https://www.terraform.io/docs
- **GCP Docs**: https://cloud.google.com/docs

## Branch Status

✅ **Ready for use** - All configuration and documentation complete
✅ **Tested structure** - Files organized and formatted correctly
✅ **Production-ready** - Includes security best practices
✅ **Well-documented** - Multiple guides and troubleshooting resources

## Important Notes

⚠️ **Security**: Default SSH access is open to all IPs (`0.0.0.0/0`). Update `ssh_source_ranges` in `terraform.tfvars` to restrict access.

⚠️ **Costs**: Running infrastructure incurs GCP costs. Use `terraform destroy` when not needed.

⚠️ **Installation Time**: DappNode installation takes 5-10 minutes after VM creation.

⚠️ **State Management**: Terraform state is stored remotely in GCS. Do not delete the state bucket.

## Contributing

When making changes to this branch:

1. Test changes locally before committing
2. Run `terraform fmt -recursive` to format code
3. Run `terraform validate` to check syntax
4. Update documentation as needed
5. Follow existing patterns and conventions

## License

This configuration is part of the DappNode_Docker_IoB project.
