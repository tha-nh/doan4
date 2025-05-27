package com.project.paymentservice.repository;

import com.project.paymentservice.model.Payment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface PaymentRepository extends JpaRepository<Payment, Integer> {
    // Các phương thức tuỳ chỉnh có thể được thêm vào nếu cần
}
