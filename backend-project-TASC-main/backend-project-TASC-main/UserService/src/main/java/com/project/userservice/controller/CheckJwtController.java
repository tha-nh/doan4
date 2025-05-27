package com.project.userservice.controller;

import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.Map;



@RestController
@RequestMapping("/api/userservice/jwt")
@SecurityRequirement(name = "bearerAuth")
public class CheckJwtController {




    @GetMapping("/staff/overview")
    @PreAuthorize("hasRole('STAFF')")
    public ResponseEntity<Map<String, String>> getStaffOverview() {
        Map<String, String> response = new HashMap<>();
        response.put("message", "This is the staff overview, accessible only to staff members.");
        return ResponseEntity.ok(response);
    }

    @GetMapping("/admin/overview")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Map<String, String>> getAdminOverview() {
        Map<String, String> response = new HashMap<>();
        response.put("message", "This is the admin overview, accessible only to admin members.");
        return ResponseEntity.ok(response);
    }

    @GetMapping("/doctor/overview")
    @PreAuthorize("hasRole('DOCTOR')")
    public ResponseEntity<Map<String, String>> getDoctorOverview() {
        Map<String, String> response = new HashMap<>();
        response.put("message", "This is the doctor overview, accessible only to doctors.");
        System.out.println("API called successfully");
        return ResponseEntity.ok(response);
    }

    @GetMapping("/patient/overview")
    @PreAuthorize("hasRole('PATIENT')")
    public ResponseEntity<Map<String, String>> getPatientOverview() {
        Map<String, String> response = new HashMap<>();
        response.put("message", "This is the patient overview, accessible only to patients.");
        return ResponseEntity.ok(response);
    }
}
