package com.project.esavior.config;

import com.project.esavior.websocket.websocket.WebSocketHandler;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.socket.config.annotation.EnableWebSocket;
import org.springframework.web.socket.config.annotation.WebSocketConfigurer;
import org.springframework.web.socket.config.annotation.WebSocketHandlerRegistry;

@Configuration
@EnableWebSocket
public class WebSocketConfig implements WebSocketConfigurer {

    @Override
    public void registerWebSocketHandlers(WebSocketHandlerRegistry registry) {
        // Đăng ký WebSocket endpoint chung cho cả tài xế và khách hàng
        registry.addHandler(webSocketHandler(), "/ws/common")
                .setAllowedOriginPatterns("*");  // Cấu hình lại CORS nếu cần
    }

    @Bean
    public WebSocketHandler webSocketHandler() {
        return new WebSocketHandler();  // Sử dụng Bean để tạo singleton
    }
}
