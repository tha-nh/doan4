package com.project.transactionn.service.impl;

import com.project.transactionn.dto.PaymentRequestOrderId;
import com.project.transactionn.model.PaymentTransaction;
import com.project.transactionn.service.PaymentTransactionService;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

@Service

public class PaymentTransactionServiceImpl implements PaymentTransactionService {

    private final RestTemplate restTemplate = new RestTemplate();

    @Override
    public boolean sendRequestPaymentService(PaymentRequestOrderId paymentRequestOrderId) {
        System.out.println("gọi sang payment service");
        String url = "http://localhost:8080/api/paymentservice/create";
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        HttpEntity<PaymentRequestOrderId> entity = new HttpEntity<>(paymentRequestOrderId, headers);
        try {
            ResponseEntity<Void> response = restTemplate.exchange(url, HttpMethod.POST, entity, Void.class);
            System.out.println("API Response Status: " + response.getStatusCode());
            return true;
        } catch (Exception e) {
            System.err.println("Lỗi khi gọi API Transaction: " + e.getMessage());
            return false;
        }
    }
}
