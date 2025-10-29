package com.yappa.challenge.model;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.Map;

/**
 * Modelo para request de echo
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class EchoRequest {
    private String message;
    private Map<String, Object> data;
}
