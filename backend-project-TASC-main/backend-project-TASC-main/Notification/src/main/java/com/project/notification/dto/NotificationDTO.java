package com.project.notification.dto;

public class NotificationDTO {
    private String randomCode;
    private String message;

    public String getRandomCode() {
        return randomCode;
    }

    public void setRandomCode(String randomCode) {
        this.randomCode = randomCode;
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    @Override
    public String toString() {
        return "NotificationDTO{" +
                "randomCode='" + randomCode + '\'' +
                ", message='" + message + '\'' +
                '}';
    }
}
