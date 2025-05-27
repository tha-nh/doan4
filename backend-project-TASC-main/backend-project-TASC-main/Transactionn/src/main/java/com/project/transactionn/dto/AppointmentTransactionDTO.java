package com.project.transactionn.dto;


import java.time.LocalDateTime;

public class AppointmentTransactionDTO {
    private Integer id;
    private Integer appointmentId;
    private String status;
    private LocalDateTime createdAt;

    // Constructor
    public AppointmentTransactionDTO(Integer id, Integer appointmentId, String status, LocalDateTime createdAt) {
        this.id = id;
        this.appointmentId = appointmentId;
        this.status = status;
        this.createdAt = createdAt;
    }

    // Getters and Setters
    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }

    public Integer getAppointmentId() {
        return appointmentId;
    }

    public void setAppointmentId(Integer appointmentId) {
        this.appointmentId = appointmentId;
    }


    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
}
