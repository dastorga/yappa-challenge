# GitHub Actions CI/CD Pipeline Activated 🚀

Este proyecto ahora incluye CI/CD automatizado con GitHub Actions que se ejecuta en cada push a main/develop.

## Estado del Pipeline
- ✅ Environment 'dev' configurado
- ✅ Secret GCP_SERVICE_ACCOUNT_KEY añadido
- ✅ Workflow listo para ejecutarse

El pipeline incluye:
1. **Build & Test** - Maven compilation y tests
2. **Docker Build** - Construcción y push a Artifact Registry  
3. **Cloud Run Deploy** - Despliegue automático
4. **Terraform Plan/Apply** - Gestión de infraestructura

Ver en: https://github.com/dastorga/yappa-challenge/actions

