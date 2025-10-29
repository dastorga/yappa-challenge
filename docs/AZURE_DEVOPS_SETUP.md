# Configuración Azure DevOps Pipeline - Yappa Challenge DevOps

## Resumen del Pipeline

Pipeline completo de CI/CD que automatiza:

1. **Compilación Maven** - Compila proyecto Spring Boot con Java 17
2. **Docker Build & Push** - Construye imagen y publica en Google Artifact Registry
3. **Deploy Cloud Run** - Despliega automáticamente en entorno dev
4. **Terraform Infrastructure** - Maneja infraestructura como código

## Prerrequisitos

### 1. Proyecto Azure DevOps

- Crear nuevo proyecto en Azure DevOps
- Conectar repositorio GitHub/Azure Repos
- Habilitar Azure Pipelines

### 2. Service Account GCP

```bash
# Crear service account con permisos necesarios
gcloud iam service-accounts create azure-devops-pipeline \
  --description="Service account for Azure DevOps pipeline" \
  --display-name="Azure DevOps Pipeline"

# Asignar roles necesarios
gcloud projects add-iam-policy-binding yappa-challenge-devops-442003 \
  --member="serviceAccount:azure-devops-pipeline@yappa-challenge-devops-442003.iam.gserviceaccount.com" \
  --role="roles/artifactregistry.writer"

gcloud projects add-iam-policy-binding yappa-challenge-devops-442003 \
  --member="serviceAccount:azure-devops-pipeline@yappa-challenge-devops-442003.iam.gserviceaccount.com" \
  --role="roles/run.admin"

gcloud projects add-iam-policy-binding yappa-challenge-devops-442003 \
  --member="serviceAccount:azure-devops-pipeline@yappa-challenge-devops-442003.iam.gserviceaccount.com" \
  --role="roles/compute.admin"

gcloud projects add-iam-policy-binding yappa-challenge-devops-442003 \
  --member="serviceAccount:azure-devops-pipeline@yappa-challenge-devops-442003.iam.gserviceaccount.com" \
  --role="roles/editor"

# Generar clave JSON
gcloud iam service-accounts keys create azure-devops-key.json \
  --iam-account=azure-devops-pipeline@yappa-challenge-devops-442003.iam.gserviceaccount.com
```

## Configuración de Variables en Azure DevOps

### Variables Requeridas (Secrets)

Ir a **Pipelines → Library → Variable Groups** o **Pipeline Settings → Variables**

| Variable                  | Valor                                                                 | Descripción                     |
| ------------------------- | --------------------------------------------------------------------- | ------------------------------- |
| `GCP_PROJECT_ID`          | `yappa-challenge-devops-442003`                                       | ID del proyecto GCP             |
| `GCP_SERVICE_ACCOUNT_KEY` | `<contenido-base64-del-json>`                                         | Clave JSON codificada en base64 |
| `ARTIFACT_REGISTRY_URL`   | `us-central1-docker.pkg.dev/yappa-challenge-devops-442003/yappa-repo` | URL del registry                |
| `CLOUD_SQL_INSTANCE_IP`   | `10.2.0.3`                                                            | IP privada de Cloud SQL         |

### Codificar Service Account Key

```bash
# Codificar la clave JSON en base64
base64 -i azure-devops-key.json | tr -d '\n'
# Copiar el resultado y pegarlo en GCP_SERVICE_ACCOUNT_KEY
```

### Variables de Pipeline (No secretas)

Las siguientes variables están definidas en el YAML:

- `projectName: 'yappa-challenge-devops'`
- `artifactRegistryRegion: 'us-central1'`
- `cloudRunRegion: 'us-central1'`
- `environment: 'dev'`
- `serviceName: 'yappa-spring-boot-service'`

## Service Connection (Alternativa)

Como alternativa a las variables, puedes crear un Service Connection:

1. **Project Settings → Service Connections**
2. **New Service Connection → Google Cloud Platform**
3. **Service Account Key** method
4. Upload el archivo `azure-devops-key.json`
5. Nombrar: `gcp-connection`
6. **Verify and save**

Si usas Service Connection, modifica los steps de autenticación:

```yaml
- task: GoogleCloudPlatform@0
  displayName: "Authenticate with GCP"
  inputs:
    serviceConnection: "gcp-connection"
    scriptType: "bash"
    script: |
      gcloud config set project $(GCP_PROJECT_ID)
      gcloud auth configure-docker $(artifactRegistryRegion)-docker.pkg.dev
```

## Configuración del Repository

### 1. Archivo azure-pipelines.yml

El archivo `azure-pipelines.yml` debe estar en la raíz del repositorio.

### 2. Branch Policies

Configurar branch protection rules:

- Require pull request reviews
- Require status checks (pipeline)
- Restrict pushes to main branch

### 3. Pipeline Triggers

El pipeline se ejecuta automáticamente en:

- Push a `main` o `develop`
- Pull requests hacia `main` o `develop`
- Cambios en carpetas: `app/`, `terraform/`, `azure-pipelines.yml`

## Stages del Pipeline

### Stage 1: Build and Test

- **Job: MavenBuild**
  - Instala Java 17
  - Cachea dependencias Maven
  - Compila proyecto (`mvn clean compile`)
  - Ejecuta tests (`mvn test`)
  - Empaqueta JAR (`mvn package`)
  - Publica artifacts

### Stage 2: Docker Build and Push

- **Job: DockerBuildPush**
  - Descarga artifacts de compilación
  - Autentica con GCP
  - Construye imagen Docker
  - Publica en Artifact Registry con tags:
    - `latest`
    - `$(Build.BuildNumber)` (versioned)

### Stage 3: Deploy to Cloud Run

- **Deployment: DeployCloudRun**
  - Environment: `dev`
  - Despliega imagen en Cloud Run
  - Configura variables de entorno
  - Conecta a VPC privada
  - Ejecuta health checks
  - Prueba endpoints básicos

### Stage 4: Terraform Infrastructure

- **Job: TerraformPlan**

  - Ejecuta en paralelo con Build
  - Instala Terraform
  - Autentica con GCP
  - Ejecuta `terraform plan`
  - Publica plan como artifact

- **Job: TerraformApply**
  - Solo en branch `main`
  - Descarga plan de Terraform
  - Ejecuta `terraform apply`
  - Aplica cambios de infraestructura

## Configuración de Environments

### 1. Crear Environment 'dev'

1. **Pipelines → Environments**
2. **New Environment**
3. **Name:** `dev`
4. **Description:** `Development environment for Cloud Run`

### 2. Approval Gates (Opcional)

Para production:

1. **Environment → Approvals and checks**
2. **Add check → Approvals**
3. Configurar usuarios que deben aprobar

### 3. Variable Scoping

Variables específicas por environment:

```yaml
- group: "dev-variables"
  condition: eq(variables['Environment'], 'dev')
- group: "prod-variables"
  condition: eq(variables['Environment'], 'prod')
```

## Monitoreo y Troubleshooting

### Logs del Pipeline

```bash
# Ver logs en Azure DevOps
Pipelines → Runs → [Run específico] → Jobs → Logs

# Filtrar por job específico:
- MavenBuild logs
- DockerBuildPush logs
- DeployCloudRun logs
- TerraformPlan/Apply logs
```

### Troubleshooting Común

#### 1. Error de Autenticación GCP

```
Error: (gcloud.auth.activate-service-account) invalid_grant
```

**Solución:**

- Verificar que GCP_SERVICE_ACCOUNT_KEY está codificado correctamente en base64
- Verificar que el service account tiene los permisos necesarios
- Regenerar la clave si es muy antigua

#### 2. Error de Docker Push

```
Error: denied: Permission "artifactregistry.repositories.uploadArtifacts" denied
```

**Solución:**

- Verificar rol `roles/artifactregistry.writer`
- Verificar que el repository existe en Artifact Registry
- Verificar autenticación Docker: `gcloud auth configure-docker`

#### 3. Cloud Run Deploy Error

```
Error: (gcloud.run.deploy) PERMISSION_DENIED
```

**Solución:**

- Verificar rol `roles/run.admin`
- Verificar que el VPC connector existe
- Verificar región correcta

#### 4. Terraform Errors

```
Error: google: could not find default credentials
```

**Solución:**

- Verificar variable `GOOGLE_APPLICATION_CREDENTIALS`
- Verificar autenticación del service account
- Verificar permisos de Terraform (`roles/editor`)

### Health Checks del Deployment

El pipeline incluye verificaciones automáticas:

```bash
# Endpoints verificados automáticamente:
curl -f "$SERVICE_URL/"                 # Root endpoint
curl -f "$SERVICE_URL/actuator/health"  # Spring Boot health
curl -f "$SERVICE_URL/api/info"         # App info endpoint
```

## Extensiones Recomendadas

### Azure DevOps Extensions

1. **Google Cloud Tools** - Facilita integración con GCP
2. **Terraform** - Tasks específicas para Terraform
3. **SonarQube** - Análisis de calidad de código
4. **WhiteSource Bolt** - Escaneo de vulnerabilidades

### Pipeline Templates

Para reutilizar configuración:

```yaml
# templates/maven-build.yml
parameters:
  - name: pomPath
    default: "app/pom.xml"

steps:
  - task: Maven@3
    displayName: "Maven Build"
    inputs:
      mavenPomFile: "${{ parameters.pomPath }}"
      goals: "clean compile test package"
```

## Comandos de Verificación Post-Deploy

```bash
# Verificar servicio desplegado
gcloud run services list --region=us-central1

# Verificar logs de Cloud Run
gcloud logs tail "resource.type=cloud_run_revision AND resource.labels.service_name=yappa-spring-boot-service"

# Test endpoints manualmente
SERVICE_URL=$(gcloud run services describe yappa-spring-boot-service --region=us-central1 --format='value(status.url)')
curl -X GET $SERVICE_URL/
curl -X GET $SERVICE_URL/actuator/health
curl -X GET $SERVICE_URL/api/info
curl -X POST $SERVICE_URL/api/echo -d '{"message":"test"}' -H "Content-Type: application/json"

# Verificar métricas
curl -X GET $SERVICE_URL/actuator/metrics
curl -X GET $SERVICE_URL/actuator/prometheus
```

## Seguridad

### 1. Secrets Management

- Nunca hardcodear credenciales en el código
- Usar Azure Key Vault para secrets sensibles
- Rotar service account keys periódicamente

### 2. Service Account Permissions

- Principio de menor privilegio
- Crear service accounts específicos por environment
- Auditar permisos regularmente

### 3. Network Security

- Cloud Run configurado con VPC privada
- Sin acceso público directo a Cloud SQL
- Firewall rules restrictivas

### 4. Container Security

- Escaneo de vulnerabilidades con Trivy
- Imágenes base actualizadas
- Usuario no-root en containers

Esta configuración proporciona un pipeline completo, seguro y escalable para el proyecto Yappa Challenge DevOps.
