package com.project.appoinmentservice.dto;

public class PatientRequest {
    private String patientEmail;
    private String patientPhone;
    private String patientName;

    // Constructor
    public PatientRequest(String patientEmail, String patientPhone, String patientName) {
        this.patientEmail = patientEmail;
        this.patientPhone = patientPhone;
        this.patientName = patientName;
    }

    // Getters and Setters
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

    public String getPatientName() {
        return patientName;
    }

    public void setPatientName(String patientName) {
        this.patientName = patientName;
    }

    @Override
    public String toString() {
        return "PatientRequest{" +
                "patientEmail='" + patientEmail + '\'' +
                ", patientPhone='" + patientPhone + '\'' +
                ", patientName='" + patientName + '\'' +
                '}';
    }
}
