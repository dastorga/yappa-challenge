# Configuración del bucket de estado remoto para Terraform
# Este archivo asegura que el bucket de estado exista con configuraciones adecuadas

resource "google_storage_bucket" "terraform_state" {
  name          = "yappa-terraform-state"
  location      = var.region
  storage_class = "STANDARD"

  # Versionado para el estado de Terraform
  versioning {
    enabled = true
  }

  # Prevenir eliminación accidental
  lifecycle {
    prevent_destroy = true
  }

  # Encriptación
  encryption {
    default_kms_key_name = null
  }

  # Configuración de lifecycle para limpiar versiones antiguas
  lifecycle_rule {
    condition {
      age                = 30
      num_newer_versions = 5
    }
    action {
      type = "Delete"
    }
  }



  depends_on = [google_project_service.storage]
}

# IAM para el bucket de estado
resource "google_storage_bucket_iam_member" "terraform_state_admin" {
  bucket = google_storage_bucket.terraform_state.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

# Output del bucket de estado
output "terraform_state_bucket" {
  description = "Bucket de estado remoto de Terraform"
  value       = google_storage_bucket.terraform_state.name
}
