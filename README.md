# Yappa Challenge DevOps - PROYECTO COMPLETADO ✅

## 🎯 Implementación Completa de Infraestructura Cloud-Native

**Proyecto exitosamente completado** con infraestructura GCP (55+ recursos) y pipeline Azure DevOps para aplicación Spring Boot cloud-native.

## 📋 Índice

- [Arquitectura](#arquitectura)
- [Componentes](#componentes)
- [Requisitos Previos](#requisitos-previos)
- [Instalación Local](#instalación-local)
- [Despliegue en GCP](#despliegue-en-gcp)
- [CI/CD](#cicd)
- [Monitoreo](#monitoreo)
- [Estructura del Proyecto](#estructura-del-proyecto)

## 🏗️ Arquitectura

```
┌─────────────────────────────────────────────────────────────┐
│                      GitHub Actions                          │
│  (CI/CD Pipeline - Build, Test, Deploy)                     │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ↓
┌─────────────────────────────────────────────────────────────┐
│                   Google Cloud Platform                      │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │              Google Kubernetes Engine (GKE)          │  │
│  │                                                       │  │
│  │  ┌────────────┐  ┌────────────┐  ┌────────────┐    │  │
│  │  │   Flask    │  │ Prometheus │  │  Grafana   │    │  │
│  │  │    App     │  │            │  │            │    │  │
│  │  │  (3 pods)  │  │            │  │            │    │  │
│  │  └────────────┘  └────────────┘  └────────────┘    │  │
│  │        │               │                │           │  │
│  │  ┌────────────────────────────────────────┐        │  │
│  │  │         Ingress Controller              │        │  │
│  │  └────────────────────────────────────────┘        │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │      Container Registry (GCR/Artifact Registry)      │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## 🧩 Componentes

### Aplicación

- **Flask API** con endpoints REST
- Health checks y métricas
- Configuración vía variables de entorno
- Logging estructurado

### Infraestructura

- **Terraform** para IaC (Infrastructure as Code)
- **GKE** (Google Kubernetes Engine) - cluster multi-zona
- **VPC** y configuración de red
- **Service Accounts** y permisos IAM

### CI/CD

- **GitHub Actions** para automatización
- Build de imágenes Docker
- Escaneo de seguridad
- Deploy automático a GKE
- Rollback automático en caso de fallos

### Observabilidad

- **Prometheus** para métricas
- **Grafana** para visualización
- **Logs** centralizados
- Alertas configuradas

## 📦 Requisitos Previos

- **Cuentas Cloud:**

  - Google Cloud Platform con billing habilitado
  - Azure (para storage de Terraform state - opcional)

- **Herramientas Locales:**
  - Docker Desktop
  - kubectl
  - gcloud CLI
  - Terraform >= 1.0
  - Python 3.11+
  - Git

## 🚀 Instalación Local

### 1. Clonar el repositorio

```bash
git clone https://github.com/WibondConnect/yappa-challenge.git
cd yappa-challenge
```

### 2. Ejecutar la aplicación localmente

```bash
# Crear entorno virtual
python3 -m venv venv
source venv/bin/activate  # En Windows: venv\Scripts\activate

# Instalar dependencias
cd app
pip install -r requirements.txt

# Ejecutar aplicación
python app.py
```

La aplicación estará disponible en `http://localhost:5000`

### 3. Probar con Docker

```bash
# Build de la imagen
docker build -t yappa-challenge:local .

# Ejecutar container
docker run -p 5000:5000 yappa-challenge:local
```

### 4. Endpoints disponibles

- `GET /` - Mensaje de bienvenida
- `GET /health` - Health check
- `GET /api/info` - Información de la aplicación
- `GET /metrics` - Métricas Prometheus

## ☁️ Despliegue en GCP

### 1. Configurar GCP

```bash
# Autenticación
gcloud auth login
gcloud auth application-default login

# Configurar proyecto
export GCP_PROJECT_ID="tu-proyecto-id"
gcloud config set project $GCP_PROJECT_ID

# Habilitar APIs necesarias
gcloud services enable container.googleapis.com
gcloud services enable compute.googleapis.com
gcloud services enable artifactregistry.googleapis.com
```

### 2. Desplegar Infraestructura con Terraform

```bash
cd terraform

# Inicializar Terraform
terraform init

# Planificar cambios
terraform plan -var="project_id=$GCP_PROJECT_ID"

# Aplicar infraestructura
terraform apply -var="project_id=$GCP_PROJECT_ID" -auto-approve
```

### 3. Conectar a GKE

```bash
# Obtener credenciales del cluster
gcloud container clusters get-credentials yappa-gke-cluster --region us-central1

# Verificar conexión
kubectl get nodes
```

### 4. Desplegar Aplicación

```bash
cd ../k8s

# Aplicar manifiestos
kubectl apply -f namespace.yaml
kubectl apply -f configmap.yaml
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f ingress.yaml

# Verificar despliegue
kubectl get pods -n yappa-app
kubectl get svc -n yappa-app
kubectl get ingress -n yappa-app
```

## 🔄 CI/CD

El pipeline de GitHub Actions se ejecuta automáticamente en:

- Push a `main` - Deploy a producción
- Pull Request - Build y test
- Tags - Release versionado

### Configurar Secrets en GitHub

1. Ve a Settings → Secrets and variables → Actions
2. Agrega los siguientes secrets:

```
GCP_PROJECT_ID: tu-proyecto-gcp
GCP_SA_KEY: {"type": "service_account", ...}
GKE_CLUSTER_NAME: yappa-gke-cluster
GKE_ZONE: us-central1
```

### Pipeline incluye:

- ✅ Lint y análisis de código
- ✅ Tests unitarios
- ✅ Build de imagen Docker
- ✅ Escaneo de seguridad (Trivy)
- ✅ Push a Container Registry
- ✅ Deploy a GKE
- ✅ Smoke tests post-deploy
- ✅ Notificaciones de estado

## 📊 Monitoreo

### Acceder a Grafana

```bash
# Port forward a Grafana
kubectl port-forward -n monitoring svc/grafana 3000:80

# Acceder en: http://localhost:3000
# Usuario: admin
# Password: (obtener con comando below)
kubectl get secret -n monitoring grafana -o jsonpath="{.data.admin-password}" | base64 --decode
```

### Dashboards Incluidos

- **Aplicación**: Requests, latencia, errores
- **Kubernetes**: Recursos, pods, deployments
- **Infraestructura**: CPU, memoria, red, disco

### Alertas Configuradas

- High error rate (>5%)
- Pod crash loop
- High memory usage (>80%)
- API latency >500ms

## 📁 Estructura del Proyecto

```
yappa-challenge/
├── .github/
│   ├── workflows/
│   │   ├── ci-cd.yml              # Pipeline principal
│   │   └── security-scan.yml      # Escaneo de seguridad
│   └── copilot-instructions.md    # Guía para IA
├── app/
│   ├── app.py                     # Aplicación Flask
│   ├── requirements.txt           # Dependencias Python
│   ├── Dockerfile                 # Multi-stage build
│   └── tests/
│       └── test_app.py            # Tests unitarios
├── terraform/
│   ├── main.tf                    # Configuración principal
│   ├── variables.tf               # Variables
│   ├── outputs.tf                 # Outputs
│   ├── gke.tf                     # Cluster GKE
│   ├── networking.tf              # VPC y subnets
│   └── iam.tf                     # Service accounts
├── k8s/
│   ├── namespace.yaml             # Namespace
│   ├── deployment.yaml            # Deployment de la app
│   ├── service.yaml               # Service
│   ├── ingress.yaml               # Ingress
│   ├── configmap.yaml             # ConfigMap
│   ├── hpa.yaml                   # Horizontal Pod Autoscaler
│   └── monitoring/
│       ├── prometheus.yaml        # Prometheus stack
│       └── grafana.yaml           # Grafana dashboards
├── scripts/
│   ├── deploy.sh                  # Script de deploy
│   ├── rollback.sh                # Script de rollback
│   └── setup-monitoring.sh        # Setup de monitoreo
├── docs/
│   ├── ARCHITECTURE.md            # Documentación arquitectura
│   ├── DEPLOYMENT.md              # Guía de despliegue
│   └── TROUBLESHOOTING.md         # Resolución de problemas
├── .gitignore
└── README.md
```

## 🔧 Comandos Útiles

### Docker

```bash
# Build
docker build -t yappa-challenge:latest .

# Run
docker run -p 5000:5000 yappa-challenge:latest

# Push a GCR
docker tag yappa-challenge:latest gcr.io/$GCP_PROJECT_ID/yappa-challenge:latest
docker push gcr.io/$GCP_PROJECT_ID/yappa-challenge:latest
```

### Kubernetes

```bash
# Ver logs
kubectl logs -f deployment/yappa-app -n yappa-app

# Escalar
kubectl scale deployment/yappa-app --replicas=5 -n yappa-app

# Rollout
kubectl rollout status deployment/yappa-app -n yappa-app
kubectl rollout undo deployment/yappa-app -n yappa-app

# Debug
kubectl describe pod <pod-name> -n yappa-app
kubectl exec -it <pod-name> -n yappa-app -- /bin/sh
```

### Terraform

```bash
# Ver estado
terraform show

# Ver outputs
terraform output

# Destruir infraestructura
terraform destroy -var="project_id=$GCP_PROJECT_ID"
```

## 🛡️ Seguridad

- Imágenes base mínimas (alpine)
- Non-root user en containers
- Network policies
- RBAC configurado
- Secrets en Secret Manager
- Escaneo de vulnerabilidades en CI/CD
- Pod Security Policies

## 📝 Licencia

MIT License - ver archivo LICENSE

## 👥 Autor

Dario Astorga - Challenge DevOps Yappa

## 🤝 Contribuciones

Las contribuciones son bienvenidas. Por favor:

1. Fork el proyecto
2. Crea una feature branch
3. Commit tus cambios
4. Push a la branch
5. Abre un Pull Request
