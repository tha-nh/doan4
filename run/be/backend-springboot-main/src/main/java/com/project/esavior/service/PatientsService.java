package com.project.esavior.service;

import com.project.esavior.model.Patients;
import com.project.esavior.repository.PatientsRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.Optional;

@Service
public class PatientsService {

    private final PatientsRepository patientsRepository;

    @Autowired
    public PatientsService(PatientsRepository patientsRepository) {
        this.patientsRepository = patientsRepository;
    }

    public Patients registerPatient(Patients patient) {
        return patientsRepository.save(patient);
    }

    public Patients getPatientById(int id) {
        return patientsRepository.findById(id).orElse(null);
    }
    public Optional<Patients> getPatientProfile(Integer id) {
        return patientsRepository.findById(id);
    }
    public Patients getPatientById(Integer patientId) {
        return patientsRepository.findById(patientId)
                .orElseThrow(() -> new IllegalArgumentException("Patient not found with id: " + patientId));
    }
    public Patients updatePatientProfile(Integer id, Patients updatedPatient) {
        Optional<Patients> patient = patientsRepository.findById(id);
        if (patient.isPresent()) {
            Patients existingPatient = patient.get();
            existingPatient.setPatientName(updatedPatient.getPatientName());
            existingPatient.setPhoneNumber(updatedPatient.getPhoneNumber());
            existingPatient.setPatientAddress(updatedPatient.getPatientAddress());
            existingPatient.setZipCode(updatedPatient.getZipCode());
            return patientsRepository.save(existingPatient);
        } else {
            throw new IllegalArgumentException("Patient not found");
        }
    }

    public Optional<Patients> findByEmail(String email) {
        return patientsRepository.findByEmail(email);
    }
    public Optional<Patients> findById(Integer id) {
        return patientsRepository.findById(id);
    }

    public void save(Patients patient) {
        patientsRepository.save(patient);
    }

    public Patients authenticatePatient(String email, String password) {
        return patientsRepository.findByEmailAndPassword(email, password).orElse(null);
    }

}
