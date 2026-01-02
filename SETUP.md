# Quick Setup Guide

This guide will help you set up the CI/CD pipeline for DappNode infrastructure deployment.

## Prerequisites

- GCP Project with billing enabled
- GitHub repository access
- `gcloud` CLI installed and configured

## Step 1: Set Environment Variables

```bash
export PROJECT_ID="your-gcp-project-id"
export REGION="us-central1"
export GITHUB_OWNER="Shan3600"
export GITHUB_REPO="DappNode_Docker_IoB"
```

## Step 2: Enable Required APIs

```bash
gcloud services enable compute.googleapis.com \
  cloudbuild.googleapis.com \
  storage.googleapis.com \
  --project=${PROJECT_ID}
```

## Step 3: Create GCS Buckets

```bash
# Terraform state bucket
gsutil mb -p ${PROJECT_ID} -l ${REGION} gs://${PROJECT_ID}-terraform-state
gsutil versioning set on gs://${PROJECT_ID}-terraform-state

# Build artifacts bucket
gsutil mb -p ${PROJECT_ID} -l ${REGION} gs://${PROJECT_ID}-build-artifacts
```

## Step 4: Grant Cloud Build Permissions

```bash
# Get Cloud Build service account
PROJECT_NUMBER=$(gcloud projects describe ${PROJECT_ID} --format='value(projectNumber)')
CLOUDBUILD_SA="${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com"

# Grant necessary roles
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${CLOUDBUILD_SA}" \
  --role="roles/compute.admin"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${CLOUDBUILD_SA}" \
  --role="roles/iam.serviceAccountUser"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${CLOUDBUILD_SA}" \
  --role="roles/storage.admin"
```

## Step 5: Connect GitHub Repository to Cloud Build

### Option A: Using Cloud Console
1. Go to https://console.cloud.google.com/cloud-build/triggers
2. Click "Connect Repository"
3. Select "GitHub (Cloud Build GitHub App)"
4. Authenticate and select your repository
5. Click "Connect"

### Option B: Using gcloud CLI
```bash
# This requires manual authentication
gcloud builds triggers create github \
  --repo-name=${GITHUB_REPO} \
  --repo-owner=${GITHUB_OWNER} \
  --branch-pattern="^main$" \
  --build-config=cloudbuild.yaml
```

## Step 6: Create Cloud Build Triggers

### PR Validation Trigger
```bash
gcloud builds triggers create github \
  --name="terraform-pr-validation" \
  --repo-name=${GITHUB_REPO} \
  --repo-owner=${GITHUB_OWNER} \
  --pull-request-pattern="^main$" \
  --build-config=cloudbuild.yaml \
  --included-files="terraform/**,cloudbuild.yaml" \
  --substitutions=_TERRAFORM_VERSION="1.6.6",_TERRAFORM_ROOT="terraform" \
  --description="Validates Terraform configuration on pull requests"
```

### Main Branch Deployment Trigger
```bash
gcloud builds triggers create github \
  --name="terraform-deploy-main" \
  --repo-name=${GITHUB_REPO} \
  --repo-owner=${GITHUB_OWNER} \
  --branch-pattern="^main$" \
  --build-config=cloudbuild.yaml \
  --included-files="terraform/**,cloudbuild.yaml" \
  --substitutions=_TERRAFORM_VERSION="1.6.6",_TERRAFORM_ROOT="terraform" \
  --description="Deploys Terraform infrastructure when merged to main"
```

## Step 7: Configure Terraform Variables

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your configuration
nano terraform.tfvars
```

Update the following required variables:
- `project_id`: Your GCP project ID
- `region`: Your preferred region
- `zone`: Your preferred zone
- `ssh_public_key`: Your SSH public key

## Step 8: Configure GitHub Branch Protection

1. Go to your GitHub repository settings
2. Navigate to "Branches" → "Branch protection rules"
3. Click "Add rule"
4. Branch name pattern: `main`
5. Enable:
   - ✅ Require status checks to pass before merging
   - ✅ Require branches to be up to date before merging
   - Select: `terraform-pr-validation`
   - ✅ Require pull request reviews before merging (optional)
6. Click "Create"

## Step 9: Test the Pipeline

### Create a Test Branch
```bash
git checkout -b test/pipeline
```

### Make a Small Change
```bash
# Edit a terraform file or add a comment
echo "# Test pipeline" >> terraform/README.md
git add .
git commit -m "test: Verify CI/CD pipeline"
git push origin test/pipeline
```

### Create a Pull Request
1. Go to GitHub and create a PR from `test/pipeline` to `main`
2. Cloud Build should automatically trigger
3. Check the build status in the PR
4. Review the Terraform plan output

### Merge to Deploy
1. If the plan looks good, merge the PR
2. Cloud Build will run again and apply changes
3. Check Cloud Build console for deployment status

## Step 10: Verify Deployment

After merging, check the VM instance:

```bash
# List compute instances
gcloud compute instances list --project=${PROJECT_ID}

# Get instance details
gcloud compute instances describe INSTANCE-NAME --zone=ZONE --project=${PROJECT_ID}

# SSH to the instance
gcloud compute ssh INSTANCE-NAME --zone=ZONE --project=${PROJECT_ID}
```

## Troubleshooting

### Build Fails with Permission Denied
- Verify Cloud Build service account has necessary permissions
- Check that API services are enabled

### Terraform State Not Found
- Verify GCS bucket exists: `gsutil ls gs://${PROJECT_ID}-terraform-state`
- Check bucket permissions

### GitHub Trigger Not Working
- Verify GitHub App is installed and connected
- Check trigger configuration in Cloud Build console
- Ensure repository access is granted

### VM Instance Not Created
- Check Cloud Build logs for errors
- Verify project quotas aren't exceeded
- Check Terraform plan output for issues

## Next Steps

1. Configure custom variables in `terraform.tfvars`
2. Adjust VM machine type and disk size as needed
3. Restrict SSH access to your IP range
4. Set up monitoring and alerting
5. Configure backup strategies

## Clean Up

To remove all resources:

```bash
# Manual cleanup via Terraform
cd terraform
terraform destroy

# Or via Cloud Console
# Delete the VM instance and associated resources
```

## Support Resources

- [Terraform GCP Provider Documentation](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [Cloud Build Documentation](https://cloud.google.com/build/docs)
- [DappNode Documentation](https://docs.dappnode.io/)
