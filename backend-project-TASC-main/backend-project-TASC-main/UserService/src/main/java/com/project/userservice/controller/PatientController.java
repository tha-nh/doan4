package com.project.userservice.controller;

import com.project.userservice.dto.ChangePasswordRequest;
import com.project.userservice.dto.PatientRegistrationDto;
import com.project.userservice.model.Patients;
import com.project.userservice.model.Role;
import com.project.userservice.service.PatientService;
import org.modelmapper.ModelMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/userservice/notjwt/patients")
public class PatientController {
    @Autowired
    private BCryptPasswordEncoder passwordEncoder;

    @Autowired
    private PatientService patientService;

    @PostMapping("/register")
    public ResponseEntity<Patients> registerPatient(@RequestBody PatientRegistrationDto registrationDto) {
        System.out.println("dữ liệu đã nhận :" + registrationDto.toString());
        ModelMapper modelMapper = new ModelMapper();
        Patients patient = modelMapper.map(registrationDto, Patients.class);
        return ResponseEntity.ok(patientService.registerPatient(patient));
    }


    @PostMapping("/check")
    public ResponseEntity<Patients> checkPatients(@RequestBody Map<String, Object> requestData) {
        ModelMapper modelMapper = new ModelMapper();
        Patients patient = modelMapper.map(requestData, Patients.class);
        return ResponseEntity.ok(patientService.checkEmail(patient));
    }

    @PostMapping("/change-password")
    public ResponseEntity<Patients> changePassword(@RequestBody ChangePasswordRequest request) {
        Patients patients = patientService.changePassword(request);
        return ResponseEntity.ok(patients);
    }
}
