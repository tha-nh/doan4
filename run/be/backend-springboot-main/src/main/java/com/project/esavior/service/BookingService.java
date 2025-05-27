package com.project.esavior.service;

import com.project.esavior.model.Booking;
import com.project.esavior.model.Driver;
import com.project.esavior.repository.BookingRepository;
import com.project.esavior.repository.DriverRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Service
public class BookingService {

    private final BookingRepository bookingRepository;
    private final DriverRepository driverRepository; // Cần để lấy thông tin tài xế



    @Autowired
    public BookingService(BookingRepository bookingRepository, DriverRepository driverRepository) {
        this.bookingRepository = bookingRepository;
        this.driverRepository = driverRepository;
    }

    public Booking save(Booking booking) {
        return bookingRepository.save(booking);
    }
    // Tạo đặt chỗ mới
    public Booking createBooking(Booking booking) {
        return bookingRepository.save(booking);
    }
    public Optional<Booking> getUnfinishedBookingByDriverId(Integer driverId) {
        return bookingRepository.findFirstByDriver_DriverIdAndBookingStatus(driverId, "Pending");
    }

    // Lấy danh sách đặt chỗ
    public List<Booking> getAllBookings() {
        return bookingRepository.findAll();
    }

    public List<Booking> findBookingByDriverId(Integer driverId) {
        return bookingRepository.findByDriver_DriverId(driverId);
    }
    public Optional<Booking> getBookingForDriver(Integer driverId) {
        // Lấy booking mới nhất cho tài xế với driverId
        return bookingRepository.findTopByDriverDriverIdOrderByBookingIdDesc(driverId);
    }
    // Tìm Booking theo patientId
    public List<Booking> findBookingByPatientId(Integer patientId) {
        return bookingRepository.findByPatient_PatientId(patientId);
    }
    // Tìm kiếm chi tiết đặt chỗ theo tên bệnh viện
    public List<Booking> findByHospitalName(String hospitalName) {
        return bookingRepository.findByHospital_HospitalName(hospitalName);
    }

    // Tìm kiếm chi tiết đặt chỗ theo thành phố
    public List<Booking> findByCityName(String cityName) {
        return bookingRepository.findByHospital_City_CityName(cityName);
    }

    // Tìm kiếm theo tên bệnh viện và thành phố
    public List<Booking> findByHospitalNameAndCityName(String hospitalName, String cityName) {
        return bookingRepository.findByHospital_HospitalNameAndHospital_City_CityName(hospitalName, cityName);
    }

    // Tìm kiếm tất cả đặt chỗ liên quan đến một từ khóa (search)
    public List<Booking> searchBookings(String keyword) {
        return bookingRepository.findByHospital_HospitalNameContainingOrHospital_City_CityNameContaining(keyword, keyword);
    }

    // Lấy chi tiết đặt chỗ theo ID
    public Booking getBookingById(Integer bookingId) {
        Optional<Booking> booking = bookingRepository.findById(bookingId);
        return booking.orElse(null);
    }

    // Cập nhật thông tin đặt chỗ
    public Booking updateBooking(Integer id, Booking updatedBooking) {
        return bookingRepository.findById(id).map(booking -> {
            booking.setAmbulance(updatedBooking.getAmbulance());
            booking.setPatient(updatedBooking.getPatient());
            booking.setHospital(updatedBooking.getHospital());
            booking.setBookingType(updatedBooking.getBookingType());
            booking.setPickupAddress(updatedBooking.getPickupAddress());
            booking.setDriver(updatedBooking.getDriver());
            booking.setPickupTime(updatedBooking.getPickupTime());
            booking.setBookingStatus(updatedBooking.getBookingStatus());    
            return bookingRepository.save(booking);
        }).orElse(null);
    }

    // Xóa đặt chỗ
    public boolean deleteBooking(Integer id) {
        if (bookingRepository.existsById(id)) {
            bookingRepository.deleteById(id);
            return true;
        }
        return false;
    }
    public Optional<Booking> findBookingById(Integer bookingId) {
        return bookingRepository.findById(bookingId);
    }

    public void updateBookingWithDriver(Integer bookingId, Integer driverId) {
        // Tìm kiếm đơn đặt xe theo bookingId
        Booking booking = bookingRepository.findById(bookingId)
                .orElseThrow(() -> new IllegalArgumentException("Booking not found with id: " + bookingId));

        // Tìm kiếm tài xế theo driverId
        Driver driver = driverRepository.findById(driverId)
                .orElseThrow(() -> new IllegalArgumentException("Driver not found with id: " + driverId));

        // Cập nhật driver và các thông tin cần thiết khác vào đơn đặt xe
        booking.setDriver(driver);

        // Lưu lại thông tin đặt chỗ đã cập nhật
        bookingRepository.save(booking);
    }

    public List<Booking> getPendingBookingsByDriverId(Integer driverId) {
        return bookingRepository.findByDriver_DriverIdAndBookingStatus(driverId, "Pending");
    }
    public boolean updateBookingStatus(Integer bookingId, String status) {
        Optional<Booking> optionalBooking = bookingRepository.findById(bookingId);
        if (optionalBooking.isPresent()) {
            Booking booking = optionalBooking.get();
            booking.setBookingStatus(status);  // Cập nhật trạng thái mới
            booking.setUpdatedAt(LocalDateTime.now());  // Cập nhật thời gian cập nhật
            bookingRepository.save(booking);  // Lưu thay đổi vào cơ sở dữ liệu
            return true;
        } else {
            return false;
        }
    }

}
