package com.project.userservice.controller;

import com.project.userservice.dto.DoctorDTO;
import com.project.userservice.dto.DoctorRegistrationDto;
import com.project.userservice.model.Doctors;
import com.project.userservice.model.Role;
import com.project.userservice.service.DoctorService;
import com.project.userservice.service.implement.DoctorServiceImpl;
import org.modelmapper.ModelMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/userservice/notjwt/doctors")
public class DoctorController {

    @Autowired
    DoctorService doctorService;
    @Autowired
    BCryptPasswordEncoder passwordEncoder;


    @PostMapping("/register")
    public ResponseEntity<Doctors> registerDoctor(@RequestBody DoctorRegistrationDto registrationDto) {
        ModelMapper modelMapper = new ModelMapper();
        Doctors doctor = modelMapper.map(registrationDto, Doctors.class);
        doctorService.registerDoctor(doctor);
        return ResponseEntity.ok(doctorService.registerDoctor(doctor));
    }
    @GetMapping("/getbydepartment/{id}")
    public ResponseEntity<?> getDoctorsByDepartment(@PathVariable Integer id) {
        // Gọi service để lấy danh sách bác sĩ theo departmentId
        List<DoctorDTO> doctors = doctorService.getDoctorsByDepartment(id);
        if (doctors.isEmpty()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body("No doctors found for this department");
        }
        return ResponseEntity.ok(doctors);
    }
}
