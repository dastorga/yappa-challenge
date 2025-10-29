# 🚀 Pipeline CI/CD - Guía Completa

## ✅ Estado Actual

### Archivos Configurados

1. **`.github/workflows/ci-cd.yml`** - Pipeline único y optimizado
2. **`terraform/locals.tf`** - Definiciones de nombres de recursos
3. **Lifecycle protection** - Añadido a recursos críticos:
   - ✅ VPC (`google_compute_network.vpc`)
   - ✅ Subnet (`google_compute_subnetwork.private_subnet`)
   - ✅ Cloud SQL (`google_sql_database_instance.postgres_instance`)
   - ✅ Storage Buckets (principal y logs)
   - ✅ VPN Gateway y IP estática
   - ✅ Service Accounts (cloud-run-sa, admin-sa, backup-sa, vpn-test-sa)

### Backend de Terraform

- **Bucket**: `gs://yappa-challenge-tfstate`
- **Location**: `southamerica-east1`
- **Versionado**: Habilitado ✅
- **Prefix**: `terraform/state`

---

## 🔄 Cómo Funciona el Pipeline

### Primera Ejecución (Infraestructura Nueva)

```
1. 🗄️  Verifica/Crea el bucket de Terraform state
   └─ gs://yappa-challenge-tfstate

2. 🚀 terraform init
   └─ Conecta con el backend en GCS

3. ✅ terraform validate
   └─ Valida la sintaxis de Terraform

4. 🔄 terraform refresh
   └─ Sincroniza con GCP (vacío en primera ejecución)
   └─ State: 0 recursos

5. 📋 terraform plan
   └─ Detecta que TODO es nuevo (+)
   └─ Plan: +60 recursos a crear

6. 🏗️  terraform apply
   └─ CREA toda la infraestructura
   └─ Guarda el state en GCS
```

### Ejecuciones Siguientes (Infraestructura Existente)

```
1. 🗄️  Verifica el bucket de Terraform state
   └─ ✅ Bucket existe

2. 🚀 terraform init
   └─ Descarga el state existente desde GCS

3. ✅ terraform validate
   └─ Valida la sintaxis de Terraform

4. 🔄 terraform refresh
   └─ Sincroniza state con recursos reales en GCP
   └─ Detecta cambios manuales
   └─ State: 60 recursos sincronizados

5. 📋 terraform plan
   └─ Compara state vs configuración
   └─ Detecta:
       (+) = Recursos NUEVOS a crear
       (~) = Recursos EXISTENTES a actualizar
       (-) = Recursos a eliminar
       (nothing) = Sin cambios
   └─ Ejemplo: Plan: 2 to add, 1 to change, 0 to destroy

6. 🏗️  terraform apply
   └─ SOLO crea recursos nuevos
   └─ SOLO actualiza recursos modificados
   └─ NO recrea recursos protegidos (lifecycle)
   └─ Actualiza el state en GCS
```

---

## 🛡️ Protecciones Implementadas

### 1. Backend en GCS (State Compartido)

- ✅ State centralizado en Cloud Storage
- ✅ Versionado habilitado (recuperación de estados anteriores)
- ✅ Previene conflictos de múltiples ejecuciones
- ✅ State lock automático

### 2. Terraform Refresh

- ✅ Detecta recursos que existen en GCP
- ✅ Sincroniza el state con la realidad
- ✅ Previene intentos de recreación

### 3. Lifecycle Blocks (Recursos Críticos)

```hcl
lifecycle {
  prevent_destroy = true  # Protege contra eliminación accidental
  ignore_changes = [
    name,  # Ignora cambios en el nombre después de creación
  ]
}
```

**Recursos Protegidos:**

- VPC y Subnets
- Cloud SQL (base de datos)
- Storage Buckets
- VPN Gateway e IP estática
- Service Accounts

**Resultado**: Terraform NUNCA intentará recrear estos recursos una vez creados.

---

## 📊 Output del Pipeline

### Primera Ejecución

```
📭 No hay recursos en el state (PRIMERA EJECUCIÓN)
➡️  Terraform creará TODA la infraestructura

Plan: 60 to add, 0 to change, 0 to destroy
```

### Ejecuciones Siguientes

```
✅ State contiene 60 recursos
➡️  Terraform solo creará recursos NUEVOS o actualizará MODIFICADOS

Plan: 0 to add, 0 to change, 0 to destroy
# O si agregaste algo nuevo:
Plan: 2 to add, 1 to change, 0 to destroy
```

---

## 🎯 Casos de Uso

### Caso 1: Primer Deploy

```bash
git add .
git commit -m "Initial infrastructure"
git push origin main
```

**Resultado**: Crea toda la infraestructura desde cero ✅

### Caso 2: Agregar Nuevo Recurso

```bash
# Editas terraform/nuevos-recursos.tf
git add terraform/nuevos-recursos.tf
git commit -m "Add new Cloud Storage bucket"
git push origin main
```

**Resultado**:

- Mantiene 60 recursos existentes ✅
- Crea solo el nuevo bucket (+1) ✅

### Caso 3: Modificar Configuración

```bash
# Cambias el tier de Cloud SQL de db-f1-micro a db-g1-small
git add terraform/cloudsql.tf
git commit -m "Upgrade Cloud SQL tier"
git push origin main
```

**Resultado**:

- Mantiene 60 recursos existentes ✅
- Actualiza solo la configuración del Cloud SQL (~1) ✅
- NO recrea la base de datos ✅

### Caso 4: Pipeline Falla a Mitad

**Resultado**:

- State en GCS tiene recursos creados hasta el fallo ✅
- Siguiente ejecución continúa desde donde quedó ✅
- NO intenta recrear lo que ya existe ✅

---

## ❌ Errores 409 - ELIMINADOS

### Antes (Problema)

```
Error: Error creating Network: googleapi: Error 409:
The resource 'projects/yappa-challenge-devops/global/networks/yappa-vpc'
already exists, alreadyExists
```

### Después (Solución)

```
✅ terraform refresh detecta que yappa-vpc existe
✅ terraform plan marca 0 cambios para yappa-vpc
✅ terraform apply NO intenta recrear yappa-vpc
```

---

## 🚀 Cómo Ejecutar el Pipeline

### Opción 1: Push a Main (Recomendado)

```bash
cd /Users/darioastorga/yappa-challenge
git add .
git commit -m "Deploy infrastructure"
git push origin main
```

### Opción 2: Pull Request

```bash
git checkout -b feature/nueva-funcionalidad
# Haz cambios
git add .
git commit -m "Add new feature"
git push origin feature/nueva-funcionalidad
# Crea PR en GitHub
```

---

## 🔍 Verificación Local (Opcional)

### Validar Terraform sin aplicar

```bash
cd terraform

# Inicializar
terraform init

# Validar sintaxis
terraform validate

# Ver plan sin aplicar
terraform plan \
  -var="project_id=yappa-challenge-devops" \
  -var="region=southamerica-east1" \
  -var="environment=dev" \
  -var="db_password=TU_PASSWORD" \
  -var="storage_bucket_name=yappa-storage-bucket" \
  -var="peer_external_ip=0.0.0.0" \
  -var="vpn_shared_secret=secret123"
```

---

## 📝 Secretos Requeridos en GitHub

Asegúrate de tener estos secretos configurados en GitHub:

- Settings → Environments → dev → Secrets

```
GCP_SERVICE_ACCOUNT_KEY    # Service account key en base64
PROJECT_ID                 # yappa-challenge-devops
REGION                     # southamerica-east1
STORAGE_BUCKET_NAME        # yappa-storage-bucket
DB_PASSWORD                # Password de PostgreSQL
PEER_EXTERNAL_IP           # IP externa para VPN
VPN_SHARED_SECRET          # Secret compartido VPN
```

---

## ✅ Checklist Pre-Deploy

- [ ] Backend bucket existe: `gs://yappa-challenge-tfstate` ✅
- [ ] Versionado habilitado en bucket ✅
- [ ] Lifecycle blocks en recursos críticos ✅
- [ ] Archivo `locals.tf` creado ✅
- [ ] Pipeline único `ci-cd.yml` ✅
- [ ] Secretos configurados en GitHub
- [ ] Variables en `terraform.tfvars` o GitHub Secrets

---

## 🎉 Resultado Final

### Primera Ejecución

```
✅ Crea TODA la infraestructura (6 componentes):
   1. Cloud SQL PostgreSQL 15
   2. Cloud Run con Spring Boot
   3. Firestore Native
   4. Cloud Storage (2 buckets)
   5. VPC con subnet privada
   6. VPN Gateway con túnel

✅ Guarda state en GCS
✅ Sin errores 409
```

### Siguientes Ejecuciones

```
✅ Verifica bucket de state
✅ Descarga state existente
✅ Sincroniza con GCP (refresh)
✅ Detecta solo cambios necesarios
✅ Aplica solo lo nuevo/modificado
✅ NO recrea infraestructura existente
✅ Sin errores 409
```

---

## 🆘 Troubleshooting

### Si el pipeline falla con "state locked"

```bash
# El lock se libera automáticamente
# Si persiste, espera 5 minutos o:
cd terraform
terraform force-unlock LOCK_ID
```

### Si necesitas ver el state

```bash
cd terraform
terraform state list
terraform state show google_compute_network.vpc
```

### Si necesitas recuperar state anterior

```bash
# Versiones disponibles en:
gsutil ls -la gs://yappa-challenge-tfstate/terraform/state/
```

---

## 📌 Resumen Ejecutivo

**Lo que hace el pipeline:**

1. ✅ Primera vez: Crea TODO desde cero
2. ✅ Siguientes veces: Solo aplica cambios necesarios
3. ✅ NUNCA recrea recursos protegidos
4. ✅ State centralizado y versionado
5. ✅ Sin errores 409

**Lo que NO hace el pipeline:**

1. ❌ NO recrea infraestructura existente
2. ❌ NO ignora recursos en GCP
3. ❌ NO causa conflictos 409
4. ❌ NO pierde el state entre ejecuciones

---

¡Todo listo para ejecutar! 🚀
