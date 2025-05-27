package com.project.appoinmentservice.model;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.persistence.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Date;

@Entity
@JsonIgnoreProperties(ignoreUnknown = true)
public class Appointment {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "appointment_id")  // Chỉ định tên cột trong cơ sở dữ liệu nếu cần
    private Integer appointmentId;

    @Column(name = "patient_id")
    private Integer patientId;

    @Column(name = "doctor_id")
    private Integer doctorId;

    @Column(name = "staff_id")
    private Integer staffId;

    @Column(name = "appointment_date")
    private Date appointmentDate;

    @Column(name = "medical_day")
    private Date medicalDay;

    @Column(name = "slot")
    private Integer slot;

    @Enumerated(EnumType.STRING)
    @Column(name = "status")
    private AppointmentStatus status;

    @Column(name = "price", precision = 18, scale = 2)  // precision: tổng số chữ số, scale: số chữ số sau dấu thập phân
    private BigDecimal paymentAmount;

    @Column(name = "patientEmail")  // precision: tổng số chữ số, scale: số chữ số sau dấu thập phân
    private String patientEmail;


    public Integer getAppointmentId() {
        return appointmentId;
    }

    public void setAppointmentId(Integer appointmentId) {
        this.appointmentId = appointmentId;
    }

    public Integer getPatientId() {
        return patientId;
    }

    public void setPatientId(Integer patientId) {
        this.patientId = patientId;
    }

    public Integer getDoctorId() {
        return doctorId;
    }

    public void setDoctorId(Integer doctorId) {
        this.doctorId = doctorId;
    }

    public Integer getStaffId() {
        return staffId;
    }

    public void setStaffId(Integer staffId) {
        this.staffId = staffId;
    }

    public Date getAppointmentDate() {
        return appointmentDate;
    }

    public void setAppointmentDate(Date appointmentDate) {
        this.appointmentDate = appointmentDate;
    }

    public Date getMedicalDay() {
        return medicalDay;
    }

    public void setMedicalDay(Date medicalDay) {
        this.medicalDay = medicalDay;
    }

    public Integer getSlot() {
        return slot;
    }

    public void setSlot(Integer slot) {
        this.slot = slot;
    }

    public AppointmentStatus getStatus() {
        return status;
    }

    public void setStatus(AppointmentStatus status) {
        this.status = status;
    }

    public BigDecimal getPaymentAmount() {
        return paymentAmount;
    }

    public void setPaymentAmount(BigDecimal paymentAmount) {
        this.paymentAmount = paymentAmount;
    }

    public String getPatientEmail() {
        return patientEmail;
    }

    public void setPatientEmail(String patientEmail) {
        this.patientEmail = patientEmail;
    }

    // Phương thức được gọi trước khi lưu bản ghi mới vào cơ sở dữ liệu
    @PrePersist
    public void prePersist() {
        if (this.appointmentDate == null) {
            this.appointmentDate = new Date();
        }
    }

    @Override
    public String toString() {
        return "Appointment{" +
                "appointmentId=" + appointmentId +
                ", patientId=" + patientId +
                ", doctorId=" + doctorId +
                ", staffId=" + staffId +
                ", appointmentDate=" + appointmentDate +
                ", medicalDay=" + medicalDay +
                ", slot=" + slot +
                ", status=" + status +
                ", paymentAmount=" + paymentAmount +
                ", patientEmail='" + patientEmail + '\'' +
                '}';
    }
}
