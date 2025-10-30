# IP estática para VPN Gateway
resource "google_compute_address" "vpn_gateway_ip" {
  name   = "vpn-gateway-ip"
  region = var.region

  lifecycle {
    # prevent_destroy = true # Protege la IP estática contra eliminación accidental
    ignore_changes = [
      name, # Ignorar cambios en el nombre después de la creación
    ]
  }
}

# VPN Gateway
resource "google_compute_vpn_gateway" "vpn_gateway" {
  name    = "yappa-vpn-gateway"
  network = google_compute_network.vpc.id
  region  = var.region

  lifecycle {
    ignore_changes = [
      name,    # Ignorar cambios en el nombre después de la creación
      network, # Ignorar cambios en la red para evitar recreación
    ]
  }
}

# Túnel VPN hacia red on-premises (simulada)
resource "google_compute_vpn_tunnel" "tunnel_onprem" {
  name               = "yappa-vpn-tunnel"
  peer_ip            = var.peer_external_ip
  shared_secret      = var.vpn_shared_secret
  target_vpn_gateway = google_compute_vpn_gateway.vpn_gateway.name

  local_traffic_selector  = [var.private_subnet_cidr]
  remote_traffic_selector = [var.on_prem_cidr]

  lifecycle {
    ignore_changes = [
      name, # Ignorar cambios en el nombre después de la creación
    ]
  }

  depends_on = [
    google_compute_forwarding_rule.fr_esp,
    google_compute_forwarding_rule.fr_udp500,
    google_compute_forwarding_rule.fr_udp4500,
  ]
}

# Forwarding rules para ESP
resource "google_compute_forwarding_rule" "fr_esp" {
  name        = "fr-esp"
  ip_protocol = "ESP"
  ip_address  = google_compute_address.vpn_gateway_ip.address
  target      = google_compute_vpn_gateway.vpn_gateway.self_link
  region      = var.region
}

# Forwarding rules para UDP 500 (IKE)
resource "google_compute_forwarding_rule" "fr_udp500" {
  name        = "fr-udp500"
  ip_protocol = "UDP"
  port_range  = "500"
  ip_address  = google_compute_address.vpn_gateway_ip.address
  target      = google_compute_vpn_gateway.vpn_gateway.self_link
  region      = var.region
}

# Forwarding rules para UDP 4500 (NAT-T)
resource "google_compute_forwarding_rule" "fr_udp4500" {
  name        = "fr-udp4500"
  ip_protocol = "UDP"
  port_range  = "4500"
  ip_address  = google_compute_address.vpn_gateway_ip.address
  target      = google_compute_vpn_gateway.vpn_gateway.self_link
  region      = var.region
}

# Ruta para el tráfico hacia la red on-premises
resource "google_compute_route" "route_onprem" {
  name       = "route-to-onprem"
  network    = google_compute_network.vpc.id
  dest_range = var.on_prem_cidr
  priority   = 1000

  next_hop_vpn_tunnel = google_compute_vpn_tunnel.tunnel_onprem.id

  depends_on = [
    google_compute_vpn_tunnel.tunnel_onprem,
    google_compute_network.vpc
  ]
}

# Firewall rule para permitir tráfico desde on-premises
resource "google_compute_firewall" "allow_onprem" {
  name    = "allow-challenge-onprem-traffic"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
  }

  allow {
    protocol = "udp"
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = [var.on_prem_cidr]
  target_tags   = ["allow-onprem"]
  description   = "Permitir tráfico desde red on-premises via VPN"
}

# Instancia VM de prueba para simular conectividad (opcional)
resource "google_compute_instance" "vpn_test_vm" {
  name         = "vpn-test-vm"
  machine_type = "e2-micro"
  zone         = "${var.region}-a"

  tags = ["vpn-test", "allow-onprem"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = 20
      type  = "pd-standard"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.private_subnet.name
    # Sin IP externa - acceso solo via VPN
  }

  metadata = {
    enable-oslogin = "TRUE"
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    apt-get update
    apt-get install -y iputils-ping telnet curl
    echo "VM lista para pruebas de conectividad VPN" > /var/log/startup.log
  EOT

  service_account {
    email  = google_service_account.vpn_test_sa.email
    scopes = ["cloud-platform"]
  }
}

# Service Account para VM de prueba VPN
resource "google_service_account" "vpn_test_sa" {
  account_id   = "vpn-test-sa"
  display_name = "Service Account para VM de prueba VPN"

  lifecycle {
    ignore_changes = [
      account_id, # Ignorar cambios en el account_id después de la creación
    ]
  }
}
# trigger workflow
