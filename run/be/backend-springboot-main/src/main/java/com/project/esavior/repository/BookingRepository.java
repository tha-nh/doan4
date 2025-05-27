package com.project.esavior.repository;

import com.project.esavior.model.Booking;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface BookingRepository extends JpaRepository<Booking, Integer> {
    // Tìm kiếm chi tiết đặt chỗ theo tên bệnh viện
    List<Booking> findByHospital_HospitalName(String hospitalName);
    List<Booking> findByDriver_DriverIdAndBookingStatus(Integer driverId, String bookingStatus);

    List<Booking> findByDriver_DriverId(Integer driverId);

    // Tìm danh sách Booking theo patientId
    List<Booking> findByPatient_PatientId(Integer patientId);

    Optional<Booking> findTopByDriverDriverIdOrderByBookingIdDesc(Integer driverId);

    Booking findBookingByBookingId(Integer bookingId);

    // Tìm kiếm chi tiết đặt chỗ theo thành phố
    List<Booking> findByHospital_City_CityName(String cityName);

    // Tìm kiếm theo tên bệnh viện và thành phố
    List<Booking> findByHospital_HospitalNameAndHospital_City_CityName(String hospitalName, String cityName);

    // Tìm kiếm tất cả đặt chỗ liên quan đến một từ khóa (search)
    List<Booking> findByHospital_HospitalNameContainingOrHospital_City_CityNameContaining(String hospitalKeyword, String cityKeyword);

    Optional<Booking> findFirstByDriver_DriverIdAndBookingStatus(Integer driverId, String bookingStatus);

}
