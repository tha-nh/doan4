package com.project.esavior.controller;

import com.project.esavior.dto.AdminDTO;
import com.project.esavior.model.Admin;
import com.project.esavior.service.AdminService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/admins")
public class AdminController {

    @Autowired
    private AdminService adminService;

    @GetMapping
    public List<AdminDTO> getAllAdmins() {
        return adminService.getAllAdmins().stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }

    @GetMapping("/{id}")
    public AdminDTO getAdminById(@PathVariable Integer id) {
        Admin admin = adminService.getAdminById(id);
        return convertToDTO(admin);
    }

    @PostMapping
    public Admin createAdmin(@RequestBody Admin admin) {
        return adminService.saveAdmin(admin);
    }

    @DeleteMapping("/{id}")
    public void deleteAdmin(@PathVariable Integer id) {
        adminService.deleteAdmin(id);
    }

    private AdminDTO convertToDTO(Admin admin) {
        return new AdminDTO(admin.getAdminId(), admin.getAdminName(), admin.getAdminEmail(), admin.getCreatedAt(), admin.getUpdatedAt());
    }
}
