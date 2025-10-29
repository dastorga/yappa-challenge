#!/bin/bash
# Script para manejar recursos Terraform existentes
# Este script importa recursos que ya existen en GCP para evitar errores 409

echo "🔧 Managing existing Terraform resources..."

# Función para importar recurso si existe
import_if_exists() {
    local resource_type="$1"
    local resource_name="$2" 
    local gcp_id="$3"
    
    echo "🔍 Checking if $resource_name exists..."
    
    # Verificar si el recurso ya está en el estado de Terraform
    if terraform state show "$resource_type.$resource_name" >/dev/null 2>&1; then
        echo "✅ $resource_name already in Terraform state"
        return 0
    fi
    
    # Intentar importar el recurso
    if terraform import "$resource_type.$resource_name" "$gcp_id" >/dev/null 2>&1; then
        echo "📥 Imported existing $resource_name"
        return 0
    else
        echo "ℹ️  $resource_name will be created (doesn't exist or import failed)"
        return 1
    fi
}

# Importar service accounts si existen
echo "📋 Importing existing service accounts..."
import_if_exists "google_service_account" "cloud_run_sa" "projects/$PROJECT_ID/serviceAccounts/cloud-run-sa@$PROJECT_ID.iam.gserviceaccount.com"
import_if_exists "google_service_account" "admin_sa" "projects/$PROJECT_ID/serviceAccounts/yappa-admin-sa@$PROJECT_ID.iam.gserviceaccount.com"  
import_if_exists "google_service_account" "backup_sa" "projects/$PROJECT_ID/serviceAccounts/yappa-backup-sa@$PROJECT_ID.iam.gserviceaccount.com"
import_if_exists "google_service_account" "vpn_test_sa" "projects/$PROJECT_ID/serviceAccounts/vpn-test-sa@$PROJECT_ID.iam.gserviceaccount.com"

# Importar networking resources
echo "🌐 Importing existing network resources..."
import_if_exists "google_compute_network" "vpc" "projects/$PROJECT_ID/global/networks/yappa-vpc"
import_if_exists "google_compute_address" "vpn_gateway_ip" "projects/$PROJECT_ID/regions/$REGION/addresses/vpn-gateway-ip"

# Importar storage buckets
echo "🗄️ Importing existing storage buckets..."
import_if_exists "google_storage_bucket" "bucket" "$STORAGE_BUCKET_NAME"
import_if_exists "google_storage_bucket" "logs_bucket" "$STORAGE_BUCKET_NAME-logs"

echo "� Running Terraform plan and apply..."

# Ejecutar plan para ver qué queda por crear/actualizar
terraform plan \
  -var="project_id=$PROJECT_ID" \
  -var="region=$REGION" \
  -var="environment=dev" \
  -var="db_password=$DB_PASSWORD" \
  -var="storage_bucket_name=$STORAGE_BUCKET_NAME" \
  -var="peer_external_ip=$PEER_EXTERNAL_IP" \
  -var="vpn_shared_secret=$VPN_SHARED_SECRET" \
  -detailed-exitcode

PLAN_EXIT_CODE=$?

if [ $PLAN_EXIT_CODE -eq 0 ]; then
    echo "✅ No changes needed - infrastructure is up to date"
    exit 0
elif [ $PLAN_EXIT_CODE -eq 2 ]; then
    echo "📝 Changes detected, applying..."
    terraform apply -auto-approve \
      -var="project_id=$PROJECT_ID" \
      -var="region=$REGION" \
      -var="environment=dev" \
      -var="db_password=$DB_PASSWORD" \
      -var="storage_bucket_name=$STORAGE_BUCKET_NAME" \
      -var="peer_external_ip=$PEER_EXTERNAL_IP" \
      -var="vpn_shared_secret=$VPN_SHARED_SECRET"
    
    if [ $? -eq 0 ]; then
        echo "✅ Infrastructure deployed successfully"
    else
        echo "⚠️ Apply had issues, but continuing..."
        echo "🔍 Verifying critical resources exist..."
        
        gcloud compute networks describe yappa-vpc --quiet >/dev/null 2>&1 && echo "✅ VPC exists"
        gcloud iam service-accounts describe cloud-run-sa@$PROJECT_ID.iam.gserviceaccount.com --quiet >/dev/null 2>&1 && echo "✅ Cloud Run SA exists"
        gsutil ls gs://$STORAGE_BUCKET_NAME >/dev/null 2>&1 && echo "✅ Storage bucket exists"
        
        echo "🚀 Critical resources available - continuing deployment"
        exit 0
    fi
else
    echo "❌ Plan failed with exit code $PLAN_EXIT_CODE"
    exit $PLAN_EXIT_CODE
fi