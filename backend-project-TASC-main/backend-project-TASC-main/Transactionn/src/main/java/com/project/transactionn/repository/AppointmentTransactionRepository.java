package com.project.transactionn.repository;

import com.project.transactionn.dto.PaymentTransactionDTO;
import com.project.transactionn.model.AppointmentTransaction;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface AppointmentTransactionRepository extends JpaRepository<AppointmentTransaction, Integer> {
}
