package com.minhtrung.hrm.ai.configs;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.client.RestTemplate;

@Configuration
public class AiClientConfig {

    @Value("${ai.service.base-url:http://localhost:8000}")
    private String baseUrl = "http://localhost:8000";

    @Value("${ai.service.internal-secret:hrm-internal-key-secure-2024}")
    private String internalSecret = "hrm-internal-key-secure-2024";

    @Bean
    public RestTemplate aiRestTemplate() {
        return new RestTemplate();
    }

    public String getBaseUrl() {
        return baseUrl;
    }

    public String getInternalSecret() {
        return internalSecret;
    }
}
