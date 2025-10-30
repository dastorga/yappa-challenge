# Instancia Cloud SQL PostgreSQL
resource "google_sql_database_instance" "postgres_instance" {
  name             = local.db_instance_name
  database_version = var.db_version
  region           = var.region

  lifecycle {
    # prevent_destroy = true # Protege contra eliminación accidental de la BD
    ignore_changes = [
      name, # Ignorar cambios en el nombre después de la creación
    ]
  }

  settings {
    tier = var.db_tier

    # Configuración de disponibilidad
    availability_type = "ZONAL"

    # Configuración de disco
    disk_type       = "PD_SSD"
    disk_size       = 20
    disk_autoresize = true

    # Configuración de backup
    backup_configuration {
      enabled    = true
      start_time = "03:00"
    }

    # Configuración de red - acceso privado
    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.vpc.id
    }

    # Configuración de mantenimiento
    maintenance_window {
      day  = 7
      hour = 4
    }

    # Configuración de flags de base de datos
    database_flags {
      name  = "log_checkpoints"
      value = "on"
    }

    database_flags {
      name  = "log_connections"
      value = "on"
    }

    database_flags {
      name  = "log_disconnections"
      value = "on"
    }
  }

  depends_on = [
    google_service_networking_connection.private_vpc_connection,
    google_project_service.sqladmin
  ]
}

# Base de datos principal
resource "google_sql_database" "database" {
  name     = var.database_name
  instance = google_sql_database_instance.postgres_instance.name
}

# Usuario inicial de la base de datos
resource "google_sql_user" "db_user" {
  name     = var.db_user
  instance = google_sql_database_instance.postgres_instance.name
  password = var.db_password
}

# Usuario adicional para aplicación (solo lectura)
resource "google_sql_user" "readonly_user" {
  name     = "${var.db_user}_readonly"
  instance = google_sql_database_instance.postgres_instance.name
  password = "${var.db_password}_ro"
}
