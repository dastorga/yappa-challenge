# Servicio Cloud Run para la aplicación Spring Boot (compatible v3.22.0)
resource "google_cloud_run_service" "app" {
  name     = var.cloud_run_service_name
  location = var.region

  template {
    metadata {
      annotations = {
        "autoscaling.knative.dev/maxScale"  = "10"
        "run.googleapis.com/timeoutSeconds" = "600"
      }
    }

    spec {
      containers {
        image = var.container_image

        # Variables de entorno para conexión a Cloud SQL
        env {
          # ...sin vpc_access, se configura en el workflow
          name  = "SPRING_PROFILES_ACTIVE"
          value = "dev"
        }

        env {
          name  = "DB_HOST"
          value = google_sql_database_instance.postgres_instance.private_ip_address
        }

        env {
          name  = "DB_PORT"
          value = "5432"
        }

        env {
          name  = "DB_NAME"
          value = var.database_name
        }

        env {
          name  = "DB_USER"
          value = var.db_user
        }

        env {
          name  = "DB_PASSWORD"
          value = "YappaSecure2024!"
        }

        env {
          name  = "SPRING_DATASOURCE_URL"
          value = "jdbc:postgresql://10.27.0.3:5432/yappadb"
        }

        env {
          name  = "SPRING_DATASOURCE_USERNAME"
          value = var.db_user
        }

        env {
          name  = "SPRING_DATASOURCE_PASSWORD"
          value = "YappaSecure2024!"
        }

        env {
          name  = "STORAGE_BUCKET_NAME"
          value = google_storage_bucket.bucket.name
        }

        env {
          name  = "GOOGLE_CLOUD_PROJECT"
          value = var.project_id
        }

        # Configuración de recursos
        resources {
          limits = {
            "cpu"    = "1000m"
            "memory" = "1Gi"
          }
        }
      }

      container_concurrency = 80
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  depends_on = [
    google_project_service.run,
    google_sql_database_instance.postgres_instance
  ]
}

# Policy para permitir acceso público al servicio Cloud Run
resource "google_cloud_run_service_iam_policy" "policy" {
  location = google_cloud_run_service.app.location
  project  = google_cloud_run_service.app.project
  service  = google_cloud_run_service.app.name

  policy_data = data.google_iam_policy.public_access.policy_data
}

data "google_iam_policy" "public_access" {
  binding {
    role = "roles/run.invoker"
    members = [
      "allUsers",
    ]
  }
}
