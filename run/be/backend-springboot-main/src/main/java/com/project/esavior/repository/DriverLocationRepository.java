package com.project.esavior.repository;

import com.project.esavior.model.DriverLocation;
import org.springframework.data.jpa.repository.JpaRepository;

public interface DriverLocationRepository extends JpaRepository<DriverLocation, Integer> {
    DriverLocation findByDriverId(Integer driverId);
}
