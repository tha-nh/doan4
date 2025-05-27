package com.project.esavior.service;

import com.project.esavior.model.DriverLocation;
import com.project.esavior.repository.DriverLocationRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class DriverLocationService {

    @Autowired
    private DriverLocationRepository driverLocationRepository;

    public void updateDriverLocation(int driverId, DriverLocation location) {
        DriverLocation existingLocation = driverLocationRepository.findByDriverId(driverId);
        if (existingLocation != null) {
            existingLocation.setLatitude(location.getLatitude());
            existingLocation.setLongitude(location.getLongitude());
            driverLocationRepository.save(existingLocation); // Cập nhật vị trí tài xế
        } else {
            location.setDriverId(driverId);
            driverLocationRepository.save(location); // Lưu vị trí tài xế mới
        }
        System.out.println("Driver location updated in service for driverId: " + driverId);
    }

    public DriverLocation getDriverLocation(int driverId) {
        return driverLocationRepository.findByDriverId(driverId);
    }
}
