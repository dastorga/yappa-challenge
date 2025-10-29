package com.yappa.challenge.config;

import com.google.cloud.firestore.Firestore;
import com.google.cloud.firestore.FirestoreOptions;
import com.google.cloud.storage.Storage;
import com.google.cloud.storage.StorageOptions;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;

/**
 * Configuración para los servicios de Google Cloud
 */
@Configuration
@Slf4j
public class GoogleCloudConfig {

    @Value("${google.cloud.project-id}")
    private String projectId;

    @Value("${google.cloud.storage.bucket-name}")
    private String bucketName;

    /**
     * Bean para Google Cloud Storage
     */
    @Bean
    public Storage googleCloudStorage() {
        log.info("Configurando Google Cloud Storage para proyecto: {}", projectId);
        return StorageOptions.newBuilder()
                .setProjectId(projectId)
                .build()
                .getService();
    }

    /**
     * Bean para Google Cloud Firestore
     */
    @Bean
    public Firestore googleCloudFirestore() {
        log.info("Configurando Google Cloud Firestore para proyecto: {}", projectId);
        return FirestoreOptions.newBuilder()
                .setProjectId(projectId)
                .build()
                .getService();
    }

    /**
     * Getter para el nombre del bucket (para inyección en servicios)
     */
    @Bean("storageBucketName")
    public String getStorageBucketName() {
        return bucketName;
    }
}