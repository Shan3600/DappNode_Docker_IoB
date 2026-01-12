#!/bin/bash
#
# DappNode Terraform Deployment Initialization Script
# This script initializes and deploys the DappNode infrastructure on Google Cloud Platform
#

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PROJECT_ID="blockchaindappnode"
REGION="us-central1"
TERRAFORM_STATE_BUCKET="${PROJECT_ID}-terraform-state"
BUILD_ARTIFACTS_BUCKET="${PROJECT_ID}-build-artifacts"

echo "=========================================="
echo "DappNode Terraform Deployment Initialization"
echo "=========================================="
echo ""
echo "Project ID: ${PROJECT_ID}"
echo "Region: ${REGION}"
echo ""

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"

if ! command_exists gcloud; then
    echo -e "${RED}Error: gcloud CLI is not installed${NC}"
    echo "Please install gcloud CLI: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

if ! command_exists terraform; then
    echo -e "${RED}Error: Terraform is not installed${NC}"
    echo "Please install Terraform: https://www.terraform.io/downloads"
    exit 1
fi

echo -e "${GREEN}✓ Prerequisites checked${NC}"
echo ""

# Set GCP project
echo -e "${YELLOW}Setting GCP project...${NC}"
gcloud config set project ${PROJECT_ID}
echo -e "${GREEN}✓ GCP project set${NC}"
echo ""

# Enable required APIs
echo -e "${YELLOW}Enabling required GCP APIs...${NC}"
echo "This may take a few minutes..."
gcloud services enable compute.googleapis.com --project=${PROJECT_ID} || true
gcloud services enable cloudbuild.googleapis.com --project=${PROJECT_ID} || true
gcloud services enable storage.googleapis.com --project=${PROJECT_ID} || true
echo -e "${GREEN}✓ Required APIs enabled${NC}"
echo ""

# Create GCS bucket for Terraform state
echo -e "${YELLOW}Creating GCS bucket for Terraform state...${NC}"
if gsutil ls -b gs://${TERRAFORM_STATE_BUCKET} >/dev/null 2>&1; then
    echo "Bucket ${TERRAFORM_STATE_BUCKET} already exists"
else
    gsutil mb -p ${PROJECT_ID} -l ${REGION} gs://${TERRAFORM_STATE_BUCKET}
    gsutil versioning set on gs://${TERRAFORM_STATE_BUCKET}
    echo -e "${GREEN}✓ Terraform state bucket created${NC}"
fi
echo ""

# Create GCS bucket for build artifacts
echo -e "${YELLOW}Creating GCS bucket for build artifacts...${NC}"
if gsutil ls -b gs://${BUILD_ARTIFACTS_BUCKET} >/dev/null 2>&1; then
    echo "Bucket ${BUILD_ARTIFACTS_BUCKET} already exists"
else
    gsutil mb -p ${PROJECT_ID} -l ${REGION} gs://${BUILD_ARTIFACTS_BUCKET}
    echo -e "${GREEN}✓ Build artifacts bucket created${NC}"
fi
echo ""

# Grant Cloud Build permissions
echo -e "${YELLOW}Configuring Cloud Build permissions...${NC}"
PROJECT_NUMBER=$(gcloud projects describe ${PROJECT_ID} --format='value(projectNumber)')
CLOUDBUILD_SA="${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${CLOUDBUILD_SA}" \
  --role="roles/compute.admin" \
  --condition=None >/dev/null 2>&1 || true

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${CLOUDBUILD_SA}" \
  --role="roles/iam.serviceAccountUser" \
  --condition=None >/dev/null 2>&1 || true

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${CLOUDBUILD_SA}" \
  --role="roles/storage.admin" \
  --condition=None >/dev/null 2>&1 || true

echo -e "${GREEN}✓ Cloud Build permissions configured${NC}"
echo ""

# Initialize Terraform
echo -e "${YELLOW}Initializing Terraform...${NC}"
cd "$(dirname "$0")"
terraform init -backend-config="bucket=${TERRAFORM_STATE_BUCKET}"
echo -e "${GREEN}✓ Terraform initialized${NC}"
echo ""

# Validate Terraform configuration
echo -e "${YELLOW}Validating Terraform configuration...${NC}"
terraform validate
echo -e "${GREEN}✓ Terraform configuration is valid${NC}"
echo ""

# Format Terraform files
echo -e "${YELLOW}Formatting Terraform files...${NC}"
terraform fmt -recursive
echo -e "${GREEN}✓ Terraform files formatted${NC}"
echo ""

# Generate Terraform plan
echo -e "${YELLOW}Generating Terraform plan...${NC}"
terraform plan -out=tfplan
echo -e "${GREEN}✓ Terraform plan generated${NC}"
echo ""

# Prompt for deployment
echo "=========================================="
echo -e "${YELLOW}Ready to deploy DappNode infrastructure${NC}"
echo "=========================================="
echo ""
echo "This will create the following resources:"
echo "  - VPC Network and Subnet"
echo "  - Firewall Rules (SSH and DappNode services)"
echo "  - Static External IP"
echo "  - VM Instance with DappNode installed"
echo ""
read -p "Do you want to apply the Terraform plan? (yes/no): " CONFIRM

if [ "$CONFIRM" = "yes" ]; then
    echo ""
    echo -e "${YELLOW}Applying Terraform plan...${NC}"
    terraform apply tfplan
    echo ""
    echo -e "${GREEN}=========================================="
    echo "DappNode Infrastructure Deployed Successfully!"
    echo "==========================================${NC}"
    echo ""
    echo "Getting deployment information..."
    EXTERNAL_IP=$(terraform output -raw dappnode_external_ip 2>/dev/null || echo "N/A")
    VM_NAME=$(terraform output -raw dappnode_vm_name 2>/dev/null || echo "N/A")
    SSH_COMMAND=$(terraform output -raw ssh_command 2>/dev/null || echo "N/A")
    
    echo ""
    echo "VM Instance: ${VM_NAME}"
    echo "External IP: ${EXTERNAL_IP}"
    echo ""
    echo "SSH Command:"
    echo "  ${SSH_COMMAND}"
    echo ""
    echo "DappNode will be accessible at:"
    echo "  http://${EXTERNAL_IP}"
    echo ""
    echo "Note: DappNode installation may take 5-10 minutes to complete."
    echo "Check installation status with:"
    echo "  ${SSH_COMMAND}"
    echo "  sudo journalctl -u google-startup-scripts.service -f"
    echo ""
else
    echo ""
    echo -e "${YELLOW}Deployment cancelled. You can apply the plan later with:${NC}"
    echo "  terraform apply tfplan"
    echo ""
fi

echo "=========================================="
echo "Setup complete!"
echo "=========================================="
