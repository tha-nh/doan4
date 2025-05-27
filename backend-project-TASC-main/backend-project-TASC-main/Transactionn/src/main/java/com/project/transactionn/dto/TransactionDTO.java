package com.project.transactionn.dto;



import jakarta.persistence.PrePersist;

import java.time.LocalDateTime;

public class TransactionDTO {
    private Integer id;
    private String referenceGroupId;
    private String status;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    public TransactionDTO(Integer id, String referenceGroupId,
                          String status, LocalDateTime createdAt, LocalDateTime updatedAt) {
        this.id = id;
        this.referenceGroupId = referenceGroupId;
        this.status = status;
        this.createdAt = createdAt;
        this.updatedAt = updatedAt;
    }
    @PrePersist
    public void prePersist() {
        if (this.status == null) {
            this.status = "pending";
        }
    }

    // Getters and Setters
    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }

    public String getReferenceGroupId() {
        return referenceGroupId;
    }

    public void setReferenceGroupId(String referenceGroupId) {
        this.referenceGroupId = referenceGroupId;
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

    public LocalDateTime getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(LocalDateTime updatedAt) {
        this.updatedAt = updatedAt;
    }
}
