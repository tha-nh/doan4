package springboot.springboot.database.controller;

import springboot.springboot.database.entity.*;
import org.modelmapper.ModelMapper;
import org.springframework.beans.BeanUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.client.RestTemplate;
import springboot.springboot.database.model.EntityToJSON;
import springboot.springboot.database.model.ModelBuid;

import java.lang.reflect.Field;
import java.lang.reflect.InvocationTargetException;
import java.sql.SQLException;
import java.util.*;

@RestController
@RequestMapping("/api/v1/patients")
public class PatientsController<T extends Entity<?>> {

    @Autowired
    private ModelBuid model;
    private EntityToJSON json = new EntityToJSON();

    @GetMapping("/")
    public String showForm() {
        return "index";
    }

    @PostMapping("/insert")
    public void insert(@RequestBody Map<String, Object> requestData) throws SQLException, IllegalAccessException, InstantiationException {
        ModelMapper modelMapper = new ModelMapper();
        modelMapper.addConverter(new StringToDateConverter());
        Patients patients = modelMapper.map(requestData, Patients.class);
        model.insert(patients);
    }

    @DeleteMapping("/delete")
    public String delete(@RequestBody Map<String, Object> requestData) throws SQLException, IllegalAccessException {
        System.out.println("call success");
        ModelMapper modelMapper = new ModelMapper();
        modelMapper.addConverter(new StringToDateConverter());
        Patients patients = modelMapper.map(requestData, Patients.class);
        model.delete(patients);
        return "success";
    }

    @GetMapping("/list")
    public List<T> list() throws SQLException, InvocationTargetException, NoSuchMethodException, InstantiationException, IllegalAccessException {
        return model.getAll(new Patients().getClass());
    }

    @GetMapping("/search")
    public List<Patients> getByField(@RequestParam Map<String, String> requestParams) throws Exception {
        List<Patients> patientsList = new ArrayList<>();
        ModelMapper modelMapper = new ModelMapper();
        modelMapper.addConverter(new StringToDateConverter());
        Patients patients1 = modelMapper.map(requestParams, Patients.class);
        List<Patients> patients = model.getEntityById(patients1);
        for (Patients patient : patients) {
            Patients newPatient = new Patients();
            BeanUtils.copyProperties(patient, newPatient);
            Medicalrecords medicalrecordsFilter = new Medicalrecords();
            medicalrecordsFilter.setPatient_id(patient.getPatient_id());
            List<Medicalrecords> medicalrecordsList = model.getEntityById(medicalrecordsFilter);
            List<Medicalrecords> medicalrecords = medicalrecords(medicalrecordsList);
            Appointments appointmentsFilter = new Appointments();
            appointmentsFilter.setPatient_id(patient.getPatient_id());
            List<Appointments> appointmentsList = model.getEntityById(appointmentsFilter);
            List<Appointments> appointments = listAppointments(appointmentsList);
            newPatient.setMedicalrecordsList(medicalrecords);
            newPatient.setAppointmentsList(appointments);
            patientsList.add(newPatient);
        }
        return patientsList;
    }

    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody Map<String, String> loginRequest) throws Exception {
        String patientUsername = loginRequest.get("patient_email");
        String patientPassword = loginRequest.get("patient_password");
        System.out.println("ok");
        Patients patientExample = new Patients();
        patientExample.setPatient_username(patientUsername);
        patientExample.setPatient_password(patientPassword);
        List<Patients> patients = model.getEntityById(patientExample);
        if (!patients.isEmpty()) {
            Patients patient = patients.get(0);
            Map<String, Object> response = new HashMap<>();
            response.put("patient_username", patient.getPatient_name());
            response.put("patient_id", patient.getPatient_id());
            return ResponseEntity.ok(response);
        } else {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Collections.singletonMap("success", false));
        }
    }

    @PostMapping("/google-login")
    public ResponseEntity<?> googleLogin(@RequestBody Map<String, String> request) throws Exception {
        String email = request.get("patient_email");
        String name = request.get("patient_name");
        String password = request.get("patient_password");
        System.out.println("gglogin");
        Patients patient = new Patients();
        patient.setPatient_email(email);
        List<Patients> patientsList = model.getEntityById(patient);
        if (patientsList.isEmpty()) {
            patient.setPatient_name(name);
            patient.setPatient_password(password);
            patient.setPatient_username(email);
            model.insert(patient);
        } else {
            patient = patientsList.get(0);
        }
        Map<String, Object> response = new HashMap<>();
        response.put("patient_username", patient.getPatient_name());
        response.put("patient_id", patient.getPatient_id());
        System.out.println(response);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/facebook-login")
    public ResponseEntity<?> facebookLogin(@RequestBody Map<String, String> request) throws Exception {
        String accessToken = request.get("accessToken");
        String userID = request.get("userID");
        System.out.println("ok");
        if (accessToken == null || userID == null) {
            return ResponseEntity.badRequest().body("Missing access token or user ID");
        }
        String facebookUrl = "https://graph.facebook.com/" + userID + "?fields=id,name,email&access_token=" + accessToken;
        RestTemplate restTemplate = new RestTemplate();
        ResponseEntity<Map> response;
        try {
            response = restTemplate.getForEntity(facebookUrl, Map.class);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Invalid Facebook token or user ID");
        }
        if (response.getStatusCode() != HttpStatus.OK) {
            return ResponseEntity.status(response.getStatusCode()).body("Failed to authenticate with Facebook");
        }
        Map<String, Object> userInfo = response.getBody();
        if (userInfo == null || !userInfo.containsKey("patient_email") || !userInfo.containsKey("patient_name")) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Invalid Facebook response");
        }
        String email = (String) userInfo.get("patient_email");
        String name = (String) userInfo.get("patient_name");
        Patients patient = new Patients();
        patient.setPatient_email(email);
        List<Patients> patientsList = model.getEntityById(patient);
        if (patientsList.isEmpty()) {
            patient.setPatient_name(name);
            patient.setPatient_password(UUID.randomUUID().toString());
            patient.setPatient_username(email);
            model.insert(patient);
        } else {
            patient = patientsList.get(0);
        }
        Map<String, Object> responseBody = new HashMap<>();
        responseBody.put("patient_username", patient.getPatient_name());
        responseBody.put("patient_id", patient.getPatient_id());
        return ResponseEntity.ok(responseBody);
    }

    @PostMapping("/insertAll")
    public void insertAll(@RequestBody List<Map<String, Object>> dataList) throws SQLException, IllegalAccessException {
        List<Patients> patientsList = new ArrayList<>();
        ModelMapper modelMapper = new ModelMapper();
        modelMapper.addConverter(new StringToDateConverter());
        for (Map<String, Object> data : dataList) {
            Patients patients = modelMapper.map(data, Patients.class);
            patientsList.add(patients);
        }
        model.insertAll(patientsList);
    }

    @GetMapping("/{patientId}/appointments")
    public ResponseEntity<List<Appointments>> getAppointmentsByPatientId(@PathVariable int patientId) throws SQLException, IllegalAccessException, InstantiationException {
        Appointments appointmentsFilter = new Appointments();
        appointmentsFilter.setPatient_id(patientId);
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

    @PostMapping("/register")
    public ResponseEntity<?> register(@RequestBody Map<String, String> registerRequest) throws Exception {
        ModelMapper modelMapper = new ModelMapper();
        Patients newPatient = modelMapper.map(registerRequest, Patients.class);
        newPatient.setPatient_username(newPatient.getPatient_email());
        Patients existingPatient = new Patients();
        existingPatient.setPatient_email(newPatient.getPatient_email());
        List<Patients> patientsList = model.getEntityById(existingPatient);
        if (!patientsList.isEmpty()) {
            return ResponseEntity.status(HttpStatus.CONFLICT)
                    .body(Collections.singletonMap("error", "Email already registered."));
        }
        model.insert(newPatient);
        Map<String, Object> response = new HashMap<>();
        response.put("message", "Registration successful.");
        response.put("patient_id", newPatient.getPatient_id());
        response.put("patient_username", newPatient.getPatient_username());
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @PostMapping("/change-password")
    public void changePassword(@RequestBody Map<String, Object> requestData) throws SQLException, IllegalAccessException, InstantiationException {
        ModelMapper modelMapper = new ModelMapper();
        Patients patients = modelMapper.map(requestData, Patients.class);
        System.out.println(patients.toString());
        List<Patients> list = model.getEntityById(patients);
        Patients existingPatient = list.get(0);
        if (existingPatient == null) {
            throw new IllegalArgumentException("Patient not found.");
        }
        String currentPassword = (String) requestData.get("currentPassword");
        if (!currentPassword.equals(existingPatient.getPatient_password())) {
            throw new IllegalArgumentException("Current password is incorrect.");
        }
        String newPassword = (String) requestData.get("newPassword");
        existingPatient.setPatient_password(newPassword);
        model.update(existingPatient);
    }

    @PutMapping("/update")
    public void update(@RequestBody Map<String, Object> requestData) throws SQLException, IllegalAccessException {
        System.out.println("==================================================================================================================");
        ModelMapper modelMapper = new ModelMapper();
        modelMapper.addConverter(new StringToDateConverter());
        Patients patients = modelMapper.map(requestData, Patients.class);
        System.out.println("Mapped patient: " + patients);
        if (requestData.containsKey("patient_img")) {
            patients.setPatient_img((String) requestData.get("patient_img"));
        }
        patients.setAppointmentsList(null);
        patients.setMedicalrecordsList(null);
        model.update(patients);
    }
    @PutMapping("/update2")
    public void update2(@RequestBody Map<String, Object> requestData) throws SQLException, IllegalAccessException {
        System.out.println("==================================================================================================================");
        System.out.println("Request data received: " + requestData);

        ModelMapper modelMapper = new ModelMapper();

        // Thêm converter cho LocalDateTime
        modelMapper.addConverter(new StringToLocalDateTimeConverter());

        Patients patients = modelMapper.map(requestData, Patients.class);
        System.out.println("Mapped patient: " + patients);
        System.out.println("Patient DOB after mapping: " + patients.getPatient_dob());

        if (requestData.containsKey("patient_img")) {
            patients.setPatient_img((String) requestData.get("patient_img"));
        }

        patients.setAppointmentsList(null);
        patients.setMedicalrecordsList(null);

        model.update(patients);
        System.out.println("Patient updated successfully");
    }

    // ===== IMAGE UPDATE API - SIMPLE STRING HANDLING =====
    @PutMapping("/update-image")
    public ResponseEntity<Map<String, String>> updateImage(@RequestBody Map<String, Object> requestData) {
        try {
            Integer patientId = (Integer) requestData.get("patient_id");
            String imageString = (String) requestData.get("patient_img");

            // Basic validation
            if (patientId == null || imageString == null || imageString.isEmpty()) {
                Map<String, String> errorResponse = new HashMap<>();
                errorResponse.put("error", "Patient ID and image data are required");
                return ResponseEntity.badRequest().body(errorResponse);
            }

            // Update patient image - just treat it as a regular string
            updatePatientImage(patientId, imageString);

            Map<String, String> response = new HashMap<>();
            response.put("message", "Image updated successfully");
            response.put("patient_id", patientId.toString());

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            System.err.println("Error updating patient image: " + e.getMessage());
            e.printStackTrace();

            Map<String, String> errorResponse = new HashMap<>();
            errorResponse.put("error", "Failed to update image: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }

    private void updatePatientImage(Integer patientId, String imageString) throws SQLException, IllegalAccessException, InstantiationException {
        try {
            // Get existing patient
            Patients patientFilter = new Patients();
            patientFilter.setPatient_id(patientId);
            List<Patients> patientsList = model.getEntityById(patientFilter);

            if (patientsList.isEmpty()) {
                throw new IllegalArgumentException("Patient not found with ID: " + patientId);
            }

            Patients patient = patientsList.get(0);

            // Simply save the string (whether it's base64, file path, or any other string format)
            patient.setPatient_img(imageString);

            System.out.println("Updating patient with ID: " + patientId + " with image data (length: " + imageString.length() + ")");
            model.update(patient);

        } catch (Exception e) {
            System.err.println("Error updating patient image: " + e.getMessage());
            throw new RuntimeException("Failed to update patient image", e);
        }
    }

    @GetMapping("/search-new")
    public List<Patients> searchPatientsByKeyword(@RequestParam("keyword") String keyword) throws Exception {
        System.out.println(keyword);
        return model.searchPatientsByKeyword(keyword);
    }

    @GetMapping("/{patientId}")
    public ResponseEntity<Patients> getPatientById(@PathVariable int patientId) throws SQLException, IllegalAccessException, InstantiationException {
        Patients patientFilter = new Patients();
        patientFilter.setPatient_id(patientId);
        List<Patients> patientsList = model.getEntityById(patientFilter);
        if (patientsList.isEmpty()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(null);
        }
        Patients patient = patientsList.get(0);
        return ResponseEntity.ok(patient);
    }
}
