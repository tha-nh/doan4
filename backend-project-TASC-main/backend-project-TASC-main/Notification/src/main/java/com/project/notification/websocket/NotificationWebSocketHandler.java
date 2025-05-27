package com.project.notification.websocket;

import org.springframework.web.socket.WebSocketHandler;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.CloseStatus;
import org.springframework.web.socket.WebSocketMessage;
import java.io.IOException;
import java.util.concurrent.ConcurrentHashMap;


public class NotificationWebSocketHandler implements WebSocketHandler {

    // Lưu trữ các WebSocket session theo randomCode
    private static final ConcurrentHashMap<String, WebSocketSession> sessions = new ConcurrentHashMap<>();

    @Override
    public void afterConnectionEstablished(WebSocketSession session) throws Exception {
        // Lấy randomCode từ URL
        String randomCode = (String) session.getUri().getQuery().split("=")[1]; // Lấy tham số randomCode từ URL

        System.out.println("New WebSocket connection established with randomCode: " + randomCode);

        // Lưu session của client vào map theo randomCode
        sessions.put(randomCode, session);
    }

    @Override
    public void handleMessage(WebSocketSession session, WebSocketMessage<?> message) throws Exception {
        // Xử lý thông điệp từ client
        System.out.println("Received message: " + message.getPayload());
        session.sendMessage(new TextMessage("Message received!"));
    }

    @Override
    public void handleTransportError(WebSocketSession session, Throwable exception) throws Exception {
        System.err.println("WebSocket error: " + exception.getMessage());
    }

    @Override
    public void afterConnectionClosed(WebSocketSession session, CloseStatus status) throws Exception {
        // Tìm randomCode từ session và loại bỏ khi kết nối bị đóng
        String randomCode = (String) session.getUri().getQuery().split("=")[1];
        sessions.remove(randomCode);
        System.out.println("WebSocket connection closed for randomCode: " + randomCode);
    }

    @Override
    public boolean supportsPartialMessages() {
        return false;
    }

    // Phương thức để gửi thông báo tới client theo randomCode
    public void sendNotification(String randomCode, String message) throws IOException {
        WebSocketSession session = sessions.get(randomCode);
        if (session != null && session.isOpen()) {
            session.sendMessage(new TextMessage(message)); // Gửi thông báo
        }
    }
}
