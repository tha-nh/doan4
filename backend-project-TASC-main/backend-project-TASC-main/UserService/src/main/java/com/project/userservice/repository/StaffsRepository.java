package com.project.userservice.repository;

import com.project.userservice.model.Staffs;
import org.springframework.data.jpa.repository.JpaRepository;

public interface StaffsRepository extends JpaRepository<Staffs, Integer> {
    Staffs findByStaffEmail(String email);
}
