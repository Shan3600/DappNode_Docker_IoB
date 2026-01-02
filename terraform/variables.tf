# Variables for DappNode Terraform configuration

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region for resources"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP zone for VM instance"
  type        = string
  default     = "us-central1-a"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "subnet_cidr" {
  description = "CIDR range for the subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "machine_type" {
  description = "GCP machine type for DappNode VM"
  type        = string
  default     = "n1-standard-4"
}

variable "disk_size_gb" {
  description = "Boot disk size in GB"
  type        = number
  default     = 100
}

variable "disk_type" {
  description = "Boot disk type"
  type        = string
  default     = "pd-standard"
}

variable "debian_image" {
  description = "Debian image for the VM"
  type        = string
  default     = "debian-cloud/debian-11"
}

variable "ssh_source_ranges" {
  description = "Source IP ranges allowed for SSH access. SECURITY: Restrict to your IP for production use."
  type        = list(string)
  default     = ["0.0.0.0/0"] # WARNING: Allows SSH from anywhere - change in production!
}

variable "ssh_user" {
  description = "SSH user for VM access"
  type        = string
  default     = "admin"
}

variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
  default     = ""
}

variable "service_account_email" {
  description = "Service account email for the VM"
  type        = string
  default     = ""
}

variable "preemptible" {
  description = "Whether to use preemptible VM instances"
  type        = bool
  default     = false
}
