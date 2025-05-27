package springboot.springboot.database.controller;

import org.modelmapper.ModelMapper;
import org.springframework.beans.BeanUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import springboot.springboot.database.model.EntityToJSON;
import springboot.springboot.database.model.ModelBuid;
import springboot.springboot.database.entity.Departments;
import springboot.springboot.database.entity.Doctors;
import springboot.springboot.database.entity.Entity;

import java.lang.reflect.Constructor;
import java.lang.reflect.InvocationTargetException;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/departments")
public class DepartmentsController<T extends Entity<?>> {
    private EntityToJSON json = new EntityToJSON();
    @Autowired
    private ModelBuid model = new ModelBuid();

    @PostMapping("/insert")
    public void insert(@RequestBody Map<String, Object> requestData) throws SQLException, IllegalAccessException, InstantiationException {
        ModelMapper modelMapper = new ModelMapper();
        Departments departments = modelMapper.map(requestData, Departments.class);
        model.insert(departments);
    }

    @PutMapping("/update")
    public void update(@RequestBody Map<String, Object> requestData) throws SQLException, IllegalAccessException {
        ModelMapper modelMapper = new ModelMapper();
        Departments departments = modelMapper.map(requestData, Departments.class);
        model.update(departments);
    }

    @DeleteMapping("/delete")
    public void delete(@RequestBody Map<String, Object> requestData) throws SQLException, IllegalAccessException {
        ModelMapper modelMapper = new ModelMapper();
        Departments departments = modelMapper.map(requestData, Departments.class);
        model.delete(departments);
    }

    @GetMapping("/list")
    public List<T> list() throws SQLException, InvocationTargetException, NoSuchMethodException, InstantiationException, IllegalAccessException {
        return model.getAll(Departments.class);
    }

    @GetMapping("/search")
    public List<Departments> getByField(@RequestParam Map<String, String> requestParams) {
        try {
            List<Departments> departmentsList = new ArrayList<>();
            ModelMapper modelMapper = new ModelMapper();

            Departments departmentsFilter = modelMapper.map(requestParams, Departments.class);
            List<Departments> departments = model.getEntityById(departmentsFilter);

            for (Departments department : departments) {
                Departments newDepartment = new Departments();
                BeanUtils.copyProperties(department, newDepartment);
                System.out.println(newDepartment.toString());
                Doctors doctorsFilter = new Doctors();
                doctorsFilter.setDepartment_id(department.getDepartment_id());
                List<Doctors> doctorsList = model.getEntityById(doctorsFilter);
                newDepartment.setDoctorsList(doctorsList);

                departmentsList.add(newDepartment);
            }

            return departmentsList;
        } catch (Exception e) {
            e.printStackTrace();
            return new ArrayList<>();
        }
    }


    @GetMapping("/{departmentId}/doctors")
    public List<Doctors> getDoctorsByDepartmentId(@PathVariable("departmentId") int departmentId) throws SQLException, IllegalAccessException, InstantiationException {
        Doctors doctors = new Doctors();
        doctors.setDepartment_id(departmentId);

        return model.getEntityById(doctors);
    }

    @PostMapping("/insertAll")
    public void insertAll(@RequestBody List<Map<String, Object>> dataList) throws SQLException, IllegalAccessException {
        ModelMapper modelMapper = new ModelMapper();
        List<Departments> departmentsList = new ArrayList<>();
        for (Map<String, Object> data : dataList) {
            Departments departments = modelMapper.map(data, Departments.class);
            departmentsList.add(departments);
        }
        model.insertAll(departmentsList);
    }

    public static Object createElementInstance(Class<?> elementType) throws Exception {
        Constructor<?> constructor = elementType.getConstructor();
        return constructor.newInstance();
    }
}
