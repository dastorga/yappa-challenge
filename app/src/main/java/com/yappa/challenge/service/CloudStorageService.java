package com.yappa.challenge.service;

import com.google.cloud.storage.Blob;
import com.google.cloud.storage.BlobId;
import com.google.cloud.storage.BlobInfo;
import com.google.cloud.storage.Storage;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.stereotype.Service;

import java.nio.charset.StandardCharsets;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;

/**
 * Servicio para interactuar con Google Cloud Storage
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class CloudStorageService {

    private final Storage storage;
    
    @Qualifier("storageBucketName")
    private final String bucketName;

    /**
     * Subir un archivo de texto a Cloud Storage
     */
    public String uploadTextFile(String fileName, String content, String folder) {
        try {
            String fullPath = folder + "/" + fileName;
            BlobId blobId = BlobId.of(bucketName, fullPath);
            BlobInfo blobInfo = BlobInfo.newBuilder(blobId)
                    .setContentType("text/plain; charset=utf-8")
                    .build();

            Blob blob = storage.create(blobInfo, content.getBytes(StandardCharsets.UTF_8));
            
            log.info("Archivo subido exitosamente: gs://{}/{}", bucketName, fullPath);
            return blob.getName();
        } catch (Exception e) {
            log.error("Error al subir archivo a Cloud Storage: {}", e.getMessage(), e);
            throw new RuntimeException("Error al subir archivo: " + e.getMessage(), e);
        }
    }

    /**
     * Descargar el contenido de un archivo como String
     */
    public String downloadTextFile(String fileName, String folder) {
        try {
            String fullPath = folder + "/" + fileName;
            BlobId blobId = BlobId.of(bucketName, fullPath);
            Blob blob = storage.get(blobId);
            
            if (blob == null) {
                log.warn("Archivo no encontrado: gs://{}/{}", bucketName, fullPath);
                return null;
            }
            
            byte[] content = blob.getContent();
            String result = new String(content, StandardCharsets.UTF_8);
            
            log.info("Archivo descargado exitosamente: gs://{}/{}", bucketName, fullPath);
            return result;
        } catch (Exception e) {
            log.error("Error al descargar archivo de Cloud Storage: {}", e.getMessage(), e);
            throw new RuntimeException("Error al descargar archivo: " + e.getMessage(), e);
        }
    }

    /**
     * Listar archivos en una carpeta
     */
    public List<String> listFiles(String folder) {
        try {
            List<String> fileNames = new ArrayList<>();
            String prefix = folder + "/";
            
            for (Blob blob : storage.list(bucketName, Storage.BlobListOption.prefix(prefix)).iterateAll()) {
                // Remover el prefijo de la carpeta del nombre
                String fileName = blob.getName().substring(prefix.length());
                if (!fileName.isEmpty()) {
                    fileNames.add(fileName);
                }
            }
            
            log.info("Listados {} archivos en la carpeta: {}", fileNames.size(), folder);
            return fileNames;
        } catch (Exception e) {
            log.error("Error al listar archivos de Cloud Storage: {}", e.getMessage(), e);
            throw new RuntimeException("Error al listar archivos: " + e.getMessage(), e);
        }
    }

    /**
     * Eliminar un archivo
     */
    public boolean deleteFile(String fileName, String folder) {
        try {
            String fullPath = folder + "/" + fileName;
            BlobId blobId = BlobId.of(bucketName, fullPath);
            boolean deleted = storage.delete(blobId);
            
            if (deleted) {
                log.info("Archivo eliminado exitosamente: gs://{}/{}", bucketName, fullPath);
            } else {
                log.warn("Archivo no encontrado para eliminar: gs://{}/{}", bucketName, fullPath);
            }
            
            return deleted;
        } catch (Exception e) {
            log.error("Error al eliminar archivo de Cloud Storage: {}", e.getMessage(), e);
            throw new RuntimeException("Error al eliminar archivo: " + e.getMessage(), e);
        }
    }

    /**
     * Guardar logs de aplicación en Cloud Storage
     */
    public String saveApplicationLog(String logContent) {
        String timestamp = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd_HH-mm-ss"));
        String fileName = "app-log-" + timestamp + ".log";
        return uploadTextFile(fileName, logContent, "app-logs");
    }

    /**
     * Hacer backup de datos en Cloud Storage
     */
    public String saveBackup(String backupData, String backupName) {
        String timestamp = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd_HH-mm-ss"));
        String fileName = backupName + "-" + timestamp + ".json";
        return uploadTextFile(fileName, backupData, "backups");
    }
}