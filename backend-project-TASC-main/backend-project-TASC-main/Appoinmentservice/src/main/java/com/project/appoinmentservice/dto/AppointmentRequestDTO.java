package com.project.appoinmentservice.dto;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

public class AppointmentRequestDTO {
    private Integer patientId;
    private Integer doctorId;
    private Integer staffId;
    private LocalDate appointmentDate; // Chỉ chứa ngày
    private LocalDate medicalDay;      // Chỉ chứa ngày
    private Integer slot;
    private String status;
    private String patientEmail;
    private String patientPhone;
    private String patientName;
    private String orderID;            // Thêm trường orderID
    private String payerID;            // Thêm trường payerID
    private String paymentID;          // Thêm trường paymentID
    private String paymentSource;      // Thêm trường paymentSource
    private String facilitatorAccessToken; // Thêm trường facilitatorAccessToken
    private BigDecimal paymentAmount;  // Số tiền thanh toán
    private String randomCode;
    public AppointmentRequestDTO() {
    }

    public String getRandomCode() {
        return randomCode;
    }

    public void setRandomCode(String randomCode) {
        this.randomCode = randomCode;
    }

    public Integer getPatientId() {
        return patientId;
    }

    public void setPatientId(Integer patientId) {
        this.patientId = patientId;
    }

    public Integer getDoctorId() {
        return doctorId;
    }

    public void setDoctorId(Integer doctorId) {
        this.doctorId = doctorId;
    }

    public Integer getStaffId() {
        return staffId;
    }

    public void setStaffId(Integer staffId) {
        this.staffId = staffId;
    }

    public LocalDate getAppointmentDate() {
        return appointmentDate;
    }

    public void setAppointmentDate(LocalDate appointmentDate) {
        this.appointmentDate = appointmentDate;
    }

    public LocalDate getMedicalDay() {
        return medicalDay;
    }

    public void setMedicalDay(LocalDate medicalDay) {
        this.medicalDay = medicalDay;
    }

    public Integer getSlot() {
        return slot;
    }

    public void setSlot(Integer slot) {
        this.slot = slot;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
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

    public String getPatientName() {
        return patientName;
    }

    public void setPatientName(String patientName) {
        this.patientName = patientName;
    }



    public String getOrderID() {
        return orderID;
    }

    public void setOrderID(String orderID) {
        this.orderID = orderID;
    }

    public String getPayerID() {
        return payerID;
    }

    public void setPayerID(String payerID) {
        this.payerID = payerID;
    }

    public String getPaymentID() {
        return paymentID;
    }

    public void setPaymentID(String paymentID) {
        this.paymentID = paymentID;
    }

    public String getPaymentSource() {
        return paymentSource;
    }

    public void setPaymentSource(String paymentSource) {
        this.paymentSource = paymentSource;
    }

    public String getFacilitatorAccessToken() {
        return facilitatorAccessToken;
    }

    public void setFacilitatorAccessToken(String facilitatorAccessToken) {
        this.facilitatorAccessToken = facilitatorAccessToken;
    }

    public BigDecimal getPaymentAmount() {
        return paymentAmount;
    }

    public void setPaymentAmount(BigDecimal paymentAmount) {
        this.paymentAmount = paymentAmount;
    }

    @Override
    public String toString() {
        return "AppointmentRequestDTO{" +
                "patientId=" + patientId +
                ", doctorId=" + doctorId +
                ", staffId=" + staffId +
                ", appointmentDate=" + appointmentDate +
                ", medicalDay=" + medicalDay +
                ", slot=" + slot +
                ", status='" + status + '\'' +
                ", patientEmail='" + patientEmail + '\'' +
                ", patientPhone='" + patientPhone + '\'' +
                ", patientName='" + patientName + '\'' +
                ", orderID='" + orderID + '\'' +
                ", payerID='" + payerID + '\'' +
                ", paymentID='" + paymentID + '\'' +
                ", paymentSource='" + paymentSource + '\'' +
                ", facilitatorAccessToken='" + facilitatorAccessToken + '\'' +
                ", paymentAmount=" + paymentAmount +
                ", randomCode='" + randomCode + '\'' +
                '}';
    }
}
