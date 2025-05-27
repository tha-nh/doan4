package com.project.transactionn.service.impl;

import com.project.transactionn.dto.NotificationRequest;
import com.project.transactionn.service.NotificationService;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

@Service
public class NotificationServiceImpl implements NotificationService {

    private final RestTemplate restTemplate  = new RestTemplate();

    @Override
    public void sendNotification(NotificationRequest notificationRequest) {
        System.out.println("gọi sang notification service");
        String url = "http://localhost:8080/api/notifications/send";
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        HttpEntity<NotificationRequest> entity = new HttpEntity<>(notificationRequest, headers);
        try {
            ResponseEntity<Void> response = restTemplate.exchange(url, HttpMethod.POST, entity, Void.class);
            System.out.println("API Response Status: " + response.getStatusCode());
        } catch (Exception e) {
            System.err.println("Lỗi khi gọi API Transaction: " + e.getMessage());
        }
    }
}
