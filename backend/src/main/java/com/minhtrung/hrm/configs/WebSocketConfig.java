package com.minhtrung.hrm.configs;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.messaging.simp.config.ChannelRegistration;
import org.springframework.messaging.simp.config.MessageBrokerRegistry;
import org.springframework.web.socket.config.annotation.EnableWebSocketMessageBroker;
import org.springframework.web.socket.config.annotation.StompEndpointRegistry;
import org.springframework.web.socket.config.annotation.WebSocketMessageBrokerConfigurer;
import org.springframework.web.socket.server.HandshakeInterceptor;

import com.minhtrung.hrm.auth.services.JwtService;

import lombok.RequiredArgsConstructor;

import java.util.Map;

@Configuration
@EnableWebSocketMessageBroker
@RequiredArgsConstructor
public class WebSocketConfig implements WebSocketMessageBrokerConfigurer {

    private final JwtService jwtService;

    @Value("${jwt.secret.access}")
    private String accessSecret;

    @Override
    public void configureMessageBroker(MessageBrokerRegistry registry) {
        registry.enableSimpleBroker("/queue", "/topic");
        registry.setApplicationDestinationPrefixes("/app");
        registry.setUserDestinationPrefix("/user");
    }

    @Override
    public void registerStompEndpoints(StompEndpointRegistry registry) {
        registry.addEndpoint("/ws/notifications")
                .addInterceptors(jwtHandshakeInterceptor())
                .setAllowedOriginPatterns("*")
                .withSockJS();
    }

    @Override
    public void configureClientInboundChannel(ChannelRegistration registration) {
        registration.interceptors(new ChannelInterceptorAdapter());
    }

    private HandshakeInterceptor jwtHandshakeInterceptor() {
        return new HandshakeInterceptor() {
            @Override
            public boolean beforeHandshake(
                    org.springframework.http.server.ServerHttpRequest serverRequest,
                    org.springframework.http.server.ServerHttpResponse serverHttpResponse,
                    org.springframework.web.socket.WebSocketHandler webSocketHandler,
                    Map<String, Object> attributes) {
                String authHeader = serverRequest.getHeaders().getFirst("Authorization");
                if (authHeader != null && authHeader.startsWith("Bearer ")) {
                    String token = authHeader.substring(7);
                    try {
                        var tokenPayload = jwtService.extractAll(token, accessSecret);
                        String userId = tokenPayload.getUserId().toString();
                        if (userId != null) {
                            attributes.put("userId", userId);
                        }
                    } catch (Exception e) {
                        // Invalid token - connection will be rejected
                    }
                }
                return true;
            }

            @Override
            public void afterHandshake(
                    org.springframework.http.server.ServerHttpRequest serverRequest,
                    org.springframework.http.server.ServerHttpResponse serverHttpResponse,
                    org.springframework.web.socket.WebSocketHandler webSocketHandler,
                    Exception exception) {
                // No-op
            }
        };
    }

    private static class ChannelInterceptorAdapter implements org.springframework.messaging.support.ChannelInterceptor {
        @Override
        public org.springframework.messaging.Message<?> preSend(org.springframework.messaging.Message<?> message, org.springframework.messaging.MessageChannel channel) {
            return message;
        }
    }
}