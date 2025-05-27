package com.project.userservice.dto;

public class DepartmentDTO {

    private Integer id;
    private String departmentName;
    private String departmentImg;
    private String departmentDescription;


    public Integer getId() {
        return id;
    }

    public DepartmentDTO(Integer id, String departmentName, String departmentImg, String departmentDescription) {
        this.id = id;
        this.departmentName = departmentName;
        this.departmentImg = departmentImg;
        this.departmentDescription = departmentDescription;
    }

    public void setId(Integer id) {
        this.id = id;
    }

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
}
