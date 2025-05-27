package com.project.esavior.repository;

import com.project.esavior.model.PatientLocation;
import org.springframework.data.jpa.repository.JpaRepository;

public interface PatientLocationRepository extends JpaRepository<PatientLocation, Integer> {
    PatientLocation findByPatientId(Integer patientId);

}
