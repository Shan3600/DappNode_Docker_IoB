# Main Terraform configuration for DappNode VM deployment on GCP

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }

  backend "gcs" {
    prefix = "terraform/state"
  }
}

# Configure the Google Cloud Provider
provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# Create a VPC network for DappNode
resource "google_compute_network" "dappnode_network" {
  name                    = "${var.environment}-dappnode-network"
  auto_create_subnetworks = false
  description             = "Network for DappNode infrastructure"
}

# Create a subnet
resource "google_compute_subnetwork" "dappnode_subnet" {
  name          = "${var.environment}-dappnode-subnet"
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.dappnode_network.id

  description = "Subnet for DappNode VMs"
}

# Create a firewall rule to allow SSH
resource "google_compute_firewall" "allow_ssh" {
  name    = "${var.environment}-dappnode-allow-ssh"
  network = google_compute_network.dappnode_network.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = var.ssh_source_ranges
  target_tags   = ["dappnode-server"]

  description = "Allow SSH access to DappNode servers"
}

# Create a firewall rule to allow DappNode ports
resource "google_compute_firewall" "allow_dappnode" {
  name    = "${var.environment}-dappnode-allow-services"
  network = google_compute_network.dappnode_network.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443", "8080", "30303"]
  }

  allow {
    protocol = "udp"
    ports    = ["30303"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["dappnode-server"]

  description = "Allow DappNode service ports"
}

# Create a static external IP
resource "google_compute_address" "dappnode_ip" {
  name        = "${var.environment}-dappnode-ip"
  region      = var.region
  description = "Static IP for DappNode server"
}

# Create a VM instance for DappNode
resource "google_compute_instance" "dappnode_vm" {
  name         = "${var.environment}-dappnode-server"
  machine_type = var.machine_type
  zone         = var.zone

  tags = ["dappnode-server", "debian-vm"]

  boot_disk {
    initialize_params {
      image = var.debian_image
      size  = var.disk_size_gb
      type  = var.disk_type
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.dappnode_subnet.id

    access_config {
      nat_ip = google_compute_address.dappnode_ip.address
    }
  }

  metadata = {
    ssh-keys = var.ssh_public_key != "" ? "${var.ssh_user}:${var.ssh_public_key}" : null
  }

  metadata_startup_script = file("${path.module}/scripts/install-dappnode.sh")

  labels = {
    environment = var.environment
    service     = "dappnode"
    managed_by  = "terraform"
  }

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
    preemptible         = var.preemptible
  }

  service_account {
    email  = var.service_account_email != "" ? var.service_account_email : null
    scopes = ["cloud-platform"]
  }

  allow_stopping_for_update = true
}
