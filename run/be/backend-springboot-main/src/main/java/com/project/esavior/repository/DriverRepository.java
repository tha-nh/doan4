package com.project.esavior.repository;

import com.project.esavior.model.Driver;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface DriverRepository extends JpaRepository<Driver, Integer> {
    Driver findByEmail(String email);
    @Query("SELECT d FROM Driver d WHERE d.latitude BETWEEN ?1 AND ?2 AND d.longitude BETWEEN ?3 AND ?4")
    List<Driver> findDriversInRange(double minLatitude, double maxLatitude, double minLongitude, double maxLongitude);
    Driver findById(int id);

}
