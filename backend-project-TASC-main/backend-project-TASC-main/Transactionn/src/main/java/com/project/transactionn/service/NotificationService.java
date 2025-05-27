package com.project.transactionn.service;

import com.project.transactionn.dto.NotificationRequest;
import org.springframework.stereotype.Service;

@Service
public interface NotificationService {
    public void sendNotification(NotificationRequest notificationRequest);
}
