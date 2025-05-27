package springboot.springboot.database.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import springboot.springboot.database.entity.Patients;
import springboot.springboot.database.model.ModelBuid;
import springboot.springboot.database.model.SendEmailUsername;

import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/forgotpass")
@CrossOrigin(origins = "http://localhost:3000")
public class ForgotPassController {
    public SendEmailUsername sendEmail;
    @Autowired
    private ModelBuid model;

    @PutMapping("/forgot")
    public void forgot(@RequestBody Map<String, String> requestData) throws SQLException, IllegalAccessException, InstantiationException {
        String patientEmail = requestData.get("patient_email");
        String patientCode = requestData.get("patient_code");
        Patients patients = new Patients();
        patients.setPatient_email(patientEmail);
        List<Patients> list = model.getEntityById(patients);
        for (Patients p : list) {
            if (p.getPatient_email().equals(patientEmail)) {

                sendEmail.sendEmailForgot(p.getPatient_name(), p.getPatient_email(), patientCode);
            }
        }
        // Gọi phương thức forgotPassword với các tham số
        model.forgotPassword(patientEmail, patientCode);
    }
    @PutMapping("/reset")
    public void resetPassword(@RequestBody Map<String, String> requestData) throws SQLException {
        String patientEmail = requestData.get("patient_email");
        String patientCode = requestData.get("patient_code");
        String newPassword = requestData.get("new_password");
        // Gọi phương thức resetPassword với các tham số
        model.resetPassword(patientEmail, patientCode, newPassword);
    }
}
