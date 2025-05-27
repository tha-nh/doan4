package com.project.userservice.model;

import jakarta.persistence.*;


@Entity
@Table(name = "staffs")
public class Staffs extends Entitys{

    @Column(name = "staff_name")
    private String staffName;

    @Column(name = "staff_phone")
    private String staffPhone;

    @Column(name = "staff_address")
    private String staffAddress;

    @Column(name = "staff_type")
    private String staffType;

    @Column(name = "staff_status")
    private String staffStatus;

    @Column(name = "staff_email", unique = true)
    private String staffEmail;

    @Column(name = "staff_password")
    private String staffPassword;

    @ManyToOne
    @JoinColumn(name = "role_id", referencedColumnName = "id")
    private Role role;

    public Role getRole() {
        return role;
    }

    public void setRole(Role role) {
        this.role = role;
    }

    public Staffs() {
    }

    public String getStaffName() {
        return staffName;
    }

    public void setStaffName(String staffName) {
        this.staffName = staffName;
    }

    public String getStaffPhone() {
        return staffPhone;
    }

    public void setStaffPhone(String staffPhone) {
        this.staffPhone = staffPhone;
    }

    public String getStaffAddress() {
        return staffAddress;
    }

    public void setStaffAddress(String staffAddress) {
        this.staffAddress = staffAddress;
    }

    public String getStaffType() {
        return staffType;
    }

    public void setStaffType(String staffType) {
        this.staffType = staffType;
    }

    public String getStaffStatus() {
        return staffStatus;
    }

    public void setStaffStatus(String staffStatus) {
        this.staffStatus = staffStatus;
    }

    public String getStaffEmail() {
        return staffEmail;
    }

    public void setStaffEmail(String staffEmail) {
        this.staffEmail = staffEmail;
    }

    public String getStaffPassword() {
        return staffPassword;
    }

    public void setStaffPassword(String staffPassword) {
        this.staffPassword = staffPassword;
    }
}

