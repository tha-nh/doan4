package com.project.paymentservice.service.implement;

import com.project.paymentservice.model.Payment;
import com.project.paymentservice.repository.PaymentRepository;
import com.project.paymentservice.service.PaymentService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class PaymentServiceImpl implements PaymentService {

    @Autowired
    private PaymentRepository paymentRepository;

    @Override
    public Payment createPayment(Payment payment) {
        return paymentRepository.save(payment);
    }

    @Override
    public List<Payment> getAllPayments() {
        return paymentRepository.findAll();
    }

    @Override
    public Optional<Payment> getPaymentById(Integer id) {
        return paymentRepository.findById(id);
    }

    @Override
    public Payment updatePayment(Integer id, Payment paymentDetails) {
        Optional<Payment> paymentOptional = paymentRepository.findById(id);

        if (paymentOptional.isPresent()) {
            Payment payment = paymentOptional.get();
            payment.setPaymentAmount(paymentDetails.getPaymentAmount());
            payment.setPaymentStatus(paymentDetails.getPaymentStatus());
            payment.setUpdatedAt(paymentDetails.getUpdatedAt());

            return paymentRepository.save(payment);
        }

        return null; // Hoặc ném exception nếu không tìm thấy payment
    }

    @Override
    public boolean deletePayment(Integer id) {
        Optional<Payment> paymentOptional = paymentRepository.findById(id);

        if (paymentOptional.isPresent()) {
            paymentRepository.delete(paymentOptional.get());
            return true;
        }

        return false; // Hoặc ném exception nếu không tìm thấy payment
    }
}
