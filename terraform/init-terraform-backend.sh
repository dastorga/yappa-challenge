# Script para inicializar Terraform con backend GCS de forma segura
#!/bin/bash

set -e

PROJECT_ID=$1
REGION=$2
BUCKET_NAME="yappa-terraform-state"

echo "🚀 Initializing Terraform with GCS backend safely..."
echo "📍 Project: $PROJECT_ID"
echo "🌍 Region: $REGION"
echo "🗄️ Bucket: $BUCKET_NAME"

# Función para crear bucket si no existe
create_bucket_if_needed() {
    if ! gsutil ls "gs://$BUCKET_NAME/" >/dev/null 2>&1; then
        echo "🔧 Creating state bucket..."
        
        # Crear bucket con configuración adecuada
        gsutil mb -p "$PROJECT_ID" -c STANDARD -l "$REGION" "gs://$BUCKET_NAME/"
        
        # Habilitar versionado
        gsutil versioning set on "gs://$BUCKET_NAME/"
        
        # Configurar lifecycle para limpieza
        cat > /tmp/lifecycle.json << EOF
{
  "lifecycle": {
    "rule": [
      {
        "action": {"type": "Delete"},
        "condition": {
          "age": 30,
          "numNewerVersions": 5
        }
      }
    ]
  }
}
EOF
        gsutil lifecycle set /tmp/lifecycle.json "gs://$BUCKET_NAME/"
        
        echo "✅ State bucket created and configured"
    else
        echo "✅ State bucket already exists"
    fi
}

# Función para inicializar Terraform con backend
init_terraform() {
    echo "🔧 Initializing Terraform..."
    
    # Verificar que main.tf tiene el backend configurado
    if grep -q "backend \"gcs\"" main.tf; then
        echo "📂 GCS backend found in configuration"
        terraform init -reconfigure
    else
        echo "⚠️  No GCS backend in config, using local state"
        terraform init
    fi
}

# Ejecutar pasos
create_bucket_if_needed
init_terraform

echo "✅ Terraform initialization completed successfully"