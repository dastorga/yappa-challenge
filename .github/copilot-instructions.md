# Instrucciones para Agentes IA - Yappa Challenge DevOps

## Contexto del Proyecto

Proyecto DevOps Challenge que implementa una aplicación **Spring Boot 3.2 (Java 17)** containerizada en GKE con IaC, CI/CD y observabilidad. Todo en **español**.

## Stack Tecnológico

- **App:** Spring Boot 3.2.0 + Java 17 + Maven + Actuator + Micrometer
- **Container:** Docker multi-stage (Maven builder + JRE Alpine)
- **IaC:** Terraform (VPC, GKE, IAM)
- **CI/CD:** GitHub Actions (Maven, Docker, kubectl)
- **Monitoreo:** Prometheus + Grafana

## Estructura

```
app/
  src/main/java/com/yappa/challenge/  → Código Java
    controller/  → REST Controllers
    service/     → Lógica de negocio
    model/       → DTOs
    config/      → Configuración
  src/main/resources/application.yml  → Config Spring Boot
  src/test/java/                      → Tests JUnit 5
  pom.xml                             → Dependencias Maven
  Dockerfile                          → Multi-stage build
k8s/           → Manifiestos (puerto 8080, Actuator paths)
terraform/     → GCP infrastructure
.github/       → CI/CD workflows (setup-java, mvn test)
scripts/       → Deploy/rollback scripts
```

## Patrones Clave

### Aplicación Spring Boot

**Endpoints:**

- `GET /` - Bienvenida
- `GET /api/info` - Info completa (memoria JVM, threads, uptime)
- `GET|POST /api/echo` - Testing
- `/actuator/health/liveness` - Liveness probe K8s
- `/actuator/health/readiness` - Readiness probe K8s
- `/actuator/prometheus` - Métricas Micrometer

**Configuración (application.yml):**

```yaml
server.port: 8080
management.endpoints.web.exposure.include: health,info,metrics,prometheus
management.health.probes.enabled: true
management.metrics.export.prometheus.enabled: true
```

**Variables de Entorno:**

```
ENVIRONMENT=production|dev
PORT=8080
LOG_LEVEL=INFO|DEBUG
JAVA_OPTS=-Xms256m -Xmx512m -XX:+UseG1GC
APP_VERSION=1.0.0
```

**Testing:**

```bash
mvn test                    # Todos los tests
mvn test -Dtest=ClassName  # Test específico
mvn jacoco:report          # Coverage
```

### Dockerfile Multi-Stage

```dockerfile
# Stage 1: Builder
FROM maven:3.9.5-eclipse-temurin-17-alpine
COPY pom.xml .
RUN mvn dependency:go-offline  # Cacheable
COPY src ./src
RUN mvn clean package -DskipTests

# Stage 2: Runtime
FROM eclipse-temurin:17-jre-alpine
USER 1000
COPY --from=builder /build/target/*.jar app.jar
ENTRYPOINT ["java", "$JAVA_OPTS", "-jar", "app.jar"]
```

### Kubernetes (puerto 8080)

**Deployment - Probes (CRÍTICO):**

```yaml
livenessProbe:
  httpGet:
    path: /actuator/health/liveness
    port: 8080
  initialDelaySeconds: 30 # JVM tarda en iniciar

readinessProbe:
  httpGet:
    path: /actuator/health/readiness
    port: 8080
  initialDelaySeconds: 20

startupProbe:
  httpGet:
    path: /actuator/health/liveness
    port: 8080
  failureThreshold: 30 # 30*10s = 5min max startup
  periodSeconds: 10
```

**Resources (Spring Boot necesita más memoria):**

```yaml
resources:
  requests:
    memory: "512Mi" # Mínimo para JVM
    cpu: "250m"
  limits:
    memory: "1Gi" # Headroom para GC
    cpu: "1000m"
```

**HPA:**

```yaml
minReplicas: 3
maxReplicas: 10
targets:
  cpu: 75% # Ajustado para JVM
  memory: 85%
```

**Service:** ClusterIP, targetPort: 8080

**Ingress - Backend Config:**

```yaml
healthCheck:
  port: 8080
  requestPath: /actuator/health
```

### Prometheus + Micrometer

**Annotations en Deployment:**

```yaml
prometheus.io/scrape: "true"
prometheus.io/port: "8080"
prometheus.io/path: "/actuator/prometheus"
```

**Métricas Spring Boot (Micrometer):**

- `http_server_requests_seconds_count{status,method,uri}` - Requests
- `http_server_requests_seconds_bucket` - Latencia (histograma)
- `jvm_memory_used_bytes{area="heap"}` - Memoria JVM
- `jvm_gc_pause_seconds_*` - Garbage Collection
- `jvm_threads_live` - Threads activos

**Queries Prometheus:**

```promql
# Error rate
rate(http_server_requests_seconds_count{status=~"5..",namespace="yappa-app"}[5m])

# P95 latency
histogram_quantile(0.95, rate(http_server_requests_seconds_bucket[5m]))

# Heap usage
jvm_memory_used_bytes{area="heap"} / jvm_memory_max_bytes{area="heap"}
```

### CI/CD GitHub Actions

**Job: test**

```yaml
- uses: actions/setup-java@v4
  with:
    distribution: "temurin"
    java-version: "17"
    cache: "maven"
- run: mvn clean compile -B
- run: mvn test -B
- run: mvn jacoco:report
```

**Job: build**

```yaml
- uses: docker/build-push-action@v5
  with:
    context: ./app
    file: ./app/Dockerfile
    push: true
    cache-from: type=gha
```

**Job: security-scan**

- Trivy para vulnerabilidades en imagen
- OWASP Dependency Check para deps Maven

**Smoke tests:**

```bash
curl -f http://$INGRESS_IP/actuator/health
curl -f http://$INGRESS_IP/actuator/health/liveness
curl -f http://$INGRESS_IP/actuator/health/readiness
```

## Comandos Esenciales

### Local Development

```bash
# Build y run
cd app
mvn spring-boot:run

# Tests
mvn test
mvn verify  # Incluye integration tests

# Package
mvn clean package
java -jar target/challenge-devops.jar

# Docker
docker build -t yappa .
docker run -p 8080:8080 -e LOG_LEVEL=DEBUG yappa
```

### Deploy a GKE

```bash
# Opción 1: Script automatizado
export GCP_PROJECT_ID="tu-proyecto"
./scripts/deploy.sh

# Opción 2: Manual
cd terraform && terraform apply
gcloud container clusters get-credentials yappa-gke-cluster --region us-central1
cd ../app && docker build -t IMAGE_URL . && docker push IMAGE_URL
cd ../k8s && kubectl apply -f .
```

### Debugging

```bash
# Logs Spring Boot
kubectl logs -f -n yappa-app -l app=yappa-app

# Actuator metrics
kubectl port-forward -n yappa-app svc/yappa-app-service 8080:80
curl http://localhost:8080/actuator/metrics
curl http://localhost:8080/actuator/metrics/jvm.memory.used
curl http://localhost:8080/actuator/health

# Thread dump
curl http://localhost:8080/actuator/threaddump

# Heap dump (si habilitado)
curl http://localhost:8080/actuator/heapdump > heap.hprof
```

### Rollback

```bash
./scripts/rollback.sh
# O manual:
kubectl rollout undo deployment/yappa-app -n yappa-app
kubectl rollout history deployment/yappa-app -n yappa-app
```

## Troubleshooting Común

### OOMKilled (OutOfMemoryError)

```bash
# Síntoma: Pod restart, logs muestran java.lang.OutOfMemoryError
# Solución:
1. Verificar: kubectl describe pod POD_NAME -n yappa-app | grep -A 5 "Last State"
2. Aumentar memory limits en deployment.yaml:
   limits.memory: "1Gi" -> "2Gi"
3. Ajustar JAVA_OPTS: -Xmx768m (dejar 20-30% para non-heap)
4. Redeploy: kubectl apply -f k8s/deployment.yaml
```

### Startup Timeout

```bash
# Síntoma: Pods no pasan readiness, se reinician
# Solución:
# Aumentar startupProbe.failureThreshold en deployment.yaml:
failureThreshold: 40  # 40*10s = 6.5min max
# Spring Boot puede tardar 30-60s en iniciar
```

### Maven Build Falla en CI/CD

```bash
# Verificar Java version: debe ser 17
# Verificar maven cache en GitHub Actions
# Ejecutar localmente para reproducir:
mvn clean install -B
```

### Métricas no aparecen en Prometheus

```bash
# 1. Verificar annotations en pods:
kubectl get pod -n yappa-app POD_NAME -o yaml | grep prometheus

# 2. Test endpoint directo:
kubectl port-forward -n yappa-app POD_NAME 8080:8080
curl http://localhost:8080/actuator/prometheus

# 3. Verificar Prometheus targets:
kubectl port-forward -n monitoring svc/prometheus 9090:9090
# Abrir http://localhost:9090/targets
```

## Reglas Críticas

1. **Puerto 8080** (no 5000 como Flask)
2. **Paths Actuator** en probes (no /health directo)
3. **Memory:** Mínimo 512Mi request, 1Gi limit
4. **Startup:** failureThreshold alto (30-40) para JVM
5. **JAVA_OPTS:** -Xmx debe ser ~75% del memory limit
6. **Tests:** Ejecutar `mvn test` antes de commit
7. **Lombok:** Requerido en IDE (plugin)
8. **Java 17:** No downgrade a versiones anteriores
9. **Micrometer:** No cambiar a otras libs de métricas
10. **Español:** Todo código, comments, docs en español

## Diferencias vs Flask/Python

| Aspecto             | Flask (old)               | Spring Boot (actual)      |
| ------------------- | ------------------------- | ------------------------- |
| Puerto              | 5000                      | 8080                      |
| Health check        | /health                   | /actuator/health/liveness |
| Métricas            | /metrics                  | /actuator/prometheus      |
| Startup tiempo      | 5-10s                     | 20-40s                    |
| Memory mínima       | 128Mi                     | 512Mi                     |
| Build tool          | pip                       | Maven                     |
| Runtime             | Python + Gunicorn         | JRE + embedded Tomcat     |
| Probes initialDelay | 5-10s                     | 20-30s                    |
| Prometheus lib      | prometheus-flask-exporter | Micrometer                |

## Referencias

- Spring Boot Actuator: https://docs.spring.io/spring-boot/docs/current/reference/html/actuator.html
- Micrometer: https://micrometer.io/docs
- Terraform GKE: `terraform/`
- Scripts: `scripts/deploy.sh`, `scripts/rollback.sh`
- Docs: `docs/ARCHITECTURE.md`, `docs/DEPLOYMENT.md`, `docs/TROUBLESHOOTING.md`
