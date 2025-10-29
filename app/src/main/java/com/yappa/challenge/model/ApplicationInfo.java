package com.yappa.challenge.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * Modelo con información de la aplicación
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ApplicationInfo {
    private String name;
    private String version;
    private String environment;
    private String hostname;
    private String ipAddress;
    private String javaVersion;
    private Long totalRequests;
    private Long uptimeSeconds;
    private Long memoryUsedMB;
    private Long memoryMaxMB;
    private Integer processorsAvailable;
    private LocalDateTime timestamp;
}
