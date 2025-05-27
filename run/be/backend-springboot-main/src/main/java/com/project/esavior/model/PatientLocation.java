package com.project.esavior.model;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "patientlocation")  // Đặt tên bảng là patient_locations
public class PatientLocation {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id")  // Tên cột là id
    private Integer id;

    @Column(name = "patient_id", nullable = false)  // Tên cột là patient_id
    private Integer patientId;

    @Column(name = "latitude", nullable = false)  // Tên cột là latitude
    private Double latitude;

    @Column(name = "longitude", nullable = false)  // Tên cột là longitude
    private Double longitude;

    @Column(name = "destination_latitude")  // Tên cột là destination_latitude
    private Double destinationLatitude;

    @Column(name = "destination_longitude")  // Tên cột là destination_longitude
    private Double destinationLongitude;

    @Column(name = "booking_status")  // Tên cột là booking_status
    private String bookingStatus;

    @Column(name = "created_at")  // Tên cột là created_at
    private LocalDateTime createdAt;

    @Column(name = "updated_at")  // Tên cột là updated_at
    private LocalDateTime updatedAt;

    public PatientLocation() {
    }

    // Getters và Setters
    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }

    public Integer getPatientId() {
        return patientId;
    }

    public void setPatientId(Integer patientId) {
        this.patientId = patientId;
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

    public String getBookingStatus() {
        return bookingStatus;
    }

    public void setBookingStatus(String bookingStatus) {
        this.bookingStatus = bookingStatus;
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
        return "PatientLocation{" +
                "id=" + id +
                ", patientId=" + patientId +
                ", latitude=" + latitude +
                ", longitude=" + longitude +
                ", destinationLatitude=" + destinationLatitude +
                ", destinationLongitude=" + destinationLongitude +
                ", bookingStatus='" + bookingStatus + '\'' +
                ", createdAt=" + createdAt +
                ", updatedAt=" + updatedAt +
                '}';
    }
}
