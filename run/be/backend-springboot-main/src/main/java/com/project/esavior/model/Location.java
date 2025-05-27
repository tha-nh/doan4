package com.project.esavior.model;

import java.util.HashMap;
import java.util.Map;

public class Location {
    private double latitude;
    private double longitude;
    private String customerName;
    private String phoneNumber;
    private String email;
    private Integer driverId; // Lưu driverId cho tài xế
    private double destinationLatitude;  // Vĩ độ điểm đến
    private double destinationLongitude;
    public Location() {}
    private double driverLatitude;
    private double driverLongitude;


    public void updateDriverLocation(int driverId, double latitude, double longitude) {
        this.driverId = driverId;
        this.driverLatitude = latitude;
        this.driverLongitude = longitude;
    }
    public Location(double destinationLatitude, double destinationLongitude) {
        this.destinationLatitude = destinationLatitude;
        this.destinationLongitude = destinationLongitude;
    }
    public Map<String, Double> getDriverLocation(int driverId) {
        Map<String, Double> driverLocation = new HashMap<>();
        if (this.driverId.equals(driverId)) {
            driverLocation.put("latitude", driverLatitude);
            driverLocation.put("longitude", driverLongitude);
        } else {
            driverLocation.put("latitude", 0.0);  // Giá trị mặc định khi không tìm thấy
            driverLocation.put("longitude", 0.0);
        }
        return driverLocation;
    }
    public Location(String customerName, String phoneNumber, String email, double destinationLatitude, double destinationLongitude) {
        this.customerName = customerName;
        this.phoneNumber = phoneNumber;
        this.email = email;
        this.destinationLatitude = destinationLatitude;
        this.destinationLongitude = destinationLongitude;
    }

    public double getLatitude() {
        return latitude;
    }

    public void setLatitude(double latitude) {
        this.latitude = latitude;
    }

    public double getLongitude() {
        return longitude;
    }

    public void setLongitude(double longitude) {
        this.longitude = longitude;
    }

    public String getCustomerName() {
        return customerName;
    }

    public void setCustomerName(String customerName) {
        this.customerName = customerName;
    }

    public String getPhoneNumber() {
        return phoneNumber;
    }

    public void setPhoneNumber(String phoneNumber) {
        this.phoneNumber = phoneNumber;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public Integer getDriverId() {
        return driverId;
    }

    public void setDriverId(Integer driverId) {
        this.driverId = driverId;
    }

    public double getDestinationLatitude() {
        return destinationLatitude;
    }

    public double getDriverLatitude() {
        return driverLatitude;
    }

    public void setDriverLatitude(double driverLatitude) {
        this.driverLatitude = driverLatitude;
    }

    public double getDriverLongitude() {
        return driverLongitude;
    }

    public void setDriverLongitude(double driverLongitude) {
        this.driverLongitude = driverLongitude;
    }

    public void setDestinationLatitude(double destinationLatitude) {
        this.destinationLatitude = destinationLatitude;
    }

    public double getDestinationLongitude() {
        return destinationLongitude;
    }

    public void setDestinationLongitude(double destinationLongitude) {
        this.destinationLongitude = destinationLongitude;
    }
}
