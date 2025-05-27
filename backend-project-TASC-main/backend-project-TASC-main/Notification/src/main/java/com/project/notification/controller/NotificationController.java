package com.project.notification.controller;

import com.project.notification.dto.NotificationDTO;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import com.project.notification.websocket.NotificationWebSocketHandler;

@RestController
@RequestMapping("/api/notifications")
public class NotificationController {

    @Autowired
    private NotificationWebSocketHandler notificationWebSocketHandler;

    @PostMapping("/send")
    public String sendNotification(@RequestBody NotificationDTO notificationDTO) {
        System.out.println(notificationDTO.toString());
        try {
            // Gửi thông báo tới client với randomCode
            notificationWebSocketHandler.sendNotification(notificationDTO.getRandomCode(),notificationDTO.getMessage());
            return "Notification sent to " + notificationDTO.toString();
        } catch (Exception e) {
            return "Error sending notification: " + e.getMessage();
        }
    }
}
