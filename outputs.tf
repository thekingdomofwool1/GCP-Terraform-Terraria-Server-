output "terraria_server_ip" {
  description = "The public IP address of the Terraria server"
  value       = google_compute_instance.terraria_server.network_interface[0].access_config[0].nat_ip
}

output "terraria_server_name" {
  description = "The name of the Terraria server instance"
  value       = google_compute_instance.terraria_server.name
}

output "terraria_connection_info" {
  description = "Connection information for the Terraria server"
  value       = "Connect to Terraria server at ${google_compute_instance.terraria_server.network_interface[0].access_config[0].nat_ip}:7777"
}

output "terraria_version" {
  description = "The version of Terraria server installed"
  value       = var.terraria_version
}

output "server_management_instructions" {
  description = "Instructions for managing the Terraria server"
  value       = <<-EOT
    To SSH into your Terraria server:
    gcloud compute ssh terraria-server --project=${var.project_id} --zone=${var.zone}

    The Terraria server runs as a systemd service. You can manage it with:
    - Check status: sudo systemctl status terraria
    - Stop server: sudo systemctl stop terraria
    - Start server: sudo systemctl start terraria
    - Restart server: sudo systemctl restart terraria
    - View logs: sudo journalctl -u terraria

    Server files are located in /opt/terraria
    World files are stored in /opt/terraria/worlds
  EOT
}
