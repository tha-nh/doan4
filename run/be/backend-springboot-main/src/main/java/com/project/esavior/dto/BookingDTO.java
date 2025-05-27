package com.project.esavior.dto;

import com.project.esavior.model.Booking;

import java.time.LocalDateTime;

public class BookingDTO {

    private Integer bookingId;
    private Integer ambulanceId; // ID của Ambulance
    private Integer patientId;   // ID của Patient
    private Integer hospitalId;  // ID của Hospital
    private Integer driverId;    // ID của Driver

    private Double latitude;
    private Double longitude;

    private Double destinationLatitude;
    private Double destinationLongitude;

    private String bookingType;
    private String pickupAddress;
    private LocalDateTime pickupTime;
    private String bookingStatus;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    private Double cost;
    private String ambulanceType;
    private String zipCode;
    private String patientName;   // Thêm trường này để chứa tên bệnh nhân
    private String patientPhone;
    private String patientUsername;

    public BookingDTO(Integer patientId, Double latitude, Double longitude, Double destinationLatitude, Double destinationLongitude, String bookingType, String bookingStatus, Double cost) {
        this.patientId = patientId;
        this.latitude = latitude;
        this.longitude = longitude;
        this.destinationLatitude = destinationLatitude;
        this.destinationLongitude = destinationLongitude;
        this.bookingType = bookingType;
        this.bookingStatus = bookingStatus;
        this.cost = cost;
    }
    public BookingDTO(Booking booking) {
        this.bookingId = booking.getBookingId();
        this.patientId = booking.getPatient().getPatientId();
        this.driverId = booking.getDriver().getDriverId();
        this.latitude = booking.getLatitude();
        this.longitude = booking.getLongitude();
        this.destinationLatitude = booking.getDestinationLatitude();
        this.destinationLongitude = booking.getDestinationLongitude();
        this.bookingType = booking.getBookingType();
        this.pickupAddress = booking.getPickupAddress();
        this.pickupTime = booking.getPickupTime();
        this.bookingStatus = booking.getBookingStatus();
        this.createdAt = booking.getCreatedAt();
        this.updatedAt = booking.getUpdatedAt();
        this.cost = booking.getCost();
        this.ambulanceType = booking.getAmbulanceType();
        this.zipCode = booking.getZipCode();
        this.patientName = booking.getPatient().getPatientName();  // Assuming `Patient` has these fields
        this.patientPhone = booking.getPatient().getPhoneNumber();
        this.patientUsername = booking.getPatient().getPatientUsername();
    }

    public BookingDTO(Integer bookingId,Integer patientId, String patientName, String patientPhone, Double latitude, Double longitude, Double destinationLatitude, Double destinationLongitude) {
        this.bookingId = bookingId;
        this.patientId = patientId;
        this.patientName = patientName;
        this.patientPhone = patientPhone;
        this.latitude = latitude;
        this.longitude = longitude;
        this.destinationLatitude = destinationLatitude;
        this.destinationLongitude = destinationLongitude;
    }

    public BookingDTO(Integer bookingId, Integer ambulanceId, Integer patientId, Integer hospitalId, Integer driverId, Double latitude, Double longitude, Double destinationLatitude, Double destinationLongitude, String bookingType, String pickupAddress, LocalDateTime pickupTime, String bookingStatus, LocalDateTime createdAt, LocalDateTime updatedAt, Double cost, String ambulanceType, String zipCode, String patientName, String patientPhone, String patientUsername) {
        this.bookingId = bookingId;
        this.ambulanceId = ambulanceId;
        this.patientId = patientId;
        this.hospitalId = hospitalId;
        this.driverId = driverId;
        this.latitude = latitude;
        this.longitude = longitude;
        this.destinationLatitude = destinationLatitude;
        this.destinationLongitude = destinationLongitude;
        this.bookingType = bookingType;
        this.pickupAddress = pickupAddress;
        this.pickupTime = pickupTime;
        this.bookingStatus = bookingStatus;
        this.createdAt = createdAt;
        this.updatedAt = updatedAt;
        this.cost = cost;
        this.ambulanceType = ambulanceType;
        this.zipCode = zipCode;
        this.patientName = patientName;
        this.patientPhone = patientPhone;
        this.patientUsername = patientUsername;
    }

    public String getPatientUsername() {
        return patientUsername;
    }

    public void setPatientUsername(String patientUsername) {
        this.patientUsername = patientUsername;
    }

    public BookingDTO(Double latitude, Double longitude, Double destinationLatitude, Double destinationLongitude, String pickupAddress, String patientName, String patientPhone) {
        this.latitude = latitude;
        this.longitude = longitude;
        this.destinationLatitude = destinationLatitude;
        this.destinationLongitude = destinationLongitude;
        this.pickupAddress = pickupAddress;
        this.patientName = patientName;
        this.patientPhone = patientPhone;
    }

    public String getPatientName() {
        return patientName;
    }

    public void setPatientName(String patientName) {
        this.patientName = patientName;
    }

    public String getPatientPhone() {
        return patientPhone;
    }

    public void setPatientPhone(String patientPhone) {
        this.patientPhone = patientPhone;
    }

    // Constructor không tham số
    public BookingDTO() {}

    public BookingDTO(Integer bookingId, Integer ambulanceId, Integer patientId, Integer hospitalId, Integer driverId, Double latitude, Double longitude, Double destinationLatitude, Double destinationLongitude, String bookingType, String pickupAddress, LocalDateTime pickupTime, String bookingStatus, LocalDateTime createdAt, LocalDateTime updatedAt, Double cost, String ambulanceType, String zipCode) {
        this.bookingId = bookingId;
        this.ambulanceId = ambulanceId;
        this.patientId = patientId;
        this.hospitalId = hospitalId;
        this.driverId = driverId;
        this.latitude = latitude;
        this.longitude = longitude;
        this.destinationLatitude = destinationLatitude;
        this.destinationLongitude = destinationLongitude;
        this.bookingType = bookingType;
        this.pickupAddress = pickupAddress;
        this.pickupTime = pickupTime;
        this.bookingStatus = bookingStatus;
        this.createdAt = createdAt;
        this.updatedAt = updatedAt;
        this.cost = cost;
        this.ambulanceType = ambulanceType;
        this.zipCode = zipCode;
    }

    public Integer getBookingId() {
        return bookingId;
    }

    public void setBookingId(Integer bookingId) {
        this.bookingId = bookingId;
    }

    public Integer getAmbulanceId() {
        return ambulanceId;
    }

    public void setAmbulanceId(Integer ambulanceId) {
        this.ambulanceId = ambulanceId;
    }

    public Integer getPatientId() {
        return patientId;
    }

    public void setPatientId(Integer patientId) {
        this.patientId = patientId;
    }

    public Integer getHospitalId() {
        return hospitalId;
    }

    public void setHospitalId(Integer hospitalId) {
        this.hospitalId = hospitalId;
    }

    public Integer getDriverId() {
        return driverId;
    }

    public void setDriverId(Integer driverId) {
        this.driverId = driverId;
    }

    public Double getLatitude() {
        return latitude;
    }

    public void setLatitude(Double latitude) {
        this.latitude = latitude;
    }

    public Double getLongitude() {
        return longitude;
    }

    public void setLongitude(Double longitude) {
        this.longitude = longitude;
    }

    public Double getDestinationLatitude() {
        return destinationLatitude;
    }

    public void setDestinationLatitude(Double destinationLatitude) {
        this.destinationLatitude = destinationLatitude;
    }

    public Double getDestinationLongitude() {
        return destinationLongitude;
    }

    public void setDestinationLongitude(Double destinationLongitude) {
        this.destinationLongitude = destinationLongitude;
    }

    public String getBookingType() {
        return bookingType;
    }

    public void setBookingType(String bookingType) {
        this.bookingType = bookingType;
    }

    public String getPickupAddress() {
        return pickupAddress;
    }

    public void setPickupAddress(String pickupAddress) {
        this.pickupAddress = pickupAddress;
    }

    public LocalDateTime getPickupTime() {
        return pickupTime;
    }

    public void setPickupTime(LocalDateTime pickupTime) {
        this.pickupTime = pickupTime;
    }

    public String getBookingStatus() {
        return bookingStatus;
    }

    public void setBookingStatus(String bookingStatus) {
        this.bookingStatus = bookingStatus;
    }

    public Double getCost() {
        return cost;
    }

    public void setCost(Double cost) {
        this.cost = cost;
    }

    public String getAmbulanceType() {
        return ambulanceType;
    }

    public void setAmbulanceType(String ambulanceType) {
        this.ambulanceType = ambulanceType;
    }

    public String getZipCode() {
        return zipCode;
    }

    public void setZipCode(String zipCode) {
        this.zipCode = zipCode;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public LocalDateTime getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(LocalDateTime updatedAt) {
        this.updatedAt = updatedAt;
    }

    @Override
    public String toString() {
        return "BookingDTO{" +
                "bookingId=" + bookingId +
                ", ambulanceId=" + ambulanceId +
                ", patientId=" + patientId +
                ", hospitalId=" + hospitalId +
                ", driverId=" + driverId +
                ", latitude=" + latitude +
                ", longitude=" + longitude +
                ", destinationLatitude=" + destinationLatitude +
                ", destinationLongitude=" + destinationLongitude +
                ", bookingType='" + bookingType + '\'' +
                ", pickupAddress='" + pickupAddress + '\'' +
                ", pickupTime=" + pickupTime +
                ", bookingStatus='" + bookingStatus + '\'' +
                ", createdAt=" + createdAt +
                ", updatedAt=" + updatedAt +
                ", cost=" + cost +
                ", ambulanceType='" + ambulanceType + '\'' +
                ", zipCode='" + zipCode + '\'' +
                ", patientName='" + patientName + '\'' +
                ", patientPhone='" + patientPhone + '\'' +
                ", patientUsername='" + patientUsername + '\'' +
                '}';
    }
}
