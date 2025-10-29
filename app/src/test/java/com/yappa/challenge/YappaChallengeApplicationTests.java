package com.yappa.challenge;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@ActiveProfiles("test")
class YappaChallengeApplicationTests {

    @Test
    void contextLoads() {
        // Verificar que el contexto de Spring se carga correctamente
        assertTrue(true, "Context should load successfully");
    }

    @Test
    void simpleTest() {
        // Test básico para verificar que JUnit funciona
        assertEquals(2, 1 + 1, "Basic arithmetic should work");
    }
}
