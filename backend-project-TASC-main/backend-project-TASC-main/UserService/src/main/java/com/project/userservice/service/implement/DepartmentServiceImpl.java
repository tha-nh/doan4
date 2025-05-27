package com.project.userservice.service.implement;

import com.project.userservice.dto.DepartmentDTO;
import com.project.userservice.model.Departments;
import com.project.userservice.repository.DepartmentRepository;
import com.project.userservice.service.DepartmentService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class DepartmentServiceImpl implements DepartmentService {

    @Autowired
    DepartmentRepository departmentRepository;

    @Override
    public List<DepartmentDTO> getAllDepartments() {
        List<Departments> departments = departmentRepository.findAll();
        return departments.stream()
                .map(department -> new DepartmentDTO(department.getId(), department.getDepartmentName(),department.getDepartmentImg(),department.getDepartmentDescription()))
                .collect(Collectors.toList());
    }
}
