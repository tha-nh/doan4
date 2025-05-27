package com.project.paymentservice.service;

import com.project.paymentservice.model.Payment;

import java.util.List;
import java.util.Optional;

public interface PaymentService {

    // Create Payment
    Payment createPayment(Payment payment);

    // Get All Payments
    List<Payment> getAllPayments();

    // Get Payment by ID
    Optional<Payment> getPaymentById(Integer id);

    // Update Payment
    Payment updatePayment(Integer id, Payment paymentDetails);

    // Delete Payment
    boolean deletePayment(Integer id);
}
