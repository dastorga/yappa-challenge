package com.yappa.challenge.controller;

import com.yappa.challenge.model.ApiResponse;
import com.yappa.challenge.model.ApplicationInfo;
import com.yappa.challenge.model.EchoRequest;
import com.yappa.challenge.model.entity.ActivityLog;
import com.yappa.challenge.repository.ActivityLogRepository;
import com.yappa.challenge.service.ApplicationInfoService;
import com.yappa.challenge.service.CloudStorageService;
import com.yappa.challenge.service.FirestoreService;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Controlador REST principal de la aplicación
 */
@Slf4j
@RestController
@RequestMapping
@RequiredArgsConstructor
public class MainController {

    private final ApplicationInfoService applicationInfoService;
    private final CloudStorageService cloudStorageService;
    private final FirestoreService firestoreService;
    private final ActivityLogRepository activityLogRepository;

    /**
     * Endpoint principal con mensaje de bienvenida
     */
    @GetMapping("/")
    public ResponseEntity<ApiResponse<Map<String, Object>>> home() {
        log.info("Request recibido en endpoint principal");
        
        Map<String, Object> data = Map.of(
            "message", "¡Bienvenido al Challenge DevOps de Yappa!",
            "application", "Yappa Challenge",
            "version", applicationInfoService.getVersion(),
            "environment", applicationInfoService.getEnvironment(),
            "hostname", applicationInfoService.getHostname(),
            "timestamp", LocalDateTime.now()
        );

        return ResponseEntity.ok(
            ApiResponse.success(data, "Bienvenida exitosa")
        );
    }

    /**
     * Endpoint de información detallada de la aplicación
     */
    @GetMapping("/api/info")
    public ResponseEntity<ApiResponse<ApplicationInfo>> getInfo() {
        log.info("Request recibido en /api/info");
        
        ApplicationInfo info = applicationInfoService.getApplicationInfo();
        return ResponseEntity.ok(
            ApiResponse.success(info, "Información obtenida exitosamente")
        );
    }

    /**
     * Endpoint de echo para pruebas
     */
    @PostMapping("/api/echo")
    public ResponseEntity<ApiResponse<EchoRequest>> echoPost(@RequestBody EchoRequest request) {
        log.info("POST request recibido en /api/echo: {}", request);
        return ResponseEntity.ok(
            ApiResponse.success(request, "Echo POST exitoso")
        );
    }

    @GetMapping("/api/echo")
    public ResponseEntity<ApiResponse<Map<String, Object>>> echoGet(@RequestParam Map<String, String> params) {
        log.info("GET request recibido en /api/echo con params: {}", params);
        
        Map<String, Object> data = Map.of(
            "method", "GET",
            "params", params,
            "timestamp", LocalDateTime.now()
        );

        return ResponseEntity.ok(
            ApiResponse.success(data, "Echo GET exitoso")
        );
    }

    /**
     * Endpoint para simular errores (útil para testing de monitoreo)
     */
    @GetMapping("/api/error")
    public ResponseEntity<ApiResponse<Void>> triggerError() {
        log.error("Endpoint de error llamado - simulando error 500");
        return ResponseEntity
            .status(HttpStatus.INTERNAL_SERVER_ERROR)
            .body(ApiResponse.error("Este es un error de prueba", HttpStatus.INTERNAL_SERVER_ERROR.value()));
    }

    /**
     * Endpoint para probar Cloud SQL - obtener logs de actividad
     */
    @GetMapping("/api/cloudsql/logs")
    public ResponseEntity<ApiResponse<List<ActivityLog>>> getActivityLogs() {
        log.info("Request recibido en /api/cloudsql/logs");
        
        try {
            List<ActivityLog> logs = activityLogRepository.findTop10ByOrderByCreatedAtDesc();
            
            // Guardar evento en Firestore
            Map<String, Object> metadata = new HashMap<>();
            metadata.put("logs_count", logs.size());
            firestoreService.saveApplicationEvent("cloudsql_query", "Consulta de logs de actividad", metadata);
            
            return ResponseEntity.ok(
                ApiResponse.success(logs, "Logs obtenidos exitosamente de Cloud SQL")
            );
        } catch (Exception e) {
            log.error("Error al obtener logs de Cloud SQL: {}", e.getMessage(), e);
            return ResponseEntity
                .status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(ApiResponse.error("Error al obtener logs: " + e.getMessage(), 500));
        }
    }

    /**
     * Endpoint para probar Cloud Storage - subir archivo
     */
    @PostMapping("/api/storage/upload")
    public ResponseEntity<ApiResponse<Map<String, Object>>> uploadToStorage(
            @RequestParam String fileName,
            @RequestParam String content,
            @RequestParam(defaultValue = "uploads") String folder) {
        log.info("Request recibido en /api/storage/upload - file: {}, folder: {}", fileName, folder);
        
        try {
            String uploadedPath = cloudStorageService.uploadTextFile(fileName, content, folder);
            
            Map<String, Object> result = new HashMap<>();
            result.put("fileName", fileName);
            result.put("path", uploadedPath);
            result.put("folder", folder);
            result.put("size", content.getBytes().length);
            result.put("timestamp", LocalDateTime.now());
            
            // Guardar evento en Firestore
            Map<String, Object> metadata = new HashMap<>();
            metadata.put("file_name", fileName);
            metadata.put("file_size", content.getBytes().length);
            metadata.put("folder", folder);
            firestoreService.saveApplicationEvent("storage_upload", "Archivo subido a Cloud Storage", metadata);
            
            return ResponseEntity.ok(
                ApiResponse.success(result, "Archivo subido exitosamente a Cloud Storage")
            );
        } catch (Exception e) {
            log.error("Error al subir archivo a Cloud Storage: {}", e.getMessage(), e);
            return ResponseEntity
                .status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(ApiResponse.error("Error al subir archivo: " + e.getMessage(), 500));
        }
    }

    /**
     * Endpoint para probar Cloud Storage - listar archivos
     */
    @GetMapping("/api/storage/list")
    public ResponseEntity<ApiResponse<Map<String, Object>>> listStorageFiles(
            @RequestParam(defaultValue = "uploads") String folder) {
        log.info("Request recibido en /api/storage/list - folder: {}", folder);
        
        try {
            List<String> files = cloudStorageService.listFiles(folder);
            
            Map<String, Object> result = new HashMap<>();
            result.put("folder", folder);
            result.put("files", files);
            result.put("count", files.size());
            result.put("timestamp", LocalDateTime.now());
            
            return ResponseEntity.ok(
                ApiResponse.success(result, "Archivos listados exitosamente de Cloud Storage")
            );
        } catch (Exception e) {
            log.error("Error al listar archivos de Cloud Storage: {}", e.getMessage(), e);
            return ResponseEntity
                .status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(ApiResponse.error("Error al listar archivos: " + e.getMessage(), 500));
        }
    }

    /**
     * Endpoint para probar Firestore - guardar métricas
     */
    @PostMapping("/api/firestore/metrics")
    public ResponseEntity<ApiResponse<Map<String, Object>>> saveMetrics(
            @RequestParam String metricName,
            @RequestParam String value,
            @RequestParam Map<String, String> tags) {
        log.info("Request recibido en /api/firestore/metrics - metric: {}, value: {}", metricName, value);
        
        try {
            Map<String, Object> tagMap = new HashMap<>(tags);
            firestoreService.saveApplicationMetrics(metricName, value, tagMap);
            
            Map<String, Object> result = new HashMap<>();
            result.put("metric_name", metricName);
            result.put("value", value);
            result.put("tags", tags);
            result.put("timestamp", LocalDateTime.now());
            
            return ResponseEntity.ok(
                ApiResponse.success(result, "Métrica guardada exitosamente en Firestore")
            );
        } catch (Exception e) {
            log.error("Error al guardar métrica en Firestore: {}", e.getMessage(), e);
            return ResponseEntity
                .status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(ApiResponse.error("Error al guardar métrica: " + e.getMessage(), 500));
        }
    }

    /**
     * Endpoint para probar Firestore - obtener estadísticas
     */
    @GetMapping("/api/firestore/stats")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getFirestoreStats() {
        log.info("Request recibido en /api/firestore/stats");
        
        try {
            Map<String, Object> stats = firestoreService.getApplicationStats();
            List<Map<String, Object>> recentEvents = firestoreService.getRecentEvents(5);
            
            Map<String, Object> result = new HashMap<>();
            result.put("stats", stats);
            result.put("recent_events", recentEvents);
            result.put("timestamp", LocalDateTime.now());
            
            return ResponseEntity.ok(
                ApiResponse.success(result, "Estadísticas obtenidas exitosamente de Firestore")
            );
        } catch (Exception e) {
            log.error("Error al obtener estadísticas de Firestore: {}", e.getMessage(), e);
            return ResponseEntity
                .status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(ApiResponse.error("Error al obtener estadísticas: " + e.getMessage(), 500));
        }
    }

    /**
     * Endpoint para crear sesión de usuario (simulado)
     */
    @PostMapping("/api/session/create")
    public ResponseEntity<ApiResponse<Map<String, Object>>> createSession(HttpServletRequest request) {
        log.info("Request recibido en /api/session/create");
        
        try {
            String sessionId = UUID.randomUUID().toString();
            String userAgent = request.getHeader("User-Agent");
            String remoteIp = request.getRemoteAddr();
            
            // Guardar en Firestore
            firestoreService.saveUserSession(sessionId, userAgent, remoteIp);
            
            // Guardar en Cloud SQL
            ActivityLog activityLog = new ActivityLog(
                "/api/session/create", "POST", userAgent, remoteIp, 200, 0L
            );
            activityLogRepository.save(activityLog);
            
            Map<String, Object> result = new HashMap<>();
            result.put("session_id", sessionId);
            result.put("user_agent", userAgent);
            result.put("remote_ip", remoteIp);
            result.put("timestamp", LocalDateTime.now());
            
            return ResponseEntity.ok(
                ApiResponse.success(result, "Sesión creada exitosamente")
            );
        } catch (Exception e) {
            log.error("Error al crear sesión: {}", e.getMessage(), e);
            return ResponseEntity
                .status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(ApiResponse.error("Error al crear sesión: " + e.getMessage(), 500));
        }
    }
}
