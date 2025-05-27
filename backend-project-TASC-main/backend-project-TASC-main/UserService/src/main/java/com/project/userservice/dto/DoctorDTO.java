package com.project.userservice.dto;

import java.math.BigDecimal;

public class DoctorDTO {
    private Integer id;
    private String doctorName;
    private String doctorDescription;
    private BigDecimal doctorPrice;
    private Integer departmentId;

    public DoctorDTO(Integer id, String doctorName, String doctorDescription, BigDecimal doctorPrice, Integer departmentId) {
        this.id = id;
        this.doctorName = doctorName;
        this.doctorDescription = doctorDescription;
        this.doctorPrice = doctorPrice;
        this.departmentId = departmentId;
    }

    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }

    public String getDoctorName() {
        return doctorName;
    }

    public void setDoctorName(String doctorName) {
        this.doctorName = doctorName;
    }

    public String getDoctorDescription() {
        return doctorDescription;
    }

    public void setDoctorDescription(String doctorDescription) {
        this.doctorDescription = doctorDescription;
    }

    public BigDecimal getDoctorPrice() {
        return doctorPrice;
    }

    public void setDoctorPrice(BigDecimal doctorPrice) {
        this.doctorPrice = doctorPrice;
    }

    public Integer getDepartmentId() {
        return departmentId;
    }

    public void setDepartmentId(Integer departmentId) {
        this.departmentId = departmentId;
    }

    // Getters và Setters
}
