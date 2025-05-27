package com.project.transactionn.controller;

import com.netflix.discovery.converters.Auto;
import com.project.transactionn.dto.AppointmentTransactionDTO;
import com.project.transactionn.dto.AppontmentRequest;
import com.project.transactionn.dto.NotificationRequest;
import com.project.transactionn.dto.PaymentRequestOrderId;
import com.project.transactionn.model.AppointmentTransaction;
import com.project.transactionn.model.PaymentTransaction;
import com.project.transactionn.model.Transaction;
import com.project.transactionn.service.AppointmntTransactionService;
import com.project.transactionn.service.NotificationService;
import com.project.transactionn.service.PaymentTransactionService;
import com.project.transactionn.service.TransactionService;
import jakarta.ws.rs.POST;
import org.modelmapper.ModelMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/transactions")
public class TransactionController {

    @Autowired
    private TransactionService transactionService;

    @Autowired
    private AppointmntTransactionService appointmntTransactionService;

    @Autowired
    PaymentTransactionService paymentTransactionService;

    @Autowired
    NotificationService notificationService;

    @PostMapping("/create")
    public void createTransaction(@RequestBody AppontmentRequest appontmentRequest) {
        System.out.println(appontmentRequest.toString());
        Transaction transaction = new Transaction();
        transactionService.saveTransaction(transaction);
        AppointmentTransaction appointmentTransaction = new AppointmentTransaction();
        appointmentTransaction.setAppointmentId(appontmentRequest.getAppointmentId());
        appointmentTransaction.setStatus(appontmentRequest.getStatus());
        appointmentTransaction.setTransaction(transaction);
        appointmntTransactionService.saveAppointmentTransaction(appointmentTransaction);
        System.out.println(appointmntTransactionService.saveAppointmentTransaction(appointmentTransaction).toString());
        PaymentRequestOrderId paymentRequestOrderId = new PaymentRequestOrderId();
        paymentRequestOrderId.setOrderId(appontmentRequest.getOrderID());
        boolean check = paymentTransactionService.sendRequestPaymentService(paymentRequestOrderId);
        if (check ==true){
            NotificationRequest notificationRequest = new NotificationRequest();
            notificationRequest.setRandomCode(appontmentRequest.getRandomCode());
            notificationRequest.setMessage("thanh toán  thành công!");
            notificationService.sendNotification(notificationRequest);
        }else {
            NotificationRequest notificationRequest = new NotificationRequest();
            notificationRequest.setRandomCode(appontmentRequest.getRandomCode());
            notificationRequest.setMessage("thanh toán  thất bại!");
            notificationService.sendNotification(notificationRequest);
        }



    }
}
