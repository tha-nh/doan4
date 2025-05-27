package com.project.esavior.service;

import com.project.esavior.model.PatientLocation;
import com.project.esavior.repository.PatientLocationRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class LocationService {

    @Autowired
    private PatientLocationRepository patientLocationRepository;

    // Cập nhật vị trí và thông tin bệnh nhân
    public void updateLocationAndCustomerInfo(PatientLocation location) {
        // Tìm kiếm thông tin vị trí của bệnh nhân trong cơ sở dữ liệu
        PatientLocation existingLocation = patientLocationRepository.findByPatientId(location.getPatientId());
        if (existingLocation != null) {
            // Nếu đã có vị trí, cập nhật thông tin mới
            existingLocation.setLatitude(location.getLatitude());
            existingLocation.setLongitude(location.getLongitude());
            existingLocation.setDestinationLatitude(location.getDestinationLatitude());
            existingLocation.setDestinationLongitude(location.getDestinationLongitude());
            existingLocation.setBookingStatus(location.getBookingStatus());
            patientLocationRepository.save(existingLocation);  // Lưu vào cơ sở dữ liệu
        } else {
            // Nếu chưa có, lưu vị trí bệnh nhân mới
            patientLocationRepository.save(location);
        }
    }

    // Lấy vị trí và thông tin của bệnh nhân
    public PatientLocation getCustomerLocation(int patientId) {
        return patientLocationRepository.findByPatientId(patientId);
    }
}
