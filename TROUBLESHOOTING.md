# Troubleshooting Guide

Common issues and solutions for DappNode Terraform deployment on Google Cloud Platform.

## Table of Contents
- [Pre-Deployment Issues](#pre-deployment-issues)
- [Terraform Issues](#terraform-issues)
- [Deployment Issues](#deployment-issues)
- [Post-Deployment Issues](#post-deployment-issues)
- [DappNode Specific Issues](#dappnode-specific-issues)
- [Network and Connectivity Issues](#network-and-connectivity-issues)

## Pre-Deployment Issues

### Issue: `gcloud` command not found

**Symptoms:**
```bash
bash: gcloud: command not found
```

**Solution:**
Install Google Cloud SDK:
```bash
# For Linux/macOS
curl https://sdk.cloud.google.com | bash
exec -l $SHELL

# For specific OS instructions
# Visit: https://cloud.google.com/sdk/docs/install
```

### Issue: Not authenticated with Google Cloud

**Symptoms:**
```
ERROR: (gcloud.compute.instances.list) You do not currently have an active account selected.
```

**Solution:**
```bash
gcloud auth login
gcloud auth application-default login
gcloud config set project blockchaindappnode
```

### Issue: Insufficient permissions

**Symptoms:**
```
ERROR: (gcloud.compute.xxx) The user does not have permission to access project
```

**Solution:**
1. Verify project access:
   ```bash
   gcloud projects get-iam-policy blockchaindappnode
   ```
2. Contact project owner to grant necessary roles:
   - `roles/compute.admin`
   - `roles/storage.admin`
   - `roles/iam.serviceAccountUser`

### Issue: Terraform not installed

**Symptoms:**
```bash
bash: terraform: command not found
```

**Solution:**
Install Terraform:
```bash
# For Linux (amd64)
wget https://releases.hashicorp.com/terraform/1.6.6/terraform_1.6.6_linux_amd64.zip
unzip terraform_1.6.6_linux_amd64.zip
sudo mv terraform /usr/local/bin/
terraform --version

# For macOS
brew install terraform

# For Windows
# Download from: https://www.terraform.io/downloads
```

## Terraform Issues

### Issue: Backend bucket does not exist

**Symptoms:**
```
Error: Failed to get existing workspaces: querying Cloud Storage failed: storage: bucket doesn't exist
```

**Solution:**
Create the backend bucket:
```bash
gsutil mb -p blockchaindappnode -l us-central1 gs://blockchaindappnode-terraform-state
gsutil versioning set on gs://blockchaindappnode-terraform-state
```

### Issue: Terraform state is locked

**Symptoms:**
```
Error: Error acquiring the state lock
Lock Info:
  ID:        xxx
  Path:      xxx
```

**Solution:**
1. Check if another Terraform process is running
2. If stuck, force unlock (use with caution):
   ```bash
   terraform force-unlock LOCK_ID
   ```
3. Or manually remove lock file:
   ```bash
   gsutil rm gs://blockchaindappnode-terraform-state/terraform/state/default.tflock
   ```

### Issue: Terraform validation fails

**Symptoms:**
```
Error: Invalid reference
Error: Unsupported argument
```

**Solution:**
1. Check syntax in `.tf` files
2. Ensure all required variables are defined
3. Verify Terraform version compatibility:
   ```bash
   terraform --version
   # Should be >= 1.6.0
   ```

### Issue: Terraform plan fails with quota exceeded

**Symptoms:**
```
Error: Error waiting for instance to create: Quota 'CPUS' exceeded
```

**Solution:**
1. Check current quotas:
   ```bash
   gcloud compute project-info describe --project=blockchaindappnode
   ```
2. Request quota increase:
   - Visit: https://console.cloud.google.com/iam-admin/quotas
   - Filter by region and metric
   - Select and request increase

### Issue: Variables not being read from terraform.tfvars

**Symptoms:**
```
Error: No value for required variable
```

**Solution:**
1. Ensure `terraform.tfvars` is in the terraform directory
2. Verify file name (must be exactly `terraform.tfvars`)
3. Check variable syntax in the file
4. Explicitly specify the file:
   ```bash
   terraform plan -var-file="terraform.tfvars"
   ```

## Deployment Issues

### Issue: API not enabled

**Symptoms:**
```
Error: Error creating instance: googleapi: Error 403: Access Not Configured. Compute Engine API has not been used
```

**Solution:**
Enable required APIs:
```bash
gcloud services enable compute.googleapis.com \
  cloudbuild.googleapis.com \
  storage.googleapis.com \
  --project=blockchaindappnode
```

### Issue: VM creation fails due to insufficient resources

**Symptoms:**
```
Error: Error waiting for instance to create: The zone 'projects/xxx/zones/us-central1-a' does not have enough resources
```

**Solution:**
1. Try a different zone:
   ```hcl
   # Edit terraform.tfvars
   zone = "us-central1-b"  # or us-central1-c
   ```
2. Or try a different region:
   ```hcl
   region = "us-east1"
   zone   = "us-east1-b"
   ```

### Issue: Firewall rule creation fails

**Symptoms:**
```
Error: Error creating firewall: googleapi: Error 409: The resource already exists
```

**Solution:**
1. Check existing firewall rules:
   ```bash
   gcloud compute firewall-rules list --project=blockchaindappnode
   ```
2. Delete conflicting rule:
   ```bash
   gcloud compute firewall-rules delete RULE_NAME --project=blockchaindappnode
   ```
3. Or import existing rule into Terraform state:
   ```bash
   terraform import google_compute_firewall.allow_ssh projects/blockchaindappnode/global/firewalls/RULE_NAME
   ```

### Issue: Static IP already in use

**Symptoms:**
```
Error: Error creating address: googleapi: Error 409: The resource already exists
```

**Solution:**
1. List existing addresses:
   ```bash
   gcloud compute addresses list --project=blockchaindappnode
   ```
2. Delete unused address:
   ```bash
   gcloud compute addresses delete ADDRESS_NAME --region=us-central1 --project=blockchaindappnode
   ```

## Post-Deployment Issues

### Issue: Cannot SSH to VM

**Symptoms:**
```
ssh: connect to host X.X.X.X port 22: Connection refused
```

**Solution:**
1. Verify VM is running:
   ```bash
   gcloud compute instances list --project=blockchaindappnode
   ```
2. Check firewall rules:
   ```bash
   gcloud compute firewall-rules describe dev-dappnode-allow-ssh --project=blockchaindappnode
   ```
3. Verify your IP is allowed:
   ```bash
   curl ifconfig.me  # Get your public IP
   # Compare with ssh_source_ranges in terraform.tfvars
   ```
4. Use gcloud SSH (bypasses SSH keys):
   ```bash
   gcloud compute ssh dev-dappnode-server --zone=us-central1-a --project=blockchaindappnode
   ```

### Issue: SSH key not working

**Symptoms:**
```
Permission denied (publickey)
```

**Solution:**
1. Verify SSH key format in terraform.tfvars:
   ```hcl
   ssh_public_key = "ssh-rsa AAAAB3NzaC1... your-email@example.com"
   ```
2. Check metadata:
   ```bash
   gcloud compute instances describe dev-dappnode-server \
     --zone=us-central1-a \
     --project=blockchaindappnode \
     --format="value(metadata.items[ssh-keys])"
   ```
3. Add key manually:
   ```bash
   gcloud compute instances add-metadata dev-dappnode-server \
     --zone=us-central1-a \
     --project=blockchaindappnode \
     --metadata ssh-keys="admin:$(cat ~/.ssh/id_rsa.pub)"
   ```

### Issue: External IP not accessible

**Symptoms:**
- Cannot access DappNode web interface
- Ping fails to external IP

**Solution:**
1. Get the external IP:
   ```bash
   terraform output dappnode_external_ip
   ```
2. Verify IP is attached:
   ```bash
   gcloud compute instances describe dev-dappnode-server \
     --zone=us-central1-a \
     --project=blockchaindappnode \
     --format="value(networkInterfaces[0].accessConfigs[0].natIP)"
   ```
3. Check firewall for your service:
   ```bash
   gcloud compute firewall-rules list --project=blockchaindappnode | grep dappnode
   ```

## DappNode Specific Issues

### Issue: DappNode installation script failed

**Symptoms:**
- Web interface not accessible
- Docker containers not running

**Solution:**
1. Check startup script logs:
   ```bash
   gcloud compute ssh dev-dappnode-server --zone=us-central1-a --project=blockchaindappnode
   sudo journalctl -u google-startup-scripts.service -n 100
   ```
2. Check for errors in the logs
3. Re-run installation script manually:
   ```bash
   sudo bash /var/lib/cloud/instance/scripts/part-001
   ```

### Issue: Docker not installed or not running

**Symptoms:**
```bash
docker: command not found
```
or
```
Cannot connect to the Docker daemon
```

**Solution:**
1. Check Docker status:
   ```bash
   sudo systemctl status docker
   ```
2. Start Docker:
   ```bash
   sudo systemctl start docker
   sudo systemctl enable docker
   ```
3. Re-install Docker if necessary:
   ```bash
   curl -fsSL https://get.docker.com -o get-docker.sh
   sudo sh get-docker.sh
   ```

### Issue: DappNode containers not starting

**Symptoms:**
```bash
sudo docker ps
# No DappNode containers listed
```

**Solution:**
1. Check Docker logs:
   ```bash
   sudo journalctl -u docker -n 100
   ```
2. Check DappNode directory:
   ```bash
   ls -la /usr/src/dappnode/
   ```
3. Check available disk space:
   ```bash
   df -h
   ```
4. Try restarting Docker:
   ```bash
   sudo systemctl restart docker
   ```

### Issue: DappNode web interface shows error

**Symptoms:**
- Page loads but shows errors
- Services not responding

**Solution:**
1. Check DappNode container logs:
   ```bash
   sudo docker ps
   sudo docker logs <container-id>
   ```
2. Restart DappNode services:
   ```bash
   sudo docker restart $(sudo docker ps -q)
   ```
3. Check system resources:
   ```bash
   free -h
   top
   ```

## Network and Connectivity Issues

### Issue: Cannot access port 80/443

**Symptoms:**
```
curl: (7) Failed to connect to X.X.X.X port 80: Connection refused
```

**Solution:**
1. Verify firewall rules:
   ```bash
   gcloud compute firewall-rules describe dev-dappnode-allow-services --project=blockchaindappnode
   ```
2. Check if service is listening:
   ```bash
   gcloud compute ssh dev-dappnode-server --zone=us-central1-a --project=blockchaindappnode
   sudo netstat -tlnp | grep -E ':(80|443)'
   ```
3. Verify Docker containers are exposing ports:
   ```bash
   sudo docker ps
   ```

### Issue: High network latency

**Symptoms:**
- Slow SSH connection
- Slow web interface

**Solution:**
1. Check VM location vs your location
2. Consider deploying in a region closer to you:
   ```hcl
   # Edit terraform.tfvars
   region = "europe-west1"  # For European users
   zone   = "europe-west1-b"
   ```
3. Check VM performance:
   ```bash
   gcloud compute ssh dev-dappnode-server --zone=us-central1-a --project=blockchaindappnode
   ping google.com
   ```

### Issue: VPC network conflicts

**Symptoms:**
```
Error: Error creating subnetwork: googleapi: Error 409: The resource already exists
```

**Solution:**
1. Check existing networks:
   ```bash
   gcloud compute networks list --project=blockchaindappnode
   gcloud compute networks subnets list --project=blockchaindappnode
   ```
2. Delete conflicting resources:
   ```bash
   gcloud compute networks subnets delete SUBNET_NAME --region=us-central1 --project=blockchaindappnode
   gcloud compute networks delete NETWORK_NAME --project=blockchaindappnode
   ```

## General Debugging Commands

### Get VM serial console output
```bash
gcloud compute instances get-serial-port-output dev-dappnode-server \
  --zone=us-central1-a \
  --project=blockchaindappnode
```

### View all project resources
```bash
gcloud compute instances list --project=blockchaindappnode
gcloud compute networks list --project=blockchaindappnode
gcloud compute firewall-rules list --project=blockchaindappnode
gcloud compute addresses list --project=blockchaindappnode
```

### Check Cloud Build logs
```bash
gcloud builds list --project=blockchaindappnode --limit=5
gcloud builds log BUILD_ID --project=blockchaindappnode
```

### Terraform debugging
```bash
# Enable verbose logging
export TF_LOG=DEBUG
terraform plan

# Show current state
terraform show

# List resources in state
terraform state list
```

## Getting Help

If none of these solutions work:

1. **Check Documentation**
   - Terraform README: `terraform/README.md`
   - DappNode Docs: https://docs.dappnode.io/
   - GCP Docs: https://cloud.google.com/docs

2. **Collect Debug Information**
   ```bash
   # Terraform state
   terraform show > terraform-state.txt
   
   # GCP resources
   gcloud compute instances describe dev-dappnode-server \
     --zone=us-central1-a \
     --project=blockchaindappnode > vm-info.txt
   
   # Startup logs
   gcloud compute ssh dev-dappnode-server \
     --zone=us-central1-a \
     --project=blockchaindappnode \
     --command="sudo journalctl -u google-startup-scripts.service" > startup-logs.txt
   ```

3. **Community Support**
   - DappNode Discourse: https://discourse.dappnode.io/
   - GitHub Issues: Create an issue with debug information

4. **Professional Support**
   - Google Cloud Support: https://cloud.google.com/support
   - Terraform Support: https://support.hashicorp.com/

## Prevention Tips

- Always review Terraform plan before applying
- Keep regular backups of important data
- Document any custom configurations
- Test changes in a separate environment first
- Monitor resource usage and costs
- Keep Terraform and providers updated
- Use version control for infrastructure code
