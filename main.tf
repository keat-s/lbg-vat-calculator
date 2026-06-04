# Terraform settings: provider requirements and remote state backend.
terraform {
  # Pin the Google provider to the 7.x line.
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.0"
    }
  }
  # Store state remotely in a GCS bucket (enables team sharing + locking).
  backend "gcs" {
    bucket = "qadevoprac3-lab10-tfstate-9665-24593"
    prefix = "terraform/state/lab10"
  }
}

# Input variables, supplied via TF_VAR_* env vars from the Jenkins pipeline.
variable "gcp_project" {}     # GCP project ID to deploy into.
variable "docker_registry" {} # Image repo, e.g. <user>/vatcal.

# Google Cloud provider config: target project and region.
provider "google" {
  project = var.gcp_project
  region  = "europe-west1"
}

# Compute VM that runs the app container.
resource "google_compute_instance" "docker_server" {
  name         = "app-server"
  machine_type = "e2-medium"
  zone         = "europe-west1-b"

  # OS disk: Ubuntu 24.04 LTS, 16 GB.
  boot_disk {
    initialize_params {
      image = "ubuntu-2404-lts-amd64"
      size  = 16
    }
  }

  # Boot-time script: install Docker and run the latest app image on port 80.
  metadata_startup_script = <<EOF
apt-get update
apt-get install -y docker.io
systemctl enable --now docker
docker run -d -p 80:80 ${var.docker_registry}:latest

EOF

  # Attach to the default network with an ephemeral public IP.
  network_interface {
    network = "default"
    access_config {}
  }
}

# Firewall: allow inbound ping + SSH/HTTP from anywhere.
# NOTE: 0.0.0.0/0 is open to the whole internet — fine for a lab, tighten for prod.
resource "google_compute_firewall" "default" {
  name          = "server-firewall"
  network       = "default"
  direction     = "INGRESS"
  source_ranges = ["10.0.0.1/16"]

  # Allow ICMP (ping).
  allow {
    protocol = "icmp"
  }

  # Allow SSH (22) and HTTP (80).
  allow {
    ports    = ["22", "80"]
    protocol = "tcp"
  }
}
