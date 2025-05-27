package com.project.transactionn.service.impl;

import com.project.transactionn.model.AppointmentTransaction;
import com.project.transactionn.repository.AppointmentTransactionRepository;
import com.project.transactionn.service.AppointmntTransactionService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service

public class AppointmntTransactionServiceImpl implements AppointmntTransactionService {

    @Autowired
    AppointmentTransactionRepository appointmentTransactionRepository;
    @Override
    public AppointmentTransaction saveAppointmentTransaction(AppointmentTransaction appointmentTransaction) {
        return appointmentTransactionRepository.save(appointmentTransaction);
    }
}
