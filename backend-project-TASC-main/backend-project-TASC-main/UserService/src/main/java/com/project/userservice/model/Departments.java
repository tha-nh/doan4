package com.project.userservice.model;

import jakarta.persistence.*;

import java.math.BigDecimal;
import java.util.List;

@Entity
@Table(name = "Departments")
public class Departments extends Entitys {

    @Column(name = "department_name")
    private String departmentName;

    @Column(name = "department_img")
    private String departmentImg;

    @Column(name = "department_description")
    private String departmentDescription;

    @OneToMany(mappedBy = "department", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    private List<Doctors> doctors;

    public String getDepartmentName() {
        return departmentName;
    }

    public void setDepartmentName(String departmentName) {
        this.departmentName = departmentName;
    }

    public String getDepartmentImg() {
        return departmentImg;
    }

    public void setDepartmentImg(String departmentImg) {
        this.departmentImg = departmentImg;
    }

    public String getDepartmentDescription() {
        return departmentDescription;
    }

    public void setDepartmentDescription(String departmentDescription) {
        this.departmentDescription = departmentDescription;
    }

    public List<Doctors> getDoctors() {
        return doctors;
    }

    public void setDoctors(List<Doctors> doctors) {
        this.doctors = doctors;
    }
}
