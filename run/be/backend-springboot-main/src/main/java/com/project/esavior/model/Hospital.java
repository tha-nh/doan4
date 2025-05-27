package com.project.esavior.model;

import com.fasterxml.jackson.annotation.JsonBackReference;
import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonManagedReference;
import jakarta.persistence.*;
import java.time.LocalDateTime;
import java.util.List;

@Entity
@Table(name = "hospitals")
public class Hospital {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "hospital_id")
    private Integer hospitalId;

    @Column(name = "hospital_name", nullable = false)
    private String hospitalName;

    @Column(name = "address")
    private String address;

    @ManyToOne
    @JoinColumn(name = "city_id")
    private City city;

    @Column(name = "phone_number")
    private String phoneNumber;

    @OneToMany(mappedBy = "hospital")
    private List<Ambulance> ambulances;

    @OneToMany(mappedBy = "hospital")
    private List<Booking> bookings;

    @Column(name = "hospital_created_at")
    private LocalDateTime createdAt;

    @Column(name = "hospital_updated_at")
    private LocalDateTime updatedAt;

    @Column(name = "zip_code")
    private String zipCode;

    @Column(name = "latitude")
    private Double latitude; // Thêm trường này

    @Column(name = "longitude")
    private Double longitude;
    // Constructors, Getters và Setters
    public Hospital() {}

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
// Getters and Setters for each field

    public Integer getHospitalId() {
        return hospitalId;
    }

    public String getZipCode() {
        return zipCode;
    }

    public void setZipCode(String zipCode) {
        this.zipCode = zipCode;
    }

    public void setHospitalId(Integer hospitalId) {
        this.hospitalId = hospitalId;
    }

    public String getHospitalName() {
        return hospitalName;
    }

    public void setHospitalName(String hospitalName) {
        this.hospitalName = hospitalName;
    }

    public String getAddress() {
        return address;
    }

    public void setAddress(String address) {
        this.address = address;
    }

    public City getCity() {
        return city;
    }

    public void setCity(City city) {
        this.city = city;
    }

    public String getPhoneNumber() {
        return phoneNumber;
    }

    public void setPhoneNumber(String phoneNumber) {
        this.phoneNumber = phoneNumber;
    }

    public List<Ambulance> getAmbulances() {
        return ambulances;
    }

    public void setAmbulances(List<Ambulance> ambulances) {
        this.ambulances = ambulances;
    }

    public List<Booking> getBookings() {
        return bookings;
    }

    public void setBookings(List<Booking> bookings) {
        this.bookings = bookings;
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
        return "Hospital{" +
                "hospitalId=" + hospitalId +
                ", hospitalName='" + hospitalName + '\'' +
                ", address='" + address + '\'' +
                ", city=" + city +
                ", phoneNumber='" + phoneNumber + '\'' +
                ", ambulances=" + ambulances +
                ", bookings=" + bookings +
                ", createdAt=" + createdAt +
                ", updatedAt=" + updatedAt +
                '}';
    }
}
