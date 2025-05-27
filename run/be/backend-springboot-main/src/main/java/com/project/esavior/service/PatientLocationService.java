package com.project.esavior.service;

import com.project.esavior.model.PatientLocation;
import com.project.esavior.model.Patients;
import com.project.esavior.repository.PatientLocationRepository;
import com.project.esavior.repository.PatientsRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

@Service
public class PatientLocationService {

    @Autowired
    private PatientLocationRepository patientLocationRepository;
    @Autowired
    private PatientsRepository patientsRepository;

    // Cập nhật vị trí và thông tin bệnh nhân
    public void savePatientLocation(PatientLocation patientLocation) {
        patientLocationRepository.save(patientLocation); // Sử dụng repository để lưu
    }
    // Lấy vị trí và thông tin của bệnh nhân
    public PatientLocation getPaientLocation(int patientId) {
        return patientLocationRepository.findByPatientId(patientId);
    }
    public Map<String, Object> getPatientAndLocationInfo(Integer patientId) {
        // Truy xuất thông tin vị trí bệnh nhân
        PatientLocation patientLocation = patientLocationRepository.findByPatientId(patientId);

        if (patientLocation == null) {
            throw new IllegalStateException("Patient location not found for patient ID: " + patientId);
        }

        // Truy xuất thông tin bệnh nhân
        Patients patient = patientsRepository.findById(patientId)
                .orElseThrow(() -> new IllegalStateException("Patient not found for ID: " + patientId));

        // Tạo map để trả về thông tin vị trí và thông tin bệnh nhân
        Map<String, Object> info = new HashMap<>();
        info.put("latitude", patientLocation.getLatitude());
        info.put("longitude", patientLocation.getLongitude());
        info.put("customerName", patient.getPatientName());
        info.put("phoneNumber", patient.getPhoneNumber());
        info.put("email", patient.getEmail());
        info.put("destinationLatitude", patientLocation.getDestinationLatitude());
        info.put("destinationLongitude", patientLocation.getDestinationLongitude());
        return info;
    }
    public void updateLocation(PatientLocation patient) {
        // Tìm bản ghi patient location trong cơ sở dữ liệu dựa trên patientId
        PatientLocation patientLocation = patientLocationRepository.findByPatientId(patient.getPatientId());

        // Nếu không tìm thấy, tạo mới bản ghi
        if (patientLocation == null) {
            patientLocation = new PatientLocation();
            patientLocation.setPatientId(patient.getPatientId());
            patientLocation.setCreatedAt(LocalDateTime.now());
        }

        // Cập nhật các trường cần thiết
        patientLocation.setLatitude(patient.getLatitude());
        patientLocation.setLongitude(patient.getLongitude());
        patientLocation.setUpdatedAt(LocalDateTime.now());

        // Lưu vào cơ sở dữ liệu
        patientLocationRepository.save(patientLocation);
    }
    public PatientLocation getCustomerLocation(Integer patientId) {
        return patientLocationRepository.findByPatientId(patientId);
    }
}
