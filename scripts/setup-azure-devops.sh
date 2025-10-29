#!/bin/bash
# Script para configurar Azure DevOps Pipeline con Google Cloud Platform
# Yappa Challenge DevOps - Setup Script

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables
PROJECT_ID="yappa-challenge-devops-442003"
SERVICE_ACCOUNT_NAME="azure-devops-pipeline"
SERVICE_ACCOUNT_EMAIL="${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
KEY_FILE="azure-devops-key.json"
ARTIFACT_REGISTRY_REPO="yappa-repo"
REGION="us-central1"

echo -e "${BLUE}=== Yappa Challenge DevOps - Azure DevOps Setup ===${NC}"
echo -e "${BLUE}Configurando integración Azure DevOps con Google Cloud Platform${NC}"
echo ""

# Verificar gcloud instalado
if ! command -v gcloud &> /dev/null; then
    echo -e "${RED}Error: gcloud CLI no está instalado${NC}"
    echo "Instala gcloud CLI: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# Verificar autenticación
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q "@"; then
    echo -e "${YELLOW}No hay sesión activa de gcloud. Autenticándose...${NC}"
    gcloud auth login
fi

# Configurar proyecto
echo -e "${YELLOW}Configurando proyecto GCP: ${PROJECT_ID}${NC}"
gcloud config set project ${PROJECT_ID}

# Verificar que el proyecto existe
if ! gcloud projects describe ${PROJECT_ID} &> /dev/null; then
    echo -e "${RED}Error: El proyecto ${PROJECT_ID} no existe o no tienes acceso${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Proyecto ${PROJECT_ID} configurado${NC}"

# Habilitar APIs necesarias
echo -e "${YELLOW}Habilitando APIs necesarias...${NC}"
gcloud services enable artifactregistry.googleapis.com
gcloud services enable run.googleapis.com
gcloud services enable compute.googleapis.com
gcloud services enable iam.googleapis.com
gcloud services enable cloudbuild.googleapis.com

echo -e "${GREEN}✓ APIs habilitadas${NC}"

# Crear service account si no existe
if gcloud iam service-accounts describe ${SERVICE_ACCOUNT_EMAIL} &> /dev/null; then
    echo -e "${YELLOW}Service account ${SERVICE_ACCOUNT_NAME} ya existe${NC}"
else
    echo -e "${YELLOW}Creando service account: ${SERVICE_ACCOUNT_NAME}${NC}"
    gcloud iam service-accounts create ${SERVICE_ACCOUNT_NAME} \
        --description="Service account for Azure DevOps pipeline" \
        --display-name="Azure DevOps Pipeline"
    
    echo -e "${GREEN}✓ Service account creado${NC}"
fi

# Asignar roles necesarios
echo -e "${YELLOW}Asignando roles al service account...${NC}"

ROLES=(
    "roles/artifactregistry.writer"
    "roles/run.admin"
    "roles/compute.admin"
    "roles/editor"
    "roles/storage.admin"
    "roles/cloudsql.admin"
)

for ROLE in "${ROLES[@]}"; do
    echo "  Asignando rol: ${ROLE}"
    gcloud projects add-iam-policy-binding ${PROJECT_ID} \
        --member="serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
        --role="${ROLE}" \
        --quiet
done

echo -e "${GREEN}✓ Roles asignados${NC}"

# Generar clave del service account
echo -e "${YELLOW}Generando clave JSON para el service account...${NC}"

if [ -f "${KEY_FILE}" ]; then
    echo -e "${YELLOW}Archivo ${KEY_FILE} ya existe. ¿Sobrescribir? (y/N)${NC}"
    read -r response
    if [[ ! "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        echo "Usando archivo existente"
    else
        rm "${KEY_FILE}"
    fi
fi

if [ ! -f "${KEY_FILE}" ]; then
    gcloud iam service-accounts keys create ${KEY_FILE} \
        --iam-account=${SERVICE_ACCOUNT_EMAIL}
    echo -e "${GREEN}✓ Clave JSON generada: ${KEY_FILE}${NC}"
else
    echo -e "${GREEN}✓ Usando clave existente: ${KEY_FILE}${NC}"
fi

# Codificar en base64 para Azure DevOps
echo -e "${YELLOW}Codificando clave en base64...${NC}"
if command -v base64 &> /dev/null; then
    BASE64_KEY=$(base64 -i ${KEY_FILE} | tr -d '\n')
    echo -e "${GREEN}✓ Clave codificada en base64${NC}"
else
    echo -e "${RED}Error: comando base64 no disponible${NC}"
    exit 1
fi

# Verificar Artifact Registry
echo -e "${YELLOW}Verificando Artifact Registry...${NC}"
if gcloud artifacts repositories describe ${ARTIFACT_REGISTRY_REPO} --location=${REGION} &> /dev/null; then
    echo -e "${GREEN}✓ Repository ${ARTIFACT_REGISTRY_REPO} ya existe${NC}"
else
    echo -e "${YELLOW}Creando repository en Artifact Registry...${NC}"
    gcloud artifacts repositories create ${ARTIFACT_REGISTRY_REPO} \
        --repository-format=docker \
        --location=${REGION} \
        --description="Docker repository for Yappa Challenge"
    echo -e "${GREEN}✓ Repository ${ARTIFACT_REGISTRY_REPO} creado${NC}"
fi

# Configurar Docker para Artifact Registry
echo -e "${YELLOW}Configurando Docker para Artifact Registry...${NC}"
gcloud auth configure-docker ${REGION}-docker.pkg.dev
echo -e "${GREEN}✓ Docker configurado${NC}"

# Mostrar información de configuración
echo ""
echo -e "${BLUE}=== INFORMACIÓN PARA AZURE DEVOPS ===${NC}"
echo ""
echo -e "${YELLOW}Variables a configurar en Azure DevOps:${NC}"
echo ""
echo "GCP_PROJECT_ID:"
echo "  ${PROJECT_ID}"
echo ""
echo "ARTIFACT_REGISTRY_URL:"
echo "  ${REGION}-docker.pkg.dev/${PROJECT_ID}/${ARTIFACT_REGISTRY_REPO}"
echo ""
echo "CLOUD_SQL_INSTANCE_IP:"
echo "  10.2.0.3"
echo ""
echo "GCP_SERVICE_ACCOUNT_KEY (base64):"
echo "${BASE64_KEY}" | fold -w 80
echo ""

# Generar archivo de variables para importar
cat > azure-devops-variables.txt << EOF
# Variables para Azure DevOps Pipeline
# Copiar estos valores en Pipeline Variables o Variable Groups

GCP_PROJECT_ID=${PROJECT_ID}
ARTIFACT_REGISTRY_URL=${REGION}-docker.pkg.dev/${PROJECT_ID}/${ARTIFACT_REGISTRY_REPO}
CLOUD_SQL_INSTANCE_IP=10.2.0.3
GCP_SERVICE_ACCOUNT_KEY=${BASE64_KEY}
EOF

echo -e "${GREEN}✓ Variables guardadas en: azure-devops-variables.txt${NC}"

# Instrucciones finales
echo ""
echo -e "${BLUE}=== PRÓXIMOS PASOS ===${NC}"
echo ""
echo -e "${YELLOW}1. Azure DevOps Setup:${NC}"
echo "   - Ir a tu proyecto de Azure DevOps"
echo "   - Navegar a Pipelines → Library → Variable groups"
echo "   - Crear nuevo Variable Group: 'yappa-gcp-variables'"
echo "   - Agregar las variables mostradas arriba"
echo "   - Marcar GCP_SERVICE_ACCOUNT_KEY como 'secret'"
echo ""
echo -e "${YELLOW}2. Pipeline Configuration:${NC}"
echo "   - Asegurar que azure-pipelines.yml está en la raíz del repo"
echo "   - Crear nuevo pipeline desde el archivo YAML"
echo "   - Vincular el Variable Group al pipeline"
echo ""
echo -e "${YELLOW}3. Environment Setup:${NC}"
echo "   - Crear environment 'dev' en Azure DevOps"
echo "   - Configurar approval gates si es necesario"
echo ""
echo -e "${YELLOW}4. Test Pipeline:${NC}"
echo "   - Hacer push a branch main o develop"
echo "   - Verificar que el pipeline se ejecute correctamente"
echo "   - Validar deploy en Cloud Run"
echo ""

# Comandos de verificación
echo -e "${YELLOW}5. Comandos de verificación post-deploy:${NC}"
cat << 'EOF'

# Verificar servicio en Cloud Run
gcloud run services list --region=us-central1

# Obtener URL del servicio
SERVICE_URL=$(gcloud run services describe yappa-spring-boot-service --region=us-central1 --format='value(status.url)')

# Test endpoints
curl -X GET $SERVICE_URL/
curl -X GET $SERVICE_URL/actuator/health  
curl -X GET $SERVICE_URL/api/info

EOF

echo ""
echo -e "${GREEN}=== CONFIGURACIÓN COMPLETADA ===${NC}"
echo -e "${GREEN}Revisa el archivo 'docs/AZURE_DEVOPS_SETUP.md' para más detalles${NC}"
echo ""

# Advertencia de seguridad
echo -e "${RED}IMPORTANTE:${NC}"
echo -e "${RED}- El archivo ${KEY_FILE} contiene credenciales sensibles${NC}"
echo -e "${RED}- No lo subas al repositorio${NC}"  
echo -e "${RED}- Considera eliminarlo después de configurar Azure DevOps${NC}"
echo -e "${RED}- Rota las claves periódicamente${NC}"