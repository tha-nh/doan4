package springboot.springboot.database.controller;

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
import java.util.*;

@RestController
@RequestMapping("/api/v1/doctors")
public class DoctorsController<T extends Entity<?>> {

    @Autowired
    private ModelBuid model;
    private EntityToJSON json = new EntityToJSON();

    @PostMapping("/insert")
    public void insert(@RequestBody Map<String, Object> requestData) throws SQLException, IllegalAccessException, InstantiationException {
        ModelMapper modelMapper = new ModelMapper();
        modelMapper.addConverter(new StringToDateConverter());
        Doctors doctors = modelMapper.map(requestData, Doctors.class);
        model.insert(doctors);
    }

    @PutMapping("/update")
    public void update(@RequestBody Map<String, Object> requestData) throws SQLException, IllegalAccessException {
        ModelMapper modelMapper = new ModelMapper();
        modelMapper.addConverter(new StringToDateConverter());
        Doctors doctors = modelMapper.map(requestData, Doctors.class);
        doctors.setAppointmentsList(null);
        doctors.setMedicalrecordsList(null);
        model.update(doctors);
    }

    @DeleteMapping("/delete")
    public String delete(@RequestBody Map<String, Object> requestData) throws SQLException, IllegalAccessException {
        ModelMapper modelMapper = new ModelMapper();
        modelMapper.addConverter(new StringToDateConverter());
        Doctors doctors = modelMapper.map(requestData, Doctors.class);
        model.delete(doctors);
        return "success";
    }

    @GetMapping("/list")
    public List<T> list() throws SQLException, InvocationTargetException, NoSuchMethodException, InstantiationException, IllegalAccessException {
        return model.getAll(new Doctors().getClass());
    }

    @GetMapping("/search")
    public List<Doctors> getByField(@RequestParam Map<String, String> requestParams) {
        try {
            List<Doctors> doctorsList = new ArrayList<>();
            ModelMapper modelMapper = new ModelMapper();
            modelMapper.addConverter(new StringToDateConverter());

            Doctors doctors1 = modelMapper.map(requestParams, Doctors.class);
            List<Doctors> doctors = model.getEntityById(doctors1);

            for (Doctors doctor : doctors) {
                Doctors newDoctor = new Doctors();
                BeanUtils.copyProperties(doctor, newDoctor);
                Medicalrecords medicalrecordsFilter = new Medicalrecords();
                medicalrecordsFilter.setDoctor_id(doctor.getDoctor_id());
                List<Medicalrecords> medicalrecordsList = model.getEntityById(medicalrecordsFilter);
                List<Medicalrecords> medicalrecords = medicalrecords(medicalrecordsList);

                Appointments appointmentsFilter = new Appointments();
                appointmentsFilter.setDoctor_id(doctor.getDoctor_id());
                List<Appointments> appointmentsList = model.getEntityById(appointmentsFilter);
                List<Appointments> appointments = listAppointments(appointmentsList);

                Departments departmentsFilter = new Departments();
                departmentsFilter.setDepartment_id(doctor.getDepartment_id());
                newDoctor.setDepartment(model.getEntityById(departmentsFilter));

                newDoctor.setMedicalrecordsList(medicalrecords);
                newDoctor.setAppointmentsList(appointments);
                doctorsList.add(newDoctor);
            }


            return doctorsList;
        } catch (Exception e) {
            // Log the exception and return an appropriate error response
            e.printStackTrace();
            return new ArrayList<>(); // or return a custom error response
        }
    }

    @PostMapping("/insertAll")
    public void insertAll(@RequestBody List<Map<String, Object>> dataList) throws SQLException, IllegalAccessException, InstantiationException {
        List<Doctors> doctorsList = new ArrayList<>();
        ModelMapper modelMapper = new ModelMapper();
        modelMapper.addConverter(new StringToDateConverter());
        for (Map<String, Object> data : dataList) {
            Doctors doctors = modelMapper.map(data, Doctors.class);
            doctorsList.add(doctors);
        }
        model.insertAll(doctorsList);
    }

    @GetMapping("/{doctorId}/appointments")
    public ResponseEntity<List<Appointments>> getAppointmentsByDoctorId(@PathVariable int doctorId) throws SQLException, IllegalAccessException, InstantiationException {
        Appointments appointmentsFilter = new Appointments();
        appointmentsFilter.setDoctor_id(doctorId);
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
    @GetMapping("/{doctorId}/medicalrecords")
    public ResponseEntity<List<Medicalrecords>> getMedicalByDoctorId(@PathVariable int doctorId) throws SQLException, IllegalAccessException, InstantiationException {
        Medicalrecords medicalrecords = new Medicalrecords();
        medicalrecords.setDoctor_id(doctorId);
        List<Medicalrecords> medicalrecordsList = model.getEntityById(medicalrecords);
        return ResponseEntity.ok(medicalrecords(medicalrecordsList));
    }
    public List<Medicalrecords> medicalrecords(List<Medicalrecords> medicalrecordsList) throws SQLException, IllegalAccessException, InstantiationException {
        List<Medicalrecords> medicalrecords = new ArrayList<>();
        for (Medicalrecords medicalrecord : medicalrecordsList) {
            Medicalrecords newMedicalrecord = new Medicalrecords();
            BeanUtils.copyProperties(medicalrecord, newMedicalrecord);
            if (medicalrecord.getDoctor_id() != null) {
                Doctors doctorsFilter = new Doctors();
                doctorsFilter.setDoctor_id(medicalrecord.getDoctor_id());
                newMedicalrecord.setDoctors(model.getEntityById(doctorsFilter));
            }
            medicalrecords.add(newMedicalrecord);
        }
        return medicalrecords;
    }
    @PostMapping("/login")
    public ResponseEntity<Map<String, Object>> doctorLogin(@RequestBody Map<String, String> requestData) throws SQLException, IllegalAccessException, InstantiationException {
        String username = requestData.get("username");
        String password = requestData.get("password");

        Doctors doctorFilter = new Doctors();
        doctorFilter.setDoctor_username(username);
        doctorFilter.setDoctor_password(password);

        List<Doctors> doctors = model.getEntityById(doctorFilter);
        if (doctors.isEmpty()) {
            return ResponseEntity.status(401).body(null); // Unauthorized
        }

        Doctors doctor = doctors.get(0);

        // Prepare the response map
        Map<String, Object> response = new HashMap<>();
        response.put("doctor_id", doctor.getDoctor_id());
        response.put("doctor_name", doctor.getDoctor_name());
        response.put("doctor_description", doctor.getDoctor_description());
        response.put("department_id", doctor.getDepartment_id());
        response.put("doctor_username", doctor.getDoctor_username());
        response.put("doctor_password", doctor.getDoctor_password());
        response.put("summary", doctor.getSummary());
        // Add other fields as needed

        return ResponseEntity.ok(response);
    }
    @GetMapping("/{id}")
    public ResponseEntity<Doctors> getDoctorById(@PathVariable int id) throws SQLException, IllegalAccessException, InstantiationException {
        Doctors doctorFilter = new Doctors();
        doctorFilter.setDoctor_id(id);
        List<Doctors> doctors = model.getEntityById(doctorFilter);
        if (doctors.isEmpty()) {
            return ResponseEntity.notFound().build();
        }
        return ResponseEntity.ok(doctors.get(0));
    }
    @GetMapping("/search-new")
    public List<Doctors> searchDoctorsByKeyword(@RequestParam("keyword") String keyword) throws Exception {
        return model.searchDoctorsByKeyword(keyword);
    }

}
