package com.project.userservice.model;

import jakarta.persistence.*;

import java.time.LocalDateTime;
import java.util.Date;


@Entity
@Table(name = "patients")
public class Patients extends Entitys {

    @Column(name = "patient_name", nullable = false)
    private String patientName;

    @Column(name = "patient_phone", nullable = false)
    private String patientPhone;

    @Column(name = "zip_code")
    private String zipCode;

    @Column(name = "patient_email",nullable = false, unique = true)
    private String patientEmail;

    @Column(name = "patient_password", nullable = false)
    private String patientPassword;

    @Column(name = "patient_created_at")
    private LocalDateTime createdAt;

    @Column(name = "patient_address")
    private String patientAddress;

    @Column(name = "patient_dob")
    private Date patientDob; // Ngày sinh

    @Column(name = "patient_gender")
    private String patientGender;

    @Column(name = "patient_img")
    private String patientImg;

    @ManyToOne
    @JoinColumn(name = "role_id", referencedColumnName = "id")
    private Role role;

    public Patients() {
    }

    public Role getRole() {
        return role;
    }

    public void setRole(Role role) {
        this.role = role;
    }

    public String getPatientName() {
        return patientName;
    }

    public void setPatientName(String patientName) {
        this.patientName = patientName;
    }

    public String getPatientPhone() {
        return patientPhone;
    }

    public void setPatientPhone(String patientPhone) {
        this.patientPhone = patientPhone;
    }

    public String getZipCode() {
        return zipCode;
    }

    public void setZipCode(String zipCode) {
        this.zipCode = zipCode;
    }

    public String getPatientEmail() {
        return patientEmail;
    }

    public void setPatientEmail(String patientEmail) {
        this.patientEmail = patientEmail;
    }

    public String getPatientPassword() {
        return patientPassword;
    }

    public void setPatientPassword(String patientPassword) {
        this.patientPassword = patientPassword;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public String getPatientAddress() {
        return patientAddress;
    }

    public void setPatientAddress(String patientAddress) {
        this.patientAddress = patientAddress;
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

    public String getPatientImg() {
        return patientImg;
    }

    public void setPatientImg(String patientImg) {
        this.patientImg = patientImg;
    }

    @Override
    public String toString() {
        return "Patients{" +
                "patientName='" + patientName + '\'' +
                ", patientPhone='" + patientPhone + '\'' +
                ", zipCode='" + zipCode + '\'' +
                ", patientEmail='" + patientEmail + '\'' +
                ", patientPassword='" + patientPassword + '\'' +
                ", createdAt=" + createdAt +
                ", patientAddress='" + patientAddress + '\'' +
                ", patientDob=" + patientDob +
                ", patientGender='" + patientGender + '\'' +
                ", patientImg='" + patientImg + '\'' +
                '}';
    }
}
