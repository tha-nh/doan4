package com.project.appoinmentservice.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import com.project.appoinmentservice.dto.AppointmentRequestDTO;
import com.project.appoinmentservice.dto.LockSlotDTO;
import com.project.appoinmentservice.dto.PaymentRequest;
import com.project.appoinmentservice.dto.ResponseDTO;
import com.project.appoinmentservice.model.Appointment;
import com.project.appoinmentservice.service.AppointmentService;
import com.project.appoinmentservice.service.LockSlotService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;


@RestController
@RequestMapping("/api/appointments")
public class AppointmentController {

    @Autowired
    private AppointmentService appointmentService;

    @Autowired
    private LockSlotService lockSlotService;

    @GetMapping("/checkslot/{doctorId}")
    public ResponseEntity<List<Appointment>> getDoctorAppointments(@PathVariable Integer doctorId) {
        List<Appointment> appointments = appointmentService.getAppointmentsByDoctor(doctorId);
        if (appointments.isEmpty()) {
            return ResponseEntity.noContent().build(); // Trả về 204 nếu không có lịch hẹn nào
        }
        return ResponseEntity.ok(appointments); // Trả về 200 với danh sách các lịch hẹn
    }

    @PostMapping("/register")
    public ResponseEntity<Map<String, Object>> register(@RequestBody AppointmentRequestDTO requestData) {
        System.out.println("dữ liệu đã nhận " + requestData.toString());
        return appointmentService.register(requestData);
    }


    @PostMapping("/lock")
    public ResponseEntity<ResponseDTO> lockSlot(@RequestBody LockSlotDTO lockSlotDTO) {
        return lockSlotService.getLockSlotByCode(lockSlotDTO);
    }
}
