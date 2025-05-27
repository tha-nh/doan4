package com.project.transactionn.dto;

public class NotificationRequest {
    private String message;
    private String randomCode; // Mã random

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    public String getRandomCode() {
        return randomCode;
    }

    public void setRandomCode(String randomCode) {
        this.randomCode = randomCode;
    }

    @Override
    public String toString() {
        return "NotificationRequest{" +
                "message='" + message + '\'' +
                ", randomCode='" + randomCode + '\'' +
                '}';
    }
}
