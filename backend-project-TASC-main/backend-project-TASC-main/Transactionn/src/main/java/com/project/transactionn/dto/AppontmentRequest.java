package com.project.transactionn.dto;

public class AppontmentRequest {
    private Integer appointmentId;
    private String status;
    private String orderID;
    private String randomCode;
    public Integer getAppointmentId() {
        return appointmentId;
    }

    public String getRandomCode() {
        return randomCode;
    }

    public void setRandomCode(String randomCode) {
        this.randomCode = randomCode;
    }

    public void setAppointmentId(Integer appointmentId) {
        this.appointmentId = appointmentId;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public String getOrderID() {
        return orderID;
    }

    public void setOrderID(String orderID) {
        this.orderID = orderID;
    }

    @Override
    public String toString() {
        return "AppontmentRequest{" +
                "appointmentId=" + appointmentId +
                ", status='" + status + '\'' +
                ", orderID='" + orderID + '\'' +
                ", randomCode='" + randomCode + '\'' +
                '}';
    }
}
