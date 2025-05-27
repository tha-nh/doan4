package com.project.esavior.controller;

import com.project.esavior.dto.AmbulanceDTO;
import com.project.esavior.model.Ambulance;
import com.project.esavior.service.AmbulanceService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/ambulances")
public class AmbulanceController {


    @Autowired
    private AmbulanceService ambulanceService;

    @GetMapping
    public List<AmbulanceDTO> getAllAmbulances() {
        // Chuyển đổi danh sách Ambulance sang DTO trước khi trả về
        return ambulanceService.getAllAmbulances().stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }

    @GetMapping("/{id}")
    public ResponseEntity<AmbulanceDTO> getAmbulanceById(@PathVariable Integer id) {
        Ambulance ambulance = ambulanceService.getAmbulanceById(id);
        if (ambulance != null) {
            return new ResponseEntity<>(convertToDTO(ambulance), HttpStatus.OK);
        } else {
            return new ResponseEntity<>(HttpStatus.NOT_FOUND);
        }
    }

    @PostMapping
    public ResponseEntity<String> createAmbulance(@RequestBody Ambulance ambulance) {
        Ambulance createdAmbulance = ambulanceService.saveAmbulance(ambulance);
        if (createdAmbulance != null) {
            return new ResponseEntity<>("Ambulance created successfully", HttpStatus.CREATED);
        } else {
            return new ResponseEntity<>("Ambulance creation failed", HttpStatus.BAD_REQUEST);
        }
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<String> deleteAmbulance(@PathVariable Integer id) {
        ambulanceService.deleteAmbulance(id);
        return new ResponseEntity<>("Ambulance deleted successfully", HttpStatus.OK);
    }

    @GetMapping("/driver/{driverId}")
    public ResponseEntity<List<AmbulanceDTO>> getAmbulancesByDriverId(@PathVariable Integer driverId) {
        List<Ambulance> ambulances = ambulanceService.getAmbulancesByDriverId(driverId);

        if (!ambulances.isEmpty()) {
            // Chuyển đổi danh sách ambulances sang DTO
            List<AmbulanceDTO> ambulanceDTOs = ambulances.stream()
                    .map(this::convertToDTO)
                    .collect(Collectors.toList());
            return new ResponseEntity<>(ambulanceDTOs, HttpStatus.OK);
        } else {
            return new ResponseEntity<>(HttpStatus.NOT_FOUND);
        }
    }


    // Phương thức chuyển đổi từ Entity sang DTO
    private AmbulanceDTO convertToDTO(Ambulance ambulance) {
        return new AmbulanceDTO(
                ambulance.getAmbulanceId(),
                ambulance.getAmbulanceNumber(),
                ambulance.getDriver() != null ? ambulance.getDriver().getDriverId() : null,
                ambulance.getAmbulanceStatus(),
                ambulance.getAmbulanceType(),
                ambulance.getHospital() != null ? ambulance.getHospital().getHospitalId() : null,
                ambulance.getCreatedAt(),
                ambulance.getUpdatedAt()
        );
    }
}
