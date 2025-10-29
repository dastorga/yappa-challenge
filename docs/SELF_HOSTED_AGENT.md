# Configuración Self-hosted Agent para Azure DevOps

## Requisitos

- Máquina virtual (GCP Compute Engine, AWS EC2, Azure VM, etc.)
- Ubuntu 20.04+ o Windows Server
- Docker instalado
- Conectividad a internet

## Pasos para Ubuntu

### 1. Crear VM en GCP

```bash
gcloud compute instances create azure-devops-agent \
  --zone=us-central1-a \
  --machine-type=e2-standard-2 \
  --subnet=default \
  --network-tier=PREMIUM \
  --maintenance-policy=MIGRATE \
  --image-family=ubuntu-2004-lts \
  --image-project=ubuntu-os-cloud \
  --boot-disk-size=50GB \
  --boot-disk-type=pd-standard \
  --metadata=startup-script='#!/bin/bash
    apt update
    apt install -y docker.io wget curl
    systemctl enable docker
    systemctl start docker
    usermod -aG docker $USER'
```

### 2. Conectar y configurar agente

```bash
# SSH a la VM
gcloud compute ssh azure-devops-agent --zone=us-central1-a

# Descargar agente
mkdir myagent && cd myagent
wget https://vstsagentpackage.azureedge.net/agent/3.232.3/vsts-agent-linux-x64-3.232.3.tar.gz
tar zxvf vsts-agent-linux-x64-3.232.3.tar.gz

# Configurar
./config.sh
# Cuando pregunte:
# Server URL: https://dev.azure.com/TU_ORGANIZACION
# Authentication type: PAT
# Personal access token: [crear en Azure DevOps]
# Agent pool: default
# Agent name: yappa-gcp-agent

# Ejecutar como servicio
sudo ./svc.sh install
sudo ./svc.sh start
```

### 3. Actualizar azure-pipelines.yml para usar self-hosted

```yaml
pool:
  name: "default" # En lugar de vmImage: ubuntu-latest
```

## Personal Access Token (PAT)

1. Ir a Azure DevOps → User Settings → Personal Access Tokens
2. New Token con permisos:
   - Agent Pools: Read & manage
   - Build: Read & execute
   - Code: Read
3. Copiar el token para usar en config.sh
