# VPC personalizada
resource "google_compute_network" "vpc" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
  description             = "VPC personalizada para el proyecto Yappa"

  lifecycle {
    prevent_destroy = true # Protege la VPC contra eliminación accidental
    ignore_changes = [
      name, # Ignorar cambios en el nombre después de la creación
    ]
  }

  depends_on = [google_project_service.compute]
}

# Subnet privada en southamerica-east1
resource "google_compute_subnetwork" "private_subnet" {
  name          = var.private_subnet_name
  ip_cidr_range = var.private_subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc.name

  description = "Subnet privada para Cloud SQL y Cloud Run"

  # Habilitar Private Google Access para acceso a APIs sin IP pública
  private_ip_google_access = true

  lifecycle {
    prevent_destroy = true # Protege la subnet contra eliminación accidental
    ignore_changes = [
      name, # Ignorar cambios en el nombre después de la creación
    ]
  }
}

# Reserva de IP para Cloud SQL
resource "google_compute_global_address" "private_ip_range" {
  name          = "private-ip-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc.id
}

# Conexión de servicio para Cloud SQL
resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_range.name]

  depends_on = [google_project_service.servicenetworking]
}

# Firewall: Permitir tráfico interno en la VPC
resource "google_compute_firewall" "allow_internal" {
  name    = "allow-internal"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = [var.private_subnet_cidr, var.on_prem_cidr]
  description   = "Permitir tráfico interno en la VPC"
}

# Firewall: Permitir acceso a Cloud SQL (PostgreSQL)
resource "google_compute_firewall" "allow_postgres" {
  name    = "allow-postgres"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["5432"]
  }

  source_ranges = [var.private_subnet_cidr]
  target_tags   = ["postgres"]
  description   = "Permitir acceso a PostgreSQL desde Cloud Run"
}

# Firewall: Permitir acceso SSH para administración
resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"] # Identity-Aware Proxy
  target_tags   = ["ssh"]
  description   = "Permitir SSH via Identity-Aware Proxy"
}

# VPC Connector para Cloud Run
resource "google_vpc_access_connector" "connector" {
  name           = "yappa-vpc-connector"
  region         = var.region
  ip_cidr_range  = "10.9.0.0/28"
  network        = google_compute_network.vpc.name
  min_throughput = 200
  max_throughput = 1000

  depends_on = [google_project_service.vpcaccess]
}
