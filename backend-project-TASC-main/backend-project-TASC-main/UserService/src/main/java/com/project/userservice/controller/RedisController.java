package com.project.userservice.controller;

import com.project.userservice.model.Patients;
import com.project.userservice.service.PatientService;
import com.project.userservice.service.implement.RedisService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/redis")
public class RedisController {

    private final RedisService redisService;
    @Autowired
    PatientService patientService;

    @Autowired
    public RedisController(RedisService redisService) {
        this.redisService = redisService;
    }

    @PostMapping("/save")
    public String saveValue(@RequestParam String key, @RequestParam String value) {
        redisService.saveValue(key, value);
        return "Saved!";
    }

    @GetMapping("/get")
    public Object getValue(@RequestParam String key) {
        return redisService.getValue(key);
    }
    @GetMapping("/getAll")
    public ResponseEntity<List<Patients>> getAllPatients() {
        List<Patients> patients = patientService.findAllPatients();
        return ResponseEntity.ok(patients); // Trả về ResponseEntity với HTTP status 200 và danh sách patients
    }

    @DeleteMapping("/delete")
    public String deleteValue(@RequestParam String key) {
        redisService.deleteValue(key);
        return "Deleted!";
    }
    @GetMapping("/patients")
    public ResponseEntity<List<Patients>> getAlPatients() {
        List<Patients> patients = patientService.findAlPatients();  // Tự động lấy từ cache nếu có
        return ResponseEntity.ok(patients);
    }

}
