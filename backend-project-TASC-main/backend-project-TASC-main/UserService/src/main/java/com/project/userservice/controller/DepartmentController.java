package com.project.userservice.controller;


import com.project.userservice.dto.DepartmentDTO;
import com.project.userservice.model.Departments;
import com.project.userservice.service.DepartmentService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import java.util.List;

@RestController
@RequestMapping("/api/userservice/notjwt/departments")
public class DepartmentController {

    @Autowired
    private DepartmentService departmentService;

    @GetMapping("/getall")
    public List<DepartmentDTO> getAll(){
        return departmentService.getAllDepartments();
    }
}
