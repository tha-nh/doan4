package com.project.apigetway.filter;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ServerWebExchange;
import org.springframework.cloud.gateway.filter.GatewayFilter;
import org.springframework.cloud.gateway.filter.GatewayFilterChain;
import reactor.core.publisher.Mono;

import javax.crypto.SecretKey;

@Component
public class AuthenFilter implements GatewayFilter {

    @Value("${jwt.secret}")
    private String jwtSecret;

    @Override
    public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
        // Lấy token từ header Authorization
        String token = getTokenFromRequest(exchange);

        // Nếu không có JWT, cho phép đi tiếp
        if (token == null) {
            return chain.filter(exchange);
        }

        // Nếu có JWT, kiểm tra tính hợp lệ
        if (!isValidToken(token)) {
            exchange.getResponse().setStatusCode(HttpStatus.UNAUTHORIZED);
            return exchange.getResponse().setComplete();
        }

        // Token hợp lệ, tiếp tục chuyển tiếp yêu cầu
        return chain.filter(exchange);
    }

    private String getTokenFromRequest(ServerWebExchange exchange) {
        String token = exchange.getRequest().getHeaders().getFirst(HttpHeaders.AUTHORIZATION);
        if (token != null && token.startsWith("Bearer ")) {
            return token.substring(7); // Loại bỏ "Bearer "
        }
        return null;
    }

    private boolean isValidToken(String token) {
        try {
            getClaimsFromToken(token); // Kiểm tra tính hợp lệ thông qua việc phân tích token
            return true;
        } catch (Exception e) {
            return false;
        }
    }

    private Claims getClaimsFromToken(String token) {
        try {
            SecretKey secretKey = Keys.hmacShaKeyFor(jwtSecret.getBytes());
            return Jwts.parserBuilder()
                    .setSigningKey(secretKey)
                    .build()
                    .parseClaimsJws(token)
                    .getBody();
        } catch (Exception e) {
            throw new RuntimeException("Invalid token", e);
        }
    }
}
