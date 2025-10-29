# Valores locales para nombres de recursos
# Esto permite generar nombres únicos y evitar conflictos 409

locals {
  # Nombres base desde variables
  db_instance_name    = var.db_instance_name
  storage_bucket_name = var.storage_bucket_name
  logs_bucket_name    = "${var.storage_bucket_name}-logs"

  # Networking
  vpc_name            = var.vpc_name
  private_subnet_name = var.private_subnet_name

  # VPN
  vpn_gateway_name    = "yappa-vpn-gateway"
  vpn_gateway_ip_name = "vpn-gateway-ip"
  vpn_tunnel_name     = "yappa-vpn-tunnel"

  # Service Accounts
  cloud_run_sa_name = "cloud-run-sa"
  admin_sa_name     = "admin-sa"
  backup_sa_name    = "backup-sa"
  vpn_test_sa_name  = "vpn-test-sa"
}
