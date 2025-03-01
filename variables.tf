variable "project_id" {
  description = "The GCP project ID to deploy resources to"
  type        = string
}

variable "region" {
  description = "The GCP region to deploy resources to"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "The GCP zone to deploy resources to"
  type        = string
  default     = "us-central1-a"
}

variable "machine_type" {
  description = "The machine type for the Terraria server"
  type        = string
  default     = "e2-medium"  # 2 vCPUs, 4 GB memory - good starting point for a small Terraria server
}

variable "disk_size_gb" {
  description = "The boot disk size in GB"
  type        = number
  default     = 20
}

variable "terraria_version" {
  description = "The version of Terraria server to install (fixed at 1.4.4.9 with hardcoded download URL)"
  type        = string
  default     = "1.4.4.9"  # This is hardcoded in the startup script with a direct download URL - changing this value won't change the installed version
}

variable "world_name" {
  description = "The name of the Terraria world to create"
  type        = string
  default     = "terraform-world"
}

variable "world_size" {
  description = "The size of the Terraria world (1=small, 2=medium, 3=large)"
  type        = number
  default     = 2  # Medium world
}

variable "max_players" {
  description = "The maximum number of players allowed on the server"
  type        = number
  default     = 8
}

variable "server_password" {
  description = "The password for the Terraria server (leave empty for no password)"
  type        = string
  default     = ""
  sensitive   = true
}
