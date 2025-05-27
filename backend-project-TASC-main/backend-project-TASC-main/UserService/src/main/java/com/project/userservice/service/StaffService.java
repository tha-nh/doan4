package com.project.userservice.service;

import com.project.userservice.model.Staffs;
import org.springframework.stereotype.Service;

@Service
public interface StaffService {
    public Staffs registerStaff(Staffs staff);
}
