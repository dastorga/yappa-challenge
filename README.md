# Yappa Challenge DevOps

## 🎯 Implementación Completa de Infraestructura Cloud-Native

**Proyecto exitosamente completado** con infraestructura GCP completa, aplicación Spring Boot 3.2 y CI/CD dual (Azure DevOps + GitHub Actions).

[![CI/CD Pipeline](https://github.com/dastorga/yappa-challenge/actions/workflows/ci-cd.yml/badge.svg)](https://github.com/dastorga/yappa-challenge/actions/workflows/ci-cd.yml)
[![Spring Boot](https://img.shields.io/badge/Spring%20Boot-3.2.0-brightgreen.svg)](https://spring.io/projects/spring-boot)
[![Java](https://img.shields.io/badge/Java-17-red.svg)](https://openjdk.java.net/projects/jdk/17/)
[![GCP](https://img.shields.io/badge/GCP-Cloud%20Run-4285F4.svg)](https://cloud.google.com/run)

## 📋 Índice

- [🏗️ Arquitectura](#️-arquitectura)
- [🧩 Componentes](#-componentes)
- [📦 Requisitos Previos](#-requisitos-previos)
- [🚀 Instalación Local](#-instalación-local)
- [☁️ Despliegue en GCP](#️-despliegue-en-gcp)
- [🔄 CI/CD](#-cicd)
- [📊 Monitoreo](#-monitoreo)
- [📁 Estructura del Proyecto](#-estructura-del-proyecto)
- [🔧 Comandos Útiles](#-comandos-útiles)

## 🏗️ Arquitectura

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                                   INTERNET                                      │
└─────────────────────────┬───────────────────────────────────────────────────────┘
                          │
┌─────────────────────────▼───────────────────────────────────────────────────────┐
│                          GOOGLE CLOUD PLATFORM                                 │
│                                                                                 │
│  ┌─────────────────┐    ┌──────────────────────────────────────────────────┐   │
│  │   Cloud Run     │    │                 VPC Network                      │   │
│  │                 │    │                                                  │   │
│  │ Spring Boot App │◄───┤  ┌─────────────────┐  ┌─────────────────────┐   │   │
│  │ - Java 17       │    │  │   Cloud SQL     │  │    Firestore        │   │   │
│  │ - Actuator      │    │  │   PostgreSQL    │  │    NoSQL DB         │   │   │
│  │ - Micrometer    │    │  │   10.2.0.3      │  │                     │   │   │
│  │ - Port 8080     │    │  └─────────────────┘  └─────────────────────┘   │   │
│  └─────────────────┘    │                                                  │   │
│           │              │  ┌─────────────────┐  ┌─────────────────────┐   │   │
│           │              │  │  Cloud Storage  │  │  Artifact Registry  │   │   │
│           │              │  │  Static Files   │  │  Docker Images      │   │   │
│  ┌─────────────────┐    │  └─────────────────┘  └─────────────────────┘   │   │
│  │  VPC Connector  │◄───┤                                                  │   │
│  │  Private Egress │    │  ┌─────────────────┐  ┌─────────────────────┐   │   │
│  └─────────────────┘    │  │     VPN         │  │    Memorystore      │   │   │
│                          │  │  On-premises    │  │     Redis           │   │   │
│                          │  │   Connection    │  │                     │   │   │
│                          │  └─────────────────┘  └─────────────────────┘   │   │
│                          └──────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────────┐
│                              CI/CD PIPELINES                                    │
│                                                                                 │
│  GitHub Actions:                    Azure DevOps:                             │
│  ┌─────────────────┐                ┌─────────────────────────────────────┐    │
│  │ 1. Maven Build  │                │ 1. Maven Build & Test               │    │
│  │ 2. Docker Push  │                │ 2. Docker Build & Push              │    │
│  │ 3. Cloud Run    │                │ 3. Cloud Run Deploy                 │    │
│  │ 4. Terraform    │                │ 4. Terraform Plan & Apply           │    │
│  └─────────────────┘                └─────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────────────────┘
```

## 🧩 Componentes

### Aplicación Spring Boot 3.2

- **Framework**: Spring Boot 3.2.0 con Java 17
- **Puerto**: 8080 (no 5000 como Flask)
- **Actuator**: Health checks y métricas en `/actuator/*`
- **Micrometer**: Métricas para Prometheus en `/actuator/prometheus`
- **Profiles**: `dev`, `prod` con configuraciones específicas
- **Container**: Docker multi-stage con JRE Alpine optimizado

### Infraestructura GCP (55+ recursos Terraform)

- **Cloud Run**: Serverless container platform principal
- **Cloud SQL**: PostgreSQL 14 en IP privada (10.2.0.3)
- **Firestore**: NoSQL database para datos no estructurados
- **Cloud Storage**: Almacenamiento de archivos estáticos
- **VPC Network**: Red privada con subredes regionales
- **VPC Connector**: Conectividad privada Cloud Run ↔ VPC
- **Artifact Registry**: Repositorio Docker privado
- **Memorystore**: Redis para caché distribuido
- **Cloud VPN**: Conexión segura a on-premises
- **IAM**: Service accounts con permisos mínimos

### CI/CD Dual

- **GitHub Actions**: Pipeline automático completo
- **Azure DevOps**: Pipeline alternativo con manual gcloud SDK

## 📦 Requisitos Previos

- **Cuentas Cloud:**

  - Google Cloud Platform con billing habilitado
  - GitHub Account (para Actions)
  - Azure DevOps (opcional)

- **Herramientas Locales:**

  - Java 17 (OpenJDK o Temurin)
  - Maven 3.9+
  - Docker Desktop
  - gcloud CLI
  - Terraform >= 1.6.0
  - Git

- **GCP APIs Habilitadas:**
  ```bash
  gcloud services enable run.googleapis.com
  gcloud services enable sql-component.googleapis.com
  gcloud services enable artifactregistry.googleapis.com
  gcloud services enable compute.googleapis.com
  gcloud services enable vpcaccess.googleapis.com
  gcloud services enable redis.googleapis.com
  ```

## 🚀 Instalación Local

### 1. Clonar el repositorio

```bash
git clone https://github.com/dastorga/yappa-challenge.git
cd yappa-challenge
```

### 2. Ejecutar Spring Boot localmente

```bash
cd app

# Compilar con Maven
mvn clean compile

# Ejecutar tests
mvn test

# Ejecutar aplicación
mvn spring-boot:run

# O con JAR compilado
mvn package -DskipTests
java -jar target/yappa-challenge-devops-1.0.0.jar
```

La aplicación estará disponible en `http://localhost:8080`

### 3. Probar con Docker

```bash
cd app

# Build de la imagen (multi-stage)
docker build -t yappa-challenge:local .

# Ejecutar container
docker run -p 8080:8080 \
  -e ENVIRONMENT=dev \
  -e LOG_LEVEL=DEBUG \
  yappa-challenge:local
```

### 4. Endpoints disponibles

**Principales:**

- `GET /` - Mensaje de bienvenida
- `GET /api/info` - Información completa (JVM, threads, uptime)
- `GET|POST /api/echo` - Endpoint de testing

**Actuator (Spring Boot):**

- `GET /actuator/health` - Health check general
- `GET /actuator/health/liveness` - Liveness probe K8s
- `GET /actuator/health/readiness` - Readiness probe K8s
- `GET /actuator/metrics` - Métricas disponibles
- `GET /actuator/prometheus` - Métricas formato Prometheus
- `GET /actuator/info` - Info de la aplicación

## ☁️ Despliegue en GCP

### 1. Configurar GCP

```bash
# Autenticación
gcloud auth login
gcloud auth application-default login

# Configurar proyecto
export GCP_PROJECT_ID="yappa-challenge-devops"
gcloud config set project $GCP_PROJECT_ID

# Habilitar APIs necesarias (ver requisitos previos)
```

### 2. Despliegue Automático (Recomendado)

```bash
# Usar el script de deploy automatizado
export GCP_PROJECT_ID="yappa-challenge-devops"
./scripts/deploy.sh
```

El script ejecuta automáticamente:

- ✅ Terraform plan & apply (55+ recursos)
- ✅ Docker build & push a Artifact Registry
- ✅ Cloud Run deploy con configuración optimizada
- ✅ Smoke tests de endpoints

### 3. Despliegue Manual

#### 3.1 Infraestructura con Terraform

```bash
cd terraform

# Inicializar Terraform
terraform init

# Planificar cambios (revisar 55+ recursos)
terraform plan -var="project_id=$GCP_PROJECT_ID"

# Aplicar infraestructura completa
terraform apply -var="project_id=$GCP_PROJECT_ID"

# Ver outputs importantes
terraform output
```

#### 3.2 Construir y Subir Imagen

```bash
cd app

# Configurar Artifact Registry
gcloud auth configure-docker us-central1-docker.pkg.dev

# Build y push
docker build -t us-central1-docker.pkg.dev/$GCP_PROJECT_ID/yappa-repo/yappa-spring-boot-service:latest .
docker push us-central1-docker.pkg.dev/$GCP_PROJECT_ID/yappa-repo/yappa-spring-boot-service:latest
```

#### 3.3 Deploy a Cloud Run

```bash
gcloud run deploy yappa-spring-boot-service \
  --image=us-central1-docker.pkg.dev/$GCP_PROJECT_ID/yappa-repo/yappa-spring-boot-service:latest \
  --region=us-central1 \
  --platform=managed \
  --allow-unauthenticated \
  --memory=1Gi \
  --cpu=1 \
  --max-instances=10 \
  --min-instances=1 \
  --port=8080 \
  --set-env-vars="SPRING_PROFILES_ACTIVE=dev,ENVIRONMENT=dev,GCP_PROJECT_ID=$GCP_PROJECT_ID,CLOUD_SQL_INSTANCE_IP=10.2.0.3" \
  --vpc-connector=projects/$GCP_PROJECT_ID/locations/us-central1/connectors/yappa-vpc-connector \
  --vpc-egress=private-ranges-only
```

### 4. Verificar Despliegue

```bash
# Obtener URL del servicio
SERVICE_URL=$(gcloud run services describe yappa-spring-boot-service \
  --region=us-central1 \
  --format='value(status.url)')

echo "Servicio desplegado en: $SERVICE_URL"

# Smoke tests
curl -f "$SERVICE_URL/"
curl -f "$SERVICE_URL/actuator/health"
curl -f "$SERVICE_URL/api/info"
```

## 🔄 CI/CD

### GitHub Actions Pipeline (Principal)

El pipeline se ejecuta automáticamente en:

- **Push a `main`** → Deploy completo a Cloud Run
- **Push a `develop`** → Build y test únicamente
- **Pull Request** → Build, test y validación
- **Cambios en** `app/`, `terraform/`, `.github/workflows/`

#### Configurar Secrets en GitHub

1. Ve a **Settings** → **Secrets and variables** → **Actions**
2. Agrega el secret requerido:

```bash
# Generar service account key
gcloud iam service-accounts keys create azure-devops-key.json \
  --iam-account=azure-devops-pipeline@yappa-challenge-devops.iam.gserviceaccount.com

# Base64 encode para GitHub
base64 -i azure-devops-key.json

# Agregar como GCP_SERVICE_ACCOUNT_KEY en GitHub Secrets
```

3. Configurar environment 'dev' con el secret

#### Jobs del Pipeline

```yaml
jobs:
  build-and-test: # Maven compile, test, package
  docker-build-push: # Docker build → Artifact Registry
  deploy-cloud-run: # Cloud Run deploy + smoke tests
  terraform-plan: # Terraform validate + plan
  terraform-apply: # Terraform apply (solo main)
```

### Azure DevOps Pipeline (Alternativo)

Configurado en `azure-pipelines.yml` con las mismas etapas pero bloqueado por limitación de paralelismo de Microsoft.

**Para habilitar Azure DevOps:**

1. Solicitar paralelismo gratuito: [aka.ms/azpipelines-parallelism-request](https://aka.ms/azpipelines-parallelism-request)
2. O configurar self-hosted agent
3. Configurar variables: `GCP_PROJECT_ID`, `GCP_SERVICE_ACCOUNT_KEY`

### Pipeline incluye:

- ✅ **Maven Build**: Compile, test, package con cache
- ✅ **Docker Multi-stage**: Optimizado para Spring Boot
- ✅ **Security Scanning**: Vulnerabilidades en dependencias
- ✅ **Artifact Registry**: Push a repositorio privado GCP
- ✅ **Cloud Run Deploy**: Con VPC connector y env vars
- ✅ **Terraform**: Plan siempre, apply solo en main
- ✅ **Smoke Tests**: Health checks post-deploy
- ✅ **Environment Protection**: Ambiente 'dev' protegido

## 📊 Monitoreo

### Métricas Nativas de Spring Boot

La aplicación expone métricas completas vía **Micrometer** en formato Prometheus:

```bash
# Métricas principales
curl https://SERVICE_URL/actuator/prometheus | grep -E "(http_server_requests|jvm_memory|jvm_gc)"

# Métricas específicas
curl https://SERVICE_URL/actuator/metrics/http.server.requests
curl https://SERVICE_URL/actuator/metrics/jvm.memory.used?tag=area:heap
curl https://SERVICE_URL/actuator/metrics/jvm.threads.live
```

### Métricas Clave Disponibles

**HTTP Requests:**

- `http_server_requests_seconds_count{status,method,uri}` - Contador de requests
- `http_server_requests_seconds_bucket` - Latencia en buckets (P50, P95, P99)
- `http_server_requests_seconds_sum` - Tiempo total de requests

**JVM Memory:**

- `jvm_memory_used_bytes{area="heap"}` - Memoria heap utilizada
- `jvm_memory_max_bytes{area="heap"}` - Memoria heap máxima
- `jvm_gc_pause_seconds_*` - Métricas de Garbage Collection

**Application:**

- `application_started_time_seconds` - Tiempo de startup
- `process_uptime_seconds` - Tiempo de funcionamiento
- `system_cpu_usage` - Uso de CPU del sistema

### Cloud Operations Suite (Stackdriver)

Las métricas de **Cloud Run** se integran automáticamente con **Cloud Monitoring**:

```bash
# Ver métricas en Cloud Console
echo "https://console.cloud.google.com/monitoring/metrics-explorer?project=$GCP_PROJECT_ID"

# Métricas de Cloud Run disponibles:
# - run.googleapis.com/container/cpu/utilizations
# - run.googleapis.com/container/memory/utilizations
# - run.googleapis.com/request_count
# - run.googleapis.com/request_latencies
```

### Alertas Recomendadas

Configurable via Cloud Monitoring:

- **Error Rate > 5%**: Requests con status 5xx
- **High Latency > 2s**: P95 de latencia de requests
- **Memory Usage > 85%**: Uso de memoria del container
- **High CPU > 80%**: Utilización de CPU sostenida
- **Health Check Failures**: Fallas en actuator/health

## 📁 Estructura del Proyecto

```
yappa-challenge/
├── .github/
│   ├── workflows/
│   │   └── ci-cd.yml              # GitHub Actions pipeline
│   └── copilot-instructions.md    # Guía para IA agents
├── app/                           # 📱 Spring Boot Application
│   ├── src/
│   │   ├── main/
│   │   │   ├── java/com/yappa/challenge/
│   │   │   │   ├── YappaChallengeApplication.java  # Main class
│   │   │   │   ├── controller/
│   │   │   │   │   ├── HomeController.java         # REST endpoints
│   │   │   │   │   └── ApiController.java          # API endpoints
│   │   │   │   ├── service/
│   │   │   │   │   └── InfoService.java            # Business logic
│   │   │   │   ├── model/
│   │   │   │   │   └── InfoResponse.java           # DTOs
│   │   │   │   └── config/
│   │   │   │       └── ActuatorConfig.java         # Actuator config
│   │   │   └── resources/
│   │   │       ├── application.yml                 # Main config
│   │   │       ├── application-dev.yml             # Dev profile
│   │   │       └── application-prod.yml            # Prod profile
│   │   └── test/
│   │       └── java/com/yappa/challenge/
│   │           └── YappaChallengeApplicationTests.java  # Tests
│   ├── pom.xml                    # Maven dependencies
│   ├── Dockerfile                 # Multi-stage Docker build
│   └── .dockerignore              # Docker ignore rules
├── terraform/                     # 🏗️ Infrastructure as Code
│   ├── main.tf                    # Main Terraform config
│   ├── variables.tf               # Input variables
│   ├── outputs.tf                 # Output values
│   ├── providers.tf               # GCP provider config
│   ├── cloud-run.tf              # Cloud Run service
│   ├── cloud-sql.tf              # PostgreSQL database
│   ├── networking.tf             # VPC, subnets, firewall
│   ├── storage.tf                # Cloud Storage buckets
│   ├── firestore.tf              # NoSQL database
│   ├── memorystore.tf            # Redis cache
│   ├── artifact-registry.tf      # Docker registry
│   ├── vpc-connector.tf          # Private connectivity
│   ├── vpn.tf                    # VPN to on-premises
│   ├── iam.tf                    # Service accounts & IAM
│   └── terraform.tf              # Terraform version constraints
├── scripts/                       # 🚀 Deployment Scripts
│   ├── deploy.sh                  # Automated deployment
│   └── rollback.sh                # Rollback script
├── docs/                          # 📚 Documentation
│   ├── ARCHITECTURE.md            # System architecture
│   ├── DEPLOYMENT.md              # Deployment guide
│   └── TROUBLESHOOTING.md         # Common issues
├── azure-pipelines.yml            # Azure DevOps pipeline
├── .gitignore                     # Git ignore rules
└── README.md                      # This file
```

## 🔧 Comandos Útiles

### Maven & Spring Boot

```bash
cd app

# Compilar
mvn clean compile

# Tests con coverage
mvn test
mvn jacoco:report  # Coverage report en target/site/jacoco/

# Ejecutar aplicación
mvn spring-boot:run
mvn spring-boot:run -Dspring-boot.run.profiles=dev

# Package JAR
mvn clean package -DskipTests
java -jar target/yappa-challenge-devops-1.0.0.jar

# Debug mode
mvn spring-boot:run -Dspring-boot.run.jvmArguments="-Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=y,address=5005"
```

### Docker

```bash
cd app

# Build multi-stage
docker build -t yappa-challenge:latest .

# Run con variables de entorno
docker run -p 8080:8080 \
  -e ENVIRONMENT=dev \
  -e LOG_LEVEL=DEBUG \
  -e JAVA_OPTS="-Xms256m -Xmx512m" \
  yappa-challenge:latest

# Push a Artifact Registry
export REGISTRY_URL="us-central1-docker.pkg.dev/yappa-challenge-devops/yappa-repo"
docker tag yappa-challenge:latest $REGISTRY_URL/yappa-spring-boot-service:latest
docker push $REGISTRY_URL/yappa-spring-boot-service:latest
```

### Cloud Run

```bash
# Ver logs en tiempo real
gcloud run services logs tail yappa-spring-boot-service --region=us-central1

# Actualizar configuración
gcloud run services update yappa-spring-boot-service \
  --region=us-central1 \
  --memory=2Gi \
  --cpu=2

# Ver métricas
gcloud run services describe yappa-spring-boot-service \
  --region=us-central1 \
  --format="get(status.url,status.conditions)"

# Rollback a versión anterior
gcloud run services update-traffic yappa-spring-boot-service \
  --region=us-central1 \
  --to-revisions=REVISION-NAME=100
```

### Terraform

```bash
cd terraform

# Ver estado actual
terraform show
terraform state list

# Ver outputs específicos
terraform output cloud_run_url
terraform output cloud_sql_ip
terraform output artifact_registry_url

# Importar recursos existentes
terraform import google_cloud_run_service.yappa projects/PROJECT/locations/REGION/services/SERVICE

# Destruir infraestructura
terraform destroy -var="project_id=$GCP_PROJECT_ID"
```

### Debugging y Monitoreo

```bash
# Health checks
curl -f https://SERVICE_URL/actuator/health
curl -f https://SERVICE_URL/actuator/health/liveness
curl -f https://SERVICE_URL/actuator/health/readiness

# Métricas Prometheus
curl https://SERVICE_URL/actuator/prometheus

# Info de JVM
curl https://SERVICE_URL/actuator/metrics/jvm.memory.used
curl https://SERVICE_URL/actuator/metrics/jvm.threads.live
curl https://SERVICE_URL/actuator/metrics/http.server.requests

# Thread dump (útil para debugging)
curl https://SERVICE_URL/actuator/threaddump
```

## 🛡️ Seguridad

### Container Security

- **Base Image**: Eclipse Temurin 17 JRE Alpine (minimal)
- **Non-root User**: Container ejecuta como UID 1000
- **Multi-stage Build**: Artifacts de build no incluidos en imagen final
- **Security Scanning**: Dependencias Maven escaneadas en CI/CD

### Network Security

- **VPC Private**: Cloud Run conecta via VPC Connector
- **Private IPs**: Cloud SQL en IP privada (10.2.0.3)
- **Firewall Rules**: Tráfico restringido por reglas específicas
- **VPN Gateway**: Conexión segura a on-premises

### Access Control

- **IAM Roles**: Service accounts con permisos mínimos requeridos
- **Secret Manager**: Credenciales almacenadas de forma segura
- **OAuth 2.0**: Autenticación para APIs de GCP
- **Environment Protection**: GitHub Actions con environment 'dev' protegido

### Service Accounts

```bash
# Service account principal para CI/CD
azure-devops-pipeline@yappa-challenge-devops.iam.gserviceaccount.com

# Roles asignados:
# - Artifact Registry Writer
# - Cloud Run Admin
# - Cloud SQL Admin
# - Compute Admin
# - Editor (para Terraform)
```

## 🚀 Próximos Pasos

- [ ] Configurar **Cloud Armor** para protección DDoS
- [ ] Implementar **Identity-Aware Proxy** para autenticación
- [ ] Agregar **Cloud CDN** para contenido estático
- [ ] Configurar **Multi-region** para alta disponibilidad
- [ ] Implementar **Blue-Green Deployment** en Cloud Run
- [ ] Agregar **Chaos Engineering** con Gremlin

## 📊 Métricas del Proyecto

- **📦 Recursos Terraform**: 55+ recursos desplegados
- **🏗️ Líneas de Código**: ~2,000 líneas (Spring Boot + IaC)
- **⚡ Tiempo de Deploy**: ~8-12 minutos (completo)
- **🔄 Pipeline Duration**: ~5-7 minutos (GitHub Actions)
- **💰 Costo Estimado**: $15-30 USD/mes (con tráfico mínimo)

## 📝 Licencia

MIT License - ver archivo [LICENSE](LICENSE)

## 👥 Autor

**Dario Maximiliano Astorga**  
DevOps Engineer - Yappa Challenge  
📧 [dario.astorga@ejemplo.com](mailto:dario.astorga@ejemplo.com)  
🐙 [GitHub](https://github.com/dastorga)  
💼 [LinkedIn](https://linkedin.com/in/dario-astorga)

## 🤝 Contribuciones

Las contribuciones son bienvenidas! Por favor sigue estos pasos:

1. **Fork** el proyecto
2. **Crear** feature branch: `git checkout -b feature/nueva-funcionalidad`
3. **Commit** cambios: `git commit -am 'feat: agregar nueva funcionalidad'`
4. **Push** a branch: `git push origin feature/nueva-funcionalidad`
5. **Abrir** Pull Request

### Convenciones

- **Commits**: Seguir [Conventional Commits](https://conventionalcommits.org/es/)
- **Branches**: `feature/`, `bugfix/`, `hotfix/`
- **Tests**: Agregar tests para nueva funcionalidad
- **Docs**: Actualizar documentación relevante

---

## 🎯 Challenge Completado

✅ **Infraestructura GCP** - 55+ recursos con Terraform  
✅ **Aplicación Spring Boot** - Java 17 con Actuator y Micrometer  
✅ **CI/CD Dual** - GitHub Actions + Azure DevOps  
✅ **Monitoreo Nativo** - Métricas Prometheus + Cloud Monitoring  
✅ **Seguridad** - VPC privada + IAM + Container security  
✅ **Documentación** - README completo + guías técnicas

**Tiempo Total**: ~40 horas  
**Tecnologías**: Spring Boot, GCP, Terraform, Docker, GitHub Actions  
**Resultado**: Infraestructura cloud-native production-ready 🚀
