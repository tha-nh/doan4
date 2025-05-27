package springboot.springboot.database.entity;

import java.util.List;

public class Staffs extends Entity<Integer> {
    private Integer staff_id;
    private String staff_name;
    private Integer staff_phone;
    private String staff_address;
    private String staff_type;
    private String staff_status;
    private String staff_username;
    private String staff_password;
    private String staff_email;
    private List<Appointments> appointmentsList;
    public Staffs() {}

    public Integer getStaff_id() {
        return staff_id;
    }

    public void setStaff_id(Integer staff_id) {
        this.staff_id = staff_id;
    }

    public String getStaff_email() {
        return staff_email;
    }

    public void setStaff_email(String staff_email) {
        this.staff_email = staff_email;
    }

    public String getStaff_name() {
        return staff_name;
    }

    public void setStaff_name(String staff_name) {
        this.staff_name = staff_name;
    }

    public Integer getStaff_phone() {
        return staff_phone;
    }

    public void setStaff_phone(Integer staff_phone) {
        this.staff_phone = staff_phone;
    }

    public String getStaff_address() {
        return staff_address;
    }

    public void setStaff_address(String staff_address) {
        this.staff_address = staff_address;
    }

    public String getStaff_type() {
        return staff_type;
    }

    public void setStaff_type(String staff_type) {
        this.staff_type = staff_type;
    }

    public String getStaff_status() {
        return staff_status;
    }

    public void setStaff_status(String staff_status) {
        this.staff_status = staff_status;
    }

    public String getStaff_username() {
        return staff_username;
    }

    public void setStaff_username(String staff_username) {
        this.staff_username = staff_username;
    }

    public String getStaff_password() {
        return staff_password;
    }

    public void setStaff_password(String staff_password) {
        this.staff_password = staff_password;
    }

    public List<Appointments> getAppointmentsList() {
        return appointmentsList;
    }

    public void setAppointmentsList(List<Appointments> appointmentsList) {
        this.appointmentsList = appointmentsList;
    }
}
