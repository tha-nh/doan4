package com.project.esavior.dto;

import java.time.LocalDateTime;

public class DriverDTO {
    private Integer driverId;
    private String driverName;
    private String email;
    private String password;
    private String driverPhone;
    private String licenseNumber;
    private String status;
    private Double latitude;
    private Double longitude;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    private Integer hospitalId; // Chỉ lưu trữ ID của Hospital
    private Integer ambulanceId; // Chỉ lưu trữ ID của Ambulance

    // Constructor không tham số
    public DriverDTO() {}

    public DriverDTO(Integer driverId, String driverName, String driverPhone, Double longitude, Double latitude, String status) {
        this.driverId = driverId;
        this.driverName = driverName;
        this.driverPhone = driverPhone;
        this.longitude = longitude;
        this.latitude = latitude;
        this.status = status;
    }

    public DriverDTO(Integer driverId, String driverName, String email, String driverPhone, String licenseNumber, String status) {
        this.driverId = driverId;
        this.driverName = driverName;
        this.email = email;
        this.driverPhone = driverPhone;
        this.status = status;
    }

    // Constructor có tham số
    public DriverDTO(Integer driverId, String driverName, String email, String driverPhone,
                     String licenseNumber, String status, Double latitude, Double longitude,
                     LocalDateTime createdAt, LocalDateTime updatedAt, Integer hospitalId, Integer ambulanceId) {
        this.driverId = driverId;
        this.driverName = driverName;
        this.email = email;
        this.driverPhone = driverPhone;
        this.licenseNumber = licenseNumber;
        this.status = status;
        this.latitude = latitude;
        this.longitude = longitude;
        this.createdAt = createdAt;
        this.updatedAt = updatedAt;
        this.hospitalId = hospitalId;
        this.ambulanceId = ambulanceId;
    }

    public DriverDTO(Integer driverId, String driverPhone, String driverName, Double longitude, Double latitude) {
    }

    // Getters và Setters cho từng trường


    public String getPassword() {
        return password;
    }

    public void setPassword(String password) {
        this.password = password;
    }

    public Integer getDriverId() {
        return driverId;
    }

    public void setDriverId(Integer driverId) {
        this.driverId = driverId;
    }

    public String getDriverName() {
        return driverName;
    }

    public void setDriverName(String driverName) {
        this.driverName = driverName;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getDriverPhone() {
        return driverPhone;
    }

    public void setDriverPhone(String driverPhone) {
        this.driverPhone = driverPhone;
    }

    public String getLicenseNumber() {
        return licenseNumber;
    }

    public void setLicenseNumber(String licenseNumber) {
        this.licenseNumber = licenseNumber;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public Double getLatitude() {
        return latitude;
    }

    public void setLatitude(Double latitude) {
        this.latitude = latitude;
    }

    public Double getLongitude() {
        return longitude;
    }

    public void setLongitude(Double longitude) {
        this.longitude = longitude;
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

    public Integer getHospitalId() {
        return hospitalId;
    }

    public void setHospitalId(Integer hospitalId) {
        this.hospitalId = hospitalId;
    }

    public Integer getAmbulanceId() {
        return ambulanceId;
    }

    public void setAmbulanceId(Integer ambulanceId) {
        this.ambulanceId = ambulanceId;
    }
}
