provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}


resource "google_compute_instance" "terraria_server" {
  name         = "terraria-server"
  machine_type = var.machine_type
  tags         = ["terraria-server"]
}
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = var.disk_size_gb
    }
  }

  allow_stopping_for_update = true

  # Ensure the instance has an external IP
  network_interface {
    network = "default"
    access_config {
      // Ephemeral public IP
    }
  }


  metadata_startup_script = file("${path.module}/startup-script.sh")
  

  metadata = {
    terraria_version = var.terraria_version
    world_name       = var.world_name
    world_size       = var.world_size
    max_players      = var.max_players
    server_password  = var.server_password
  }


resource "google_compute_firewall" "terraria_server" {
  name    = "allow-terraria"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["7777"]  # Default Terraria port
  }


  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["terraria-server"]
}


resource "google_compute_firewall" "terraria_ssh" {
  name    = "allow-ssh-terraria"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22"]  # SSH port
  }


  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["terraria-server"]
}
## adding a test comment. 
