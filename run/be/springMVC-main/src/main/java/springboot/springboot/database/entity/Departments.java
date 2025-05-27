package springboot.springboot.database.entity;

import java.util.List;

public class Departments extends Entity<Integer> {
    private Integer department_id;
    private String department_name;
    private String location;
    private String department_img;
    private String department_description;
    private String summary;
    private List<Doctors> doctorsList;

    public Departments() {
    }

    public String getSummary() {
        return summary;
    }

    public void setSummary(String summary) {
        this.summary = summary;
    }

    public Integer getDepartment_id() {
        return department_id;
    }

    public void setDepartment_id(Integer department_id) {
        this.department_id = department_id;
    }

    public String getDepartment_name() {
        return department_name;
    }

    public void setDepartment_name(String department_name) {
        this.department_name = department_name;
    }

    public String getLocation() {
        return location;
    }

    public void setLocation(String location) {
        this.location = location;
    }

    public List<Doctors> getDoctorsList() {
        return doctorsList;
    }

    public void setDoctorsList(List<Doctors> doctorsList) {
        this.doctorsList = doctorsList;
    }

    public String getDepartment_img() {
        return department_img;
    }

    public void setDepartment_img(String department_img) {
        this.department_img = department_img;
    }

    public String getDepartment_description() {
        return department_description;
    }

    public void setDepartment_description(String department_description) {
        this.department_description = department_description;
    }

    @Override
    public String toString() {
        return "Departments{" +
                "department_id=" + department_id +
                ", department_name='" + department_name + '\'' +
                ", location='" + location + '\'' +
                ", department_img='" + department_img + '\'' +
                ", department_description='" + department_description + '\'' +
                ", summary='" + summary + '\'' +
                ", doctorsList=" + doctorsList +
                '}';
    }
}
