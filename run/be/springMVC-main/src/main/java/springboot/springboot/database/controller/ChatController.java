package springboot.springboot.database.controller;

import org.json.JSONObject;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.client.RestTemplate;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/chat")
public class ChatController {

    private static final String WIT_AI_API_URL = "https://api.wit.ai/message?v=20230516&q=";
    private static final String WIT_AI_AUTH_TOKEN = "Bearer J3OV3JPRNG2MWGNUMBYE2MOKOT54KJ2S"; // Đảm bảo rằng bạn đã thay YOUR_WIT_AI_SERVER_ACCESS_TOKEN bằng token thực tế

    @PostMapping
    public ResponseEntity<Map<String, String>> getReply(@RequestBody Map<String, String> request) {
        String userMessage = request.get("message");
        String reply = generateReply(userMessage);

        Map<String, String> response = new HashMap<>();
        response.put("reply", reply);
        return new ResponseEntity<>(response, HttpStatus.OK);
    }

    private String generateReply(String userMessage) {
        RestTemplate restTemplate = new RestTemplate();
        String url = WIT_AI_API_URL + userMessage;
        HttpHeaders headers = new HttpHeaders();
        headers.set("Authorization", WIT_AI_AUTH_TOKEN);
        HttpEntity<String> entity = new HttpEntity<>(headers);

        try {
            ResponseEntity<String> response = restTemplate.exchange(url, HttpMethod.GET, entity, String.class);
            String responseString = response.getBody();
            System.out.println("Received response: " + responseString);  // Log response
            return extractReplyFromResponse(responseString);
        } catch (Exception e) {
            e.printStackTrace();
            return "Sorry, something went wrong.";
        }
    }

    private String extractReplyFromResponse(String responseString) {
        try {
            JSONObject jsonResponse = new JSONObject(responseString);
            System.out.println("JSON Response: " + jsonResponse.toString(2));  // Log JSON response pretty printed

            // Check if there are any intents in the response
            if (jsonResponse.has("intents") && jsonResponse.getJSONArray("intents").length() > 0) {
                String reply = jsonResponse.getJSONArray("intents").getJSONObject(0).getString("name");
                return reply;
            } else {
                return "Intent not found in response.";
            }
        } catch (Exception e) {
            e.printStackTrace();
            return "Error parsing response from API.";
        }
    }
}
