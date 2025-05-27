package com.project.esavior.controller;

import com.project.esavior.dto.PatientsDTO;
import com.project.esavior.model.Patients;
import com.project.esavior.service.PatientsService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/api/patients")
public class PatientsController {

    private final PatientsService patientsService;

    @Autowired
    public PatientsController(PatientsService patientsService) {
        this.patientsService = patientsService;
    }

    // Đăng ký bệnh nhân mới
    @PostMapping("/register")
    public ResponseEntity<PatientsDTO> registerPatient(@RequestBody Patients patient) {
        System.out.println("====registerpatient====");
        // Kiểm tra các trường hợp đăng ký hợp lệ (nếu cần)

        // Đăng ký bệnh nhân
        Patients registeredPatient = patientsService.registerPatient(patient);

        // Chuyển đổi sang DTO để phản hồi
        PatientsDTO patientDTO = convertToDTO(registeredPatient);

        return new ResponseEntity<>(patientDTO, HttpStatus.CREATED);
    }

    // Đăng nhập bệnh nhân
    @PostMapping("/login")
    public ResponseEntity<String> loginPatient(@RequestParam String email, @RequestParam String password) {
        Patients authenticatedPatient = patientsService.authenticatePatient(email, password);
        if (authenticatedPatient != null) {
            Map<String, Object> response = new HashMap<>();
            response.put("message", "Login successful");
            response.put("patientId", authenticatedPatient.getPatientId());
            return ResponseEntity.ok("Login successful");
        }
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Invalid email or password");
    }

    // Xem thông tin hồ sơ bệnh nhân
    @GetMapping("/profile/{id}")
    public ResponseEntity<PatientsDTO> getPatientProfile(@PathVariable Integer id) {
        return patientsService.getPatientProfile(id)
                .map(patient -> new ResponseEntity<>(convertToDTO(patient), HttpStatus.OK))
                .orElse(new ResponseEntity<>(HttpStatus.NOT_FOUND));
    }

    // Cập nhật thông tin hồ sơ bệnh nhân
    @PutMapping("/profile/{id}")
    public ResponseEntity<PatientsDTO> updatePatientProfile(@PathVariable Integer id, @RequestBody Patients updatedPatient) {
        try {
            Patients updatedProfile = patientsService.updatePatientProfile(id, updatedPatient);
            PatientsDTO updatedProfileDTO = convertToDTO(updatedProfile);
            return ResponseEntity.ok(updatedProfileDTO);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(null);
        }
    }

    // Kiểm tra email bệnh nhân
    @PostMapping("/check")
    public ResponseEntity<Boolean> checkPatient(@RequestBody Patients patient) {
        System.out.println("====checkPatient====");
        System.out.println("Checking email: " + patient.getEmail());
        Optional<Patients> existingPatient = patientsService.findByEmail(patient.getEmail());
        if (existingPatient.isPresent()) {
            System.out.println("Email found: " + existingPatient.get().getEmail());
            return new ResponseEntity<>(true, HttpStatus.OK); // Email đã tồn tại
        }
        System.out.println("Email not found");
        return new ResponseEntity<>(false, HttpStatus.OK); // Email chưa tồn tại
    }

    // Cập nhật thông tin bệnh nhân nếu email đã tồn tại
    @PutMapping("/update")
    public ResponseEntity<PatientsDTO> updatePatient(@RequestBody Patients patient) {
        System.out.println(" === Update Patient ===");
        Optional<Patients> existingPatient = patientsService.findByEmail(patient.getEmail());
        if (existingPatient.isPresent()) {
            Patients updatePatient = existingPatient.get();
            updatePatient.setPatientName(patient.getPatientName());
            updatePatient.setPhoneNumber(patient.getPhoneNumber());

            // Lưu bệnh nhân đã cập nhật
            patientsService.save(updatePatient);

            // Chuyển đổi Patients thành PatientsDTO để trả về
            PatientsDTO patientDTO = convertToDTO(updatePatient);

            return new ResponseEntity<>(patientDTO, HttpStatus.OK);
        }
        // Nếu bệnh nhân không tồn tại, trả về lỗi 404
        return new ResponseEntity<>(HttpStatus.NOT_FOUND);
    }


    // Phương thức chuyển đổi từ entity sang DTO
    private PatientsDTO convertToDTO(Patients patient) {
        PatientsDTO dto = new PatientsDTO();
        dto.setPatientId(patient.getPatientId());
        dto.setEmail(patient.getEmail());
        dto.setPatientName(patient.getPatientName());
        dto.setPhoneNumber(patient.getPhoneNumber());
        dto.setAddress(patient.getPatientAddress());
        dto.setZipCode(patient.getZipCode());
        dto.setEmergencyContact(patient.getEmergencyContact());
        dto.setLatitude(patient.getLatitude());
        dto.setLongitude(patient.getLongitude());
        dto.setPatientDob(patient.getPatientDob());
        dto.setPatientGender(patient.getPatientGender());
        dto.setPatientCode(patient.getPatientCode());
        dto.setPatientImg(patient.getPatientImg());
        dto.setCreatedAt(patient.getCreatedAt());
        dto.setUpdatedAt(patient.getUpdatedAt());
        return dto;
    }
}
