# Outputs de la infraestructura

# Información de la VPC
output "vpc_name" {
  description = "Nombre de la VPC creada"
  value       = google_compute_network.vpc.name
}

output "vpc_id" {
  description = "ID de la VPC creada"
  value       = google_compute_network.vpc.id
}

output "private_subnet_name" {
  description = "Nombre de la subnet privada"
  value       = google_compute_subnetwork.private_subnet.name
}

output "private_subnet_cidr" {
  description = "CIDR de la subnet privada"
  value       = google_compute_subnetwork.private_subnet.ip_cidr_range
}

# Output del VPC Connector
output "vpc_connector_name" {
  description = "Nombre del VPC Access Connector para Cloud Run"
  value       = google_vpc_access_connector.yappa_vpc_connector.name
}
output "vpc_connector_id" {
  description = "ID del VPC Access Connector"
  value       = google_vpc_access_connector.yappa_vpc_connector.id
}

# Información de Cloud SQL
output "cloudsql_instance_name" {
  description = "Nombre de la instancia Cloud SQL"
  value       = google_sql_database_instance.postgres_instance.name
}

output "cloudsql_connection_name" {
  description = "Connection name de Cloud SQL"
  value       = google_sql_database_instance.postgres_instance.connection_name
}

output "cloudsql_private_ip" {
  description = "IP privada de la instancia Cloud SQL"
  value       = google_sql_database_instance.postgres_instance.private_ip_address
  sensitive   = true
}

output "database_name" {
  description = "Nombre de la base de datos creada"
  value       = google_sql_database.database.name
}

# Información de Cloud Run
output "cloud_run_service_url" {
  description = "URL del servicio Cloud Run"
  value       = google_cloud_run_service.app.status[0].url
}

output "cloud_run_service_name" {
  description = "Nombre del servicio Cloud Run"
  value       = google_cloud_run_service.app.name
}

# Información de Cloud Storage
output "storage_bucket_name" {
  description = "Nombre del bucket principal de Cloud Storage"
  value       = google_storage_bucket.bucket.name
}

output "storage_bucket_url" {
  description = "URL del bucket de Cloud Storage"
  value       = google_storage_bucket.bucket.url
}

output "logs_bucket_name" {
  description = "Nombre del bucket de logs"
  value       = google_storage_bucket.logs_bucket.name
}

# Información de Firestore
output "firestore_database_name" {
  description = "Firestore habilitado via API (no requiere App Engine)"
  value       = "${var.project_id}-firestore-native"
}

output "firestore_location" {
  description = "Ubicación de la base de datos Firestore"
  value       = var.firestore_location
}

# Información de VPN
output "vpn_gateway_name" {
  description = "Nombre del VPN Gateway"
  value       = google_compute_vpn_gateway.vpn_gateway.name
}

output "vpn_gateway_ip" {
  description = "IP externa del VPN Gateway"
  value       = google_compute_address.vpn_gateway_ip.address
}

output "vpn_tunnel_name" {
  description = "Nombre del túnel VPN"
  value       = google_compute_vpn_tunnel.tunnel_onprem.name
}

# Service Accounts
output "cloud_run_service_account_email" {
  description = "Email del service account de Cloud Run"
  value       = google_service_account.cloud_run_sa.email
}

output "admin_service_account_email" {
  description = "Email del service account administrativo"
  value       = google_service_account.admin_sa.email
}

# Información de conectividad

# Artifact Registry
output "artifact_registry_repository" {
  description = "URL del repositorio Artifact Registry"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/yappa-docker-repo"
}

# Información para conexión a la aplicación
output "connection_instructions" {
  description = "Instrucciones de conexión"
  value       = <<-EOT
    
    🚀 Infraestructura Yappa Challenge desplegada exitosamente!
    
    📊 Servicios creados:
    - Cloud Run: ${google_cloud_run_service.app.status[0].url}
    - Cloud SQL: ${google_sql_database_instance.postgres_instance.connection_name}
    - Firestore: Habilitado via API nativa (sin App Engine)
    - Storage: gs://${google_storage_bucket.bucket.name}
    - VPN Gateway: ${google_compute_address.vpn_gateway_ip.address}
    
    🔐 Para acceder a Cloud SQL desde Cloud Run:
    Host: ${google_sql_database_instance.postgres_instance.private_ip_address}
    Puerto: 5432
    Base de datos: ${google_sql_database.database.name}
    Usuario: ${google_sql_user.db_user.name}
    
    📝 Comandos útiles:
    - Ver logs Cloud Run: gcloud logs read "resource.type=cloud_run_revision" --limit=50
    - Conectar a Cloud SQL: gcloud sql connect ${google_sql_database_instance.postgres_instance.name} --user=${google_sql_user.db_user.name}
    - Listar archivos en Storage: gsutil ls gs://${google_storage_bucket.bucket.name}/
    
  EOT
}
