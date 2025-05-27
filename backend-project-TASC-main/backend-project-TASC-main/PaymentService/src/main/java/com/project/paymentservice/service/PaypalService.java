package com.project.paymentservice.service;

import org.springframework.stereotype.Service;

@Service
public interface PaypalService {
    public boolean verifyPayment(String orderID) ;
}
