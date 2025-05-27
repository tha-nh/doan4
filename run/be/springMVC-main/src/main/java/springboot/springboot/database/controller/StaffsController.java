package springboot.springboot.database.controller;

import org.springframework.http.HttpStatus;
import springboot.springboot.database.entity.*;
import org.modelmapper.ModelMapper;
import org.springframework.beans.BeanUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import springboot.springboot.database.model.EntityToJSON;
import springboot.springboot.database.model.ModelBuid;

import java.lang.reflect.Field;
import java.lang.reflect.InvocationTargetException;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/staffs")
public class StaffsController<T extends Entity<?>> {

    @Autowired
    private ModelBuid model;
    private EntityToJSON json = new EntityToJSON();

    @PostMapping("/insert")
    public void insert(@RequestBody Map<String, Object> requestData) throws SQLException, IllegalAccessException, InstantiationException {
        ModelMapper modelMapper = new ModelMapper();
        modelMapper.addConverter(new StringToDateConverter());
        Staffs staffs = modelMapper.map(requestData, Staffs.class);
        model.insert(staffs);
    }

    @PutMapping("/update")
    public void update(@RequestBody Map<String, Object> requestData) throws SQLException, IllegalAccessException {
        ModelMapper modelMapper = new ModelMapper();
        modelMapper.addConverter(new StringToDateConverter());
        Staffs staffs = modelMapper.map(requestData, Staffs.class);
        staffs.setAppointmentsList(null);
        model.update(staffs);
    }

    @DeleteMapping("/delete")
    public String delete(@RequestBody Map<String, Object> requestData) throws SQLException, IllegalAccessException {
        ModelMapper modelMapper = new ModelMapper();
        modelMapper.addConverter(new StringToDateConverter());
        Staffs staffs = modelMapper.map(requestData, Staffs.class);
        model.delete(staffs);
        return "success";
    }

    @GetMapping("/list")
    public List<T> list() throws SQLException, InvocationTargetException, NoSuchMethodException, InstantiationException, IllegalAccessException {
        return model.getAll(new Staffs().getClass());
    }

    @GetMapping("/search")
    public List<Staffs> getByField(@RequestParam Map<String, String> requestParams) {
        try {
            List<Staffs> staffsList = new ArrayList<>();
            ModelMapper modelMapper = new ModelMapper();
            modelMapper.addConverter(new StringToDateConverter());

            Staffs staffs1 = modelMapper.map(requestParams, Staffs.class);
            List<Staffs> staffs = model.getEntityById(staffs1);

            for (Staffs staff : staffs) {
                Staffs newStaff = new Staffs();
                BeanUtils.copyProperties(staff, newStaff);

                Appointments appointmentsFilter = new Appointments();
                appointmentsFilter.setStaff_id(staff.getStaff_id());
                List<Appointments> appointmentsList = model.getEntityById(appointmentsFilter);
                List<Appointments> appointments = listAppointments(appointmentsList);

                newStaff.setAppointmentsList(appointments);
                staffsList.add(newStaff);
            }
            return staffsList;
        } catch (Exception e) {
            // Log the exception and return an appropriate error response
            e.printStackTrace();
            return new ArrayList<>(); // or return a custom error response
        }
    }

    @PostMapping("/insertAll")
    public void insertAll(@RequestBody List<Map<String, Object>> dataList) throws SQLException, IllegalAccessException, InstantiationException {
        List<Staffs> staffsList = new ArrayList<>();
        ModelMapper modelMapper = new ModelMapper();
        modelMapper.addConverter(new StringToDateConverter());
        for (Map<String, Object> data : dataList) {
            Staffs staffs = modelMapper.map(data, Staffs.class);
            staffsList.add(staffs);
        }
        model.insertAll(staffsList);
    }

    @GetMapping("/{staffId}/appointments")
    public ResponseEntity<List<Appointments>> getAppointmentsByStaffId(@PathVariable int staffId) throws SQLException, IllegalAccessException, InstantiationException {
        Appointments appointmentsFilter = new Appointments();
        appointmentsFilter.setStaff_id(staffId);
        List<Appointments> appointmentsList = model.getEntityById(appointmentsFilter);
        return ResponseEntity.ok(listAppointments(appointmentsList));
    }

    public static List<String> getChildClassFieldNames(Class<?> parentClass) {
        List<String> childFieldNames = new ArrayList<>();

        Field[] fields = parentClass.getDeclaredFields();

        for (Field field : fields) {
            Class<?> fieldClass = field.getType();
            if (fieldClass != null && !fieldClass.isPrimitive() && fieldClass != String.class && !parentClass.isAssignableFrom(fieldClass) && fieldClass != Date.class) {
                childFieldNames.add(field.getName());
            }
        }
        return childFieldNames;
    }

    public List<Appointments> listAppointments(List<Appointments> appointmentsList) throws SQLException, InstantiationException, IllegalAccessException {
        List<Appointments> appointments = new ArrayList<>();
        for (Appointments appointment : appointmentsList) {
            Appointments newAppointment = new Appointments();
            BeanUtils.copyProperties(appointment, newAppointment);
            if (appointment.getDoctor_id() != null) {
                Doctors doctorsFilter = new Doctors();
                doctorsFilter.setDoctor_id(appointment.getDoctor_id());
                List<Doctors> doctorsList = model.getEntityById(doctorsFilter);
                List<Doctors> doctors = listDoctors(doctorsList);
                newAppointment.setDoctor(doctors);
            }
            if (appointment.getStaff_id() != null) {
                Staffs staffsFilter = new Staffs();
                staffsFilter.setStaff_id(appointment.getStaff_id());
                newAppointment.setStaff(model.getEntityById(staffsFilter));
            }
            appointments.add(newAppointment);
        }
        return appointments;
    }

    public List<Doctors> listDoctors(List<Doctors> doctorsList) throws SQLException, InstantiationException, IllegalAccessException {
        List<Doctors> doctors = new ArrayList<>();
        for (Doctors doctor : doctorsList) {
            Doctors newDoctor = new Doctors();
            BeanUtils.copyProperties(doctor, newDoctor);
            if (doctor.getDepartment_id() != null) {
                Departments departmentsFilter = new Departments();
                departmentsFilter.setDepartment_id(doctor.getDepartment_id());
                newDoctor.setDepartment(model.getEntityById(departmentsFilter));
            }
            doctors.add(newDoctor);
        }
        return doctors;
    }

    @PostMapping("/login")
    public ResponseEntity<Staffs> login(@RequestBody Map<String, Object> requestData) throws SQLException, IllegalAccessException, InstantiationException {
        String username = (String) requestData.get("username");
        String password = (String) requestData.get("password");

        Staffs staffFilter = new Staffs();
        staffFilter.setStaff_username(username); // Giả sử Staffs có thuộc tính username
        staffFilter.setStaff_password(password); // Giả sử Staffs có thuộc tính password

        List<Staffs> staffs = model.getEntityById(staffFilter);
        if (staffs.isEmpty()) {
            return ResponseEntity.status(401).body(null); // Unauthorized
        }

        Staffs staff = staffs.get(0);
        if ("admin".equals(staff.getStaff_type())) {
            return ResponseEntity.ok(staff);
        } else {
            return ResponseEntity.status(403).body(null); // Forbidden
        }
    }
    @PostMapping("/loginStaff")
    public ResponseEntity<Staffs> loginStaff(@RequestBody Map<String, Object> requestData) throws SQLException, IllegalAccessException, InstantiationException {
        String username = (String) requestData.get("username");
        String password = (String) requestData.get("password");

        Staffs staffFilter = new Staffs();
        staffFilter.setStaff_username(username); // Giả sử Staffs có thuộc tính username
        staffFilter.setStaff_password(password); // Giả sử Staffs có thuộc tính password

        List<Staffs> staffs = model.getEntityById(staffFilter);
        if (staffs.isEmpty()) {
            return ResponseEntity.status(401).body(null); // Unauthorized
        }

        Staffs staff = staffs.get(0);
        if ("staff".equals(staff.getStaff_type())) {
            return ResponseEntity.ok(staff);
        } else {
            return ResponseEntity.status(403).body(null); // Forbidden
        }
    }

    @GetMapping("/search-new")
    public List<Staffs> searchStaffsByKeyword(@RequestParam("keyword") String keyword) throws Exception {
        return model.searchStaffsByKeyword(keyword);
    }
    @GetMapping("/{staffId}")
    public ResponseEntity<Staffs> getStaffById(@PathVariable("staffId") int staffId) {
        try {
            Staffs staffFilter = new Staffs();
            staffFilter.setStaff_id(staffId);
            List<Staffs> staffs = model.getEntityById(staffFilter);
            if (staffs.isEmpty()) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).body(null);
            }
            return ResponseEntity.ok(staffs.get(0));
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(null);
        }
    }

}
