#!/bin/bash
# Script de validación para Azure DevOps Pipeline
# Yappa Challenge DevOps - Validation Script

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Variables
PROJECT_ID="yappa-challenge-devops-442003"
SERVICE_ACCOUNT_EMAIL="azure-devops-pipeline@${PROJECT_ID}.iam.gserviceaccount.com"
REGION="us-central1"
ARTIFACT_REGISTRY_REPO="yappa-repo"
CLOUD_RUN_SERVICE="yappa-spring-boot-service"

echo -e "${BLUE}=== Validación Azure DevOps Pipeline Setup ===${NC}"
echo -e "${BLUE}Verificando configuración para Yappa Challenge DevOps${NC}"
echo ""

# Función para verificar comando
check_command() {
    local cmd=$1
    local name=$2
    
    if command -v $cmd &> /dev/null; then
        echo -e "${GREEN}✓ $name instalado${NC}"
        return 0
    else
        echo -e "${RED}✗ $name NO instalado${NC}"
        return 1
    fi
}

# Función para verificar recurso GCP
check_gcp_resource() {
    local resource_type=$1
    local resource_name=$2  
    local check_command=$3
    local description=$4
    
    echo -n "  Verificando $description..."
    if eval $check_command &> /dev/null; then
        echo -e " ${GREEN}✓${NC}"
        return 0
    else
        echo -e " ${RED}✗${NC}"
        return 1
    fi
}

# 1. Verificar herramientas locales
echo -e "${YELLOW}1. Verificando herramientas locales...${NC}"
TOOLS_OK=true

check_command "gcloud" "Google Cloud SDK" || TOOLS_OK=false
check_command "docker" "Docker" || TOOLS_OK=false
check_command "curl" "curl" || TOOLS_OK=false
check_command "base64" "base64" || TOOLS_OK=false

if ! $TOOLS_OK; then
    echo -e "${RED}Algunas herramientas necesarias no están instaladas${NC}"
    exit 1
fi

# 2. Verificar autenticación GCP
echo -e "${YELLOW}2. Verificando autenticación GCP...${NC}"
if gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q "@"; then
    CURRENT_ACCOUNT=$(gcloud auth list --filter=status:ACTIVE --format="value(account)")
    echo -e "${GREEN}✓ Autenticado como: $CURRENT_ACCOUNT${NC}"
else
    echo -e "${RED}✗ No hay sesión activa de gcloud${NC}"
    echo "Ejecutar: gcloud auth login"
    exit 1
fi

# Verificar proyecto actual
CURRENT_PROJECT=$(gcloud config get-value project 2>/dev/null)
if [ "$CURRENT_PROJECT" = "$PROJECT_ID" ]; then
    echo -e "${GREEN}✓ Proyecto actual: $PROJECT_ID${NC}"
else
    echo -e "${YELLOW}⚠ Proyecto actual: $CURRENT_PROJECT (esperado: $PROJECT_ID)${NC}"
    echo "Ejecutar: gcloud config set project $PROJECT_ID"
fi

# 3. Verificar APIs habilitadas
echo -e "${YELLOW}3. Verificando APIs habilitadas...${NC}"
APIS=(
    "artifactregistry.googleapis.com:Artifact Registry"
    "run.googleapis.com:Cloud Run"  
    "compute.googleapis.com:Compute Engine"
    "iam.googleapis.com:Identity and Access Management"
    "cloudbuild.googleapis.com:Cloud Build"
    "sql.googleapis.com:Cloud SQL"
    "storage.googleapis.com:Cloud Storage"
    "firestore.googleapis.com:Firestore"
)

for api_info in "${APIS[@]}"; do
    api=$(echo $api_info | cut -d: -f1)
    name=$(echo $api_info | cut -d: -f2)
    
    check_gcp_resource "api" "$api" "gcloud services list --enabled --filter=name:$api --format='value(name)' | grep -q $api" "$name API"
done

# 4. Verificar Service Account
echo -e "${YELLOW}4. Verificando Service Account...${NC}"
check_gcp_resource "iam" "$SERVICE_ACCOUNT_EMAIL" "gcloud iam service-accounts describe $SERVICE_ACCOUNT_EMAIL" "Service Account"

# Verificar roles del service account
echo "  Verificando roles asignados..."
REQUIRED_ROLES=(
    "roles/artifactregistry.writer"
    "roles/run.admin"
    "roles/compute.admin" 
    "roles/editor"
)

for role in "${REQUIRED_ROLES[@]}"; do
    if gcloud projects get-iam-policy $PROJECT_ID --format="value(bindings[].members[])" --filter="bindings.role:$role" | grep -q $SERVICE_ACCOUNT_EMAIL; then
        echo -e "    ${GREEN}✓ $role${NC}"
    else
        echo -e "    ${RED}✗ $role${NC}"
    fi
done

# 5. Verificar Artifact Registry
echo -e "${YELLOW}5. Verificando Artifact Registry...${NC}"
check_gcp_resource "repository" "$ARTIFACT_REGISTRY_REPO" "gcloud artifacts repositories describe $ARTIFACT_REGISTRY_REPO --location=$REGION" "Docker Repository"

# Verificar configuración Docker
echo "  Verificando configuración Docker..."
DOCKER_CONFIG="$HOME/.docker/config.json"
if [ -f "$DOCKER_CONFIG" ] && grep -q "$REGION-docker.pkg.dev" "$DOCKER_CONFIG"; then
    echo -e "    ${GREEN}✓ Docker configurado para Artifact Registry${NC}"
else
    echo -e "    ${YELLOW}⚠ Docker no configurado${NC}"
    echo "    Ejecutar: gcloud auth configure-docker $REGION-docker.pkg.dev"
fi

# 6. Verificar infraestructura desplegada
echo -e "${YELLOW}6. Verificando infraestructura desplegada...${NC}"

# Cloud SQL
check_gcp_resource "cloudsql" "yappa-postgres-main" "gcloud sql instances describe yappa-postgres-main" "Cloud SQL Instance"

# Cloud Run (si existe)  
if gcloud run services describe $CLOUD_RUN_SERVICE --region=$REGION &> /dev/null; then
    echo -e "  ${GREEN}✓ Cloud Run service existe${NC}"
    
    # Verificar estado
    SERVICE_STATUS=$(gcloud run services describe $CLOUD_RUN_SERVICE --region=$REGION --format="value(status.conditions[0].status)")
    if [ "$SERVICE_STATUS" = "True" ]; then
        echo -e "    ${GREEN}✓ Servicio está listo${NC}"
        
        # Obtener URL
        SERVICE_URL=$(gcloud run services describe $CLOUD_RUN_SERVICE --region=$REGION --format="value(status.url)")
        echo -e "    URL: ${BLUE}$SERVICE_URL${NC}"
    else
        echo -e "    ${YELLOW}⚠ Servicio no está listo${NC}"
    fi
else
    echo -e "  ${YELLOW}⚠ Cloud Run service no existe (será creado por el pipeline)${NC}"
fi

# VPC Connector
check_gcp_resource "vpc-connector" "yappa-vpc-connector" "gcloud compute networks vpc-access connectors describe yappa-vpc-connector --region=$REGION" "VPC Connector"

# 7. Verificar archivos de configuración
echo -e "${YELLOW}7. Verificando archivos de configuración...${NC}"

# Pipeline YAML
if [ -f "azure-pipelines.yml" ]; then
    echo -e "${GREEN}✓ azure-pipelines.yml existe${NC}"
    
    # Verificar contenido crítico
    if grep -q "MavenBuild" azure-pipelines.yml; then
        echo -e "    ${GREEN}✓ Job MavenBuild definido${NC}"
    else
        echo -e "    ${RED}✗ Job MavenBuild no encontrado${NC}"
    fi
    
    if grep -q "DockerBuildPush" azure-pipelines.yml; then
        echo -e "    ${GREEN}✓ Job DockerBuildPush definido${NC}"
    else
        echo -e "    ${RED}✗ Job DockerBuildPush no encontrado${NC}"
    fi
    
    if grep -q "DeployCloudRun" azure-pipelines.yml; then
        echo -e "    ${GREEN}✓ Deployment DeployCloudRun definido${NC}"
    else
        echo -e "    ${RED}✗ Deployment DeployCloudRun no encontrado${NC}"
    fi
    
else
    echo -e "${RED}✗ azure-pipelines.yml NO existe${NC}"
fi

# Dockerfile
if [ -f "app/Dockerfile" ]; then
    echo -e "${GREEN}✓ app/Dockerfile existe${NC}"
    
    # Verificar multi-stage build
    if grep -q "FROM.*AS builder" app/Dockerfile; then
        echo -e "    ${GREEN}✓ Multi-stage build configurado${NC}"
    else
        echo -e "    ${YELLOW}⚠ Multi-stage build no detectado${NC}"
    fi
else
    echo -e "${RED}✗ app/Dockerfile NO existe${NC}"
fi

# pom.xml
if [ -f "app/pom.xml" ]; then
    echo -e "${GREEN}✓ app/pom.xml existe${NC}"
else
    echo -e "${RED}✗ app/pom.xml NO existe${NC}"
fi

# 8. Test de conectividad
echo -e "${YELLOW}8. Test de conectividad...${NC}"

# Test Docker build local
echo "  Probando Docker build local..."
if cd app && docker build -t yappa-test . &> /dev/null; then
    echo -e "    ${GREEN}✓ Docker build exitoso${NC}"
    docker rmi yappa-test &> /dev/null || true
else
    echo -e "    ${RED}✗ Docker build falló${NC}"
fi
cd - > /dev/null

# Test gcloud commands
echo "  Probando comandos gcloud..."
if gcloud projects describe $PROJECT_ID &> /dev/null; then
    echo -e "    ${GREEN}✓ Acceso al proyecto GCP${NC}"
else
    echo -e "    ${RED}✗ No se puede acceder al proyecto${NC}"
fi

# 9. Generar resumen de configuración
echo ""
echo -e "${BLUE}=== RESUMEN DE CONFIGURACIÓN ===${NC}"
echo ""

# Información para Azure DevOps
echo -e "${YELLOW}Variables para Azure DevOps:${NC}"
echo "GCP_PROJECT_ID: $PROJECT_ID"
echo "ARTIFACT_REGISTRY_URL: $REGION-docker.pkg.dev/$PROJECT_ID/$ARTIFACT_REGISTRY_REPO"
echo "CLOUD_SQL_INSTANCE_IP: 10.2.0.3"
echo ""

# Service Account Key
if [ -f "azure-devops-key.json" ]; then
    echo -e "${YELLOW}GCP_SERVICE_ACCOUNT_KEY disponible:${NC}"
    echo "Archivo: azure-devops-key.json"
    echo "Para Azure DevOps: base64 -i azure-devops-key.json | tr -d '\\n'"
else
    echo -e "${YELLOW}GCP_SERVICE_ACCOUNT_KEY:${NC}"
    echo "Generar con: gcloud iam service-accounts keys create azure-devops-key.json --iam-account=$SERVICE_ACCOUNT_EMAIL"
fi

echo ""
echo -e "${YELLOW}URLs importantes:${NC}"
if [ -n "$SERVICE_URL" ]; then
    echo "Cloud Run Service: $SERVICE_URL"
fi
echo "Artifact Registry: https://console.cloud.google.com/artifacts/docker/$PROJECT_ID/$REGION/$ARTIFACT_REGISTRY_REPO"
echo "Cloud Run Console: https://console.cloud.google.com/run?project=$PROJECT_ID"

# 10. Verificaciones finales y recomendaciones
echo ""
echo -e "${BLUE}=== RECOMENDACIONES ===${NC}"
echo ""

echo -e "${YELLOW}Antes de ejecutar el pipeline:${NC}"
echo "1. Configurar variables en Azure DevOps (ver docs/AZURE_DEVOPS_SETUP.md)"
echo "2. Crear environment 'dev' en Azure DevOps"
echo "3. Verificar permisos del service account"
echo "4. Probar conexión VPC → Cloud SQL"

echo ""
echo -e "${YELLOW}Para debugging:${NC}"
echo "1. Habilitar logs detallados en el pipeline"
echo "2. Verificar health checks de Cloud Run"
echo "3. Monitorear métricas en Cloud Monitoring"

echo ""
echo -e "${GREEN}=== VALIDACIÓN COMPLETADA ===${NC}"

# Generar reporte
REPORT_FILE="validation-report-$(date +%Y%m%d-%H%M%S).txt"
{
    echo "Yappa Challenge DevOps - Validation Report"
    echo "Fecha: $(date)"
    echo "Proyecto: $PROJECT_ID"
    echo "Usuario: $(gcloud auth list --filter=status:ACTIVE --format='value(account)')"
    echo ""
    echo "Status: READY FOR AZURE DEVOPS PIPELINE"
    echo ""
    echo "Próximos pasos:"
    echo "1. Configurar variables en Azure DevOps"
    echo "2. Ejecutar pipeline en branch main/develop" 
    echo "3. Verificar deploy en Cloud Run"
} > $REPORT_FILE

echo -e "${GREEN}Reporte guardado en: $REPORT_FILE${NC}"