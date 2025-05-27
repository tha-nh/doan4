package com.project.esavior.model;
import java.util.List;  // Import List
import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "drivers")
public class Driver {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "driver_id")
    private Integer driverId;

    @Column(name = "driver_name", nullable = false)
    private String driverName;

    @Column(name = "email", unique = true) // Thêm trường email
    private String email;

    @Column(name = "password")
    private String password;

    @OneToMany(mappedBy = "driver", cascade = CascadeType.ALL)
    private List<Booking> bookings;

    @Column(name = "driver_phone", nullable = false, unique = true)
    private String driverPhone;

    @Column(name = "license_number", nullable = false, unique = true)
    private String licenseNumber;

    @OneToOne(mappedBy = "driver")
    private Ambulance ambulance;

    @Column(name = "status")
    private String status;

    @Column(name = "latitude")
    private Double latitude; // Thêm trường này

    @Column(name = "longitude")
    private Double longitude;

    @Column(name = "driver_created_at")
    private LocalDateTime createdAt;

    @Column(name = "driver_updated_at")
    private LocalDateTime updatedAt;

    @ManyToOne
    @JoinColumn(name = "hospital_id")
    private Hospital hospital;
    // Constructors, Getters và Setters
    public Driver() {}

    // Getters and Setters for each field

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

    public String getEmail() {
        return email;
    }

    public Hospital getHospital() {
        return hospital;
    }

    public void setHospital(Hospital hospital) {
        this.hospital = hospital;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getPassword() {
        return password;
    }

    public void setPassword(String password) {
        this.password = password;
    }



    public Integer getDriverId() {
        return driverId;
    }

    public void setDriverId(Integer driverId) {
        this.driverId = driverId;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public String getDriverName() {
        return driverName;
    }

    public void setDriverName(String driverName) {
        this.driverName = driverName;
    }

    public String getDriverPhone() {
        return driverPhone;
    }

    public void setDriverPhone(String driverPhone) {
        this.driverPhone = driverPhone;
    }

    public String getLicenseNumber() {
        return licenseNumber;
    }

    public void setLicenseNumber(String licenseNumber) {
        this.licenseNumber = licenseNumber;
    }

    public Ambulance getAmbulance() {
        return ambulance;
    }

    public void setAmbulance(Ambulance ambulance) {
        this.ambulance = ambulance;
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
        return "Driver{" +
                "driverId=" + driverId +
                ", driverName='" + driverName + '\'' +
                ", email='" + email + '\'' +
                ", password='" + password + '\'' +
                ", driverPhone='" + driverPhone + '\'' +
                ", licenseNumber='" + licenseNumber + '\'' +
                ", ambulance=" + ambulance +
                ", status='" + status + '\'' +
                ", latitude=" + latitude +
                ", longitude=" + longitude +
                ", createdAt=" + createdAt +
                ", updatedAt=" + updatedAt +
                ", hospital=" + hospital +
                '}';
    }
}
