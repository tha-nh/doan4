package com.project.userservice.repository;

import com.project.userservice.model.Patients;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface PatientRepository extends JpaRepository<Patients, Integer> {
    Patients findByPatientEmail(String email);
    public void deleteByPatientEmail(String email);
}
