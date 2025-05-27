package com.project.paymentservice.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.project.paymentservice.dto.PaymentDTO;
import com.project.paymentservice.dto.PaymentRequestOrderId;
import com.project.paymentservice.model.Payment;
import com.project.paymentservice.model.PaymentStatus;
import com.project.paymentservice.service.PaymentService;
import com.project.paymentservice.service.PaypalService;
import org.modelmapper.ModelMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@RestController
@RequestMapping("/api/paymentservice")
public class PaymentController {

    @Autowired
    private PaymentService paymentService;

    @Autowired
    private PaypalService paypalService;
    // Create Payment
    @PostMapping("/create")
    public ResponseEntity<Payment> createPayment(@RequestBody PaymentRequestOrderId paymentRequestOrderId) {
        System.out.println("Dữ liệu đã nhận :" + paymentRequestOrderId.toString());

        // Tạo đối tượng thanh toán


        // Lưu thanh toán vào cơ sở dữ liệu

        // Xác thực thanh toán với PayPal
        // Bỏ facilitatorAccessToken và chỉ sử dụng paymentID và payerID
        boolean isPaymentValid = paypalService.verifyPayment(paymentRequestOrderId.getOrderId());

        // Cập nhật trạng thái thanh toán
        if (isPaymentValid) {
//            savedPayment.setPaymentStatus(PaymentStatus.COMPLETED); // Nếu thanh toán hợp lệ, cập nhật trạng thái
            System.out.println("xác thực thanh toán thành công");
        } else {
//            savedPayment.setPaymentStatus(PaymentStatus.FAILED); // Nếu thanh toán không hợp lệ
            System.out.println("xác thực thanh toán thất bại");

        }

//        paymentService.updatePayment(savedPayment.getId(), savedPayment); // Cập nhật lại trạng thái thanh toán trong DB

        // Trả về phản hồi
        return null;
    }



    // Get All Payments
    @GetMapping
    public ResponseEntity<List<Payment>> getAllPayments() {
        List<Payment> payments = paymentService.getAllPayments();
        return new ResponseEntity<>(payments, HttpStatus.OK);
    }

    // Get Payment by ID
    @GetMapping("/{id}")
    public ResponseEntity<Payment> getPaymentById(@PathVariable Integer id) {
        Optional<Payment> payment = paymentService.getPaymentById(id);

        return payment.map(value -> new ResponseEntity<>(value, HttpStatus.OK))
                .orElseGet(() -> new ResponseEntity<>(HttpStatus.NOT_FOUND));
    }

    // Update Payment
    @PutMapping("/{id}")
    public ResponseEntity<Payment> updatePayment(@PathVariable Integer id, @RequestBody Payment paymentDetails) {
        Payment updatedPayment = paymentService.updatePayment(id, paymentDetails);

        if (updatedPayment != null) {
            return new ResponseEntity<>(updatedPayment, HttpStatus.OK);
        } else {
            return new ResponseEntity<>(HttpStatus.NOT_FOUND);
        }
    }

    // Delete Payment
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deletePayment(@PathVariable Integer id) {
        boolean isDeleted = paymentService.deletePayment(id);

        if (isDeleted) {
            return new ResponseEntity<>(HttpStatus.NO_CONTENT);
        } else {
            return new ResponseEntity<>(HttpStatus.NOT_FOUND);
        }
    }
}
