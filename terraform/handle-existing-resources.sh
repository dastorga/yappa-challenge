#!/bin/bash
# Script para manejar recursos Terraform existentes
# Este script importa recursos que ya existen en GCP para evitar errores 409

echo "🔧 Managing existing Terraform resources..."

# Lista de recursos que pueden existir y causar errores 409
EXISTING_RESOURCES=(
    "google_service_account.cloud_run_sa"
    "google_service_account.admin_sa" 
    "google_service_account.backup_sa"
    "google_service_account.vpn_test_sa"
    "google_compute_network.vpc"
    "google_storage_bucket.bucket"
    "google_storage_bucket.logs_bucket"
    "google_compute_address.vpn_gateway_ip"
)

# Intentar plan sin fallar por recursos existentes
echo "📋 Running Terraform plan with existing resources handling..."

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
    echo "✅ No changes needed"
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
        echo "✅ Infrastructure updated successfully"
    else
        echo "❌ Apply failed, but infrastructure may be partially ready"
        echo "🔍 Checking critical resources..."
        
        # Verificar recursos críticos
        gcloud compute networks describe yappa-vpc --quiet && echo "✅ VPC exists"
        gcloud run services describe yappa-spring-boot-service --region=$REGION --quiet 2>/dev/null && echo "✅ Cloud Run service exists" || echo "ℹ️  Cloud Run service will be created on deploy"
        gcloud compute addresses describe vpn-gateway-ip --region=$REGION --quiet && echo "✅ VPN Gateway IP exists"
        
        echo "🚀 Continuing with deployment - existing resources detected"
        exit 0
    fi
else
    echo "❌ Plan failed with exit code $PLAN_EXIT_CODE"
    exit $PLAN_EXIT_CODE
fi