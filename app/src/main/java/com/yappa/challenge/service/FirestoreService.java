package com.yappa.challenge.service;

import com.google.cloud.firestore.DocumentReference;
import com.google.cloud.firestore.DocumentSnapshot;
import com.google.cloud.firestore.Firestore;
import com.google.cloud.firestore.QueryDocumentSnapshot;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ExecutionException;
import java.util.stream.Collectors;

/**
 * Servicio para interactuar con Google Cloud Firestore
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class FirestoreService {

    private final Firestore firestore;
    
    private static final String COLLECTION_METRICS = "application_metrics";
    private static final String COLLECTION_SESSIONS = "user_sessions";
    private static final String COLLECTION_EVENTS = "application_events";

    /**
     * Guardar métricas de aplicación en Firestore
     */
    public void saveApplicationMetrics(String metricName, Object value, Map<String, Object> tags) {
        try {
            Map<String, Object> data = new HashMap<>();
            data.put("metric_name", metricName);
            data.put("value", value);
            data.put("tags", tags != null ? tags : new HashMap<>());
            data.put("timestamp", LocalDateTime.now().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME));
            data.put("environment", "dev");

            String docId = metricName + "_" + System.currentTimeMillis();
            DocumentReference docRef = firestore.collection(COLLECTION_METRICS).document(docId);
            
            docRef.set(data).get();
            log.info("Métrica guardada en Firestore: {} = {}", metricName, value);
        } catch (Exception e) {
            log.error("Error al guardar métrica en Firestore: {}", e.getMessage(), e);
            throw new RuntimeException("Error al guardar métrica: " + e.getMessage(), e);
        }
    }

    /**
     * Obtener métricas por nombre
     */
    public List<Map<String, Object>> getMetricsByName(String metricName) {
        try {
            return firestore.collection(COLLECTION_METRICS)
                    .whereEqualTo("metric_name", metricName)
                    .orderBy("timestamp", com.google.cloud.firestore.Query.Direction.DESCENDING)
                    .limit(100)
                    .get()
                    .get()
                    .getDocuments()
                    .stream()
                    .map(QueryDocumentSnapshot::getData)
                    .collect(Collectors.toList());
        } catch (Exception e) {
            log.error("Error al obtener métricas de Firestore: {}", e.getMessage(), e);
            throw new RuntimeException("Error al obtener métricas: " + e.getMessage(), e);
        }
    }

    /**
     * Guardar sesión de usuario
     */
    public String saveUserSession(String sessionId, String userAgent, String remoteIp) {
        try {
            Map<String, Object> sessionData = new HashMap<>();
            sessionData.put("session_id", sessionId);
            sessionData.put("user_agent", userAgent);
            sessionData.put("remote_ip", remoteIp);
            sessionData.put("start_time", LocalDateTime.now().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME));
            sessionData.put("last_activity", LocalDateTime.now().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME));
            sessionData.put("active", true);

            DocumentReference docRef = firestore.collection(COLLECTION_SESSIONS).document(sessionId);
            docRef.set(sessionData).get();
            
            log.info("Sesión de usuario guardada en Firestore: {}", sessionId);
            return sessionId;
        } catch (Exception e) {
            log.error("Error al guardar sesión en Firestore: {}", e.getMessage(), e);
            throw new RuntimeException("Error al guardar sesión: " + e.getMessage(), e);
        }
    }

    /**
     * Actualizar última actividad de sesión
     */
    public void updateSessionActivity(String sessionId) {
        try {
            DocumentReference docRef = firestore.collection(COLLECTION_SESSIONS).document(sessionId);
            Map<String, Object> updates = new HashMap<>();
            updates.put("last_activity", LocalDateTime.now().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME));
            
            docRef.update(updates).get();
            log.debug("Actividad de sesión actualizada: {}", sessionId);
        } catch (Exception e) {
            log.error("Error al actualizar sesión en Firestore: {}", e.getMessage(), e);
        }
    }

    /**
     * Cerrar sesión de usuario
     */
    public void closeUserSession(String sessionId) {
        try {
            DocumentReference docRef = firestore.collection(COLLECTION_SESSIONS).document(sessionId);
            Map<String, Object> updates = new HashMap<>();
            updates.put("end_time", LocalDateTime.now().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME));
            updates.put("active", false);
            
            docRef.update(updates).get();
            log.info("Sesión cerrada en Firestore: {}", sessionId);
        } catch (Exception e) {
            log.error("Error al cerrar sesión en Firestore: {}", e.getMessage(), e);
        }
    }

    /**
     * Guardar evento de aplicación
     */
    public void saveApplicationEvent(String eventType, String description, Map<String, Object> metadata) {
        try {
            Map<String, Object> eventData = new HashMap<>();
            eventData.put("event_type", eventType);
            eventData.put("description", description);
            eventData.put("metadata", metadata != null ? metadata : new HashMap<>());
            eventData.put("timestamp", LocalDateTime.now().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME));
            eventData.put("environment", "dev");

            String docId = eventType + "_" + System.currentTimeMillis();
            DocumentReference docRef = firestore.collection(COLLECTION_EVENTS).document(docId);
            
            docRef.set(eventData).get();
            log.info("Evento guardado en Firestore: {}", eventType);
        } catch (Exception e) {
            log.error("Error al guardar evento en Firestore: {}", e.getMessage(), e);
            throw new RuntimeException("Error al guardar evento: " + e.getMessage(), e);
        }
    }

    /**
     * Obtener eventos recientes
     */
    public List<Map<String, Object>> getRecentEvents(int limit) {
        try {
            return firestore.collection(COLLECTION_EVENTS)
                    .orderBy("timestamp", com.google.cloud.firestore.Query.Direction.DESCENDING)
                    .limit(limit)
                    .get()
                    .get()
                    .getDocuments()
                    .stream()
                    .map(QueryDocumentSnapshot::getData)
                    .collect(Collectors.toList());
        } catch (Exception e) {
            log.error("Error al obtener eventos de Firestore: {}", e.getMessage(), e);
            throw new RuntimeException("Error al obtener eventos: " + e.getMessage(), e);
        }
    }

    /**
     * Obtener estadísticas de aplicación desde Firestore
     */
    public Map<String, Object> getApplicationStats() {
        try {
            Map<String, Object> stats = new HashMap<>();
            
            // Contar sesiones activas
            long activeSessions = firestore.collection(COLLECTION_SESSIONS)
                    .whereEqualTo("active", true)
                    .get()
                    .get()
                    .size();
            stats.put("active_sessions", activeSessions);
            
            // Contar eventos del día
            String today = LocalDateTime.now().toLocalDate().toString();
            long todayEvents = firestore.collection(COLLECTION_EVENTS)
                    .whereGreaterThanOrEqualTo("timestamp", today)
                    .get()
                    .get()
                    .size();
            stats.put("today_events", todayEvents);
            
            return stats;
        } catch (Exception e) {
            log.error("Error al obtener estadísticas de Firestore: {}", e.getMessage(), e);
            return new HashMap<>();
        }
    }
}