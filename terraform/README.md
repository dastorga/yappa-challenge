# Infraestructura Terraform - Yappa Challenge

Esta configuración de Terraform crea toda la infraestructura necesaria en Google Cloud Platform para el proyecto Yappa Challenge.

## 📋 Componentes de Infraestructura

### 1. **Cloud SQL (PostgreSQL)**

- **Ubicación**: `southamerica-east1`
- **Versión**: PostgreSQL 15
- **Tier**: `db-f1-micro` (modificable)
- **Características**:
  - Instancia configurada con acceso privado desde la VPC
  - Base de datos y usuario inicial creados automáticamente
  - Backups automáticos habilitados (03:00 AM)
  - Configuración de logs (connections, disconnections, checkpoints)
  - Acceso **solo privado** (sin IP pública)

### 2. **Cloud Run**

- **Ubicación**: `southamerica-east1`
- **Características**:
  - Servicio desplegable para aplicación Spring Boot
  - Conectado a la VPC para acceso a Cloud SQL
  - Variables de entorno configuradas automáticamente:
    - `DB_HOST`: Conexión a Cloud SQL
    - `DB_NAME`: Nombre de la base de datos
    - `DB_USER`: Usuario de la base de datos
    - `DB_PASSWORD`: Password (desde secrets)
  - Service Account con permisos necesarios
  - Autoscaling configurado

### 3. **Firestore**

- **Modo**: Nativo
- **Ubicación**: `southamerica-east1`
- **Características**:
  - Creación automática mediante Terraform
  - Habilitado para uso inmediato

### 4. **Cloud Storage (Buckets)**

- **Bucket Principal**: Para artefactos y archivos temporales
- **Bucket de Logs**: Para logs de aplicación
- **Características**:
  - Versionado habilitado
  - Política de retención configurada (30 días)
  - Ubicación: `southamerica-east1`
  - Lifecycle rules para optimización de costos

### 5. **VPC Personalizada**

- **Nombre**: `yappa-vpc`
- **Subnet Privada**: `10.1.0.0/24` en `southamerica-east1`
- **Características**:
  - Sin subnets automáticas
  - Private Google Access habilitado
  - Conectividad con Cloud SQL mediante VPC Peering
  - Conectividad con Cloud Run mediante VPC Connector

### 6. **VPN**

- **Tipo**: Gateway VPN básico
- **Características**:
  - Configuración de VPN Gateway
  - IP externa reservada
  - Túnel VPN simulando conectividad con red on-prem o partner
  - Configuración de rutas personalizadas

## 🔧 Variables Requeridas

Las siguientes variables deben configurarse en GitHub Actions Secrets:

| Variable                  | Descripción                  | Ejemplo                   |
| ------------------------- | ---------------------------- | ------------------------- |
| `PROJECT_ID`              | ID del proyecto GCP          | `yappa-challenge-devops`  |
| `REGION`                  | Región de GCP                | `southamerica-east1`      |
| `DB_PASSWORD`             | Password para Cloud SQL      | `YappaSecure2024!`        |
| `STORAGE_BUCKET_NAME`     | Nombre del bucket principal  | `yappa-challenge-storage` |
| `PEER_EXTERNAL_IP`        | IP externa del peer VPN      | `203.0.113.1`             |
| `VPN_SHARED_SECRET`       | Secret compartido para VPN   | `SuperSecret123!`         |
| `GCP_SERVICE_ACCOUNT_KEY` | Service Account Key (base64) | `ewogICJ0eXBlIjo...`      |

## 🚀 Uso

### Despliegue Automático (CI/CD)

El pipeline de GitHub Actions se encarga de:

1. Compilar la aplicación Spring Boot
2. Crear toda la infraestructura con Terraform
3. Construir y publicar la imagen Docker
4. Desplegar en Cloud Run

### Despliegue Manual Local

```bash
# Inicializar Terraform
terraform init

# Planificar cambios
terraform plan \
  -var="project_id=yappa-challenge-devops" \
  -var="region=southamerica-east1" \
  -var="environment=dev" \
  -var="db_password=YourPassword" \
  -var="storage_bucket_name=yappa-storage" \
  -var="peer_external_ip=203.0.113.1" \
  -var="vpn_shared_secret=YourSecret"

# Aplicar cambios
terraform apply -auto-approve \
  -var="project_id=yappa-challenge-devops" \
  -var="region=southamerica-east1" \
  -var="environment=dev" \
  -var="db_password=YourPassword" \
  -var="storage_bucket_name=yappa-storage" \
  -var="peer_external_ip=203.0.113.1" \
  -var="vpn_shared_secret=YourSecret"

# Ver outputs
terraform output
```

## 📊 Outputs Importantes

Después del despliegue, Terraform mostrará:

- URL del servicio Cloud Run
- Connection name de Cloud SQL
- Nombre de la VPC y subnet
- Nombres de los buckets de storage
- IP del VPN Gateway
- Y más...

## 🔒 Seguridad

- **Cloud SQL**: Solo acceso privado desde la VPC
- **Service Accounts**: Permisos mínimos necesarios
- **Secrets**: Almacenados en GitHub Secrets
- **VPN**: Túnel encriptado con shared secret
- **Buckets**: Sin acceso público por defecto

## 📦 Backend de Estado

El estado de Terraform se almacena en:

- **Bucket GCS**: `yappa-challenge-tfstate`
- **Ruta**: `terraform/state`
- **Versionado**: Habilitado

## 🧹 Limpieza

Para destruir toda la infraestructura:

```bash
terraform destroy \
  -var="project_id=yappa-challenge-devops" \
  -var="region=southamerica-east1" \
  -var="environment=dev" \
  -var="db_password=YourPassword" \
  -var="storage_bucket_name=yappa-storage" \
  -var="peer_external_ip=203.0.113.1" \
  -var="vpn_shared_secret=YourSecret"
```

## 📝 Archivos de Configuración

- `main.tf`: Configuración principal y backend GCS
- `variables.tf`: Definición de variables
- `cloudsql.tf`: Cloud SQL PostgreSQL
- `cloudrun.tf`: Cloud Run service
- `firestore.tf`: Firestore en modo nativo
- `storage.tf`: Cloud Storage buckets
- `networking.tf`: VPC y subnets
- `vpn.tf`: VPN Gateway y túneles
- `iam.tf`: Service Accounts y permisos
- `outputs.tf`: Outputs de infraestructura
