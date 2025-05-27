package com.project.transactionn.service.impl;

import com.project.transactionn.model.Transaction;
import com.project.transactionn.repository.TransactionRepository;
import com.project.transactionn.service.TransactionService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Service

public class TransactionServiceImpl implements TransactionService {
    @Autowired
    private TransactionRepository transactionRepository;

    @Override
    public Transaction saveTransaction(Transaction transaction) {
        transaction.setReferenceGroupId(generateReferenceGroupId());
        transaction.setStatus("pending");
        return transactionRepository.save(transaction);
    }
    private static String generateReferenceGroupId() {
        return "REF-" + UUID.randomUUID().toString().replace("-", "").substring(0, 8).toUpperCase();
    }

}
