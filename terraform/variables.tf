# Variables principales del proyecto
variable "project_id" {
  description = "ID del proyecto de GCP"
  type        = string
}

variable "region" {
  description = "Región principal de GCP (southamerica-east1)"
  type        = string
  default     = "southamerica-east1"
}

variable "environment" {
  description = "Ambiente (dev, staging, production)"
  type        = string
  default     = "dev"
}

# VPC y Networking
variable "vpc_name" {
  description = "Nombre de la VPC personalizada"
  type        = string
  default     = "yappa-vpc"
}

variable "private_subnet_name" {
  description = "Nombre de la subnet privada"
  type        = string
  default     = "yappa-private-subnet"
}

variable "private_subnet_cidr" {
  description = "CIDR para la subnet privada"
  type        = string
  default     = "10.1.0.0/24"
}

# Cloud SQL Variables
variable "db_instance_name" {
  description = "Nombre de la instancia Cloud SQL"
  type        = string
  default     = "yappa-postgres-instance"
}

variable "db_version" {
  description = "Versión de PostgreSQL"
  type        = string
  default     = "POSTGRES_15"
}

variable "db_tier" {
  description = "Tier de la instancia Cloud SQL"
  type        = string
  default     = "db-f1-micro"
}

variable "database_name" {
  description = "Nombre de la base de datos"
  type        = string
  default     = "yappadb"
}

variable "db_user" {
  description = "Usuario inicial de la base de datos"
  type        = string
  default     = "yappa_user"
}

variable "db_password" {
  description = "Contraseña del usuario de la base de datos"
  type        = string
  sensitive   = true
}

# Cloud Run Variables
variable "cloud_run_service_name" {
  description = "Nombre del servicio Cloud Run"
  type        = string
  default     = "yappa-app"
}

variable "container_image" {
  description = "Imagen del container para Cloud Run"
  type        = string
  default     = "gcr.io/cloudrun/hello"
}

variable "cloud_run_port" {
  description = "Puerto de la aplicación Spring Boot"
  type        = number
  default     = 8080
}

# Cloud Storage Variables
variable "storage_bucket_name" {
  description = "Nombre del bucket Cloud Storage"
  type        = string
}

variable "storage_location" {
  description = "Ubicación del bucket"
  type        = string
  default     = "SOUTHAMERICA-EAST1"
}

# Firestore Variables
variable "firestore_location" {
  description = "Ubicación de Firestore"
  type        = string
  default     = "southamerica-east1"
}

# VPN Variables
variable "vpn_gateway_name" {
  description = "Nombre del VPN Gateway"
  type        = string
  default     = "yappa-vpn-gateway"
}

variable "peer_external_ip" {
  description = "IP externa del peer (simulada para on-prem)"
  type        = string
  default     = "8.8.8.8" # IP pública válida (Google DNS)
}

variable "vpn_shared_secret" {
  description = "Secreto compartido para la VPN"
  type        = string
  sensitive   = true
  default     = "changeme-secure-secret-123"
}

variable "on_prem_cidr" {
  description = "CIDR de la red on-premises simulada"
  type        = string
  default     = "192.168.1.0/24"
}
