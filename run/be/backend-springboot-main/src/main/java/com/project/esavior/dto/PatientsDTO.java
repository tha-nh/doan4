package com.project.esavior.dto;

import java.time.LocalDateTime;
import java.util.Date;

public class PatientsDTO {

    private Integer patientId;
    private String email;
    private String patientName;
    private String phoneNumber;
    private String address;
    private String zipCode;
    private String emergencyContact;
    private String password;
    private Double latitude;
    private Double longitude;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    private Date patientDob; // Ngày sinh
    private String patientGender; // Giới tính
    private String patientCode; // Mã bệnh nhân
    private String patientImg; // Đường dẫn ảnh bệnh nhân

    // Constructor không tham số
    public PatientsDTO() {
    }

    // Constructor có tham số
    public PatientsDTO(Integer patientId, String email, String patientName, String phoneNumber,
                       String address, String zipCode, String emergencyContact, String password,
                       Double latitude, Double longitude, LocalDateTime createdAt,
                       LocalDateTime updatedAt, Date patientDob, String patientGender,
                       String patientCode, String patientImg) {
        this.patientId = patientId;
        this.email = email;
        this.patientName = patientName;
        this.phoneNumber = phoneNumber;
        this.address = address;
        this.zipCode = zipCode;
        this.emergencyContact = emergencyContact;
        this.password = password;
        this.latitude = latitude;
        this.longitude = longitude;
        this.createdAt = createdAt;
        this.updatedAt = updatedAt;
        this.patientDob = patientDob;
        this.patientGender = patientGender;
        this.patientCode = patientCode;
        this.patientImg = patientImg;
    }

    public Integer getPatientId() {
        return patientId;
    }

    public void setPatientId(Integer patientId) {
        this.patientId = patientId;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getPatientName() {
        return patientName;
    }

    public void setPatientName(String patientName) {
        this.patientName = patientName;
    }

    public String getPhoneNumber() {
        return phoneNumber;
    }

    public void setPhoneNumber(String phoneNumber) {
        this.phoneNumber = phoneNumber;
    }

    public String getAddress() {
        return address;
    }

    public void setAddress(String address) {
        this.address = address;
    }

    public String getZipCode() {
        return zipCode;
    }

    public void setZipCode(String zipCode) {
        this.zipCode = zipCode;
    }

    public String getEmergencyContact() {
        return emergencyContact;
    }

    public void setEmergencyContact(String emergencyContact) {
        this.emergencyContact = emergencyContact;
    }

    public String getPassword() {
        return password;
    }

    public void setPassword(String password) {
        this.password = password;
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

    public Date getPatientDob() {
        return patientDob;
    }

    public void setPatientDob(Date patientDob) {
        this.patientDob = patientDob;
    }

    public String getPatientGender() {
        return patientGender;
    }

    public void setPatientGender(String patientGender) {
        this.patientGender = patientGender;
    }

    public String getPatientCode() {
        return patientCode;
    }

    public void setPatientCode(String patientCode) {
        this.patientCode = patientCode;
    }

    public String getPatientImg() {
        return patientImg;
    }

    public void setPatientImg(String patientImg) {
        this.patientImg = patientImg;
    }
}