package com.project.appoinmentservice.dto;

public class ResponseDTO {
    private int code;
    private String message;

    public ResponseDTO(int code, String message) {
        this.code = code;
        this.message = message;
    }

    // Getter và Setter
    public int getCode() {
        return code;
    }

    public void setCode(int code) {
        this.code = code;
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }
}

