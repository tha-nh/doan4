package com.project.paymentservice.dto;

public class PaymentRequestOrderId {
    private String orderId;

    public String getOrderId() {
        return orderId;
    }

    public void setOrderId(String orderId) {
        this.orderId = orderId;
    }

    @Override
    public String toString() {
        return "PaymentRequestOrderId{" +
                "orderId='" + orderId + '\'' +
                '}';
    }
}
