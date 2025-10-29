#!/bin/bash

# Script para verificar el estado de la infraestructura en GCP
# Uso: ./verify-infrastructure.sh

set -e

PROJECT_ID="${PROJECT_ID:-yappa-challenge-devops}"
REGION="${REGION:-southamerica-east1}"

echo "======================================"
echo "🔍 Verificando Infraestructura GCP"
echo "======================================"
echo "Proyecto: $PROJECT_ID"
echo "Región: $REGION"
echo ""

# Configurar proyecto
gcloud config set project $PROJECT_ID

echo "1️⃣  Verificando VPC..."
VPC_EXISTS=$(gcloud compute networks list --filter="name=yappa-vpc" --format="value(name)" 2>/dev/null || echo "")
if [ -n "$VPC_EXISTS" ]; then
  echo "   ✅ VPC 'yappa-vpc' existe"
  gcloud compute networks subnets list --network=yappa-vpc --regions=$REGION --format="table(name,ipCidrRange)"
else
  echo "   ❌ VPC 'yappa-vpc' no encontrada"
fi
echo ""

echo "2️⃣  Verificando Cloud SQL..."
SQL_EXISTS=$(gcloud sql instances list --filter="name:yappa-postgres" --format="value(name)" 2>/dev/null || echo "")
if [ -n "$SQL_EXISTS" ]; then
  echo "   ✅ Instancia Cloud SQL encontrada"
  gcloud sql instances describe $SQL_EXISTS --format="table(name,databaseVersion,region,state,ipAddresses[0].ipAddress)"
else
  echo "   ❌ Instancia Cloud SQL no encontrada"
fi
echo ""

echo "3️⃣  Verificando Cloud Run..."
RUN_EXISTS=$(gcloud run services list --platform=managed --region=$REGION --filter="metadata.name:yappa-app" --format="value(metadata.name)" 2>/dev/null || echo "")
if [ -n "$RUN_EXISTS" ]; then
  echo "   ✅ Servicio Cloud Run encontrado"
  gcloud run services describe $RUN_EXISTS --platform=managed --region=$REGION --format="table(metadata.name,status.url,status.conditions[0].status)"
else
  echo "   ❌ Servicio Cloud Run no encontrado (puede ser normal si aún no se desplegó)"
fi
echo ""

echo "4️⃣  Verificando Firestore..."
FIRESTORE_EXISTS=$(gcloud firestore databases list --format="value(name)" 2>/dev/null | grep -c "(default)" || echo "0")
if [ "$FIRESTORE_EXISTS" -gt 0 ]; then
  echo "   ✅ Firestore configurado"
  gcloud firestore databases describe --database="(default)" --format="table(name,type,locationId)"
else
  echo "   ❌ Firestore no configurado"
fi
echo ""

echo "5️⃣  Verificando Cloud Storage..."
BUCKET_EXISTS=$(gsutil ls | grep -c "yappa-challenge-storage" || echo "0")
if [ "$BUCKET_EXISTS" -gt 0 ]; then
  echo "   ✅ Buckets de Storage encontrados:"
  gsutil ls | grep "yappa-challenge"
else
  echo "   ❌ Buckets de Storage no encontrados"
fi
echo ""

echo "6️⃣  Verificando VPN Gateway..."
VPN_EXISTS=$(gcloud compute vpn-gateways list --filter="region=$REGION" --format="value(name)" 2>/dev/null || echo "")
if [ -n "$VPN_EXISTS" ]; then
  echo "   ✅ VPN Gateway encontrado"
  gcloud compute vpn-gateways list --filter="region=$REGION" --format="table(name,region,network)"
else
  echo "   ❌ VPN Gateway no encontrado"
fi
echo ""

echo "7️⃣  Verificando Service Accounts..."
SA_COUNT=$(gcloud iam service-accounts list --filter="email:*@$PROJECT_ID.iam.gserviceaccount.com" --format="value(email)" | grep -c "yappa\|cloud-run" || echo "0")
if [ "$SA_COUNT" -gt 0 ]; then
  echo "   ✅ Service Accounts encontradas ($SA_COUNT):"
  gcloud iam service-accounts list --filter="email:*@$PROJECT_ID.iam.gserviceaccount.com" --format="table(email,displayName)" | grep -E "yappa|cloud-run"
else
  echo "   ❌ Service Accounts no encontradas"
fi
echo ""

echo "======================================"
echo "✅ Verificación completada"
echo "======================================"
