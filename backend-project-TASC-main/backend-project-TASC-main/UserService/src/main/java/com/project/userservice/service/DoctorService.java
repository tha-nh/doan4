package com.project.userservice.service;

import com.project.userservice.dto.DoctorDTO;
import com.project.userservice.model.Doctors;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public interface DoctorService {
    public Doctors registerDoctor(Doctors doctor);
    public Doctors findByEmail(String email);
    List<DoctorDTO> getDoctorsByDepartment(Integer departmentId);

}
