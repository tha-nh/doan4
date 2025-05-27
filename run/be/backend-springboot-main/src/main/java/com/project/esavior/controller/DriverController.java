package com.project.esavior.controller;

import com.project.esavior.dto.BookingDTO;
import com.project.esavior.dto.DriverDTO;
import com.project.esavior.model.*;
import com.project.esavior.service.*;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;


import java.io.IOException;
import java.util.*;

@RestController
@RequestMapping("/api/drivers")
public class DriverController {

    private final DriverLocationService driverLocationService;
    private DriverService driverService;
    private BookingService bookingService;
    private PatientLocationService patientLocationService;
    private PatientsService patientsService;

    public DriverController(DriverLocationService driverLocationService, DriverService driverService, BookingService bookingService, PatientLocationService patientLocationService, PatientsService patientsService) {
        this.driverLocationService = driverLocationService;
        this.driverService = driverService;
        this.bookingService = bookingService;
        this.patientLocationService = patientLocationService;
        this.patientsService = patientsService;
    }

    // Đăng nhập tài xế
    @PostMapping("/login")
    public ResponseEntity<?> loginDriver(@RequestBody Map<String, String> loginRequest) {
        String driverEmail = loginRequest.get("email");
        String driverPassword = loginRequest.get("password");

        // Xác thực tài xế
        Driver authenticatedDriver = driverService.authenticateDriver(driverEmail, driverPassword);

        if (authenticatedDriver != null) {
            // Chuyển đổi Driver sang DriverDTO
            DriverDTO driverDTO = convertToDTO(authenticatedDriver);

            // Trả về đối tượng DriverDTO
            return ResponseEntity.ok(driverDTO);
        } else {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Collections.singletonMap("success", false));
        }
    }

    @PostMapping
    public ResponseEntity<String> createDriver(@RequestBody Driver driver) {
        Driver createdDriver = driverService.saveDriver(driver);
        if (createdDriver != null) {
            return new ResponseEntity<>("Driver created successfully", HttpStatus.CREATED);
        } else {
            return new ResponseEntity<>("Driver creation failed", HttpStatus.BAD_REQUEST);
        }
    }


    // Chuyển đổi từ Driver entity sang DTO
    public DriverDTO convertToDTO(Driver driver) {
        DriverDTO dto = new DriverDTO();
        dto.setDriverId(driver.getDriverId());
        dto.setDriverName(driver.getDriverName());
        dto.setEmail(driver.getEmail());
        dto.setPassword(driver.getPassword());
        dto.setDriverPhone(driver.getDriverPhone());
        dto.setLicenseNumber(driver.getLicenseNumber());
        dto.setStatus(driver.getStatus());
        dto.setLatitude(driver.getLatitude());
        dto.setLongitude(driver.getLongitude());
        if (driver.getHospital() != null) {
            dto.setHospitalId(driver.getHospital().getHospitalId());
        }
        dto.setCreatedAt(driver.getCreatedAt());
        dto.setUpdatedAt(driver.getUpdatedAt());
        return dto;
    }


    // Lấy danh sách tài xế
    @GetMapping("/all")
    public List<DriverDTO> getAllDrivers() {
        List<Driver> drivers = driverService.getAllDrivers();
        return drivers.stream()
                .map(this::convertToDTO)
                .toList(); // Chuyển đổi sang DTO
    }

    @PostMapping("/update-status")
    public ResponseEntity<DriverDTO> updateDriverStatus(@RequestBody DriverDTO requestBody) {
        try {
            // Lấy driverId và status từ requestBody
            Integer driverId = requestBody.getDriverId();
            String status = requestBody.getStatus();

            // Kiểm tra xem tài xế có tồn tại không
            Optional<Driver> driverOptional = driverService.findDriverById(driverId);
            if (driverOptional.isEmpty()) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).body(null); // Không tìm thấy tài xế
            }

            // Cập nhật trạng thái tài xế
            Driver updatedDriver = driverService.updateDriverStatus(driverId, status);

            // Chuyển đổi sang DTO
            DriverDTO updatedDriverDTO = convertToDTO(updatedDriver);

            // Trả về kết quả
            return ResponseEntity.ok(updatedDriverDTO);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(null); // Lỗi yêu cầu không hợp lệ
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(null); // Lỗi hệ thống
        }
    }


    // Cập nhật trạng thái đặt chỗ
    @PutMapping("/bookings/{bookingId}/status")
    public ResponseEntity<Booking> updateBookingStatus(@PathVariable Integer bookingId, @RequestParam String status) {
        try {
            System.out.println("ok");
            Booking updatedBooking = driverService.updateBookingStatus(bookingId, status);
            return ResponseEntity.ok(updatedBooking);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(null);
        }
    }

    // Cập nhật trạng thái xe cứu thương
    @PutMapping("/{driverId}/ambulance/status")
    public ResponseEntity<DriverDTO> updateAmbulanceStatus(@PathVariable Integer driverId, @RequestParam String status) {
        try {
            Driver updatedDriver = driverService.updateDriverStatus(driverId, status);
            DriverDTO updatedDriverDTO = convertToDTO(updatedDriver); // Chuyển đổi sang DTO
            return ResponseEntity.ok(updatedDriverDTO);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(null);
        }
    }

    // Tìm tài xế gần nhất
    @PostMapping("/nearest")
    public ResponseEntity<List<DriverDTO>> findNearestDrivers(@RequestBody Map<String, Object> location) {
        double latitude = (double) location.get("latitude");
        double longitude = (double) location.get("longitude");
        int bookingId = (int) location.get("bookingId"); // Nhận thêm bookingId từ request

        // Tìm các tài xế gần nhất
        List<Driver> nearestDrivers = driverService.findNearestDrivers(latitude, longitude);

        // Nếu không có tài xế gần nhất
        if (nearestDrivers.isEmpty()) {
            return ResponseEntity.noContent().build();
        }

        // Chuyển đổi danh sách Driver thành danh sách DriverDTO
        List<DriverDTO> driverDTOs = nearestDrivers.stream()
                .map(driver -> new DriverDTO(
                        driver.getDriverId(),
                        driver.getDriverName(),
                        driver.getDriverPhone(),
                        driver.getLatitude(),
                        driver.getLongitude(),
                        driver.getStatus()
                ))
                .toList();

        // Lấy tài xế đầu tiên trong danh sách gần nhất
        Driver nearestDriver = nearestDrivers.get(0);

        // Cập nhật booking với driverId và vị trí khách hàng (có cả bookingId)
        bookingService.updateBookingWithDriver(bookingId, nearestDriver.getDriverId());

        // Trả về danh sách tài xế gần nhất (DTOs)
        return ResponseEntity.ok(driverDTOs);
    }


    @GetMapping("/check-booking/{driverId}")
    public ResponseEntity<BookingDTO> checkForNewBooking(@PathVariable Integer driverId) {
        // Lấy booking mới nhất của tài xế từ BookingService
        Optional<Booking> newBooking = bookingService.getBookingForDriver(driverId);

        if (newBooking.isPresent()) {
            Booking booking = newBooking.get();

            // Lấy thông tin bệnh nhân từ patientId
            Patients patient = patientsService.getPatientById(booking.getPatient().getPatientId());
            String patientName = patient.getPatientName();
            String patientPhone = patient.getPhoneNumber();

            // Tạo BookingDTO với thông tin cần thiết
            BookingDTO bookingDTO = new BookingDTO(
                    booking.getLatitude(),           // Vĩ độ điểm đón
                    booking.getLongitude(),          // Kinh độ điểm đón
                    booking.getDestinationLatitude(),// Vĩ độ điểm đến
                    booking.getDestinationLongitude(),// Kinh độ điểm đến
                    booking.getPickupAddress(),      // Địa chỉ điểm đón
                    patientName,                     // Tên bệnh nhân
                    patientPhone                     // Số điện thoại bệnh nhân
            );

            return ResponseEntity.ok(bookingDTO);
        } else {
            return ResponseEntity.noContent().build();  // Không có đơn đặt xe mới
        }
    }
    @GetMapping("/check-driver/{driverId}")
    public ResponseEntity<Map<String, Object>> checkDriverBooking(@PathVariable Integer driverId) {
        // Lấy danh sách các booking có trạng thái "Pending" của driver
        List<Booking> pendingBookings = bookingService.getPendingBookingsByDriverId(driverId);

        if (!pendingBookings.isEmpty()) {
            // Lấy booking đầu tiên trong danh sách nếu tồn tại
            Booking booking = pendingBookings.get(0);

            // Lấy thông tin khách hàng và tọa độ từ `PatientLocationService`
            Map<String, Object> customerAndLocationInfo = patientLocationService.getPatientAndLocationInfo(booking.getPatient().getPatientId());

            // Thêm bookingId vào response
            customerAndLocationInfo.put("bookingId", booking.getBookingId());

            return ResponseEntity.ok(customerAndLocationInfo); // Trả về thông tin khách hàng, tọa độ và bookingId
        } else {
            // Nếu không tìm thấy, trả về no content
            return ResponseEntity.noContent().build();
        }
    }











    @GetMapping("/get-driver-location/{driverId}")
    public ResponseEntity<DriverLocation> getDriverLocation(@PathVariable Integer driverId) {
        DriverLocation driverLocation = driverLocationService.getDriverLocation(driverId);
        if (driverLocation != null) {
            return new ResponseEntity<>(driverLocation, HttpStatus.OK);
        } else {
            return new ResponseEntity<>(HttpStatus.NOT_FOUND);
        }
    }
    @GetMapping("/{driverId}")
    public ResponseEntity<DriverDTO> getDriverById(@PathVariable Integer driverId) {
        Optional<Driver> driver = driverService.findDriverById(driverId);

        if (driver.isPresent()) {
            Driver foundDriver = driver.get();

            // Chuyển đổi từ Driver sang DriverDTO
            DriverDTO driverDTO = new DriverDTO(
                    foundDriver.getDriverId(),
                    foundDriver.getDriverName(),
                    foundDriver.getDriverPhone(),
                    foundDriver.getEmail(),
                    foundDriver.getLicenseNumber(),
                    foundDriver.getStatus()
            );

            return new ResponseEntity<>(driverDTO, HttpStatus.OK);
        } else {
            return new ResponseEntity<>(HttpStatus.NOT_FOUND);
        }
    }

    @PutMapping("/{driverId}")
    public ResponseEntity<DriverDTO> updateDriver(@PathVariable Integer driverId, @RequestBody DriverDTO driverDTO) {
        try {
            // Lấy thông tin tài xế hiện tại từ database
            Optional<Driver> existingDriver = driverService.findDriverById(driverId);

            if (existingDriver.isPresent()) {
                Driver driverToUpdate = existingDriver.get();

                // Cập nhật các trường khác (không cập nhật latitude, longitude)
                driverToUpdate.setDriverName(driverDTO.getDriverName());
                driverToUpdate.setDriverPhone(driverDTO.getDriverPhone());
                driverToUpdate.setEmail(driverDTO.getEmail());
                driverToUpdate.setPassword(driverDTO.getPassword());
                driverToUpdate.setLicenseNumber(driverDTO.getLicenseNumber());
                driverToUpdate.setStatus(driverDTO.getStatus());

                // Lưu lại thông tin đã cập nhật
                Driver updatedDriver = driverService.saveDriver(driverToUpdate);

                // Chuyển đổi từ Driver entity sang DTO
                DriverDTO updatedDriverDTO = convertToDTO(updatedDriver);

                // Trả về thông tin tài xế đã cập nhật
                return ResponseEntity.ok(updatedDriverDTO);
            } else {
                return new ResponseEntity<>(HttpStatus.NOT_FOUND);
            }
        } catch (Exception e) {
            return new ResponseEntity<>(HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
    // Cập nhật trạng thái tài xế


}
