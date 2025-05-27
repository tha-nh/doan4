package springboot.springboot.database.controller;

import org.modelmapper.ModelMapper;
import org.springframework.beans.BeanUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import springboot.springboot.database.entity.*;
import springboot.springboot.database.model.EntityToJSON;
import springboot.springboot.database.model.ModelBuid;

import java.io.IOException;
import java.lang.reflect.Field;
import java.lang.reflect.InvocationTargetException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.sql.SQLException;
import java.util.*;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/v1/medicalrecords")
public class MedicalrecordsController<T extends Entity<?>> {

    @Autowired
    private ModelBuid model;
    private EntityToJSON json = new EntityToJSON();

    @PostMapping("/insert")
    public void insert(@RequestBody Map<String, Object> requestData) throws SQLException, IllegalAccessException, InstantiationException {
        ModelMapper modelMapper = new ModelMapper();
        modelMapper.addConverter(new StringToDateConverter());
        Medicalrecords medicalrecords = modelMapper.map(requestData, Medicalrecords.class);
        System.out.println("Severity: " + medicalrecords.getSeverity() + "==========");
        model.insert(medicalrecords);
    }

    @PutMapping("/update")
    public void update(@RequestBody Map<String, Object> requestData) throws SQLException, IllegalAccessException {
        ModelMapper modelMapper = new ModelMapper();
        modelMapper.addConverter(new StringToDateConverter());
        Medicalrecords medicalrecords = modelMapper.map(requestData, Medicalrecords.class);
        model.update(medicalrecords);
    }

    @DeleteMapping("/delete")
    public String delete(@RequestBody Map<String, Object> requestData) throws SQLException, IllegalAccessException {
        ModelMapper modelMapper = new ModelMapper();
        modelMapper.addConverter(new StringToDateConverter());
        Medicalrecords medicalrecord = modelMapper.map(requestData, Medicalrecords.class);
        System.out.println(medicalrecord.toString());
        // Kiểm tra xem ID có null hay không
        if (medicalrecord.getRecord_id() == null) {
            throw new IllegalArgumentException("ID value cannot be null");
        }

        // In ra log để kiểm tra ID
        System.out.println("Deleting record with ID: " + medicalrecord.getRecord_id());

        model.delete(medicalrecord);
        return "success";
    }



    @GetMapping("/list")
    public List<T> list() throws SQLException, IllegalAccessException, NoSuchMethodException, InstantiationException, InvocationTargetException {
        return model.getAll(new Medicalrecords().getClass());
    }

    @GetMapping("/search")
    public List<Medicalrecords> getByField(@RequestParam Map<String, String> requestParams) {
        try {
            List<Medicalrecords> medicalrecordsList = new ArrayList<>();
            ModelMapper modelMapper = new ModelMapper();
            modelMapper.addConverter(new StringToDateConverter());

            Medicalrecords medicalrecords1 = modelMapper.map(requestParams, Medicalrecords.class);
            System.out.println(medicalrecords1.toString()+"=======");
            List<Medicalrecords> medicalrecords = model.getEntityById(medicalrecords1);

            for (Medicalrecords record : medicalrecords) {
                Medicalrecords newRecord = new Medicalrecords();
                BeanUtils.copyProperties(record, newRecord);

                Patients patientsFilter = new Patients();
                patientsFilter.setPatient_id(record.getPatient_id());
                List<Patients> patientsList = model.getEntityById(patientsFilter);
                newRecord.setPatients(patientsList);

                Doctors doctorsFilter = new Doctors();
                if (record.getDoctor_id() != null) {
                    doctorsFilter.setDoctor_id(record.getDoctor_id());
                    List<Doctors> doctorsList = model.getEntityById(doctorsFilter);
                    newRecord.setDoctors(doctorsList);
                } else {
                    // Nếu không có doctor_id, có thể set null hoặc giá trị mặc định
                    newRecord.setDoctors(null);
                }

                medicalrecordsList.add(newRecord);
            }


            return medicalrecordsList;
        } catch (Exception e) {
            e.printStackTrace();
            return new ArrayList<>();
        }
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
    @GetMapping("/fields")
    public ResponseEntity<List<String>> getMedicalRecordFields() {
        Field[] fields = Medicalrecords.class.getDeclaredFields();
        List<String> fieldNames = Arrays.stream(fields)
                .map(Field::getName)
                .collect(Collectors.toList());
        return ResponseEntity.ok(fieldNames);
    }
    @GetMapping("/doctor/{doctorId}")
    public List<Medicalrecords> getByDoctorId(@PathVariable int doctorId) {
        try {
            Medicalrecords filter = new Medicalrecords();
            filter.setDoctor_id(doctorId);
            List<Medicalrecords> records = model.getEntityById(filter);

            for (Medicalrecords record : records) {
                Patients patientsFilter = new Patients();
                patientsFilter.setPatient_id(record.getPatient_id());
                List<Patients> patientsList = model.getEntityById(patientsFilter);
                record.setPatients(patientsList);

                Doctors doctorsFilter = new Doctors();
                doctorsFilter.setDoctor_id(record.getDoctor_id());
                List<Doctors> doctorsList = model.getEntityById(doctorsFilter);
                record.setDoctors(doctorsList);
            }

            return records;
        } catch (Exception e) {
            e.printStackTrace();
            return new ArrayList<>();
        }
    }
    @PostMapping("/images/upload")
    public ResponseEntity<Map<String, Object>> uploadImages(@RequestParam("files") MultipartFile[] files) {
        List<String> imagePaths = new ArrayList<>();

        for (MultipartFile file : files) {
            try {
                // Đường dẫn nơi lưu ảnh
                String uploadDir = "uploads/images/";
                String fileName = UUID.randomUUID().toString() + "_" + file.getOriginalFilename();

                // Sử dụng replace để thay thế dấu \ thành /
                String filePathString = uploadDir + fileName.replace("\\", "/");
                Path filePath = Paths.get(filePathString);

                // Tạo thư mục nếu chưa tồn tại
                Files.createDirectories(filePath.getParent());

                // Lưu file vào hệ thống
                Files.write(filePath, file.getBytes());

                // Thêm đường dẫn file vào danh sách trả về (sử dụng dấu /)
                imagePaths.add(filePathString);

            } catch (IOException e) {
                e.printStackTrace();
                return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(null);
            }
        }

        // Trả về danh sách đường dẫn ảnh đã lưu
        Map<String, Object> response = new HashMap<>();
        response.put("paths", imagePaths);
        return ResponseEntity.ok(response);
    }

}
