package com.project.userservice.repository;

import com.project.userservice.dto.DoctorDTO;
import com.project.userservice.model.Doctors;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface DoctorsRepository extends JpaRepository<Doctors, Integer> {
    Doctors findByDoctorEmail(String email);
    List<Doctors> findByDepartmentId(Integer departmentId);
}
