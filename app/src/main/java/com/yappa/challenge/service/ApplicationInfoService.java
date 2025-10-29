package com.yappa.challenge.service;

import com.yappa.challenge.model.ApplicationInfo;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.lang.management.ManagementFactory;
import java.net.InetAddress;
import java.net.UnknownHostException;
import java.time.Duration;
import java.time.LocalDateTime;
import java.util.concurrent.atomic.AtomicLong;

/**
 * Servicio para gestionar información de la aplicación
 */
@Slf4j
@Service
public class ApplicationInfoService {

    private final AtomicLong requestCount = new AtomicLong(0);
    private final LocalDateTime startTime = LocalDateTime.now();

    @Value("${app.name:yappa-challenge}")
    private String appName;

    @Value("${app.version:1.0.0}")
    private String version;

    @Value("${app.environment:development}")
    private String environment;

    /**
     * Incrementa y retorna el contador de requests
     */
    public long incrementRequestCount() {
        return requestCount.incrementAndGet();
    }

    /**
     * Obtiene el contador actual de requests
     */
    public long getRequestCount() {
        return requestCount.get();
    }

    /**
     * Obtiene el tiempo de uptime en segundos
     */
    public long getUptimeSeconds() {
        return Duration.between(startTime, LocalDateTime.now()).getSeconds();
    }

    /**
     * Obtiene el hostname del servidor
     */
    public String getHostname() {
        try {
            return InetAddress.getLocalHost().getHostName();
        } catch (UnknownHostException e) {
            log.warn("No se pudo obtener hostname: {}", e.getMessage());
            return "unknown";
        }
    }

    /**
     * Obtiene la IP local del servidor
     */
    public String getIpAddress() {
        try {
            return InetAddress.getLocalHost().getHostAddress();
        } catch (UnknownHostException e) {
            log.warn("No se pudo obtener IP: {}", e.getMessage());
            return "unknown";
        }
    }

    /**
     * Obtiene la versión de la aplicación
     */
    public String getVersion() {
        return version;
    }

    /**
     * Obtiene el ambiente actual
     */
    public String getEnvironment() {
        return environment;
    }

    /**
     * Obtiene información completa de la aplicación
     */
    public ApplicationInfo getApplicationInfo() {
        Runtime runtime = Runtime.getRuntime();
        
        return ApplicationInfo.builder()
            .name(appName)
            .version(version)
            .environment(environment)
            .hostname(getHostname())
            .ipAddress(getIpAddress())
            .javaVersion(System.getProperty("java.version"))
            .totalRequests(getRequestCount())
            .uptimeSeconds(getUptimeSeconds())
            .memoryUsedMB((runtime.totalMemory() - runtime.freeMemory()) / 1024 / 1024)
            .memoryMaxMB(runtime.maxMemory() / 1024 / 1024)
            .processorsAvailable(runtime.availableProcessors())
            .timestamp(LocalDateTime.now())
            .build();
    }
}
