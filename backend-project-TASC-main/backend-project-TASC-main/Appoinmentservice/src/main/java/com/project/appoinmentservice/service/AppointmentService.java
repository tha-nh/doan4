package com.project.appoinmentservice.service;

import com.project.appoinmentservice.dto.AppointmentRequestDTO;
import com.project.appoinmentservice.dto.PaymentRequest;
import com.project.appoinmentservice.model.Appointment;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;

@Service
public interface AppointmentService {
    public Integer getPatientFromApi(String email, String phone, String name);
    public Appointment saveAppointment(Appointment appointment);
    public boolean createPayment(PaymentRequest paymentDTO);
    List<Appointment> getAppointmentsByDoctor(Integer doctorId);
    public ResponseEntity<Map<String, Object>> register(AppointmentRequestDTO appointmentRequestDTO);
}
