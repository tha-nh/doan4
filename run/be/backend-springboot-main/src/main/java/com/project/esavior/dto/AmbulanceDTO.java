package com.project.esavior.dto;

import java.time.LocalDateTime;

public class AmbulanceDTO {

    private Integer ambulanceId;
    private String ambulanceNumber;
    private Integer driverId; // Chỉ lưu trữ ID của Driver
    private String ambulanceStatus;
    private String ambulanceType;
    private Integer hospitalId; // Chỉ lưu trữ ID của Hospital
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    // Constructor không tham số
    public AmbulanceDTO() {
    }

    // Constructor có tham số nếu cần thiết
    public AmbulanceDTO(Integer ambulanceId, String ambulanceNumber, Integer driverId, String ambulanceStatus,
                        String ambulanceType, Integer hospitalId, LocalDateTime createdAt, LocalDateTime updatedAt) {
        this.ambulanceId = ambulanceId;
        this.ambulanceNumber = ambulanceNumber;
        this.driverId = driverId;
        this.ambulanceStatus = ambulanceStatus;
        this.ambulanceType = ambulanceType;
        this.hospitalId = hospitalId;
        this.createdAt = createdAt;
        this.updatedAt = updatedAt;
    }

    public Integer getAmbulanceId() {
        return ambulanceId;
    }

    public void setAmbulanceId(Integer ambulanceId) {
        this.ambulanceId = ambulanceId;
    }

    public String getAmbulanceNumber() {
        return ambulanceNumber;
    }

    public void setAmbulanceNumber(String ambulanceNumber) {
        this.ambulanceNumber = ambulanceNumber;
    }

    public Integer getDriverId() {
        return driverId;
    }

    public void setDriverId(Integer driverId) {
        this.driverId = driverId;
    }

    public String getAmbulanceStatus() {
        return ambulanceStatus;
    }

    public void setAmbulanceStatus(String ambulanceStatus) {
        this.ambulanceStatus = ambulanceStatus;
    }

    public String getAmbulanceType() {
        return ambulanceType;
    }

    public void setAmbulanceType(String ambulanceType) {
        this.ambulanceType = ambulanceType;
    }

    public Integer getHospitalId() {
        return hospitalId;
    }

    public void setHospitalId(Integer hospitalId) {
        this.hospitalId = hospitalId;
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
// Getters và Setters cho từng trường

}
