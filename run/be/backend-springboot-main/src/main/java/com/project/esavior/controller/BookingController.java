package com.project.esavior.controller;

import com.project.esavior.dto.BookingDTO;
import com.project.esavior.model.*;
import com.project.esavior.service.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/bookings")
public class BookingController {

    private final DriverService driverService;

    private final BookingService bookingService;
    private final PatientsService patientsService;
    private final PatientLocationService patientLocationService;
    private final PatientsService patientService;

    @Autowired
    public BookingController(BookingService bookingService, PatientsService patientsService, DriverService driverService, PatientLocationService patientLocationService, PatientsService patientService) {
        this.bookingService = bookingService;
        this.patientsService = patientsService;
        this.driverService = driverService;
        this.patientLocationService = patientLocationService;
        this.patientService = patientService;
    }


    @PostMapping("/emergency")
    public ResponseEntity<BookingDTO> createEmergencyBooking(@RequestBody Booking bookingRequest) {
        // Debug: In ra JSON request để kiểm tra
        System.out.println("Booking Request: " + bookingRequest);
        System.out.println(bookingRequest.getPatient().getEmail());

        // Kiểm tra xem thông tin bệnh nhân có tồn tại không
        if (bookingRequest.getPatient() == null || bookingRequest.getPatient().getEmail() == null) {
            return new ResponseEntity<>(HttpStatus.BAD_REQUEST); // Yêu cầu không hợp lệ
        }

        // Tìm bệnh nhân theo email
        Optional<Patients> patientOpt = patientsService.findByEmail(bookingRequest.getPatient().getEmail());
        if (patientOpt.isEmpty()) {
            return new ResponseEntity<>(HttpStatus.NOT_FOUND); // Không tìm thấy bệnh nhân
        }

        // Tạo mới booking
        Booking newBooking = new Booking();
        newBooking.setPatient(patientOpt.get());
        newBooking.setBookingType("Emergency");
        newBooking.setPickupAddress(bookingRequest.getPickupAddress());
        newBooking.setPickupTime(LocalDateTime.now());
        newBooking.setBookingStatus("Pending");
        newBooking.setLongitude(bookingRequest.getLongitude());
        newBooking.setLatitude(bookingRequest.getLatitude());
        newBooking.setDestinationLatitude(bookingRequest.getDestinationLatitude());
        newBooking.setDestinationLongitude(bookingRequest.getDestinationLongitude());
        newBooking.setCost(bookingRequest.getCost());
        newBooking.setAmbulanceType(bookingRequest.getAmbulanceType());


        // Lưu thông tin đặt chỗ mới vào cơ sở dữ liệu thông qua BookingService
        Booking savedBooking = bookingService.createBooking(newBooking);

        // Cập nhật vị trí vào bảng PatientLocation (trong cơ sở dữ liệu)
        PatientLocation patientLocation = new PatientLocation();
        patientLocation.setPatientId(patientOpt.get().getPatientId());
        patientLocation.setLatitude(bookingRequest.getLatitude());
        patientLocation.setLongitude(bookingRequest.getLongitude());
        patientLocation.setDestinationLatitude(bookingRequest.getDestinationLatitude());
        patientLocation.setDestinationLongitude(bookingRequest.getDestinationLongitude());
        patientLocation.setCreatedAt(LocalDateTime.now());
        patientLocation.setUpdatedAt(LocalDateTime.now());

        // Lưu thông tin vị trí của bệnh nhân
        patientLocationService.savePatientLocation(patientLocation);

        // Chuyển đổi Booking thành BookingDTO
        BookingDTO bookingDTO = convertToDTO(savedBooking);

        // Đảm bảo bookingId được set trong BookingDTO
        bookingDTO.setBookingId(savedBooking.getBookingId());

        // Trả về bookingDTO đã lưu kèm theo ID
        return new ResponseEntity<>(bookingDTO, HttpStatus.CREATED);
    }


    @PostMapping("/update-status")
    public ResponseEntity<String> updateBookingStatus(@RequestBody Booking request) {

        System.out.println(request.getBookingId() + " " + request.getBookingStatus());

        boolean isUpdated = bookingService.updateBookingStatus(request.getBookingId(), request.getBookingStatus());

        if (isUpdated) {
            return ResponseEntity.ok("Booking status updated successfully.");
        } else {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("An error occurred while updating booking status.");
        }
    }


    @PostMapping("/non-emergency")
    public ResponseEntity<BookingDTO> createNonEmergencyBooking(@RequestBody Booking bookingRequest) {
        if (bookingRequest.getPatient() == null || bookingRequest.getPatient().getEmail() == null) {
            return new ResponseEntity<>(HttpStatus.BAD_REQUEST); // Yêu cầu không hợp lệ
        }

        Optional<Patients> patientOpt = patientsService.findByEmail(bookingRequest.getPatient().getEmail());
        if (patientOpt.isEmpty()) {
            return new ResponseEntity<>(HttpStatus.NOT_FOUND);
        }

        Booking newBooking = new Booking();
        newBooking.setPatient(patientOpt.get());
        newBooking.setPickupAddress(bookingRequest.getPickupAddress());
        newBooking.setPickupTime(bookingRequest.getPickupTime());
        newBooking.setBookingStatus("Pending");
        newBooking.setLatitude(bookingRequest.getLatitude());
        newBooking.setLongitude(bookingRequest.getLongitude());
        newBooking.setDestinationLatitude(bookingRequest.getDestinationLatitude());
        newBooking.setDestinationLongitude(bookingRequest.getDestinationLongitude());
        newBooking.setCost(bookingRequest.getCost());
        newBooking.setBookingType(bookingRequest.getBookingType());

        Booking savedBooking = bookingService.createBooking(newBooking);

        return new ResponseEntity<>(HttpStatus.CREATED);
    }

    // Tạo đặt chỗ mới
    @PostMapping
    public ResponseEntity<Booking> createBooking(@RequestBody Booking booking) {
        Booking newBooking = bookingService.createBooking(booking);
        return new ResponseEntity<>(HttpStatus.CREATED);
    }

    // API để lấy đơn hàng chưa hoàn thành của tài xế
    @GetMapping("/unfinished/{driverId}")
    public ResponseEntity<BookingDTO> getUnfinishedBookingByDriverId(@PathVariable Integer driverId) {
        Optional<Booking> unfinishedBooking = bookingService.getUnfinishedBookingByDriverId(driverId);
        System.out.println(unfinishedBooking.toString());
        if (unfinishedBooking.isPresent()) {
            Booking booking = unfinishedBooking.get();
            // Lấy thông tin bệnh nhân từ patientId
            Optional<Patients> patient = patientService.findById(booking.getPatient().getPatientId());

            BookingDTO bookingDTO = new BookingDTO(unfinishedBooking.get().getBookingId(),unfinishedBooking.get().getPatient().getPatientId(), patient.get().getPatientName(), patient.get().getPhoneNumber(),
                    unfinishedBooking.get().getLatitude(), unfinishedBooking.get().getDestinationLongitude(), unfinishedBooking.get().getDestinationLatitude()
                    , unfinishedBooking.get().getLongitude());

            System.out.println("============================"+bookingDTO.toString() + "================== phan tu tra vè");
            return ResponseEntity.ok(bookingDTO);
        } else {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(null);
        }
    }

    // Lấy danh sách đặt chỗ
    @GetMapping
    public ResponseEntity<List<BookingDTO>> getAllBookings() {
        List<BookingDTO> bookings = bookingService.getAllBookings().stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
        return ResponseEntity.ok(bookings);
    }

    // Tìm kiếm chi tiết đặt chỗ theo tên bệnh viện
    @GetMapping("/hospital")
    public List<BookingDTO> getBookingsByHospitalName(@RequestParam String hospitalName) {
        return bookingService.findByHospitalName(hospitalName).stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }

    // Tìm kiếm chi tiết đặt chỗ theo thành phố
    @GetMapping("/city")
    public List<BookingDTO> getBookingsByCityName(@RequestParam String cityName) {
        return bookingService.findByCityName(cityName).stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }

    // Tìm kiếm theo tên bệnh viện và thành phố
    @GetMapping("/search")
    public List<BookingDTO> getBookingsByHospitalAndCity(@RequestParam String hospitalName, @RequestParam String cityName) {
        return bookingService.findByHospitalNameAndCityName(hospitalName, cityName).stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }

    @GetMapping("/driverId/{driverId}")
    public List<BookingDTO> getBookingsByDriverId(@PathVariable Integer driverId) {
        List<Booking> bookings = bookingService.findBookingByDriverId(driverId);
        return bookings.stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }

    // Lấy danh sách Booking theo patientId
    @GetMapping("/patientId/{patientId}")
    public List<BookingDTO> getBookingsByPatientId(@PathVariable Integer patientId) {
        List<Booking> bookings = bookingService.findBookingByPatientId(patientId);
        return bookings.stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }

    // Tìm kiếm tất cả đặt chỗ liên quan đến một từ khóa (search)
    @GetMapping("/keyword")
    public List<BookingDTO> searchBookings(@RequestParam String keyword) {
        return bookingService.searchBookings(keyword).stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }

    // Lấy chi tiết đặt chỗ theo ID
    @GetMapping("/{id}")
    public ResponseEntity<BookingDTO> getBookingById(@PathVariable Integer id) {
        Optional<Booking> bookingOpt = bookingService.findBookingById(id);
        if (bookingOpt.isPresent()) {
            return ResponseEntity.ok(convertToDTO(bookingOpt.get()));
        }
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(null);
    }

    // Cập nhật thông tin đặt chỗ
    @PutMapping("/{id}")
    public ResponseEntity<BookingDTO> updateBooking(@PathVariable Integer id, @RequestBody Booking updatedBooking) {
        Booking booking = bookingService.updateBooking(id, updatedBooking);
        if (booking != null) {
            return ResponseEntity.ok(convertToDTO(booking));
        }
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(null);
    }

    // Xóa đặt chỗ
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteBooking(@PathVariable Integer id) {
        boolean deleted = bookingService.deleteBooking(id);
        if (deleted) {
            return ResponseEntity.status(HttpStatus.NO_CONTENT).body(null);
        }
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(null);
    }

    @PostMapping("/calculate-cost")
    public ResponseEntity<Map<String, Object>> calculateCost(@RequestBody Map<String, Object> locationData) {
        double startLatitude = (double) locationData.get("startLatitude");
        double startLongitude = (double) locationData.get("startLongitude");
        double destinationLatitude = (double) locationData.get("destinationLatitude");
        double destinationLongitude = (double) locationData.get("destinationLongitude");

        double distance = calculateDistance(startLatitude, startLongitude, destinationLatitude, destinationLongitude);
        double costPerKmUSD = 1.5;
        double costInUSD = distance * costPerKmUSD;

        Map<String, Object> response = new HashMap<>();
        response.put("distance", distance);
        response.put("costInUSD", costInUSD);

        return ResponseEntity.ok(response);
    }

    @PutMapping("/update-driver/{id}")
    public ResponseEntity<BookingDTO> updateBookingWithDriverId(@PathVariable Integer id, @RequestBody Map<String, Object> requestData) {
        Integer driverId = (Integer) requestData.get("driverId");

        // Tìm kiếm booking bằng ID
        Optional<Booking> bookingOptional = bookingService.findBookingById(id);
        if (bookingOptional.isPresent()) {
            Booking booking = bookingOptional.get();

            // Tìm kiếm driver bằng ID
            Optional<Driver> driverOptional = driverService.findDriverById(driverId);
            if (driverOptional.isPresent()) {
                Driver driver = driverOptional.get();

                // Cập nhật driver cho booking
                booking.setDriver(driver);

                // Lưu lại thông tin booking đã cập nhật
                Booking updatedBooking = bookingService.save(booking);

                // Chuyển đổi thành DTO và trả về
                return ResponseEntity.ok(convertToDTO(updatedBooking));
            } else {
                // Không tìm thấy driver
                return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
            }
        } else {
            // Không tìm thấy booking
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
    }


    private BookingDTO convertToDTO(Booking booking) {
        BookingDTO bookingDTO = new BookingDTO();
        bookingDTO.setBookingId(booking.getBookingId());
        bookingDTO.setAmbulanceId(booking.getAmbulance() != null ? booking.getAmbulance().getAmbulanceId() : null);
        bookingDTO.setPatientId(booking.getPatient() != null ? booking.getPatient().getPatientId() : null);
        bookingDTO.setHospitalId(booking.getHospital() != null ? booking.getHospital().getHospitalId() : null);
        bookingDTO.setDriverId(booking.getDriver() != null ? booking.getDriver().getDriverId() : null);
        bookingDTO.setLatitude(booking.getLatitude());
        bookingDTO.setLongitude(booking.getLongitude());
        bookingDTO.setDestinationLatitude(booking.getDestinationLatitude());
        bookingDTO.setDestinationLongitude(booking.getDestinationLongitude());
        bookingDTO.setBookingType(booking.getBookingType());
        bookingDTO.setPickupAddress(booking.getPickupAddress());
        bookingDTO.setPickupTime(booking.getPickupTime());
        bookingDTO.setBookingStatus(booking.getBookingStatus());
        bookingDTO.setCreatedAt(booking.getCreatedAt());
        bookingDTO.setUpdatedAt(booking.getUpdatedAt());
        bookingDTO.setCost(booking.getCost());
        bookingDTO.setZipCode(booking.getZipCode());
        return bookingDTO;
    }


    private double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
        final int R = 6371;
        double latDistance = Math.toRadians(lat2 - lat1);
        double lonDistance = Math.toRadians(lon2 - lon1);
        double a = Math.sin(latDistance / 2) * Math.sin(latDistance / 2)
                + Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2))
                * Math.sin(lonDistance / 2) * Math.sin(lonDistance / 2);
        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        return R * c;
    }
}
