package com.project.esavior.controller;

import com.project.esavior.dto.HospitalDTO;
import com.project.esavior.model.Hospital;
import com.project.esavior.service.HospitalService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/hospitals")
public class HospitalController {

    @Autowired
    private HospitalService hospitalService;

    @GetMapping("/all")
    public ResponseEntity<List<HospitalDTO>> getAllHospitals() {
        List<Hospital> hospitals = hospitalService.getAllHospitals();

        // Chuyển đổi danh sách Hospital thành HospitalDTO
        List<HospitalDTO> hospitalDTOs = hospitals.stream().map(hospital -> {
            HospitalDTO dto = new HospitalDTO();
            dto.setHospitalId(hospital.getHospitalId());
            dto.setHospitalName(hospital.getHospitalName());
            dto.setAddress(hospital.getAddress());
            dto.setPhoneNumber(hospital.getPhoneNumber());
            dto.setCityId(hospital.getCity().getCityId()); // Chỉ lấy City ID để tránh vòng lặp
            dto.setCreatedAt(hospital.getCreatedAt());
            dto.setUpdatedAt(hospital.getUpdatedAt());
            dto.setZipCode(hospital.getZipCode());
            dto.setLatitude(hospital.getLatitude());
            dto.setLongitude(hospital.getLongitude());

            return dto;
        }).toList();

        return ResponseEntity.ok(hospitalDTOs);
    }
}
