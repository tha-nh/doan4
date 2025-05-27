package com.project.transactionn.repository;

import com.project.transactionn.model.PaymentTransaction;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository

public interface PaymentTransactionRepository extends JpaRepository<PaymentTransaction, Integer> {

}
