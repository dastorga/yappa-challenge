package com.yappa.challenge.controller;

import com.yappa.challenge.service.ApplicationInfoService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import static org.hamcrest.Matchers.*;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(MainController.class)
@ActiveProfiles("test")
class MainControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private ApplicationInfoService applicationInfoService;

    @Test
    void testHome() throws Exception {
        when(applicationInfoService.getVersion()).thenReturn("1.0.0");
        when(applicationInfoService.getEnvironment()).thenReturn("test");
        when(applicationInfoService.getHostname()).thenReturn("localhost");

        mockMvc.perform(get("/"))
            .andExpect(status().isOk())
            .andExpect(content().contentType(MediaType.APPLICATION_JSON))
            .andExpect(jsonPath("$.success").value(true))
            .andExpect(jsonPath("$.data.message").value(containsString("Bienvenido")))
            .andExpect(jsonPath("$.data.version").value("1.0.0"))
            .andExpect(jsonPath("$.data.environment").value("test"));
    }

    @Test
    void testEchoGet() throws Exception {
        mockMvc.perform(get("/api/echo")
                .param("test", "value")
                .param("foo", "bar"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.success").value(true))
            .andExpect(jsonPath("$.data.method").value("GET"))
            .andExpect(jsonPath("$.data.params.test").value("value"))
            .andExpect(jsonPath("$.data.params.foo").value("bar"));
    }

    @Test
    void testEchoPost() throws Exception {
        String jsonRequest = "{\"message\":\"test\",\"data\":{\"key\":\"value\"}}";

        mockMvc.perform(post("/api/echo")
                .contentType(MediaType.APPLICATION_JSON)
                .content(jsonRequest))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.success").value(true))
            .andExpect(jsonPath("$.data.message").value("test"))
            .andExpect(jsonPath("$.data.data.key").value("value"));
    }

    @Test
    void testErrorEndpoint() throws Exception {
        mockMvc.perform(get("/api/error"))
            .andExpect(status().isInternalServerError())
            .andExpect(jsonPath("$.success").value(false))
            .andExpect(jsonPath("$.statusCode").value(500));
    }
}
