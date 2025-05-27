package com.project.transactionn.service;

import com.project.transactionn.dto.PaymentRequestOrderId;
import com.project.transactionn.model.PaymentTransaction;
import org.springframework.stereotype.Service;

@Service

public interface PaymentTransactionService {
    public boolean sendRequestPaymentService(PaymentRequestOrderId paymentRequestOrderId);
}
