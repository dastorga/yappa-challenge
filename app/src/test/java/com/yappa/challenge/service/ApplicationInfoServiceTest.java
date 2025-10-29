package com.yappa.challenge.service;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

import static org.assertj.core.api.Assertions.assertThat;

// Temporalmente deshabilitado para debug
// @SpringBootTest
// @ActiveProfiles("test")
class ApplicationInfoServiceTest {

    @Autowired
    private ApplicationInfoService service;

    @Test
    void testIncrementRequestCount() {
        long initialCount = service.getRequestCount();
        service.incrementRequestCount();
        assertThat(service.getRequestCount()).isEqualTo(initialCount + 1);
    }

    @Test
    void testGetHostname() {
        String hostname = service.getHostname();
        assertThat(hostname).isNotNull();
        assertThat(hostname).isNotEmpty();
    }

    @Test
    void testGetIpAddress() {
        String ip = service.getIpAddress();
        assertThat(ip).isNotNull();
        assertThat(ip).isNotEmpty();
    }

    @Test
    void testGetApplicationInfo() {
        var info = service.getApplicationInfo();
        
        assertThat(info).isNotNull();
        assertThat(info.getName()).isNotEmpty();
        assertThat(info.getVersion()).isNotEmpty();
        assertThat(info.getJavaVersion()).isNotEmpty();
        assertThat(info.getTotalRequests()).isNotNull();
        assertThat(info.getUptimeSeconds()).isNotNull();
        assertThat(info.getTimestamp()).isNotNull();
    }
}
