package com.project.esavior.service;

import com.project.esavior.model.Ambulance;
import com.project.esavior.repository.AmbulanceRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class AmbulanceService {

    @Autowired
    private AmbulanceRepository ambulanceRepository;

    public List<Ambulance> getAllAmbulances() {
        return ambulanceRepository.findAll();
    }

    public Ambulance getAmbulanceById(Integer id) {
        return ambulanceRepository.findById(id).orElse(null);
    }

    public Ambulance saveAmbulance(Ambulance ambulance) {
        return ambulanceRepository.save(ambulance);
    }

    public void deleteAmbulance(Integer id) {
        ambulanceRepository.deleteById(id);
    }

    public List<Ambulance> getAmbulancesByDriverId(Integer driverId) {
        return ambulanceRepository.findAmbulanceByDriverDriverId(driverId);
    }
}
