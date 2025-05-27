package springboot.springboot.database.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import springboot.springboot.database.entity.*;

import java.lang.reflect.Field;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/fields")
public class FieldsController {

    @GetMapping("/{category}")
    public ResponseEntity<List<Map<String, String>>> getFields(@PathVariable String category) {
        List<Map<String, String>> fields;
        switch (category.toLowerCase()) {
            case "patients":
                fields = getFields(Patients.class);
                break;
            case "staffs":
                fields = getFields(Staffs.class);
                break;
            case "doctors":
                fields = getFields(Doctors.class);
                break;
            case "appointments":
                fields = getFields(Appointments.class);
                break;
            case "departments":
                fields = getFields(Departments.class);
                break;
            case "medicalrecords":
                fields = getFields(Medicalrecords.class);
                break;
            default:
                return ResponseEntity.notFound().build();
        }
        return ResponseEntity.ok(fields);
    }

    private List<Map<String, String>> getFields(Class<?> clazz) {
        List<Map<String, String>> fields = new ArrayList<>();
        for (Field field : clazz.getDeclaredFields()) {
            if (!List.class.isAssignableFrom(field.getType())) { // Loại bỏ các trường là danh sách
                Map<String, String> fieldInfo = new HashMap<>();
                fieldInfo.put("field", field.getName());
                fieldInfo.put("headerName", field.getName().substring(0, 1).toUpperCase() + field.getName().substring(1));
                fields.add(fieldInfo);
            }
        }
        return fields;
    }
}
