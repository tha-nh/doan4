package com.project.appoinmentservice.service;

import org.springframework.stereotype.Service;

@Service
public interface SendEmail {
    public void sendEmail(String name, String email, String passwordpatient);
    public void sendEmailFormRegisterAppointment(String doctorName, String departmentName, String medicalDay, String patientEmail, String patientName,String timeSlot);
    public void sendEmailForgot(String name, String email, String code);
    public void sendEmailReply(String name, String email, String message);
    public void sendEmailToDoctor(String doctorName, String departmentName, String appointmentDate, String doctorEmail, String patientName, String timeSlot);
    }
