package com.project.esavior.repository;

import com.project.esavior.model.Ambulance;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface AmbulanceRepository extends JpaRepository<Ambulance, Integer> {
    List<Ambulance>  findAmbulanceByDriverDriverId(Integer driverId);
}
