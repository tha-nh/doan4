package com.project.appoinmentservice.service.implement;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import com.project.appoinmentservice.dto.*;
import com.project.appoinmentservice.model.Appointment;
import com.project.appoinmentservice.model.AppointmentStatus;
import com.project.appoinmentservice.repository.AppointmentRepository;
import com.project.appoinmentservice.service.AppointmentService;
import com.project.appoinmentservice.service.SendEmail;
import org.modelmapper.ModelMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.*;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.time.LocalDate;
import java.time.ZoneId;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;

import static org.springframework.kafka.support.KafkaHeaders.TOPIC;

@Service
public class AppointmentServiceImpl implements AppointmentService {

    @Autowired
    private AppointmentRepository appointmentRepository;

    @Autowired
    private KafkaTemplate<String, String> kafkaTemplate;

    private static final String TOPIC = "appointment";

    private final RestTemplate restTemplate  = new RestTemplate();

    @Autowired
    private SendEmail sendEmail;

    public Integer getPatientFromApi(String patientEmail, String patientPhone, String patientName) {
        String url = "http://localhost:8080/api/userservice/notjwt/patients/check";
        PatientRequest requestBody = new PatientRequest(patientEmail, patientPhone, patientName);
        System.out.println(requestBody);
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        HttpEntity<PatientRequest> entity = new HttpEntity<>(requestBody, headers);

        ResponseEntity<Map> response = restTemplate.exchange(url, HttpMethod.POST, entity, Map.class);
        System.out.println("Phản hồi API: " + response.getBody());
        // Kiểm tra phản hồi để lấy giá trị patientId
        Map<String, Object> responseBody = response.getBody();
        if (responseBody != null && responseBody.containsKey("id")) {
            // Lấy patientId dưới dạng String
            return (Integer)responseBody.get("id");
        } else {
            // Xử lý trường hợp không tìm thấy patientId
            throw new RuntimeException("Không tìm thấy patientId trong phản hồi");
        }
    }

    public Appointment saveAppointment(Appointment appointment) {
           return appointmentRepository.save(appointment);
    }


    public boolean createPayment(PaymentRequest paymentDTO) {
        System.out.println("gọi hàm create payment");
        System.out.println(paymentDTO.toString());
        String url = "http://localhost:8080/api/paymentservice/create";
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        HttpEntity<PaymentRequest> entity = new HttpEntity<>(paymentDTO, headers);
        try {
            ResponseEntity<Void> response = restTemplate.exchange(url, HttpMethod.POST, entity, Void.class);
            System.out.println("API Response Status: " + response.getStatusCode());
            if (response.getStatusCode() == HttpStatus.CREATED) {
                return true;
            } else {
                return false;
            }
        } catch (Exception e) {
            System.err.println("Lỗi khi gọi API thanh toán: " + e.getMessage());
            return false;
        }
    }
    public boolean  transactionSuccess(AppoinmntTransactionDTO appoinmntTransactionDTO) {
        System.out.println("gọi sang transactionService thông báo success");
        String url = "http://localhost:8080/api/transactions/create";
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        HttpEntity<AppoinmntTransactionDTO> entity = new HttpEntity<>(appoinmntTransactionDTO, headers);
        try {
            ResponseEntity<Void> response = restTemplate.exchange(url, HttpMethod.POST, entity, Void.class);
            System.out.println("API Response Status: " + response.getStatusCode());
            if (response.getStatusCode() == HttpStatus.CREATED) {
                return true;
            } else {
                return false;
            }
        } catch (Exception e) {
            System.err.println("Lỗi khi gọi API Transaction: " + e.getMessage());
            return false;
        }
    }
    @Override
    public List<Appointment> getAppointmentsByDoctor(Integer doctorId) {
        List<Appointment> appointments = appointmentRepository.findByDoctorId(doctorId);
        Iterator<Appointment> iterator = appointments.iterator();

        LocalDate currentDate = LocalDate.now(); // Lấy ngày hiện tại

        while (iterator.hasNext()) {
            Appointment appointment = iterator.next();

            // Chuyển đổi medicalDay từ Date sang LocalDate
            LocalDate medicalDay = appointment.getMedicalDay().toInstant()
                    .atZone(ZoneId.systemDefault())
                    .toLocalDate();

            // Kiểm tra điều kiện: loại bỏ các lịch hẹn đã xác nhận và có ngày trong quá khứ
            // Lịch hẹn được giữ lại nếu ngày medicalDay là hôm nay hoặc trong tương lai
            if (appointment.getStatus() != AppointmentStatus.CONFIRMED || medicalDay.isBefore(currentDate)) {
                iterator.remove(); // Loại bỏ phần tử nếu không thỏa mãn điều kiện
            }
        }
        return appointments;
    }




    @Override
    public ResponseEntity<Map<String, Object>> register(AppointmentRequestDTO appointmentRequestDTO) {
        System.out.println("gọi hàm register");
        System.out.println(appointmentRequestDTO.toString());
        ObjectMapper mapper = new ObjectMapper();
        mapper.registerModule(new JavaTimeModule());
        mapper.configure(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS, false);

        Appointment appointment = mapper.convertValue(appointmentRequestDTO, Appointment.class);
        appointment.setStatus(AppointmentStatus.CONFIRMED);
        PaymentRequest paymentRequest = mapper.convertValue(appointmentRequestDTO, PaymentRequest.class);
        System.out.println(paymentRequest.toString());
        Map<String, Object> response = new HashMap<>();
        try {
            appointment.setPatientId(getPatientFromApi(appointmentRequestDTO.getPatientEmail(), appointmentRequestDTO.getPatientPhone(), appointmentRequestDTO.getPatientName()));
            paymentRequest.setPatientId(getPatientFromApi(appointmentRequestDTO.getPatientEmail(), appointmentRequestDTO.getPatientPhone(), appointmentRequestDTO.getPatientName()));
            paymentRequest.setAppointmentId(saveAppointment(appointment).getAppointmentId());
//            boolean paymentSuccess = createPayment(paymentRequest);
//            System.out.println(paymentSuccess);
//            if (paymentSuccess) {
//                sendEmail.sendEmailFormRegisterAppointment();
//            }
            Appointment savedAppointment = saveAppointment(appointment);
            if (savedAppointment != null) { // Kiểm tra nếu lưu thành công
                AppoinmntTransactionDTO appointmentTransactionDTO = new AppoinmntTransactionDTO();
                appointmentTransactionDTO.setAppointmentId(savedAppointment.getAppointmentId());
                appointmentTransactionDTO.setOrderID(appointmentRequestDTO.getOrderID());
                appointmentTransactionDTO.setStatus(String.valueOf(AppointmentStatus.CONFIRMED));
                appointmentTransactionDTO.setRandomCode(appointmentRequestDTO.getRandomCode());
                System.out.println(appointmentTransactionDTO.toString());
                transactionSuccess(appointmentTransactionDTO);
            } else {
                return ResponseEntity.status(HttpStatus.CONFLICT).body(response);
            }

            response.put("appointment", savedAppointment);
//            response.put("paymentSuccess", paymentSuccess);

            return ResponseEntity.ok(response);
        } catch (Exception e) {
            response.put("appointment", null);
            response.put("paymentSuccess", false);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(response);
        }
    }

    @KafkaListener(topics = "transaction", groupId = "appointment-group")
    public void consume(@Payload String payload) throws JsonProcessingException {
        ClientRequestDTO clientRequest = new ObjectMapper().readValue(payload, ClientRequestDTO.class);
        System.out.println("dữ liệu đã nhận :" + clientRequest);
        ModelMapper modelMapper = new ModelMapper();
        Appointment appointment = modelMapper.map(clientRequest, Appointment.class);
        Appointment savedAppointment = saveAppointment(appointment);
        if (savedAppointment != null) {
            responseToTransaction();
        }
    }

    public void responseToTransaction(){
        kafkaTemplate.send(TOPIC, "success");
    }

}
