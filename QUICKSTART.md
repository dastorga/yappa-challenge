# Inicio Rápido - Yappa Challenge

Este es un resumen ejecutivo para poner en marcha el proyecto rápidamente.

## Prerrequisitos

✅ Cuenta GCP con billing  
✅ Docker, gcloud CLI, Terraform instalados  
✅ Python 3.11+

## Despliegue Rápido (10 minutos)

### 1. Configuración Inicial

```bash
# Clonar repo
git clone https://github.com/WibondConnect/yappa-challenge.git
cd yappa-challenge

# Configurar GCP
export GCP_PROJECT_ID="tu-proyecto-id"
gcloud config set project $GCP_PROJECT_ID
gcloud auth application-default login

# Habilitar APIs
gcloud services enable container.googleapis.com compute.googleapis.com artifactregistry.googleapis.com
```

### 2. Desplegar Infraestructura

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Editar terraform.tfvars con tu project_id

terraform init
terraform apply -var="project_id=$GCP_PROJECT_ID" -auto-approve
```

⏱️ Espera ~10 minutos

### 3. Desplegar Aplicación

```bash
cd ..
chmod +x scripts/deploy.sh
./scripts/deploy.sh
```

⏱️ Espera ~5 minutos

### 4. Configurar Monitoreo

```bash
chmod +x scripts/setup-monitoring.sh
./scripts/setup-monitoring.sh
```

### 5. Obtener URL

```bash
kubectl get ingress -n yappa-app
# Espera a que aparezca la IP (puede tardar 5-10 min)

# Cuando aparezca:
curl http://TU_IP/health
```

## Verificación Rápida

```bash
# Ver todo funcionando
kubectl get all -n yappa-app
kubectl get all -n monitoring

# Test de la app
INGRESS_IP=$(kubectl get ingress -n yappa-app -o jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}')
curl http://$INGRESS_IP/health
curl http://$INGRESS_IP/api/info
```

## Acceso a Servicios

### Aplicación

```bash
echo "http://$(kubectl get ingress -n yappa-app -o jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}')"
```

### Grafana

```bash
kubectl port-forward -n monitoring svc/grafana 3000:80
# Abrir: http://localhost:3000
# Usuario: admin
# Password: admin123
```

### Prometheus

```bash
kubectl port-forward -n monitoring svc/prometheus 9090:9090
# Abrir: http://localhost:9090
```

## Comandos Útiles

```bash
# Ver logs
kubectl logs -f -n yappa-app -l app=yappa-app

# Escalar
kubectl scale deployment/yappa-app --replicas=5 -n yappa-app

# Rollback
./scripts/rollback.sh

# Limpiar todo
./scripts/cleanup.sh
```

## Siguiente Paso: CI/CD

1. Fork el repositorio en GitHub
2. Configurar secrets en GitHub:
   - `GCP_PROJECT_ID`
   - `GCP_SA_KEY` (obtener con: `terraform output -raw cicd_key`)
3. Push a main → Deploy automático

## Problemas?

Ver `docs/TROUBLESHOOTING.md` para soluciones comunes.

## Documentación Completa

- `README.md` - Documentación completa
- `docs/ARCHITECTURE.md` - Arquitectura detallada
- `docs/DEPLOYMENT.md` - Guía de despliegue paso a paso
- `.github/copilot-instructions.md` - Para agentes IA
