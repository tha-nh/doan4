package com.project.paymentservice.dto;

import com.project.paymentservice.model.PaymentStatus;
import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;


public class PaymentDTO {


    private Integer patientId;
    private Integer appointmentId;
    private BigDecimal paymentAmount;
    private String orderID;            // Thêm trường orderID
    private String payerID;            // Thêm trường payerID
    private String paymentID;          // Thêm trường paymentID
    private String paymentSource;      // Thêm trường paymentSource
    private String facilitatorAccessToken; // Thêm trường facilitatorAccessToken




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



    public Integer getPatientId() {
        return patientId;
    }

    public void setPatientId(Integer patientId) {
        this.patientId = patientId;
    }

    public Integer getAppointmentId() {
        return appointmentId;
    }

    public void setAppointmentId(Integer appointmentId) {
        this.appointmentId = appointmentId;
    }

    public BigDecimal getPaymentAmount() {
        return paymentAmount;
    }

    public void setPaymentAmount(BigDecimal paymentAmount) {
        this.paymentAmount = paymentAmount;
    }


    @Override
    public String toString() {
        return "PaymentRequest{" +
                "patientId=" + patientId +
                ", appointmentId=" + appointmentId +
                ", paymentAmount=" + paymentAmount +
                ", orderID='" + orderID + '\'' +
                ", payerID='" + payerID + '\'' +
                ", paymentID='" + paymentID + '\'' +
                ", paymentSource='" + paymentSource + '\'' +
                ", facilitatorAccessToken='" + facilitatorAccessToken + '\'' +
                '}';
    }

}
