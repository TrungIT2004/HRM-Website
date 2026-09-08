package com.minhtrung.social_app;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableAsync;
import org.springframework.scheduling.annotation.EnableScheduling;

import io.swagger.v3.oas.annotations.OpenAPIDefinition;
import io.swagger.v3.oas.annotations.info.Info;

@SpringBootApplication
@EnableAsync
@EnableScheduling
@OpenAPIDefinition(info = @Info(
title = "HRM API",
version = "1.0",
description = "API documentation for HRM Website"
))
public class SocialAppApplication {
	public static void main(String[] args) {
 		System.out.println("🔥🔥🔥 APPLICATION STARTING 🔥🔥🔥");
        SpringApplication.run(SocialAppApplication.class, args);
		System.out.println("🔥🔥🔥 APPLICATION STARTED 🔥🔥🔥");
	}
}
