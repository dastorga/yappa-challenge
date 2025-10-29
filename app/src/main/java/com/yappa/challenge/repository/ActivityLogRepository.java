package com.yappa.challenge.repository;

import com.yappa.challenge.model.entity.ActivityLog;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

/**
 * Repositorio para ActivityLog usando Cloud SQL PostgreSQL
 */
@Repository
public interface ActivityLogRepository extends JpaRepository<ActivityLog, Long> {

    /**
     * Buscar logs por endpoint
     */
    List<ActivityLog> findByEndpointContainingIgnoreCase(String endpoint);

    /**
     * Buscar logs por método HTTP
     */
    List<ActivityLog> findByMethod(String method);

    /**
     * Buscar logs por rango de fechas
     */
    @Query("SELECT a FROM ActivityLog a WHERE a.createdAt BETWEEN :startDate AND :endDate ORDER BY a.createdAt DESC")
    List<ActivityLog> findByDateRange(@Param("startDate") LocalDateTime startDate, 
                                     @Param("endDate") LocalDateTime endDate);

    /**
     * Buscar logs por status de respuesta
     */
    List<ActivityLog> findByResponseStatus(Integer responseStatus);

    /**
     * Obtener logs recientes
     */
    List<ActivityLog> findTop10ByOrderByCreatedAtDesc();

    /**
     * Contar requests por endpoint en las últimas 24 horas
     */
    @Query("SELECT a.endpoint, COUNT(a) FROM ActivityLog a WHERE a.createdAt >= :since GROUP BY a.endpoint ORDER BY COUNT(a) DESC")
    List<Object[]> countRequestsByEndpointSince(@Param("since") LocalDateTime since);

    /**
     * Obtener tiempo promedio de ejecución por endpoint
     */
    @Query("SELECT a.endpoint, AVG(a.executionTimeMs) FROM ActivityLog a WHERE a.executionTimeMs IS NOT NULL GROUP BY a.endpoint")
    List<Object[]> getAverageExecutionTimeByEndpoint();
}