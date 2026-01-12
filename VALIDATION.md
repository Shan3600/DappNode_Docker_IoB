# Deployment Validation Checklist

Use this checklist to verify your DappNode deployment on Google Cloud Platform.

## Pre-Deployment Validation

### Prerequisites Check
- [ ] Google Cloud SDK (`gcloud`) installed
  ```bash
  gcloud --version
  ```
- [ ] Terraform installed (>= 1.6.0)
  ```bash
  terraform --version
  ```
- [ ] Authenticated with GCP
  ```bash
  gcloud auth list
  ```
- [ ] Project set correctly
  ```bash
  gcloud config get-value project
  # Should return: blockchaindappnode
  ```

### GCP Project Setup
- [ ] Required APIs enabled
  ```bash
  gcloud services list --enabled --project=blockchaindappnode | grep -E "(compute|cloudbuild|storage)"
  ```
- [ ] GCS bucket for Terraform state exists
  ```bash
  gsutil ls gs://blockchaindappnode-terraform-state
  ```
- [ ] GCS bucket for build artifacts exists
  ```bash
  gsutil ls gs://blockchaindappnode-build-artifacts
  ```

### Terraform Configuration
- [ ] terraform.tfvars file exists
  ```bash
  ls terraform/terraform.tfvars
  ```
- [ ] Project ID is set correctly in terraform.tfvars
  ```bash
  grep "project_id" terraform/terraform.tfvars
  # Should show: project_id = "blockchaindappnode"
  ```
- [ ] SSH configuration reviewed
  ```bash
  grep "ssh_source_ranges" terraform/terraform.tfvars
  # Verify IP range restrictions
  ```

## Deployment Validation

### Terraform Initialization
- [ ] Terraform initialized successfully
  ```bash
  cd terraform
  terraform init -backend-config="bucket=blockchaindappnode-terraform-state"
  # Should show: "Terraform has been successfully initialized!"
  ```

### Terraform Validation
- [ ] Configuration is valid
  ```bash
  terraform validate
  # Should show: "Success! The configuration is valid."
  ```
- [ ] Terraform plan generates without errors
  ```bash
  terraform plan
  # Review the plan output
  ```

### Resource Creation
After running `terraform apply`:

- [ ] VPC Network created
  ```bash
  gcloud compute networks list --project=blockchaindappnode | grep dappnode
  ```
- [ ] Subnet created
  ```bash
  gcloud compute networks subnets list --project=blockchaindappnode | grep dappnode
  ```
- [ ] Firewall rules created
  ```bash
  gcloud compute firewall-rules list --project=blockchaindappnode | grep dappnode
  ```
- [ ] Static IP allocated
  ```bash
  gcloud compute addresses list --project=blockchaindappnode | grep dappnode
  ```
- [ ] VM instance running
  ```bash
  gcloud compute instances list --project=blockchaindappnode
  # Status should be: RUNNING
  ```

## Post-Deployment Validation

### VM Connectivity
- [ ] VM is reachable via SSH
  ```bash
  gcloud compute ssh dev-dappnode-server --zone=us-central1-a --project=blockchaindappnode --command="echo 'SSH works'"
  ```
- [ ] External IP responds to ping (if ICMP is allowed)
  ```bash
  EXTERNAL_IP=$(terraform output -raw dappnode_external_ip)
  ping -c 4 $EXTERNAL_IP
  ```

### DappNode Installation
- [ ] Docker is installed and running
  ```bash
  gcloud compute ssh dev-dappnode-server --zone=us-central1-a --project=blockchaindappnode --command="sudo systemctl status docker"
  # Should show: active (running)
  ```
- [ ] Docker Compose is installed
  ```bash
  gcloud compute ssh dev-dappnode-server --zone=us-central1-a --project=blockchaindappnode --command="docker-compose --version"
  ```
- [ ] DappNode startup script completed
  ```bash
  gcloud compute ssh dev-dappnode-server --zone=us-central1-a --project=blockchaindappnode --command="sudo journalctl -u google-startup-scripts.service | tail -20"
  # Look for: "DappNode Installation Complete!"
  ```
- [ ] DappNode containers are running
  ```bash
  gcloud compute ssh dev-dappnode-server --zone=us-central1-a --project=blockchaindappnode --command="sudo docker ps"
  # Should show DappNode containers
  ```

### Web Interface Access
- [ ] DappNode web interface is accessible
  ```bash
  EXTERNAL_IP=$(terraform output -raw dappnode_external_ip)
  curl -I http://$EXTERNAL_IP
  # Should return HTTP response
  ```
- [ ] Open browser and verify UI loads
  ```bash
  # Navigate to: http://<EXTERNAL_IP>
  # DappNode setup wizard should appear
  ```

## Terraform Outputs Validation

Verify all expected outputs are available:

```bash
cd terraform

# All outputs
terraform output

# Individual outputs
terraform output dappnode_vm_name        # dev-dappnode-server
terraform output dappnode_external_ip    # <IP Address>
terraform output dappnode_internal_ip    # 10.0.1.x
terraform output dappnode_network_name   # dev-dappnode-network
terraform output dappnode_subnet_name    # dev-dappnode-subnet
terraform output ssh_command             # gcloud compute ssh ...
```

Expected outputs:
- [ ] `dappnode_vm_name` returns VM name
- [ ] `dappnode_external_ip` returns public IP
- [ ] `dappnode_internal_ip` returns private IP
- [ ] `dappnode_network_name` returns network name
- [ ] `dappnode_subnet_name` returns subnet name
- [ ] `ssh_command` returns valid SSH command

## Security Validation

### Network Security
- [ ] SSH firewall rule is properly configured
  ```bash
  gcloud compute firewall-rules describe dev-dappnode-allow-ssh --project=blockchaindappnode
  # Check sourceRanges matches your configuration
  ```
- [ ] DappNode service ports are accessible
  ```bash
  gcloud compute firewall-rules describe dev-dappnode-allow-services --project=blockchaindappnode
  # Verify ports: 80, 443, 8080, 30303
  ```
- [ ] Only necessary ports are open
  ```bash
  gcloud compute firewall-rules list --project=blockchaindappnode
  # Review all rules
  ```

### Access Control
- [ ] SSH key is configured (if provided)
  ```bash
  gcloud compute instances describe dev-dappnode-server --zone=us-central1-a --project=blockchaindappnode --format="value(metadata.items[ssh-keys])"
  ```
- [ ] Service account has minimal required permissions
  ```bash
  gcloud compute instances describe dev-dappnode-server --zone=us-central1-a --project=blockchaindappnode --format="value(serviceAccounts[0].email)"
  ```

## Performance Validation

### Resource Utilization
- [ ] VM has adequate resources
  ```bash
  gcloud compute ssh dev-dappnode-server --zone=us-central1-a --project=blockchaindappnode --command="free -h && df -h"
  ```
- [ ] CPU and memory usage is reasonable
  ```bash
  gcloud compute ssh dev-dappnode-server --zone=us-central1-a --project=blockchaindappnode --command="top -bn1 | head -20"
  ```

### Disk Space
- [ ] Adequate disk space available
  ```bash
  gcloud compute ssh dev-dappnode-server --zone=us-central1-a --project=blockchaindappnode --command="df -h /"
  # Should have plenty of free space from 100GB disk
  ```

## Monitoring Setup (Optional)

### Logging
- [ ] Startup script logs are available
  ```bash
  gcloud compute instances get-serial-port-output dev-dappnode-server --zone=us-central1-a --project=blockchaindappnode
  ```
- [ ] System logs are accessible
  ```bash
  gcloud logging read "resource.type=gce_instance AND resource.labels.instance_id:dev-dappnode-server" --limit 10 --project=blockchaindappnode
  ```

### Metrics
- [ ] CPU metrics available in Cloud Monitoring
  ```bash
  # Visit: https://console.cloud.google.com/monitoring
  # Navigate to: GCE VM Instances → dev-dappnode-server
  ```

## Troubleshooting Checklist

If any validation step fails:

### Common Issues
- [ ] Quota exceeded
  ```bash
  gcloud compute project-info describe --project=blockchaindappnode
  ```
- [ ] Permission issues
  ```bash
  gcloud projects get-iam-policy blockchaindappnode
  ```
- [ ] Network connectivity issues
  ```bash
  gcloud compute networks describe dev-dappnode-network --project=blockchaindappnode
  ```
- [ ] Startup script failures
  ```bash
  gcloud compute ssh dev-dappnode-server --zone=us-central1-a --project=blockchaindappnode --command="sudo journalctl -u google-startup-scripts.service -n 200"
  ```

## Cleanup Validation

After running `terraform destroy`:

- [ ] VM instance deleted
  ```bash
  gcloud compute instances list --project=blockchaindappnode | grep dappnode
  # Should return nothing
  ```
- [ ] Static IP released
  ```bash
  gcloud compute addresses list --project=blockchaindappnode | grep dappnode
  # Should return nothing
  ```
- [ ] Firewall rules deleted
  ```bash
  gcloud compute firewall-rules list --project=blockchaindappnode | grep dappnode
  # Should return nothing
  ```
- [ ] Network resources cleaned up
  ```bash
  gcloud compute networks list --project=blockchaindappnode | grep dappnode
  # Should return nothing
  ```

## Success Criteria

Deployment is considered successful when:
- ✅ All pre-deployment checks pass
- ✅ Terraform apply completes without errors
- ✅ VM instance is running and accessible
- ✅ Docker and Docker Compose are installed
- ✅ DappNode installation script completes successfully
- ✅ DappNode containers are running
- ✅ Web interface is accessible via external IP
- ✅ All security configurations are in place

## Notes
- DappNode installation can take 5-10 minutes after VM creation
- Some services may take additional time to initialize
- Check logs if any step fails for detailed error messages
- Ensure adequate time between deployment and validation steps

## Support
For issues during validation:
1. Check the troubleshooting section above
2. Review logs using the commands provided
3. Consult `terraform/README.md` for detailed documentation
4. Visit DappNode documentation: https://docs.dappnode.io/
