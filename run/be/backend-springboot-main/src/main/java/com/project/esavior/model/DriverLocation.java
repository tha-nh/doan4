package com.project.esavior.model;

import jakarta.persistence.*;

@Entity
@Table(name = "driverlocation")  // Tên bảng là driverlocation
public class DriverLocation {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)  // Tự động tăng id
    @Column(name = "id")  // Khóa chính mới
    private Integer id;

    @Column(name = "driver_id", nullable = false)  // Tên cột là driver_id
    private Integer driverId;

    @Column(name = "latitude", nullable = false)  // Tên cột là latitude
    private Double latitude;

    @Column(name = "longitude", nullable = false)  // Tên cột là longitude
    private Double longitude;

    // Constructor mặc định
    public DriverLocation() {}

    // Constructor với driverId, latitude và longitude
    public DriverLocation(Integer driverId, Double latitude, Double longitude) {
        this.driverId = driverId;
        this.latitude = latitude;
        this.longitude = longitude;
    }

    public DriverLocation(Double latitude, Double longitude) {
        this.latitude = latitude;
        this.longitude = longitude;
    }

    // Getters và Setters
    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
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

    @Override
    public String toString() {
        return "DriverLocation{" +
                "id=" + id +
                ", driverId=" + driverId +
                ", latitude=" + latitude +
                ", longitude=" + longitude +
                '}';
    }
}
