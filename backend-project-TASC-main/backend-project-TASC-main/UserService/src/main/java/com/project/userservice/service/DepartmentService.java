package com.project.userservice.service;

import com.project.userservice.dto.DepartmentDTO;
import com.project.userservice.model.Departments;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface DepartmentService {
    public List<DepartmentDTO> getAllDepartments();
}
