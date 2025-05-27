package com.project.apigetway.config;

import com.project.apigetway.filter.AuthenFilter;
import org.springframework.cloud.gateway.route.RouteLocator;
import org.springframework.cloud.gateway.route.builder.RouteLocatorBuilder;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.server.reactive.ServerHttpRequest;
import org.springframework.http.server.reactive.ServerHttpResponse;
import org.springframework.web.cors.reactive.CorsUtils;
import org.springframework.web.server.ServerWebExchange;
import org.springframework.web.server.WebFilter;
import org.springframework.web.server.WebFilterChain;
import reactor.core.publisher.Mono;

@Configuration
public class BeanConfig {

    @Bean
    public RouteLocator customRouteLocator(RouteLocatorBuilder builder, AuthenFilter authenFilter) {
        return builder.routes()
                // Route cho UserService với JWT
                .route("UserServiceWithJwt", r -> r.path("/api/userservice/jwt/**")
                        .filters(f -> f.filter(authenFilter))  // Áp dụng AuthenFilter
                        .uri("lb://USERSERVICE"))  // Load balance đến USERSERVICE

                // Route cho UserService không sử dụng JWT
                .route("UserServicePublic", r -> r.path("/api/userservice/notjwt/**")
                        .uri("lb://USERSERVICE"))  // Load balance đến USERSERVICE (không cần filter)

                .route("Notification", r -> r.path("/ws/notification")
                        .uri("lb://NOTIFICATION"))  // Load balance đến notification

                .route("Notification", r -> r.path("/api/notifications/**")
                        .uri("lb://NOTIFICATION"))  // Load balance đến notification

                .route("Transactionn", r -> r.path("/api/transactions/**")
                        .uri("lb://TRANSACTIONN"))
                // Route cho AppointmentService
                .route("AppoinmentService", r -> r.path("/api/appointments/**")
                        .filters(f -> f.filter(authenFilter))  // Áp dụng AuthenFilter
                        .uri("lb://APPOINMENTSERVICE"))  // Load balance đến APPOINMENTSERVICE

                // Route cho PaymentService công khai (tạo payment)
                .route("PaymentServicePublic", r -> r.path("/api/paymentservice/create")
                        .uri("lb://PAYMENTSERVICE"))  // Load balance đến PAYMENTSERVICE (không cần filter)

                // Route cho PaymentService với JWT
                .route("PaymentService", r -> r.path("/api/paymentservice/**")
                        .filters(f -> f.filter(authenFilter))  // Áp dụng AuthenFilter
                        .uri("lb://PAYMENTSERVICE"))  // Load balance đến PAYMENTSERVICE

                .build();
    }

    // Cấu hình CORS như trước
    @Bean
    public WebFilter corsFilter() {
        return (ServerWebExchange ctx, WebFilterChain chain) -> {
            ServerHttpRequest request = ctx.getRequest();
            if (CorsUtils.isCorsRequest(request)) {
                ServerHttpResponse response = ctx.getResponse();
                if (request.getMethod() == HttpMethod.OPTIONS) {
                    HttpHeaders headers = response.getHeaders();
                    headers.add("Access-Control-Allow-Origin", "*");
                    headers.add("Access-Control-Allow-Methods", "GET, PUT, POST, DELETE, OPTIONS");
                    headers.add("Access-Control-Max-Age", "3600");
                    headers.add("Access-Control-Allow-Headers", "x-requested-with, authorization, Content-Type, Authorization, credential, X-XSRF-TOKEN");
                    response.setStatusCode(HttpStatus.OK);
                    return Mono.empty();
                }
            }
            return chain.filter(ctx);
        };
    }
}
