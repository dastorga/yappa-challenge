package com.yappa.challenge.model.entity;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;

/**
 * Entidad para almacenar logs de actividad en Cloud SQL
 */
@Entity
@Table(name = "activity_logs")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ActivityLog {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String endpoint;

    @Column(nullable = false)
    private String method;

    @Column(name = "user_agent")
    private String userAgent;

    @Column(name = "remote_ip")
    private String remoteIp;

    @Column(name = "response_status")
    private Integer responseStatus;

    @Column(name = "execution_time_ms")
    private Long executionTimeMs;

    @Column(columnDefinition = "TEXT")
    private String requestBody;

    @Column(columnDefinition = "TEXT")
    private String responseBody;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    // Constructor de conveniencia
    public ActivityLog(String endpoint, String method, String userAgent, String remoteIp, 
                      Integer responseStatus, Long executionTimeMs) {
        this.endpoint = endpoint;
        this.method = method;
        this.userAgent = userAgent;
        this.remoteIp = remoteIp;
        this.responseStatus = responseStatus;
        this.executionTimeMs = executionTimeMs;
    }
}