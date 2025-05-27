package com.project.userservice.service.implement;


import com.project.userservice.model.Role;
import com.project.userservice.model.Staffs;
import com.project.userservice.repository.StaffsRepository;
import com.project.userservice.service.StaffService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class StaffServiceImpl implements StaffService {

    @Autowired
    StaffsRepository staffsRepository;
    @Override
    public Staffs registerStaff(Staffs staff){
        staff.setStaffStatus("working");
        Role staffRole = new Role();
        staffRole.setId(3);
        staff.setRole(staffRole);
        return staffsRepository.save(staff);
    }
}
