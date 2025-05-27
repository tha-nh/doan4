package com.project.userservice.dto;

import java.util.Date;

public class PatientRegistrationDto {
    private String patientName;
    private String patientEmail;
    private String patientPhone;
    private String patientPassword;
    private Integer roleId; // thêm roleId
    private Date dateOfBirth;
    public PatientRegistrationDto() {
    }
    public Date getDateOfBirth() {
        return dateOfBirth;
    }
    public void setDateOfBirth(Date dateOfBirth) {
        this.dateOfBirth = dateOfBirth;
    }
    public Integer getRoleId() {
        return roleId;
    }

    public void setRoleId(Integer roleId) {
        this.roleId = roleId;
    }

    // Getters and Setters
    public String getPatientName() {
        return patientName;
    }

    public void setPatientName(String patientName) {
        this.patientName = patientName;
    }

    public String getPatientEmail() {
        return patientEmail;
    }

    public void setPatientEmail(String patientEmail) {
        this.patientEmail = patientEmail;
    }

    public String getPatientPhone() {
        return patientPhone;
    }

    public void setPatientPhone(String patientPhone) {
        this.patientPhone = patientPhone;
    }

    public String getPatientPassword() {
        return patientPassword;
    }

    public void setPatientPassword(String patientPassword) {
        this.patientPassword = patientPassword;
    }

    @Override
    public String toString() {
        return "PatientRegistrationDto{" +
                "patientName='" + patientName + '\'' +
                ", patientEmail='" + patientEmail + '\'' +
                ", patientPhone='" + patientPhone + '\'' +
                ", patientPassword='" + patientPassword + '\'' +
                ", roleId=" + roleId +
                '}';
    }
}
