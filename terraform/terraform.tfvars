# Terraform variables for DappNode deployment
# Project configuration
project_id  = "blockchaindappnode"
region      = "us-central1"
zone        = "us-central1-a"
environment = "dev"

# Network configuration
subnet_cidr = "10.0.1.0/24"

# VM configuration
# n2-custom-16-24576: 16 vCPU and 24GB RAM (custom machine type)
machine_type = "n2-custom-16-24576"
disk_size_gb = 300
disk_type    = "pd-ssd"
debian_image = "debian-cloud/debian-11"

# SSH configuration
ssh_source_ranges = ["0.0.0.0/0"] # Restrict this to your IP range for security
ssh_user          = "admin"
# ssh_public_key  = "ssh-rsa AAAAB3... your-email@example.com"

# Service account (optional)
# service_account_email = "terraform@blockchaindappnode.iam.gserviceaccount.com"

# Cost optimization
preemptible = false
