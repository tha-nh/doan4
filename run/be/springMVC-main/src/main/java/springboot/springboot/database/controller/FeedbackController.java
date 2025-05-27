// FeedbackController.java
package springboot.springboot.database.controller;

import org.modelmapper.ModelMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import springboot.springboot.database.entity.Feedback;
import springboot.springboot.database.entity.FeedbackReplyDto;
import springboot.springboot.database.model.ModelBuid;
import springboot.springboot.database.model.SendEmailUsername;

import java.sql.SQLException;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/feedback")
public class FeedbackController {

    @Autowired
    private ModelBuid model;

    @Autowired
    private ModelMapper modelMapper;

    @PostMapping("/submit")
    public ResponseEntity<?> submitFeedback(@RequestBody Map<String, String> requestData) {
        try {
            Feedback feedback = modelMapper.map(requestData, Feedback.class);
            feedback.setCreated_at(LocalDateTime.now());

            model.saveFeedback(feedback);

            return ResponseEntity.ok("Thank you for your feedback!");
        } catch (SQLException e) {
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("Có lỗi xảy ra, vui lòng thử lại.");
        }
    }

    @GetMapping("/list")
    public ResponseEntity<List<Feedback>> getFeedbackList() {
        try {
            List<Feedback> feedbackList = model.getAll(Feedback.class);
            return ResponseEntity.ok(feedbackList);
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(null);
        }
    }

    @PostMapping("/reply")
    public ResponseEntity<String> replyToFeedback(@RequestBody FeedbackReplyDto replyDto) {

        try {
            SendEmailUsername sendEmailUsername = new SendEmailUsername();
            sendEmailUsername.sendEmailReply(replyDto.getName(), replyDto.getEmail(), replyDto.getMessage());

            return ResponseEntity.ok("Email sent successfully");
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("Error sending email");
        }
    }



}
