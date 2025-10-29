# Configuración de Terraform
terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      source = "hashicorp/google"
    }
  }

  # Backend para almacenar el estado (comentado temporalmente para evitar errores)
  # backend "gcs" {
  #   bucket = "yappa-terraform-state"
  #   prefix = "terraform/state"
  # }
}

# Provider de Google Cloud
provider "google" {
  project = var.project_id
  region  = var.region
}

# Habilitar APIs necesarias
resource "google_project_service" "compute" {
  service            = "compute.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "sqladmin" {
  service            = "sqladmin.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "run" {
  service            = "run.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "firestore" {
  service            = "firestore.googleapis.com"
  disable_on_destroy = false
}

# App Engine no es necesario para Firestore nativo moderno
# resource "google_project_service" "appengine" {
#   service            = "appengine.googleapis.com"
#   disable_on_destroy = false
# }

resource "google_project_service" "storage" {
  service            = "storage.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "servicenetworking" {
  service            = "servicenetworking.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "vpcaccess" {
  service            = "vpcaccess.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "artifactregistry" {
  service            = "artifactregistry.googleapis.com"
  disable_on_destroy = false
}
