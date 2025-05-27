package com.project.transactionn.model;

import jakarta.persistence.*;

import java.time.LocalDateTime;

@Entity
public class PaymentTransaction {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @ManyToOne
    @JoinColumn(name = "transaction_id", nullable = false,referencedColumnName = "id") // Liên kết với bảng Transaction
    private Transaction transaction; // Mối quan hệ với bảng Transaction

    @Column(nullable = false)
    private Integer paymentId; // ID thanh toán.

    @Column(name = "status" , nullable = false)
    private String status; // Trạng thái giao dịch thanh toán.

    @Column(nullable = false)
    private LocalDateTime createdAt;


    @PrePersist
    public void prePersist() {
        if (this.createdAt == null) {
            this.createdAt = LocalDateTime.now();
        }
    }

    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }

    public Transaction getTransaction() {
        return transaction;
    }

    public void setTransaction(Transaction transaction) {
        this.transaction = transaction;
    }

    public Integer getPaymentId() {
        return paymentId;
    }

    public void setPaymentId(Integer paymentId) {
        this.paymentId = paymentId;
    }


    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    @Override
    public String toString() {
        return "PaymentTransaction{" +
                "id=" + id +
                ", transaction=" + transaction +
                ", paymentId=" + paymentId +
                ", status=" + status +
                ", createdAt=" + createdAt +
                '}';
    }
}
