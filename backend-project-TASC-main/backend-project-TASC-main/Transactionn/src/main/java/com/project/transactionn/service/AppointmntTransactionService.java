package com.project.transactionn.service;

import com.project.transactionn.model.AppointmentTransaction;
import org.springframework.stereotype.Service;

@Service

public interface AppointmntTransactionService {
    public AppointmentTransaction saveAppointmentTransaction(AppointmentTransaction appointmentTransaction);
}
