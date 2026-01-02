# Outputs for DappNode infrastructure

output "dappnode_vm_name" {
  description = "Name of the DappNode VM instance"
  value       = google_compute_instance.dappnode_vm.name
}

output "dappnode_vm_id" {
  description = "ID of the DappNode VM instance"
  value       = google_compute_instance.dappnode_vm.id
}

output "dappnode_external_ip" {
  description = "External IP address of the DappNode server"
  value       = google_compute_address.dappnode_ip.address
}

output "dappnode_internal_ip" {
  description = "Internal IP address of the DappNode server"
  value       = google_compute_instance.dappnode_vm.network_interface[0].network_ip
}

output "dappnode_network_name" {
  description = "Name of the VPC network"
  value       = google_compute_network.dappnode_network.name
}

output "dappnode_subnet_name" {
  description = "Name of the subnet"
  value       = google_compute_subnetwork.dappnode_subnet.name
}

output "ssh_command" {
  description = "SSH command to connect to the DappNode server"
  value       = "gcloud compute ssh ${google_compute_instance.dappnode_vm.name} --zone=${var.zone} --project=${var.project_id}"
}
