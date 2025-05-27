package com.project.esavior.controller;

import com.project.esavior.model.Driver;
import com.project.esavior.model.DriverLocation;
import com.project.esavior.model.PatientLocation;
import com.project.esavior.service.DriverLocationService;
import com.project.esavior.service.PatientLocationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/patientlocation")
public class PatientLocationController {

    @Autowired
    private PatientLocationService patientLocationService; // Inject service
    @Autowired
    private DriverLocationService driverLocationService;

    @PostMapping("/update")
    public ResponseEntity<String> updateLocation(@RequestBody PatientLocation patientLocation) {
        try {
            System.out.println("update location");
            // Gọi service để lưu vị trí
            patientLocationService.updateLocation(patientLocation);
            System.out.println(patientLocation.toString());
            return new ResponseEntity<>("Location updated successfully", HttpStatus.OK);
        } catch (Exception e) {
            return new ResponseEntity<>("Error updating location: " + e.getMessage(), HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
    @PostMapping("/update-location")
    public ResponseEntity<String> updateDriverLocation(@RequestBody Map<String, Object> request) {
        Integer driverId = (Integer) request.get("driverId");
        Double latitude = (Double) request.get("latitude");
        Double longitude = (Double) request.get("longitude");

        DriverLocation driverLocation = new DriverLocation(latitude , longitude);

        driverLocationService.updateDriverLocation(driverId, driverLocation);  // Cập nhật vị trí tài xế
        System.out.println("Updating location for driverId: " + driverId + " with lat: " + latitude + ", long: " + longitude);

        return new ResponseEntity<>("Location updated successfully", HttpStatus.OK);
    }
    @PostMapping("/location")
    public ResponseEntity<Map<String, Object>> getDriverLocation(@RequestBody Driver request) {
        Integer driverId = request.getDriverId();
        DriverLocation location = driverLocationService.getDriverLocation(driverId);  // Lấy vị trí tài xế

        if (location != null) {
            Map<String, Object> response = new HashMap<>();
            response.put("latitude", location.getLatitude());
            response.put("longitude", location.getLongitude());
            return new ResponseEntity<>(response, HttpStatus.OK);
        } else {
            return new ResponseEntity<>(HttpStatus.NOT_FOUND);
        }
    }
    @GetMapping("/get-driver-location/{driverId}")
    public ResponseEntity<DriverLocation> getDriverLocation(@PathVariable Integer driverId) {
        DriverLocation location = driverLocationService.getDriverLocation(driverId);
        System.out.println(location.toString());
        if (location != null) {
            System.out.println("Returning location for driverId: " + driverId);
            return new ResponseEntity<>(location, HttpStatus.OK);
        } else {
            System.out.println("No location found for driverId: " + driverId);
            return new ResponseEntity<>(HttpStatus.NOT_FOUND);
        }
    }
    @GetMapping("/get-customer-location/{patientId}")
    public ResponseEntity<PatientLocation> getCustomerLocation(@PathVariable Integer patientId) {
        PatientLocation location = patientLocationService.getCustomerLocation(patientId);
        if (location != null) {
            return new ResponseEntity<>(location, HttpStatus.OK);
        } else {
            return new ResponseEntity<>(HttpStatus.NOT_FOUND);
        }
    }
}
