package com.project.transactionn.dto;


import java.time.LocalDateTime;

public class PaymentTransactionDTO {
    private Integer id;
    private Integer paymentId;
    private String status;
    private LocalDateTime createdAt;

    // Constructor
    public PaymentTransactionDTO(Integer id, Integer paymentId, String status, LocalDateTime createdAt) {
        this.id = id;
        this.paymentId = paymentId;
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

    public Integer getPaymentId() {
        return paymentId;
    }

    public void setPaymentId(Integer paymentId) {
        this.paymentId = paymentId;
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
