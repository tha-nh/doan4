package com.project.transactionn.model;

import jakarta.persistence.*;

import java.time.LocalDateTime;

@Entity
public class AppointmentTransaction {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @ManyToOne
    @JoinColumn(name = "transaction_id", nullable = false,referencedColumnName = "id") // Liên kết với bảng Transaction
    private Transaction transaction; // Mối quan hệ với bảng Transaction

    @Column(nullable = false)
    private Integer appointmentId; // ID lịch hẹn.

    @Column(name = "status" , nullable = false)
    private String status; // Trạng thái giao dịch lịch hẹn.

    @Column(nullable = false)
    private LocalDateTime createdAt;


    @PrePersist
    public void prePersist() {
        if (this.createdAt == null) {
            this.createdAt = LocalDateTime.now();
        }
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
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

    public Integer getAppointmentId() {
        return appointmentId;
    }

    public void setAppointmentId(Integer appointmentId) {
        this.appointmentId = appointmentId;
    }



    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    @Override
    public String toString() {
        return "AppointmentTransaction{" +
                "id=" + id +
                ", transaction=" + transaction +
                ", appointmentId=" + appointmentId +
                ", status=" + status +
                ", createdAt=" + createdAt +
                '}';
    }
}
