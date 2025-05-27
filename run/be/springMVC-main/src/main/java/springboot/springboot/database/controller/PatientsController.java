package springboot.springboot.database.controller;

import org.springframework.web.multipart.MultipartFile;
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

import java.io.File;
import java.io.IOException;
import java.lang.reflect.Field;
import java.lang.reflect.InvocationTargetException;
import java.sql.SQLException;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
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
            response.put("patient_id", patient.getPatient_id()); // Thêm patient_id vào phản hồi
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
            patient.setPatient_username(email);  // Assuming email is used as username
            model.insert(patient);
        } else {
            patient = patientsList.get(0);
        }

        Map<String, Object> response = new HashMap<>();
        response.put("patient_name", patient.getPatient_name());
        response.put("patient_id", patient.getPatient_id()); // Thêm patient_id vào phản hồi
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

        // Facebook API URL to get user info
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
            patient.setPatient_password(UUID.randomUUID().toString()); // Generate random password
            patient.setPatient_username(email);  // Assuming email is used as username
            model.insert(patient);
        } else {
            patient = patientsList.get(0);
        }

        Map<String, Object> responseBody = new HashMap<>();
        responseBody.put("patient_username", patient.getPatient_name());
        responseBody.put("patient_id", patient.getPatient_id()); // Thêm patient_id vào phản hồi

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

        // Map các trường từ request sang đối tượng Patients
        Patients newPatient = modelMapper.map(registerRequest, Patients.class);
        newPatient.setPatient_username(newPatient.getPatient_email());

        // Kiểm tra xem email đã được sử dụng chưa
        Patients existingPatient = new Patients();
        existingPatient.setPatient_email(newPatient.getPatient_email());

        List<Patients> patientsList = model.getEntityById(existingPatient);

        // Nếu email đã được đăng ký
        if (!patientsList.isEmpty()) {
            return ResponseEntity.status(HttpStatus.CONFLICT)
                    .body(Collections.singletonMap("error", "Email already registered."));
        }

        // Lưu trữ đối tượng mới vào cơ sở dữ liệu
        model.insert(newPatient);

        // Tạo phản hồi chứa thông tin cần thiết
        Map<String, Object> response = new HashMap<>();
        response.put("message", "Registration successful.");
        response.put("patient_id", newPatient.getPatient_id()); // Giả sử đối tượng newPatient có trường này
        response.put("patient_username", newPatient.getPatient_username());

        // Trả về response với status 201 Created và thông tin cần thiết
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @PostMapping("/change-password")
    public void changePassword(@RequestBody Map<String, Object> requestData) throws SQLException, IllegalAccessException, InstantiationException {
        ModelMapper modelMapper = new ModelMapper();
        Patients patients = modelMapper.map(requestData, Patients.class);
        System.out.println(patients.toString());
        // Kiểm tra và lấy bệnh nhân từ cơ sở dữ liệu
        List<Patients> list = model.getEntityById(patients);
        Patients existingPatient = list.get(0);
        if (existingPatient == null) {
            throw new IllegalArgumentException("Patient not found.");
        }

        // Kiểm tra mật khẩu hiện tại
        String currentPassword = (String) requestData.get("currentPassword");
        if (!currentPassword.equals(existingPatient.getPatient_password())) {
            throw new IllegalArgumentException("Current password is incorrect.");
        }

        // Cập nhật mật khẩu mới
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

        // Đảm bảo rằng đường dẫn ảnh được bao gồm trong requestData
        if (requestData.containsKey("patient_img")) {
            patients.setPatient_img((String) requestData.get("patient_img"));
        }
        // Chuyển đổi ngày sinh (patient_dob) sang LocalDate nếu nó tồn tại trong requestD
        // Set các danh sách khác về null để tránh lỗi ánh xạ không cần thiết
        patients.setAppointmentsList(null);
        patients.setMedicalrecordsList(null);

        // Cập nhật bệnh nhân
        model.update(patients);
    }
    @PostMapping("/upload-image")
    public ResponseEntity<Map<String, String>> uploadImage(@RequestParam("patient_image") MultipartFile image, @RequestParam("patient_id") Integer patientId) {
        String imagePath = ""; // Tùy chỉnh logic lưu trữ và đường dẫn ảnh

        try {
            // Lưu trữ ảnh và cập nhật đường dẫn ảnh vào cơ sở dữ liệu
            imagePath = saveImage(image);
            updatePatientImage(patientId, imagePath);

            Map<String, String> response = new HashMap<>();
            response.put("filePath", imagePath);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(null);
        }
    }

    private String saveImage(MultipartFile image) throws IOException {
        // Lưu ảnh vào thư mục uploads và trả về đường dẫn ảnh
        String uploadsDir = "uploads/";
        String realPathtoUploads = new File(uploadsDir).getAbsolutePath();
        if (!new File(realPathtoUploads).exists()) {
            new File(realPathtoUploads).mkdir();
        }

        String orgName = image.getOriginalFilename();
        String filePath = realPathtoUploads + File.separator + orgName;
        File dest = new File(filePath);
        image.transferTo(dest);
        return uploadsDir + orgName;
    }

    private void updatePatientImage(Integer patientId, String imagePath) throws SQLException, IllegalAccessException, InstantiationException {
        Patients patient = new Patients();
        patient.setPatient_id(patientId);
        List<Patients> patientsList = model.getEntityById(patient);
        if (!patientsList.isEmpty()) {
            patient = patientsList.get(0);
            patient.setPatient_img(imagePath);
            System.out.println("Updating patient with ID: " + patientId + " with image path: " + imagePath);
            model.update(patient);
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
