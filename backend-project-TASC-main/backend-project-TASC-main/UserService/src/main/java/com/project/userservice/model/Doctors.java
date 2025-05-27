package com.project.userservice.model;

import jakarta.persistence.*;

import java.math.BigDecimal;

@Entity
@Table(name = "doctors")
public class Doctors extends Entitys {

    @Column(name = "doctor_name")
    private String doctorName;

    @Column(name = "doctor_phone")
    private String doctorPhone;

    @Column(name = "doctor_address")
    private String doctorAddress;

    @Column(name = "doctor_email",nullable = false, unique = true)
    private String doctorEmail;

    @Column(name = "doctor_password")
    private String doctorPassword;

    @Column(name = "doctor_image")
    private String doctorImage;

    @Column(name = "doctor_price")
    private BigDecimal doctorPrice;

    @Column(name = "doctor_summary")
    private String doctorSummary;

    @Column(name = "doctor_description")
    private String doctorDescription;

    @Column(name = "doctor_status")
    private String doctorStatus;

    @ManyToOne
    @JoinColumn(name = "role_id", referencedColumnName = "id")
    private Role role;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "department_id", nullable = false)
    private Departments department;

    public Doctors() {
    }

    public Departments getDepartment() {
        return department;
    }

    public void setDepartment(Departments department) {
        this.department = department;
    }

    public String getDoctorName() {
        return doctorName;
    }

    public void setDoctorName(String doctorName) {
        this.doctorName = doctorName;
    }

    public String getDoctorPhone() {
        return doctorPhone;
    }

    public Role getRole() {
        return role;
    }

    public void setRole(Role role) {
        this.role = role;
    }

    public void setDoctorPhone(String doctorPhone) {
        this.doctorPhone = doctorPhone;
    }

    public String getDoctorAddress() {
        return doctorAddress;
    }

    public void setDoctorAddress(String doctorAddress) {
        this.doctorAddress = doctorAddress;
    }

    public String getDoctorEmail() {
        return doctorEmail;
    }

    public void setDoctorEmail(String doctorEmail) {
        this.doctorEmail = doctorEmail;
    }

    public String getDoctorPassword() {
        return doctorPassword;
    }

    public void setDoctorPassword(String doctorPassword) {
        this.doctorPassword = doctorPassword;
    }

    public String getDoctorImage() {
        return doctorImage;
    }

    public void setDoctorImage(String doctorImage) {
        this.doctorImage = doctorImage;
    }

    public BigDecimal getDoctorPrice() {
        return doctorPrice;
    }

    public void setDoctorPrice(BigDecimal doctorPrice) {
        this.doctorPrice = doctorPrice;
    }

    public String getDoctorSummary() {
        return doctorSummary;
    }

    public void setDoctorSummary(String doctorSummary) {
        this.doctorSummary = doctorSummary;
    }

    public String getDoctorDescription() {
        return doctorDescription;
    }

    public void setDoctorDescription(String doctorDescription) {
        this.doctorDescription = doctorDescription;
    }

    public String getDoctorStatus() {
        return doctorStatus;
    }

    public void setDoctorStatus(String doctorStatus) {
        this.doctorStatus = doctorStatus;
    }

    @Override
    public String toString() {
        return "Doctors{" +
                "doctorName='" + doctorName + '\'' +
                ", doctorPhone='" + doctorPhone + '\'' +
                ", doctorAddress='" + doctorAddress + '\'' +
                ", doctorEmail='" + doctorEmail + '\'' +
                ", doctorPassword='" + doctorPassword + '\'' +
                ", doctorImage='" + doctorImage + '\'' +
                ", doctorPrice=" + doctorPrice +
                ", doctorSummary='" + doctorSummary + '\'' +
                ", doctorDescription='" + doctorDescription + '\'' +
                ", doctorStatus='" + doctorStatus + '\'' +
                ", role=" + role +
                ", department=" + department +
                '}';
    }
}
