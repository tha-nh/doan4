package com.project.userservice.controller;


import com.project.userservice.dto.StaffRegistrationDto;
import com.project.userservice.model.Role;
import com.project.userservice.model.Staffs;
import com.project.userservice.service.StaffService;
import com.project.userservice.service.implement.StaffServiceImpl;
import org.modelmapper.ModelMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/userservice/notjwt/staffs")
public class StaffController {
    @Autowired
    private BCryptPasswordEncoder passwordEncoder;
    @Autowired
    StaffService staffService;


    @PostMapping("/register")
    public ResponseEntity<Staffs> registerStaff(@RequestBody StaffRegistrationDto registrationDto) {
        ModelMapper modelMapper = new ModelMapper();
        Staffs staff = modelMapper.map(registrationDto, Staffs.class);
        staff.setStaffPassword(passwordEncoder.encode(registrationDto.getStaffPassword())); // Mã hóa mật khẩu
        return ResponseEntity.ok(staffService.registerStaff(staff));
    }
}
