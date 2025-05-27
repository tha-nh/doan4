package com.project.esavior.repository;

import com.project.esavior.model.Patients;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface PatientsRepository extends JpaRepository<Patients, Integer> {
    Optional<Patients> findByEmail(String email);
    Optional<Patients> findByEmailAndPassword(String email, String password);
    Optional<Patients> findById(Integer id);
}
