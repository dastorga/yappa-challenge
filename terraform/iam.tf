# Service Account para Cloud Run
resource "google_service_account" "cloud_run_sa" {
  account_id   = "cloud-run-sa"
  display_name = "Service Account para Cloud Run"
  description  = "Service Account utilizado por el servicio Cloud Run de Yappa"
}

# Permisos para Cloud Run - acceso a Cloud SQL
resource "google_project_iam_member" "cloud_run_sql_client" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

# Permisos para Cloud Run - acceso a Firestore
resource "google_project_iam_member" "cloud_run_firestore_user" {
  project = var.project_id
  role    = "roles/datastore.user"
  member  = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

# Permisos para Cloud Run - acceso a Cloud Storage
resource "google_project_iam_member" "cloud_run_storage_admin" {
  project = var.project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

# Permisos para Cloud Run - acceso a Secret Manager
resource "google_project_iam_member" "cloud_run_secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

# Permisos para Cloud Run - logs y monitoring
resource "google_project_iam_member" "cloud_run_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

resource "google_project_iam_member" "cloud_run_monitoring_writer" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

# Permisos para Cloud Run - trace writer
resource "google_project_iam_member" "cloud_run_trace_agent" {
  project = var.project_id
  role    = "roles/cloudtrace.agent"
  member  = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

# Service Account para administración del proyecto (opcional)
resource "google_service_account" "admin_sa" {
  account_id   = "yappa-admin-sa"
  display_name = "Service Account Administrativo Yappa"
  description  = "Service Account para tareas administrativas del proyecto"
}

# Permisos administrativos limitados
resource "google_project_iam_member" "admin_editor" {
  project = var.project_id
  role    = "roles/editor"
  member  = "serviceAccount:${google_service_account.admin_sa.email}"
}

# Service Account para backups y mantenimiento
resource "google_service_account" "backup_sa" {
  account_id   = "yappa-backup-sa"
  display_name = "Service Account para Backups"
  description  = "Service Account para operaciones de backup y mantenimiento"
}

# Permisos específicos para backups
resource "google_project_iam_member" "backup_sql_admin" {
  project = var.project_id
  role    = "roles/cloudsql.admin"
  member  = "serviceAccount:${google_service_account.backup_sa.email}"
}

resource "google_project_iam_member" "backup_storage_admin" {
  project = var.project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.backup_sa.email}"
}

resource "google_project_iam_member" "backup_firestore_admin" {
  project = var.project_id
  role    = "roles/datastore.owner"
  member  = "serviceAccount:${google_service_account.backup_sa.email}"
}

# Habilitar APIs adicionales para IAM y Secret Manager
resource "google_project_service" "iam" {
  service            = "iam.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "secretmanager" {
  service            = "secretmanager.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "cloudkms" {
  service            = "cloudkms.googleapis.com"
  disable_on_destroy = false
}
