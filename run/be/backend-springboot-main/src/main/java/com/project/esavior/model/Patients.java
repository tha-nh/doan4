package com.project.esavior.model;

import com.fasterxml.jackson.annotation.JsonManagedReference;
import jakarta.persistence.*;
import java.time.LocalDateTime;
import java.util.Date;
import java.util.List;

@Entity
@Table(name = "patients")
public class Patients {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "patient_id")
    private Integer patientId;

    @Column(name = "patient_email", unique = true)
    private String email;

    @Column(name = "patient_name", nullable = false)
    private String patientName;

    @Column(name = "patient_phone", nullable = false, unique = true)
    private String phoneNumber;

    @Column(name = "zip_code")
    private String zipCode;

    @Column(name = "emergency_contact")
    private String emergencyContact;

    @OneToMany(mappedBy = "patient")
    private List<Booking> bookings;

    @Column(name = "patient_password", nullable = false)
    private String password;

    @Column(name = "latitude")
    private Double latitude;

    @Column(name = "longitude")
    private Double longitude;

    @Column(name = "patient_created_at")
    private LocalDateTime createdAt;

    @Column(name = "patient_address")
    private String patientAddress;

    @Column(name = "patient_updated_at")
    private LocalDateTime updatedAt;

    // Các trường từ class 1
    @Column(name = "patient_dob")
    private Date patientDob; // Ngày sinh

    @Column(name = "patient_gender")
    private String patientGender; // Giới tính

    @Column(name = "patient_code")
    private String patientCode; // Mã bệnh nhân

    @Column(name = "patient_img")
    private String patientImg; // Đường dẫn ảnh bệnh nhân
    @Column(name = "patient_username ")
    private String patientUsername;

    // Constructors, Getters và Setters
    public Patients() {
    }

    public String getPatientUsername() {
        return patientUsername;
    }

    public void setPatientUsername(String patientUsername) {
        this.patientUsername = patientUsername;
    }

    public String getPatientAddress() {
        return patientAddress;
    }

    public void setPatientAddress(String patientAddress) {
        this.patientAddress = patientAddress;
    }

    // Getters và Setters cho các trường mới
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

    // Getters và Setters cho các trường còn lại
    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public Integer getPatientId() {
        return patientId;
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

    public void setPatientId(Integer patientId) {
        this.patientId = patientId;
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

    public String getPassword() {
        return password;
    }

    public void setPassword(String password) {
        this.password = password;
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

    public List<Booking> getBookings() {
        return bookings;
    }

    public void setBookings(List<Booking> bookings) {
        this.bookings = bookings;
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

    @Override
    public String toString() {
        return "Patients{" +
                "patientId=" + patientId +
                ", email='" + email + '\'' +
                ", patientName='" + patientName + '\'' +
                ", phoneNumber='" + phoneNumber + '\'' +
                ", zipCode='" + zipCode + '\'' +
                ", emergencyContact='" + emergencyContact + '\'' +
                ", password='" + password + '\'' +
                ", latitude=" + latitude +
                ", longitude=" + longitude +
                ", createdAt=" + createdAt +
                ", updatedAt=" + updatedAt +
                ", patientDob=" + patientDob +
                ", patientGender='" + patientGender + '\'' +
                ", patientCode='" + patientCode + '\'' +
                ", patientImg='" + patientImg + '\'' +
                '}';
    }
}
