package com.project.userservice.service;

import com.project.userservice.dto.ChangePasswordRequest;
import com.project.userservice.model.Patients;
import org.springframework.security.core.parameters.P;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public interface PatientService {
    public Patients registerPatient(Patients patient);
    public Patients updatePatient(Patients patient);
    public Patients findByEmail(String email);
    public Patients checkEmail(Patients patients);
    public Patients changePassword(ChangePasswordRequest changePasswordRequest);
    public List<Patients> findAllPatients();
    public List<Patients> findAlPatients();
    public void deletePatientByEmail(String email);
    }
