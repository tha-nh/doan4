package com.project.userservice.service.implement;
import com.project.userservice.dto.ChangePasswordRequest;
import com.project.userservice.model.Patients;
import com.project.userservice.model.Role;
import com.project.userservice.repository.PatientRepository;
import com.project.userservice.service.PasswordService;
import com.project.userservice.service.PatientService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.CachePut;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class PatientServiceImpl implements PatientService {
    @Autowired
    private PasswordService passwordService;

    @Autowired
    private BCryptPasswordEncoder passwordEncoder;

    @Autowired
    private PatientRepository patientRepository;
    @Autowired
    private SendEmail sendEmail;

    @Override
    public Patients findByEmail(String email) {
        return patientRepository.findByPatientEmail(email);
    }

    @Override
    public Patients checkEmail(Patients patients) {
        Patients patient = findPatientByEmail(patients.getPatientEmail()); // Gọi method có @Cacheable
        if (patient == null) {
            patients.setPatientPassword(passwordEncoder.encode(passwordService.generateRandomPassword()));
            Patients savedPatient = patientRepository.save(patients);

            // Cập nhật cache
            updatePatientCache(savedPatient.getPatientEmail(), savedPatient);

            // Gửi email
            sendEmail.sendEmail(savedPatient.getPatientName(), savedPatient.getPatientEmail(), savedPatient.getPatientPassword());
            return savedPatient;
        } else {
            return patient;
        }
    }

    @CachePut(value = "patients", key = "#email")
    public void updatePatientCache(String email, Patients patient) {
        System.out.println("Updating cache...");
    }


    @Cacheable(value = "patients", key = "#email")
    public Patients findPatientByEmail(String email) {
        System.out.println("Fetching patient from database...");
        return patientRepository.findByPatientEmail(email);
    }

    @Override
    public Patients registerPatient(Patients patient) {
        patient.setPatientPassword(passwordEncoder.encode(patient.getPatientPassword())); // Mã hóa mật khẩu
        Role patientRole = new Role();
        patientRole.setId(2);
        patient.setRole(patientRole);
        return patientRepository.save(patient);
    }

    @Override
    public Patients updatePatient(Patients patient) {
        return patientRepository.save(patient);
    }

    @Override
    @CachePut(value = "patients", key = "#patient.patientEmail")
    public Patients changePassword(ChangePasswordRequest changePasswordRequest) {
        Patients patient = patientRepository.findByPatientEmail(changePasswordRequest.getEmail());
        if (patient == null) return null;
        if (!passwordEncoder.matches(changePasswordRequest.getOldPassword(), patient.getPatientPassword())) return null;
        patient.setPatientPassword(passwordEncoder.encode(changePasswordRequest.getNewPassword()));
        return patientRepository.save(patient);
    }
    @Override
    @Cacheable(value = "patientsAll")
    public List<Patients> findAllPatients() {
        System.out.println("Fetching patients from database...");
        return patientRepository.findAll();
    }
    @CacheEvict(value = "patientsAll", allEntries = true) // Xóa toàn bộ cache
    @Scheduled(cron = "0 0 0 * * ?") // Chạy vào 0:00 mỗi ngày
    public void refreshPatientsAllCache() {
        System.out.println("Refreshing cache for patientsAll...");
        findAllPatients(); // Gọi lại để làm mới cache
    }
    @Override
    public List<Patients> findAlPatients() {
        System.out.println("Check1.");
        return patientRepository.findAll();
    }
    @Override
    @CacheEvict(value = "patients", key = "#email")
    public void deletePatientByEmail(String email) {
        patientRepository.deleteByPatientEmail(email);
    }

}
