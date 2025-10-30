# Etapa 1: Build con Maven
FROM eclipse-temurin:17-jdk AS builder

# Instalar Maven
RUN apt-get update && apt-get install -y maven && rm -rf /var/lib/apt/lists/*

# Metadatos
LABEL maintainer="astorgadm@gmail.com"
LABEL description="Yappa DevOps Challenge - Spring Boot Application Builder"

# Directorio de trabajo
WORKDIR /build

# Copiar archivos de configuración de Maven
COPY pom.xml .

# Descargar dependencias (se cachea si pom.xml no cambia)
RUN mvn dependency:go-offline -B

# Copiar código fuente
COPY src ./src

# Compilar y empaquetar la aplicación
RUN mvn clean package -DskipTests -B

# Etapa 2: Runtime con JRE optimizado
FROM eclipse-temurin:17-jre

# Metadatos
LABEL maintainer="astorgadm@gmail.com"
LABEL description="Yappa DevOps Challenge - Spring Boot Application"
LABEL version="1.0.0"

# Variables de entorno
ENV APP_VERSION=1.0.0 \
  ENVIRONMENT=dev \
  PORT=8080 \
  JAVA_OPTS="-Xms256m -Xmx512m -XX:+UseG1GC -XX:MaxGCPauseMillis=200"

# Instalar wget para healthcheck 
RUN apt-get update && apt-get install -y wget && rm -rf /var/lib/apt/lists/*

# Crear directorios necesarios
RUN mkdir -p /app /app/logs

# Directorio de trabajo
WORKDIR /app

# Copiar JAR compilado desde el builder
COPY --from=builder /build/target/*.jar app.jar

# Healthcheck para Docker
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080/actuator/health/liveness || exit 1

# Exponer puerto
EXPOSE 8080

# Punto de entrada
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
