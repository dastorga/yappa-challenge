# Bucket de Cloud Storage para artefactos, logs y archivos temporales (v3.22.0)
resource "google_storage_bucket" "bucket" {
  name          = local.storage_bucket_name
  location      = var.storage_location
  force_destroy = false

  lifecycle {
    prevent_destroy = true # Protege contra eliminación accidental
    ignore_changes = [
      name, # Ignorar cambios en el nombre después de la creación
    ]
  }

  # Configuración de versionado
  versioning {
    enabled = true
  }

  # Configuración de lifecycle para gestión automática de archivos
  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type = "Delete"
    }
  }

  lifecycle_rule {
    condition {
      age = 7
    }
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }

  # Configuración de CORS para acceso desde aplicaciones web
  cors {
    origin          = ["*"]
    method          = ["GET", "HEAD", "PUT", "POST", "DELETE"]
    response_header = ["*"]
    max_age_seconds = 3600
  }

  # Etiquetas
  labels = {
    environment = var.environment
    purpose     = "app-storage"
    managed_by  = "terraform"
  }

  depends_on = [google_project_service.storage]
}

# Bucket separado para logs de acceso
resource "google_storage_bucket" "logs_bucket" {
  name          = local.logs_bucket_name
  location      = var.storage_location
  force_destroy = true

  lifecycle {
    prevent_destroy = true # Protege contra eliminación accidental
    ignore_changes = [
      name, # Ignorar cambios en el nombre después de la creación
    ]
  }

  # Política de retención para logs
  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type = "Delete"
    }
  }

  labels = {
    environment = var.environment
    purpose     = "access-logs"
    managed_by  = "terraform"
  }
}

# Carpetas organizacionales en el bucket
resource "google_storage_bucket_object" "folders" {
  for_each = toset([
    "uploads/",
    "temp/",
    "exports/",
    "backups/",
    "app-logs/"
  ])

  name   = each.value
  bucket = google_storage_bucket.bucket.name
  source = "/dev/null"
}

# Política de IAM para el bucket - acceso desde Cloud Run
resource "google_storage_bucket_iam_member" "bucket_admin" {
  bucket = google_storage_bucket.bucket.name
  role   = "roles/storage.admin"
  member = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}
