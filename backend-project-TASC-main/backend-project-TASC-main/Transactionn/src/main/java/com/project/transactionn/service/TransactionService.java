package com.project.transactionn.service;

import com.project.transactionn.model.Transaction;
import org.springframework.stereotype.Service;

@Service
public interface TransactionService {
    public Transaction saveTransaction(Transaction transaction);

}
