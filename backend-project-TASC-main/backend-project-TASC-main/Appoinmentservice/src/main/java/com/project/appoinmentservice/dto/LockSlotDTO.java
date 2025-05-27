package com.project.appoinmentservice.dto;

import java.time.LocalDate;

public class LockSlotDTO {
    private String slot;       // Giá trị slot (ví dụ: "08:00 - 09:00")
    private LocalDate medicalDay; // Ngày khám (định dạng ngày)
    private Integer doctorId;     // ID của bác sĩ
    private String randomCode; // Mã random

    // Constructor không tham số
    public LockSlotDTO() {}

    // Constructor có tham số
    public LockSlotDTO(String slot, LocalDate medicalDay, Integer doctorId, String randomCode) {
        this.slot = slot;
        this.medicalDay = medicalDay;
        this.doctorId = doctorId;
        this.randomCode = randomCode;
    }

    // Getters and Setters
    public String getSlot() {
        return slot;
    }

    public void setSlot(String slot) {
        this.slot = slot;
    }

    public LocalDate getMedicalDay() {
        return medicalDay;
    }

    public void setMedicalDay(LocalDate medicalDay) {
        this.medicalDay = medicalDay;
    }

    public Integer getDoctorId() {
        return doctorId;
    }

    public void setDoctorId(Integer doctorId) {
        this.doctorId = doctorId;
    }

    public String getRandomCode() {
        return randomCode;
    }

    public void setRandomCode(String randomCode) {
        this.randomCode = randomCode;
    }

    @Override
    public String toString() {
        return "LockSlotDTO{" +
                "slot='" + slot + '\'' +
                ", medicalDay=" + medicalDay +
                ", doctorId=" + doctorId +
                ", randomCode='" + randomCode + '\'' +
                '}';
    }
}
